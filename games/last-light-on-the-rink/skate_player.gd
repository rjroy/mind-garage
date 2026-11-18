extends "res://skate_motion.gd"

const Groove = preload("res://skate_groove.gd")
const GLIDE_SPEED := 205.0
const CARVE_SPEED := 142.0
const POINT_SPACING := 4.0
const MIN_LINE_LENGTH := 8.0
const MIN_CATCH_SPEED := 61.0
# Lean at least ~55 degrees off the line to leave; small inputs push along it.
const PEEL_ALIGNMENT := 0.57
const PEEL_INPUT := 0.32

var carving := false
var riding: Groove
var _line := PackedVector2Array()
var _catch_pause := 0.0
var _peel_boost := 0.0
var _ride_distance := 0.0
var _ride_direction := 1.0


func set_carve(held: bool) -> Groove:
	if held == carving:
		return null
	if held:
		carving = true
		_leave_groove()
		_line.append(pos)
		return null
	var completed := active_line()
	carving = false
	_line.clear()
	_catch_pause = 0.30
	if completed.size() < 2:
		return null
	var groove := Groove.new(completed)
	return groove if groove.length >= MIN_LINE_LENGTH else null


func active_line() -> PackedVector2Array:
	var points := _line.duplicate()
	if carving and not points.is_empty() and points[-1].distance_squared_to(pos) > 0.0225:
		points.append(pos)
	return points


func skate(dt: float, steer: Vector2, grooves: Array[Groove]) -> void:
	_catch_pause = maxf(0.0, _catch_pause - dt)
	_peel_boost = maxf(0.0, _peel_boost - dt)
	if riding != null:
		if not _wants_to_peel(steer, riding.tangent_at(_ride_distance, _ride_direction)):
			_glide_in_groove(dt, steer)
			return
		_leave_groove()
		_peel_boost = 0.20

	var before := pos
	_free_skate(dt, steer)
	if carving:
		# Sampling by distance bounds storage even if carve is held all evening.
		if _line[-1].distance_squared_to(pos) >= POINT_SPACING * POINT_SPACING:
			_line.append(pos)
	elif _catch_pause == 0.0 and vel.length_squared() >= MIN_CATCH_SPEED * MIN_CATCH_SPEED:
		_try_catch(before, steer, grooves)


func to_center(dt: float, bow: bool) -> bool:
	_leave_groove()
	# Keep a short catch pause when the player takes the reins from the centre glide.
	_catch_pause = 0.18
	return glide_to(CENTER, 149.0, 190.0, dt) and (not bow or face_audience(dt))


func _free_skate(dt: float, steer: Vector2) -> void:
	var speed := vel.length()
	var angle := vel.angle() if speed > 1.0 else heading
	if steer.length_squared() > 0.0025:
		var turn_rate := 4.9 if carving else (5.6 if _peel_boost > 0.0 else 2.85)
		angle = steer.angle() if speed < 5.0 else rotate_toward(angle, steer.angle(), turn_rate * dt)
		var alignment := maxf(0.0, Vector2.from_angle(angle).dot(steer.normalized()))
		var speed_limit := CARVE_SPEED if carving else GLIDE_SPEED
		var target := speed_limit * steer.length() * lerpf(0.54, 1.0, alignment)
		var push := 248.0 if target > speed else (265.0 if carving else 155.0)
		speed = move_toward(speed, target, push * dt)
	else:
		speed *= exp(-(0.90 if carving else 0.34) * dt)
	vel = Vector2.from_angle(angle) * speed if speed > 1.0 else Vector2.ZERO
	move_on_ice(dt)
	face_motion(dt)


func _try_catch(before: Vector2, steer: Vector2, grooves: Array[Groove]) -> void:
	var direction := vel.normalized()
	var best := Vector3(0.0, 0.0, INF)
	var chosen: Groove
	for groove in grooves:
		var contact := groove.catch_near(before, pos, direction, best.z)
		if contact.z < best.z and not _wants_to_peel(steer, groove.tangent_at(contact.x, contact.y)):
			best = contact
			chosen = groove
	if chosen == null:
		return
	riding = chosen
	_ride_distance = best.x
	_ride_direction = best.y
	pos = riding.point_at(_ride_distance)
	vel = riding.tangent_at(_ride_distance, _ride_direction) * vel.length() * 0.96


func _glide_in_groove(dt: float, steer: Vector2) -> void:
	var tangent := riding.tangent_at(_ride_distance, _ride_direction)
	var push := maxf(0.0, tangent.dot(steer))
	var speed := minf(GLIDE_SPEED, vel.length() * exp(-0.115 * dt) + push * 134.0 * dt)
	var projected := _ride_distance + _ride_direction * speed * dt
	_ride_distance = clampf(projected, 0.0, riding.length)
	pos = riding.point_at(_ride_distance)
	vel = riding.tangent_at(_ride_distance, _ride_direction) * speed
	face_motion(dt)
	if _ride_distance != projected or speed < 25.0:
		_leave_groove()


func _leave_groove() -> void:
	if riding != null:
		riding = null
		_catch_pause = 0.34


func _wants_to_peel(steer: Vector2, tangent: Vector2) -> bool:
	return steer.length_squared() >= PEEL_INPUT * PEEL_INPUT and steer.normalized().dot(tangent) < PEEL_ALIGNMENT
