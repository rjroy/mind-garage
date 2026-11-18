extends SceneTree

# godot --headless --path games/last-light-on-the-rink --script res://tests/bow_run.gd
const Evening = preload("res://evening.gd")
const DT := 0.1
const CENTER := Vector2(450.0, 250.0)
const PARTNER_SPOTS := [Vector2(391.0, 250.0), Vector2(509.0, 250.0)]
# The existing bow choreography lasts nearly four seconds after it starts.
const MIN_COMPLETE_BOW := 4.0

var failures: Array[String] = []


func _initialize() -> void:
	test_bow(false)
	test_bow(true)
	if failures.is_empty():
		print("PASS: idle and late-steering bow")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("%d bow checks failed" % failures.size())
		quit(1)


func test_bow(steer_late: bool) -> void:
	var label := "wall-edge" if steer_late else "idle"
	var model = Evening.new()
	model.reset()
	var state: Dictionary = model.snapshot()
	# Normal model stepping, with no clock injection or private state changes.
	for i in range(2400):
		if state["phase"] == "bow":
			break
		var direction := Vector2.RIGHT if steer_late and state["phase"] == "finale" else Vector2.ZERO
		model.step(DT, direction, false, false)
		state = model.snapshot()
	if not check(state["phase"] == "bow", label + ": reaches bow"):
		return
	if steer_late:
		check(state["pos"].x > 800.0, "late steering actually reaches the right wall")
		check(state["pos"].distance_to(CENTER) > 100.0, "player must travel to the bow")
	if not check(state.has("bow_time"), label + ": exposes shared bow_time"):
		return
	if steer_late:
		check(float(state["bow_time"]) < 0.0, "wall-edge cast is gathering, not bowing")

	var saw_bow := false
	var premature := false
	var clock_regressed := false
	var previous_bow := -1.0
	var stopped := false
	for i in range(400):
		state = model.snapshot()
		var bow_time := float(state["bow_time"])
		var settled := _cast_settled(state)
		if bow_time >= 0.0:
			saw_bow = true
			premature = premature or not settled
			clock_regressed = clock_regressed or (previous_bow >= 0.0 and bow_time < previous_bow)
			previous_bow = bow_time
		elif saw_bow:
			clock_regressed = true
		var previous_time := float(state["total_time"])
		model.step(DT, Vector2.ZERO, false, false)
		var next: Dictionary = model.snapshot()
		if is_equal_approx(float(next["total_time"]), previous_time):
			state = next
			stopped = true
			break
	check(saw_bow, label + ": cast eventually starts the bow")
	check(not premature, label + ": bow clock runs only when whole cast is settled")
	check(not clock_regressed, label + ": bow clock never regresses")
	check(stopped, label + ": performance reaches a stable end")
	check(float(state.get("bow_time", -1.0)) >= MIN_COMPLETE_BOW,
		label + ": ending leaves time for the full bow before goodnight")
	if stopped:
		var end_time := float(state["total_time"])
		for i in range(10):
			model.step(DT, Vector2.RIGHT, true, true)
		check(is_equal_approx(float(model.snapshot()["total_time"]), end_time),
			label + ": completed performance remains ended")

	model.reset()
	var reset: Dictionary = model.snapshot()
	check(reset["phase"] == "opening" and is_zero_approx(float(reset["total_time"])),
		label + ": restart returns to opening")
	check(float(reset.get("bow_time", 0.0)) < 0.0, label + ": restart clears bow clock")
	check(reset["pos"].is_equal_approx(CENTER) and reset["followers"].is_empty(),
		label + ": restart clears cast positions")


func _cast_settled(state: Dictionary) -> bool:
	var position: Vector2 = state["pos"]
	var velocity: Vector2 = state["vel"]
	var followers: Array = state["followers"]
	if position.distance_to(CENTER) > 2.0 or velocity.length() > 2.0 or followers.size() != 2:
		return false
	for i in range(2):
		var follower: Dictionary = followers[i]
		var partner_pos: Vector2 = follower["pos"]
		var partner_vel: Vector2 = follower["vel"]
		if partner_pos.distance_to(PARTNER_SPOTS[i]) > 2.0 or partner_vel.length() > 2.0:
			return false
	return true


func check(condition: bool, message: String) -> bool:
	if not condition:
		failures.append(message)
	return condition
