extends RefCounted

const Groove = preload("res://skate_groove.gd")
const Player = preload("res://skate_player.gd")
const Partner = preload("res://skate_partner.gd")

const PHASE_NAMES := ["opening", "rehearsal", "finale", "bow"]
const PHASE_START := [0.0, 28.0, 112.0, 164.0]
const CENTER_GLIDE_START := 156.0
const BOW_DURATION := 6.0
const GATHER_BUDGET_PER_STEP := 10.0
const MAX_STEP := 1.0 / 120.0
const CLOCK_EPSILON := 0.00000001
const MAX_GROOVES := 36
const PARTNER_COUNT := 2

enum Phase { OPENING, REHEARSAL, FINALE, BOW }

var _player := Player.new()
var _grooves: Array[Groove] = []
var _partners: Array[Partner] = []
var _phase := Phase.OPENING
var _time := 0.0
var _bow_started_at := -1.0
var _next_partner := 0
var _cue_serial := 0
var _cued_partner := -1


func reset() -> void:
	_player = Player.new()
	_grooves.clear()
	_partners.clear()
	_phase = Phase.OPENING
	_time = 0.0
	_bow_started_at = -1.0
	_next_partner = 0
	_cue_serial = 0
	_cued_partner = -1


func step(dt: float, steer: Vector2, carve: bool, cue: bool) -> void:
	if not is_finite(dt) or dt <= 0.0:
		return
	# Bound work for giant finite steps without imposing a deadline on arrivals.
	var until_bow := maxf(0.0, PHASE_START[Phase.BOW] - _time)
	var end := _time + minf(dt, until_bow + GATHER_BUDGET_PER_STEP + BOW_DURATION)
	if _phase == Phase.BOW:
		_advance_bow(end)
		return

	var direction := _bounded_steer(steer)
	_store_groove(_player.set_carve(carve))
	if cue:
		_cue_latest()
	if _phase == Phase.FINALE:
		_fill_free_partners()

	# Slice motion at fixed phase boundaries, even if the caller has a slow tick.
	while _time < end and _phase != Phase.BOW:
		var phase_end: float = PHASE_START[_phase + 1]
		var next := minf(_time + MAX_STEP, minf(phase_end, end))
		_advance_slice(next - _time, direction)
		_time = next
		if phase_end - _time <= CLOCK_EPSILON:
			_time = phase_end
			_advance_phase()
	if _phase == Phase.BOW:
		_advance_bow(end)


func snapshot() -> Dictionary:
	var grooves: Array[PackedVector2Array] = []
	for groove in _grooves:
		grooves.append(groove.points())
	var followers: Array[Dictionary] = []
	for partner in _partners:
		followers.append({
			"pos": partner.pos,
			"vel": partner.vel,
			"heading": partner.heading,
			"groove": _grooves.find(partner.groove) if partner.groove != null else -1,
		})
	return {
		"phase": PHASE_NAMES[_phase],
		"phase_time": _time - PHASE_START[_phase],
		"total_time": _time,
		"bow_time": _time - _bow_started_at if _bow_started_at >= 0.0 else -1.0,
		"pos": _player.pos,
		"vel": _player.vel,
		"heading": _player.heading,
		"grooves": grooves,
		"active_line": _player.active_line(),
		"followers": followers,
		"riding": _player.riding != null,
		"carving": _player.carving,
		"cue_serial": _cue_serial,
		"cued_partner": _cued_partner,
	}


func _advance_slice(dt: float, steer: Vector2) -> void:
	if _time >= CENTER_GLIDE_START and steer == Vector2.ZERO and not _player.carving:
		_player.to_center(dt, false)
	else:
		_player.skate(dt, steer, _grooves)
	for partner in _partners:
		partner.skate(dt)


func _advance_bow(end: float) -> void:
	while _bow_started_at < 0.0 and _time < end:
		var next := minf(_time + MAX_STEP, end)
		var dt := next - _time
		var settled := _player.to_center(dt, true)
		for partner in _partners:
			if not partner.to_bow(dt):
				settled = false
		_time = next
		if settled and _partners.size() == PARTNER_COUNT:
			_bow_started_at = _time
	if _bow_started_at >= 0.0:
		# Once gathered, all skaters hold their marks through the gesture.
		_time = minf(end, _bow_started_at + BOW_DURATION)


func _advance_phase() -> void:
	match _phase:
		Phase.OPENING:
			_phase = Phase.REHEARSAL
			while _partners.size() < PARTNER_COUNT:
				_partners.append(Partner.new(_partners.size()))
		Phase.REHEARSAL:
			_phase = Phase.FINALE
			_fill_free_partners()
		Phase.FINALE:
			_phase = Phase.BOW
			_store_groove(_player.set_carve(false))


func _cue_latest() -> void:
	if _grooves.is_empty():
		return
	# A player can invite the first lantern in before rehearsal starts.
	if _partners.is_empty():
		_partners.append(Partner.new(0))
	var slot := _next_partner % _partners.size()
	_partners[slot].assign(_grooves[-1])
	_next_partner = (slot + 1) % PARTNER_COUNT
	_cued_partner = slot
	_cue_serial += 1


func _fill_free_partners() -> void:
	if _grooves.is_empty():
		return
	var occupied: Array[Groove] = []
	for partner in _partners:
		if partner.groove != null:
			occupied.append(partner.groove)
	for partner in _partners:
		if partner.groove != null:
			continue
		var choice := _grooves[-1]
		for i in range(_grooves.size() - 1, -1, -1):
			if not occupied.has(_grooves[i]):
				choice = _grooves[i]
				break
		partner.assign(choice)
		occupied.append(choice)


func _store_groove(groove: Groove) -> void:
	if groove == null:
		return
	_grooves.append(groove)
	if _grooves.size() > MAX_GROOVES:
		# Keep active choreography intact when the oldest unassigned cut fades.
		for i in range(_grooves.size()):
			var old := _grooves[i]
			if old == _player.riding or _partners.any(func(partner: Partner) -> bool: return partner.groove == old):
				continue
			_grooves.remove_at(i)
			break


func _bounded_steer(value: Vector2) -> Vector2:
	if not value.is_finite():
		return Vector2.ZERO
	# Scale before computing length, so even extreme finite components stay safe.
	var scale := maxf(1.0, maxf(absf(value.x), absf(value.y)))
	var normal := (value / scale).limit_length()
	return normal if normal.length_squared() > 0.0025 else Vector2.ZERO
