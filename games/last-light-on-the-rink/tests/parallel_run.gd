extends SceneTree

const Groove = preload("res://skate_groove.gd")


func _initialize() -> void:
	var groove = Groove.new(PackedVector2Array([
		Vector2(0, 0), Vector2(50, 0), Vector2(100, 0),
	]))
	var failures: Array[String] = []

	# Both moves remain the same distance from the complete line. The adjacent
	# segment's endpoint must not make either move look like an approach.
	var forward: Vector3 = groove.catch_near(
		Vector2(48, 2), Vector2(49, 2), Vector2.RIGHT, INF)
	if forward.y != 0.0:
		failures.append("parallel forward motion caught at an internal sample")
	var reverse: Vector3 = groove.catch_near(
		Vector2(52, 2), Vector2(51, 2), Vector2.LEFT, INF)
	if reverse.y != 0.0:
		failures.append("parallel reverse motion caught at an internal sample")

	# A nearby perpendicular leg is not eligible at this heading and must not
	# make the parallel horizontal leg count as an approach.
	var compound = Groove.new(PackedVector2Array([
		Vector2(0, 0), Vector2(50, 0), Vector2(100, 0),
		Vector2(100, 100), Vector2(50, 100), Vector2(50, -20),
	]))
	var mixed: Vector3 = compound.catch_near(
		Vector2(46, 3), Vector2(49, 3), Vector2.RIGHT, INF)
	if mixed.y != 0.0:
		failures.append("approach to an ineligible leg caught the parallel leg")

	var approach_direction := Vector2(4, -1).normalized()
	var approach: Vector3 = groove.catch_near(
		Vector2(44, 3), Vector2(48, 2), approach_direction, INF)
	if approach.y != 1.0:
		failures.append("a genuine shallow approach did not remain eligible")

	if failures.is_empty():
		print("PASS: parallel groove entry")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)
