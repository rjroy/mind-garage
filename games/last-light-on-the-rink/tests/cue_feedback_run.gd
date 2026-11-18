extends SceneTree

# godot --headless --path games/last-light-on-the-rink --script res://tests/cue_feedback_run.gd
const Evening = preload("res://evening.gd")
const RinkView = preload("res://rink_view.gd")
const DT := 0.1

var failures: Array[String] = []
var view: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model = Evening.new()
	model.reset()
	view = RinkView.new()
	root.add_child(view)
	var state: Dictionary = model.snapshot()
	view.call("present", state)
	check(state.has("cued_partner"), "model exposes cued_partner")
	check(int(state.get("cued_partner", -2)) == -1, "no recipient before a successful cue")
	if not check(view.has_method("cue_feedback_partner"),
			"view exposes its currently rippling partner through cue_feedback_partner()"):
		_finish()
		return
	check(_recipient() == -1, "no partner ripples initially")

	# Enter rehearsal using ordinary model steps, then make two authored lines.
	for i in range(300):
		if model.snapshot()["phase"] == "rehearsal":
			break
		model.step(DT, Vector2.ZERO, false, false)
	state = model.snapshot()
	if not check(state["phase"] == "rehearsal" and state["followers"].size() == 2,
			"two partners are present"):
		_finish()
		return
	view.call("present", state)
	_draw_line(model, Vector2.RIGHT)
	state = model.snapshot()
	if not check(state["grooves"].size() == 1, "first authored line exists"):
		_finish()
		return
	view.call("present", state)
	_cue(model, 0, "first cue")
	_expire_feedback()
	check(_recipient() == -1, "first ripple expires")

	_draw_line(model, Vector2.DOWN)
	state = model.snapshot()
	if not check(state["grooves"].size() == 2, "second authored line exists"):
		_finish()
		return
	view.call("present", state)
	var before: Dictionary = model.snapshot()
	_cue(model, 1, "second cue")
	state = model.snapshot()
	check(before["followers"][0]["groove"] == state["followers"][0]["groove"],
		"second cue leaves first partner's assignment unchanged")
	check(state["followers"][0]["groove"] == 0 and state["followers"][1]["groove"] == 1,
		"second cue assigns only the second partner to the second line")
	_expire_feedback()

	# Round robin selects partner zero, then partner one again. The latter is
	# already on the latest groove, so assignment-difference detection is wrong.
	_cue(model, 0, "third cue")
	_expire_feedback()
	before = model.snapshot()
	_cue(model, 1, "repeat cue on already-followed groove")
	state = model.snapshot()
	check(before["followers"][1]["groove"] == 1 and state["followers"][1]["groove"] == 1,
		"repeat cue selects a partner already following that groove")
	_finish()


func _draw_line(model: RefCounted, direction: Vector2) -> void:
	for i in range(20):
		model.step(DT, direction, true, false)
	model.step(DT, direction, false, false)


func _cue(model: RefCounted, expected: int, label: String) -> void:
	var before: Dictionary = model.snapshot()
	model.step(DT, Vector2.ZERO, false, true)
	var after: Dictionary = model.snapshot()
	check(int(after["cue_serial"]) == int(before["cue_serial"]) + 1, label + ": successful cue event")
	check(int(after.get("cued_partner", -2)) == expected, label + ": model identifies recipient")
	view.call("present", after)
	check(_recipient() == expected, label + ": only recipient gets visual feedback")


func _expire_feedback() -> void:
	# Advance the real view animation so the previous cue cannot mask a later one.
	for i in range(60):
		view._process(0.05)


func _recipient() -> int:
	return int(view.call("cue_feedback_partner"))


func check(condition: bool, message: String) -> bool:
	if not condition:
		failures.append(message)
	return condition


func _finish() -> void:
	if failures.is_empty():
		print("PASS: cue feedback targets the cued partner")
		quit(0)
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
		printerr("%d cue feedback checks failed" % failures.size())
		quit(1)
