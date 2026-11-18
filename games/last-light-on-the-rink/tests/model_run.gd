extends SceneTree

const Evening = preload("res://evening.gd")
const DT := 0.1
var failures: Array[String] = []


func _initialize() -> void:
	test_initial_state_and_reset()
	test_steering_coasting_and_bounds()
	test_distinct_lines()
	test_cue_and_follower_traversal()
	test_finale_and_phase_progression()
	if failures.is_empty():
		print("PASS: evening model")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("%d model checks failed" % failures.size())
		quit(1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func advance(model: RefCounted, seconds: float, steer := Vector2.ZERO,
		carve := false, cue := false) -> void:
	for i in range(int(round(seconds / DT))):
		model.step(DT, steer, carve, cue and i == 0)


func draw_line(model: RefCounted, direction: Vector2) -> void:
	advance(model, 2.0, direction, true)
	model.step(DT, direction, false, false)


func wait_for_phase(model: RefCounted, target: String, max_seconds: float) -> bool:
	for _i in range(int(max_seconds / DT)):
		if model.snapshot()["phase"] == target:
			return true
		model.step(DT, Vector2.ZERO, false, false)
	return model.snapshot()["phase"] == target


func test_initial_state_and_reset() -> void:
	var model = Evening.new()
	model.reset()
	var initial: Dictionary = model.snapshot()
	check(initial["phase"] == "opening", "reset starts directly in opening")
	check(initial["phase_time"] == 0.0 and initial["total_time"] == 0.0,
		"reset clears both clocks")
	check(initial["pos"] is Vector2 and initial["vel"] is Vector2,
		"initial position and velocity are vectors")
	check(initial["pos"].x >= 0.0 and initial["pos"].x <= 900.0
		and initial["pos"].y >= 0.0 and initial["pos"].y <= 500.0,
		"reset places the skater on the ice")
	check(initial["grooves"].is_empty() and initial["active_line"].is_empty()
		and initial["followers"].is_empty() and initial["cue_serial"] == 0,
		"reset starts without lines, followers or cues")
	draw_line(model, Vector2.RIGHT)
	model.step(DT, Vector2.ZERO, false, true)
	advance(model, 1.0)
	model.reset()
	var reset_state: Dictionary = model.snapshot()
	check(reset_state["phase"] == "opening" and reset_state["total_time"] == 0.0
		and reset_state["phase_time"] == 0.0, "reset restores phase and clocks")
	check(reset_state["grooves"].is_empty() and reset_state["active_line"].is_empty()
		and reset_state["followers"].is_empty() and reset_state["cue_serial"] == 0,
		"reset clears authored and partner state")
	check(reset_state["pos"].is_equal_approx(initial["pos"])
		and reset_state["vel"].is_equal_approx(initial["vel"]),
		"reset restores skater position and velocity")


func test_steering_coasting_and_bounds() -> void:
	var model = Evening.new()
	model.reset()
	var start: Vector2 = model.snapshot()["pos"]
	advance(model, 1.0, Vector2.RIGHT)
	var moving: Dictionary = model.snapshot()
	check(moving["pos"].x > start.x, "steering right moves right")
	check(moving["vel"].x > 0.0, "steering builds rightward velocity")
	advance(model, 0.3)
	var coasting: Dictionary = model.snapshot()
	check(coasting["pos"].x > moving["pos"].x, "releasing steering coasts")
	advance(model, 3.0, Vector2.DOWN)
	var turned: Dictionary = model.snapshot()
	check(turned["pos"].y > coasting["pos"].y, "steering changes direction")
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		for _i in range(200):
			model.step(DT, direction, false, false)
			var p: Vector2 = model.snapshot()["pos"]
			check(p.x >= 0.0 and p.x <= 900.0 and p.y >= 0.0 and p.y <= 500.0,
				"movement remains within the ice")
			if not failures.is_empty() and failures[-1] == "movement remains within the ice":
				break


func test_distinct_lines() -> void:
	var model = Evening.new()
	model.reset()
	advance(model, 1.0, Vector2.RIGHT, true)
	var in_progress: Dictionary = model.snapshot()
	check(in_progress["active_line"].size() >= 2, "holding carve creates an active path")
	check(in_progress["grooves"].is_empty(), "active path is not finished before release")
	advance(model, 1.0, Vector2.RIGHT, true)
	model.step(DT, Vector2.RIGHT, false, false)
	var first: Dictionary = model.snapshot()
	check(first["grooves"].size() == 1 and first["active_line"].is_empty(),
		"release finalizes one line")
	draw_line(model, Vector2.DOWN)
	var second: Dictionary = model.snapshot()
	check(second["grooves"].size() == 2, "a second carve creates a separate line")
	if second["grooves"].size() >= 2:
		var a: PackedVector2Array = second["grooves"][0]
		var b: PackedVector2Array = second["grooves"][1]
		check(a.size() >= 2 and b.size() >= 2, "finished lines retain paths")
		if a.size() >= 2 and b.size() >= 2:
			check(not a[0].is_equal_approx(b[0]) or not a[-1].is_equal_approx(b[-1]),
				"separate gestures retain distinct geometry")


func test_cue_and_follower_traversal() -> void:
	var model = Evening.new()
	model.reset()
	draw_line(model, Vector2.RIGHT)
	var before: Dictionary = model.snapshot()
	model.step(DT, Vector2.ZERO, false, true)
	var cued: Dictionary = model.snapshot()
	check(cued["cue_serial"] > before["cue_serial"], "cue records a new cue")
	check(not cued["followers"].is_empty(), "cue assigns a partner")
	if cued["followers"].is_empty() or cued["grooves"].is_empty():
		return
	var follower: Dictionary = cued["followers"][0]
	var index: int = follower["groove"]
	check(index >= 0 and index < cued["grooves"].size(),
		"partner references a finished groove")
	if index < 0 or index >= cued["grooves"].size():
		return
	var path: PackedVector2Array = cued["grooves"][index]
	var start: Vector2 = follower["pos"]
	var moved := false
	var first_on_path := Vector2.ZERO
	var found_on_path := false
	var traveled_on_path := false
	for _i in range(100):
		model.step(DT, Vector2.ZERO, false, false)
		var followers: Array = model.snapshot()["followers"]
		if followers.is_empty():
			break
		var position: Vector2 = followers[0]["pos"]
		moved = moved or position.distance_to(start) > 5.0
		for j in range(path.size() - 1):
			var closest := Geometry2D.get_closest_point_to_segment(position, path[j], path[j + 1])
			if position.distance_to(closest) < 20.0:
				if not found_on_path:
					first_on_path = closest
					found_on_path = true
				elif closest.distance_to(first_on_path) > 5.0:
					traveled_on_path = true
	check(moved, "cued partner actually moves")
	check(traveled_on_path, "cued partner traverses the authored path")


func test_finale_and_phase_progression() -> void:
	var model = Evening.new()
	model.reset()
	draw_line(model, Vector2.RIGHT)
	draw_line(model, Vector2.DOWN)
	var authored: Array = model.snapshot()["grooves"].duplicate(true)
	check(wait_for_phase(model, "rehearsal", 360.0), "opening progresses to rehearsal")
	check(wait_for_phase(model, "finale", 360.0 - model.snapshot()["total_time"]),
		"rehearsal progresses to finale within six minutes")
	var finale: Dictionary = model.snapshot()
	check(not authored.is_empty() and finale["grooves"] == authored,
		"finale retains the player's authored lines")
	if finale["phase"] == "finale":
		var saw_authored_partner := false
		for _i in range(300):
			var state: Dictionary = model.snapshot()
			if state["phase"] != "finale":
				break
			for follower in state["followers"]:
				if follower["groove"] >= 0 and follower["groove"] < authored.size():
					saw_authored_partner = true
			model.step(DT, Vector2.ZERO, false, false)
		check(saw_authored_partner, "finale uses an authored groove for a partner")
	check(wait_for_phase(model, "bow", maxf(0.0, 360.0 - model.snapshot()["total_time"])),
		"finale progresses to bow within six minutes")
