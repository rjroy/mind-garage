extends Node
## Rink acoustics and an original, two-phrase chamber score. No sampled assets.

const SAMPLE_RATE := 24000.0
const SAMPLE_TIME := 1.0 / SAMPLE_RATE
const QUEUE_FRAMES := 1152 # 48 ms of synthesis, in addition to the device latency.
const PULSE := 0.33
const PULSES_PER_BAR := 8
const PAD_VOICES := 4
const PLUCK_VOICES := 6
const CUE_VOICES := 4
const REFLECTION_SHORT := 2272
const REFLECTION_LONG := 4214
const REFLECTION_FRAMES := REFLECTION_LONG + 1

# Dmaj7, Bm7, Gmaj7, A7sus. The second phrase lifts the melody, but not the bass.
const HARMONY := [
	[50, 57, 61, 66], [47, 57, 62, 66], [43, 55, 59, 66], [45, 55, 62, 64],
]
const MELODY := [
	[69, -1, 73, -1, 76, -1, 74, -1],
	[71, -1, 69, 66, -1, 64, -1, -1],
	[67, -1, 71, -1, 74, -1, 78, -1],
	[76, -1, 71, -1, 69, 67, -1, 64],
	[69, -1, 76, -1, 78, 76, -1, 73],
	[74, -1, 71, -1, 66, -1, 69, -1],
	[71, -1, 74, -1, 78, -1, 81, -1],
	[79, -1, 76, 74, -1, 71, 69, -1],
]
const BOW_CHORD := [50, 57, 59, 66]
const BOW_MELODY := [81, -1, 78, -1, 76, -1, 74, -1, -1, -1, 69, -1, 74]

const OPEN := &"opening"
const FINALE := &"finale"
const BOW := &"bow"

enum Timbre { FELT, STRING, BELL }


class Voice:
	var color: int
	var left: float
	var right: float
	var phase: float
	var increment: float
	var age: float
	var duration: float
	var attack: float
	var release: float
	var damping: float
	var decay: float

	func strike(
		midi: int, tone: int, gain: float, pan: float, length: float, delay: float = 0.0
	) -> void:
		color = tone
		left = gain * (1.0 - pan)
		right = gain * (1.0 + pan)
		phase = 0.0
		increment = TAU * 440.0 * pow(2.0, (midi - 69.0) / 12.0) * SAMPLE_TIME
		age = -delay
		duration = length
		damping = 1.0
		match color:
			Timbre.STRING:
				attack = 0.42
				release = minf(length * 0.67, 2.8)
				decay = 1.0
			Timbre.BELL:
				attack = 0.012
				release = 0.17
				decay = exp(-SAMPLE_TIME * 5.5)
			_:
				attack = 0.024
				release = 0.22
				decay = exp(-SAMPLE_TIME * 3.4)

	func ring_out() -> void:
		if age < duration:
			duration = minf(duration, age + release)

	func sample() -> Vector2:
		if age >= duration:
			return Vector2.ZERO
		age += SAMPLE_TIME
		if age <= 0.0:
			return Vector2.ZERO
		phase += increment
		if phase > TAU:
			phase -= TAU
		var gain := minf(age / attack, 1.0) * clampf((duration - age) / release, 0.0, 1.0)
		var wave := sin(phase)
		match color:
			Timbre.STRING:
				wave += sin(phase * 2.0) * 0.23 + sin(phase * 3.0) * 0.095
				gain *= gain
			Timbre.BELL:
				wave += sin(phase * 2.0) * damping * 0.28 + sin(phase * 5.0) * damping * 0.14
			_:
				wave += sin(phase * 2.0) * damping * 0.32 + sin(phase * 3.0) * damping * 0.15
		damping *= decay
		return Vector2(left, right) * (wave * gain * damping)


var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _queue_space := 0
var _rng := RandomNumberGenerator.new()
var _pads: Array[Voice] = []
var _plucks: Array[Voice] = []
var _cues: Array[Voice] = []
var _pad_bank := 0
var _pluck_index := 0
var _cue_index := 0
var _cue_serial := -1
var _phase: StringName = OPEN
var _score_time := 0.0
var _next_pulse := 0
var _partners := 0
var _reflections := PackedVector2Array()
var _reflection_index := 0

var _hush_target := 0.0
var _scrape_target := 0.0
var _hum_target := 0.0
var _pitch_target := 94.0
var _pan_target := 0.0
var _hush := 0.0
var _scrape := 0.0
var _hum := 0.0
var _pitch := 94.0
var _pan := 0.0
var _mix_duck := 1.0
var _quiet := false
var _paused := false
var _noise_fast := 0.0
var _noise_slow := 0.0
var _noise_body := 0.0
var _hum_phase := 0.0
var _grit_phase := 0.0


func _init() -> void:
	for i in range(PAD_VOICES * 2):
		_pads.append(Voice.new())
	for i in range(PLUCK_VOICES):
		_plucks.append(Voice.new())
	for i in range(CUE_VOICES):
		_cues.append(Voice.new())
	_reflections.resize(REFLECTION_FRAMES)
	_rng.seed = 681093


func _ready() -> void:
	if AudioServer.get_driver_name() == "Dummy":
		return
	# present() owns transport; do not let the tree apply a second pause policy.
	_player = AudioStreamPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.08
	_player.stream = generator
	add_child(_player)
	_start_stream()


func _start_stream() -> void:
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_queue_space = _playback.get_frames_available() if _playback else 0


func reset_audio() -> void:
	_cue_serial = -1
	_phase = OPEN
	_score_time = 0.0
	_next_pulse = 0
	_partners = 0
	_pad_bank = 0
	_pluck_index = 0
	_cue_index = 0
	_reflection_index = 0
	_reflections.fill(Vector2.ZERO)
	for bank in [_pads, _plucks, _cues]:
		for voice: Voice in bank:
			voice.age = voice.duration
	_hush_target = 0.0
	_scrape_target = 0.0
	_hum_target = 0.0
	_pitch_target = 94.0
	_pan_target = 0.0
	_hush = 0.0
	_scrape = 0.0
	_hum = 0.0
	_pitch = 94.0
	_pan = 0.0
	_mix_duck = 1.0
	_noise_fast = 0.0
	_noise_slow = 0.0
	_noise_body = 0.0
	_hum_phase = 0.0
	_grit_phase = 0.0
	_rng.seed = 681093
	if _player:
		_player.stop()
		_start_stream()
		_player.stream_paused = _paused


func present(s: Dictionary, _dt: float) -> void:
	var quiet := bool(s.get("muted", false))
	var paused := bool(s.get("paused", false))
	if quiet != _quiet:
		_quiet = quiet
		if _player:
			_player.volume_db = -80.0 if _quiet else 0.0
	if paused != _paused:
		_paused = paused
		if _player:
			_player.stream_paused = _paused
	if _paused:
		return

	var phase := StringName(s.get("phase", OPEN))
	var phase_time := maxf(0.0, float(s.get("phase_time", 0.0)))
	if phase != _phase:
		_change_phase(phase, phase_time)

	var vel: Vector2 = s.get("vel", Vector2.ZERO)
	var pos: Vector2 = s.get("pos", Vector2(450.0, 250.0))
	var speed := vel.length()
	var riding := bool(s.get("riding", false))
	var carving := bool(s.get("carving", false))
	var heading := float(s.get("heading", 0.0))
	var slip := absf(vel.cross(Vector2.from_angle(heading))) / maxf(speed, 1.0)
	var movement := smoothstep(7.0, 205.0, speed)
	var edge := 1.0 if carving else smoothstep(0.17, 0.80, slip) * 0.45
	var space := 0.33 if phase == BOW else (0.56 if phase == FINALE else 1.0)
	_hush_target = movement * (0.25 if riding else 1.0) * space
	_scrape_target = movement * edge * (0.10 if riding else 0.82) * space
	_hum_target = (smoothstep(12.0, 156.0, speed) * space) if riding else 0.0
	_pitch_target = lerpf(91.0, 142.0, minf(speed / 235.0, 1.0))
	_pan_target = clampf((pos.x - 450.0) / 450.0, -1.0, 1.0) * 0.31
	var serial := int(s.get("cue_serial", 0))
	if _cue_serial >= 0 and serial > _cue_serial:
		_ring_cue()
	_cue_serial = serial
	var followers: Array = s.get("followers", [])
	_partners = mini(followers.size(), 2)

	if _playback:
		var frames := maxi(0, _playback.get_frames_available() - maxi(0, _queue_space - QUEUE_FRAMES))
		for i in range(frames):
			_playback.push_frame(_mix_frame())


func _change_phase(phase: StringName, time: float) -> void:
	_phase = phase
	_score_time = time
	_next_pulse = floori(time / PULSE)
	if _phase == BOW:
		for voice in _pads:
			voice.ring_out()
	if _phase == FINALE and _next_pulse % PULSES_PER_BAR != 0:
		@warning_ignore("integer_division")
		var bar := _next_pulse / PULSES_PER_BAR
		_start_pad(
			HARMONY[bar % HARMONY.size()],
			PULSE * (PULSES_PER_BAR - _next_pulse % PULSES_PER_BAR) + 0.34,
			0.70
		)


func _ring_cue() -> void:
	_cues[_cue_index].strike(81, Timbre.BELL, 0.148, _pan_target - 0.08, 0.61)
	_cues[_cue_index + 1].strike(88, Timbre.BELL, 0.094, _pan_target + 0.10, 0.46, 0.062)
	_cue_index = (_cue_index + 2) % CUE_VOICES


func _start_pad(chord: Array, length: float, gain: float) -> void:
	var index := _pad_bank * PAD_VOICES
	_pads[index].strike(chord[0], Timbre.STRING, gain * 0.052, 0.0, length)
	_pads[index + 1].strike(chord[1], Timbre.STRING, gain * 0.036, -0.27, length, 0.035)
	_pads[index + 2].strike(chord[2], Timbre.STRING, gain * 0.027, 0.28, length, 0.075)
	_pads[index + 3].strike(chord[3], Timbre.STRING, gain * 0.024, 0.11, length, 0.112)
	_pad_bank = 1 - _pad_bank


func _pluck(note: int, gain: float, pan: float, length: float, delay: float = 0.0) -> void:
	_plucks[_pluck_index].strike(note, Timbre.FELT, gain, pan, length, delay)
	_pluck_index = (_pluck_index + 1) % PLUCK_VOICES


func _advance_score() -> void:
	if _phase != FINALE and _phase != BOW:
		return
	if _phase == BOW and _next_pulse >= BOW_MELODY.size():
		return
	if _score_time >= _next_pulse * PULSE:
		var pulse := _next_pulse
		_next_pulse += 1
		if _phase == BOW:
			if pulse == 0:
				_start_pad(BOW_CHORD, 6.2, 0.94)
			var note: int = BOW_MELODY[pulse]
			if note >= 0:
				_pluck(note, lerpf(0.10, 0.052, pulse / 12.0), -0.08, 1.34)
		else:
			_play_finale_pulse(pulse)
	_score_time += SAMPLE_TIME


func _play_finale_pulse(pulse: int) -> void:
	@warning_ignore("integer_division")
	var bar := pulse / PULSES_PER_BAR
	var beat := pulse % PULSES_PER_BAR
	var chord: Array = HARMONY[bar % HARMONY.size()]
	var motif: Array = MELODY[bar % MELODY.size()]
	var bloom := smoothstep(0.0, 24.0, _score_time)
	if beat == 0:
		_start_pad(chord, PULSE * PULSES_PER_BAR + 0.66, 0.58 + 0.37 * bloom)
		_pluck(chord[0] + 12, 0.059 + 0.020 * bloom, -0.18, 1.17, 0.035)
	var note: int = motif[beat]
	if note >= 0:
		_pluck(note, 0.087 + 0.016 * bloom, 0.13, 1.02)
	if (beat == 3 or beat == 7) or (bloom > 0.28 and (beat == 1 or beat == 5)):
		var inner_note: int = chord[1 + (beat + bar) % 3]
		_pluck(inner_note + 12, 0.035 + 0.021 * bloom, -0.32, 0.76, 0.023)
	if beat == 6 and bloom > 0.40 and _partners > 0 and _hum_target > 0.26:
		_pluck(chord[1] + 24, 0.031 + 0.008 * _partners, 0.30, 0.83, 0.082)


func _blade() -> Vector2:
	_hush += (_hush_target - _hush) * 0.0024
	_scrape += (_scrape_target - _scrape) * 0.0044
	_hum += (_hum_target - _hum) * 0.0021
	_pitch += (_pitch_target - _pitch) * 0.0020
	_pan += (_pan_target - _pan) * 0.0016

	var white := _rng.randf_range(-1.0, 1.0)
	_noise_fast += (white - _noise_fast) * 0.49
	_noise_slow += (_noise_fast - _noise_slow) * 0.13
	_noise_body += (_noise_slow - _noise_body) * 0.022
	var air := _noise_fast - _noise_slow
	var grain := _noise_slow - _noise_body
	_grit_phase = fposmod(_grit_phase + TAU * (46.0 + 59.0 * _scrape) * SAMPLE_TIME, TAU)
	_hum_phase = fposmod(_hum_phase + TAU * _pitch * SAMPLE_TIME, TAU)
	var roughness := 0.64 + 0.24 * sin(_grit_phase) + 0.12 * sin(3.0 * _grit_phase)
	var hiss := _hush * (0.24 * air + 0.18 * grain)
	var rasp := _scrape * roughness * (0.28 * air + 0.72 * grain)
	var resonance := sin(_hum_phase) + 0.36 * sin(2.0 * _hum_phase) + 0.12 * sin(3.0 * _hum_phase)
	var hum := _hum * (0.095 * resonance + 0.12 * air)
	return Vector2(1.0 - _pan, 1.0 + _pan) * (hiss + rasp + hum)


func _mix_frame() -> Vector2:
	_advance_score()
	var strings := Vector2.ZERO
	var keys := Vector2.ZERO
	var cue := Vector2.ZERO
	for voice in _pads:
		strings += voice.sample()
	for voice in _plucks:
		keys += voice.sample()
	for voice in _cues:
		cue += voice.sample()
	# Make space for the chime without taking the movement sound away.
	var duck := 1.0 - minf(0.19, (absf(cue.x) + absf(cue.y)) * 0.74)
	_mix_duck += (duck - _mix_duck) * 0.002
	# Two wall reflections give the short notes room, without smearing the blade.
	var short_tap := _reflections[(_reflection_index + REFLECTION_FRAMES - REFLECTION_SHORT) % REFLECTION_FRAMES]
	var long_tap := _reflections[(_reflection_index + REFLECTION_FRAMES - REFLECTION_LONG) % REFLECTION_FRAMES]
	_reflections[_reflection_index] = keys + cue
	_reflection_index = (_reflection_index + 1) % REFLECTION_FRAMES
	var room := Vector2(short_tap.y, long_tap.x) * 0.22 + Vector2(long_tap.y, short_tap.x) * 0.10
	var mix := (strings + keys) * (1.14 * _mix_duck) + cue + room + _blade()
	return Vector2(mix.x / (1.0 + 0.36 * absf(mix.x)), mix.y / (1.0 + 0.36 * absf(mix.y)))
