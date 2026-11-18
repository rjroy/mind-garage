extends SceneTree

const Evening = preload("res://evening.gd")
const DT := 1.0 / 60.0
var failures: Array[String] = []


func _initialize() -> void:
	test_capture_and_travel()
	test_peel(false)
	test_peel(true)
	test_steep_crossing()
	if failures.is_empty():
		print("PASS: groove interaction")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		quit(1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func skate(model: RefCounted, direction: Vector2, ticks: int, carve := false) -> void:
	for _i in range(ticks):
		model.step(DT, direction, carve, false)


# Author a hook using the same inputs available to a player.
func authored_fixture() -> Dictionary:
	var model = Evening.new()
	model.reset()
	skate(model, Vector2.RIGHT, 90, true)
	skate(model, Vector2.DOWN, 54, true)
	model.step(DT, Vector2.LEFT, false, false)
	var grooves: Array = model.snapshot()["grooves"]
	if grooves.is_empty():
		return {"model": model, "error": "carving did not produce a finished groove"}
	var path: PackedVector2Array = grooves[0]
	if path.size() < 4:
		return {"model": model, "error": "finished groove has too few points"}
	return {"model": model, "path": path}


func fixture_or_fail() -> Dictionary:
	var fixture := authored_fixture()
	if fixture.has("error"):
		check(false, fixture["error"])
	return fixture


# Return nearest distance, cumulative distance, and local tangent. These are
# measured from the actual recorded path, not from expected rink coordinates.
func locate(path: PackedVector2Array, position: Vector2) -> Dictionary:
	var best_distance := INF
	var best_progress := 0.0
	var best_tangent := Vector2.ZERO
	var distance_so_far := 0.0
	for i in range(path.size() - 1):
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var closest := Geometry2D.get_closest_point_to_segment(position, a, b)
		var distance := position.distance_to(closest)
		if distance < best_distance:
			best_distance = distance
			best_progress = distance_so_far + a.distance_to(closest)
			best_tangent = (b - a).normalized()
		distance_so_far += a.distance_to(b)
	return {"distance": best_distance, "progress": best_progress, "tangent": best_tangent}


func catch_groove(fixture: Dictionary) -> bool:
	var model: RefCounted = fixture["model"]
	# One left tick has already released the carve.
	skate(model, Vector2.LEFT, 47)
	skate(model, Vector2.UP, 42)
	for _i in range(35):
		model.step(DT, Vector2.RIGHT, false, false)
		var state: Dictionary = model.snapshot()
		if state["riding"]:
			var path: PackedVector2Array = fixture["path"]
			var pos: Vector2 = state["pos"]
			var location := locate(path, pos)
			check(location["distance"] < 25.0, "catch is near the authored groove")
			var velocity: Vector2 = state["vel"]
			var tangent: Vector2 = location["tangent"]
			fixture["travel_sign"] = -1.0 if velocity.dot(tangent) < 0.0 else 1.0
			return true
	check(false, "hook-shaped return did not catch the authored groove")
	return false


func test_capture_and_travel() -> void:
	var fixture := fixture_or_fail()
	if fixture.has("error") or not catch_groove(fixture):
		return
	var model: RefCounted = fixture["model"]
	var path: PackedVector2Array = fixture["path"]
	var start_pos: Vector2 = model.snapshot()["pos"]
	var start_progress: float = locate(path, start_pos)["progress"]
	var travel_sign: float = fixture["travel_sign"]
	var furthest := 0.0
	var riding_samples := 0
	for _i in range(44):
		model.step(DT, Vector2.ZERO, false, false)
		var state: Dictionary = model.snapshot()
		if state["riding"]:
			riding_samples += 1
			var pos: Vector2 = state["pos"]
			var location := locate(path, pos)
			check(location["distance"] < 25.0, "rider stays near the authored groove")
			var progress: float = location["progress"]
			furthest = maxf(furthest, (progress - start_progress) * travel_sign)
	check(riding_samples > 1, "riding persists beyond the catch frame")
	check(furthest > 5.0, "riding travels along the authored curve")


func test_peel(carve: bool) -> void:
	var fixture := fixture_or_fail()
	if fixture.has("error") or not catch_groove(fixture):
		return
	var model: RefCounted = fixture["model"]
	skate(model, Vector2.ZERO, 44)
	check(model.snapshot()["riding"], "fixture is riding before the peel")
	var label := "carving" if carve else "hard cross-steering"
	var left_ride := false
	var remained_free := false
	for _i in range(24):
		model.step(DT, Vector2.UP, carve, false)
		var riding: bool = model.snapshot()["riding"]
		if not riding:
			if left_ride:
				remained_free = true
			left_ride = true
		elif left_ride:
			break
	check(left_ride, label + " peels off the groove")
	check(remained_free, label + " does not immediately lock back in")


# Navigate using observed position and velocity only. The velocity lead helps
# the skater settle at the staging point rather than orbiting it.
func approach(model: RefCounted, target: Vector2, radius: float, ticks: int) -> bool:
	for _i in range(ticks):
		var state: Dictionary = model.snapshot()
		var pos: Vector2 = state["pos"]
		if pos.distance_to(target) <= radius:
			return true
		var velocity: Vector2 = state["vel"]
		var desired: Vector2 = target - pos - velocity * 0.5
		model.step(DT, desired.normalized(), false, false)
	return false


func test_steep_crossing() -> void:
	var fixture := fixture_or_fail()
	if fixture.has("error"):
		return
	var model: RefCounted = fixture["model"]
	var path: PackedVector2Array = fixture["path"]
	var index := int(path.size() * 0.25)
	var spread := maxi(1, int(path.size() * 0.08))
	var point: Vector2 = path[index]
	var tangent: Vector2 = (path[mini(path.size() - 1, index + spread)]
		- path[maxi(0, index - spread)]).normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	if not approach(model, point + normal * 90.0, 15.0, 900):
		check(false, "could not skate to the steep-crossing staging area")
		return
	var start_pos: Vector2 = model.snapshot()["pos"]
	check((start_pos - point).dot(normal) > 0.0, "steep crossing starts on the intended side")
	check(not model.snapshot()["riding"], "steep crossing starts off the groove")
	var in_band := false
	var caught_in_band := false
	var crossed := false
	for _i in range(240):
		model.step(DT, -normal, false, false)
		var state: Dictionary = model.snapshot()
		var pos: Vector2 = state["pos"]
		var velocity: Vector2 = state["vel"]
		var location := locate(path, pos)
		var local_tangent: Vector2 = location["tangent"]
		var steep: bool = velocity.length() > 1.0 and absf(velocity.normalized().dot(local_tangent)) < 0.5
		if location["distance"] < 10.0:
			caught_in_band = caught_in_band or state["riding"]
			if steep:
				in_band = true
		if in_band and (pos - point).dot(normal) < -15.0:
			crossed = true
			break
	check(in_band and crossed, "fixture crosses the authored groove in-band at a steep angle")
	check(not caught_in_band, "a steep crossing does not automatically catch")
