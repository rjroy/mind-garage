extends "res://skate_motion.gd"

const Groove = preload("res://skate_groove.gd")
const HOMES := [Vector2(146.0, 278.0), Vector2(754.0, 219.0)]
const BOW_SPOTS := [Vector2(391.0, 250.0), Vector2(509.0, 250.0)]
const PIVOT_TIME := 0.38

enum Action { FREE, APPROACH, TRACE, PIVOT }

var groove: Groove
var _slot: int
var _age := 0.0
var _action := Action.FREE
var _direction := 1.0
var _distance := 0.0
var _pace := 0.0
var _pivot_time := 0.0
var _pivot_heading := 0.0


func _init(slot: int) -> void:
	_slot = slot
	pos = HOMES[slot]
	heading = 0.0 if slot == 0 else PI


func assign(target: Groove) -> void:
	if groove == target:
		return
	groove = target
	var distance_to_start := pos.distance_squared_to(groove.point_at(0.0))
	var distance_to_finish := pos.distance_squared_to(groove.point_at(groove.length))
	_direction = 1.0 if distance_to_start <= distance_to_finish else -1.0
	_distance = 0.0 if _direction > 0.0 else groove.length
	_action = Action.APPROACH


func skate(dt: float) -> void:
	match _action:
		Action.FREE:
			_age += dt
			var t := _age * (0.55 if _slot == 0 else 0.65)
			var offset := Vector2(sin(t) * 106.0, sin(t * 2.0) * 44.0)
			var home: Vector2 = HOMES[_slot]
			glide_to(home + offset * (1.0 if _slot == 0 else -1.0), 116.0, 190.0, dt)
		Action.APPROACH:
			if glide_to(groove.point_at(_distance), 149.0, 195.0, dt):
				_pace = 0.0
				_action = Action.TRACE
		Action.TRACE:
			_trace(dt)
		Action.PIVOT:
			_pivot(dt)


func to_bow(dt: float) -> bool:
	return glide_to(BOW_SPOTS[_slot], 143.0, 183.0, dt) and face_audience(dt)


func _trace(dt: float) -> void:
	var left := groove.length - _distance if _direction > 0.0 else _distance
	var preferred := 137.0 if _slot == 0 else 151.0
	# Brake into a half-turn, rather than ping-ponging at full speed.
	var target := minf(preferred, sqrt(350.0 * left))
	_pace = move_toward(_pace, target, 220.0 * dt)
	var stride := _pace * dt
	var arrived := stride >= left
	_distance = clampf(_distance + _direction * stride, 0.0, groove.length)
	pos = groove.point_at(_distance)
	vel = groove.tangent_at(_distance, _direction) * _pace
	face_motion(dt, 13.0)
	if arrived:
		vel = Vector2.ZERO
		_pivot_time = 0.0
		_pivot_heading = groove.tangent_at(_distance, _direction).angle()
		_action = Action.PIVOT


func _pivot(dt: float) -> void:
	_pivot_time += dt
	var direction := 1.0 if _slot == 0 else -1.0
	heading = wrapf(_pivot_heading + direction * PI * smoothstep(0.0, PIVOT_TIME, _pivot_time), -PI, PI)
	if _pivot_time >= PIVOT_TIME:
		_direction = -_direction
		_pace = 0.0
		_action = Action.TRACE
