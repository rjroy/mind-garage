extends RefCounted

const CENTER := Vector2(450.0, 250.0)
const ICE := Rect2(27.0, 27.0, 846.0, 446.0)

var pos := CENTER
var vel := Vector2.ZERO
var heading := 0.0


func glide_to(target: Vector2, speed_limit: float, push: float, dt: float) -> bool:
	var offset := target - pos
	var distance := offset.length()
	if distance > 0.35:
		var pace := minf(speed_limit, sqrt(1.6 * push * distance))
		vel = vel.move_toward(offset * (pace / distance), push * dt)
		if (vel * dt).dot(offset) < distance * distance:
			move_on_ice(dt)
			face_motion(dt)
			return false
	pos = target
	vel = Vector2.ZERO
	return true


func move_on_ice(dt: float) -> void:
	var proposed := pos + vel * dt
	pos = proposed.clamp(ICE.position, ICE.end)
	if pos.x != proposed.x:
		vel.x = 0.0
	if pos.y != proposed.y:
		vel.y = 0.0


func face_motion(dt: float, turn_rate := 9.0) -> void:
	if vel.length_squared() > 4.0:
		heading = rotate_toward(heading, vel.angle(), turn_rate * dt)


func face_audience(dt: float) -> bool:
	var front := PI * 0.5
	var turn := 3.6 * dt
	if absf(angle_difference(heading, front)) <= turn:
		heading = front
		return true
	heading = rotate_toward(heading, front, turn)
	return false
