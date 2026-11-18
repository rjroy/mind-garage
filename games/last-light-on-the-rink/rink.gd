extends Node2D

const Evening = preload("res://evening.gd")
const RinkView = preload("res://rink_view.gd")
const RinkSound = preload("res://sound.gd")

var _evening = Evening.new()
var _view = RinkView.new()
var _sound = RinkSound.new()
var _keys: Dictionary = {}
var _cue_pending := false
var _paused := false
var _muted := false
var _last_phase := ""


func _ready() -> void:
	add_child(_view)
	add_child(_sound)
	_restart()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if event.pressed:
		if _keys.has(code):
			return
		_keys[code] = true
		match code:
			KEY_E:
				if not _paused:
					_cue_pending = true
			KEY_R:
				_restart()
			KEY_ESCAPE:
				_paused = not _paused
				_cue_pending = false
			KEY_M:
				_muted = not _muted
	else:
		_keys.erase(code)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_keys.clear()
		_cue_pending = false


func _physics_process(delta: float) -> void:
	if not _paused:
		var steer := Vector2(
			float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT)),
			float(_held(KEY_S, KEY_DOWN)) - float(_held(KEY_W, KEY_UP))
		).limit_length(1.0)
		_evening.step(delta, steer, _keys.has(KEY_SPACE), _cue_pending)
		_cue_pending = false
	var state := current_state()
	_log_phase(state)
	_view.present(state)
	_sound.present(state, delta)


func _held(primary: Key, alternate: Key) -> bool:
	return _keys.has(primary) or _keys.has(alternate)


func _restart() -> void:
	_evening.reset()
	_sound.reset_audio()
	_paused = false
	_cue_pending = false
	_last_phase = ""
	_log_phase(current_state())


func _log_phase(state: Dictionary) -> void:
	var phase := str(state.get("phase", ""))
	if phase == _last_phase:
		return
	_last_phase = phase
	print("Rink phase: %s, grooves=%d, followers=%d" % [
		phase, state.get("grooves", []).size(), state.get("followers", []).size()
	])


func current_state() -> Dictionary:
	var state: Dictionary = _evening.snapshot().duplicate()
	state["paused"] = _paused
	state["muted"] = _muted
	return state
