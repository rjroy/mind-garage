extends SceneTree

# godot --headless --path games/last-light-on-the-rink --script res://tests/cue_run.gd
const Evening = preload("res://evening.gd")
const DT := 0.1

var failures: Array[String] = []


func _initialize() -> void:
	var model = Evening.new()
	model.reset()
	var initial: Dictionary = model.snapshot()
	model.step(DT, Vector2.ZERO, false, true)
	var empty_cue: Dictionary = model.snapshot()
	check(empty_cue["grooves"].is_empty(), "empty cue starts without a finished groove")
	# The sound layer uses cue_serial as its successful-cue signal.
	check(empty_cue["cue_serial"] == initial["cue_serial"], "empty cue emits no successful cue")
	check(empty_cue["followers"].is_empty(), "empty cue does not invite or assign a partner")

	for i in range(20):
		model.step(DT, Vector2.RIGHT, true, false)
	model.step(DT, Vector2.RIGHT, false, false)
	var carved: Dictionary = model.snapshot()
	check(carved["grooves"].size() == 1, "carve and release produces a finished groove")
	model.step(DT, Vector2.ZERO, false, true)
	var cued: Dictionary = model.snapshot()
	check(cued["cue_serial"] == carved["cue_serial"] + 1, "legal cue emits exactly one successful cue")
	var assigned := false
	for follower in cued["followers"]:
		if follower["groove"] == 0:
			assigned = true
	check(assigned, "legal cue assigns a partner to the finished groove")

	if failures.is_empty():
		print("PASS: cue behavior")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("%d cue checks failed" % failures.size())
		quit(1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
