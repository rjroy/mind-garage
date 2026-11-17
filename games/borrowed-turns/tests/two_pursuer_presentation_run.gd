extends SceneTree
## Controlled two-source facts from the real encounter and presentation controller.

const Encounter = preload("res://model/encounter.gd")
const Controller = preload("res://ui/shadow_presentation.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const COMPONENT := "res://ui/two_pursuer_presentation.gd"
const IDS := ["A", "B"]
var presenter_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func setup() -> bool:
	if not ResourceLoader.exists(COMPONENT):
		printerr("SETUP REQUIRED: ", COMPONENT, " missing; this is not behavioral RED")
		return false
	presenter_script = load(COMPONENT)
	if presenter_script == null or not presenter_script.can_instantiate():
		printerr("SETUP REQUIRED: presenter must load and instantiate")
		return false
	var instance = presenter_script.new()
	if not instance is RefCounted:
		printerr("SETUP REQUIRED: presenter must extend RefCounted")
		if instance is Node: instance.free()
		return false
	for method in instance.get_method_list():
		if method.name == "compose" and method.args.size() == 5: return true
	printerr("SETUP REQUIRED: compose(snapshot, frame, generation, source_ids, inspected_source)")
	return false

func fixture(safe_capture: bool = false) -> Dictionary:
	var ability := {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}
	return {
		"objective": "escape", "width": 5, "height": 5, "walls": [],
		"player": {"pos": [2, 2], "hp": 8}, "exit": {"pos": [4, 4], "opens": 3},
		"rules": {"actions": 2, "capture_range": 1},
		"enemies": [
			{"id": "A", "pos": [1, 2] if safe_capture else [2, 1], "dir": [0, 1], "hp": 5, "kind": "shove", "ability": ability.duplicate(true)},
			{"id": "B", "pos": [2, 3], "dir": [1, 0] if safe_capture else [0, -1], "hp": 5, "kind": "shove", "ability": ability.duplicate(true)},
		],
	}

func game(safe_capture: bool = false):
	var model = Encounter.new()
	model.configure(fixture(safe_capture), "R2")
	return model

func occurrence(source: String, turn: int) -> Dictionary:
	return {"source": source, "turn": turn, "kind": "shove"}

func compose(presenter, state: Dictionary, frame: Dictionary, inspected: String = "") -> Dictionary:
	var prior_state := state.duplicate(true)
	var prior_frame := frame.duplicate(true)
	var ids := IDS.duplicate()
	var result = presenter.compose(state, frame, 4, ids, inspected)
	check(result is Dictionary, "presenter returns a dictionary")
	check(state == prior_state and frame == prior_frame and ids == IDS, "projection leaves all input facts unchanged")
	return result if result is Dictionary else {}

func source(desc: Dictionary, id: String) -> Dictionary:
	var sources = desc.get("sources", {})
	if not sources is Dictionary: return {}
	var row = sources.get(id, {})
	return row if row is Dictionary else {}

func intent_cells(state: Dictionary, id: String) -> Array:
	for intent in state.get("intentions", []):
		if intent.get("source", "") == id: return intent.get("cells", [])
	return []

func commit(model, controller, command: Dictionary) -> Dictionary:
	var before: Dictionary = model.snapshot()
	var assessment: Dictionary = model.assess(command)
	check(assessment.get("legal", false), "controlled command legal: " + str(command))
	if not assessment.get("legal", false): return {}
	check(model.snapshot() == before, "assessment leaves model unchanged")
	if not model.act(command):
		check(false, "assessed command commits")
		return {}
	var after: Dictionary = model.snapshot()
	check(after == assessment.get("preview", {}), "actual result equals assessed result")
	check(controller.observe(before, command, after, 4), "shared controller observes committed result")
	return after

func cue_check(desc: Dictionary, frame: Dictionary, state: Dictionary, expected_type: String, actor: String) -> void:
	var cue: Dictionary = desc.get("current_cue", {})
	var actual: Dictionary = frame.get("cue", {})
	check(cue.get("type", "") == expected_type and cue.get("kind", "") == "shove", "current cue distinguishes " + expected_type)
	check(cue.get("source", "") == actual.get("source", "") and cue.get("actor", "") == actor, "current cue preserves source and acting owner")
	check(cue.get("event_index", -1) == actual.get("event_index", -2) and cue.get("progress", -1.0) == actual.get("progress", -2.0), "current cue uses shared event index and progress")
	check(cue.get("cells", []) == actual.get("cells", []) and cue.get("from", []) == actual.get("from", []) and cue.get("to", []) == actual.get("to", []), "current cue copies model-authored geometry from controller")
	var index: int = actual.get("event_index", -1)
	var limit: int = state.get("events", []).size()
	for planned in frame.get("cues", []):
		var next: int = planned.get("event_index", -1)
		if next > index: limit = mini(limit, next)
	if index >= 0 and index < limit:
		check(cue.get("events", []) == state.events.slice(index, limit), "current cue exposes its actual ordered event segment")
	else:
		check(false, "controlled cue references an actual event")

func test_threats_and_inspection() -> void:
	var model = game()
	var state: Dictionary = model.snapshot()
	var controller = Controller.new()
	controller.reset(state, 4)
	var presenter = presenter_script.new()
	var frame: Dictionary = controller.frame()
	var desc := compose(presenter, state, frame, "B")
	check(desc.get("generation", -1) == 4 and desc.get("player_slot", "") == "center", "player occupies stable central identity slot")
	for id in IDS:
		var row := source(desc, id)
		check(row.get("slot", "") == ("left" if id == "A" else "right"), id + " has fixed theatrical slot")
		check(row.get("occurrence", {}) == occurrence(id, state.turn), id + " owns current announcement")
		check(row.get("cells", []) == intent_cells(state, id), id + " footprint is model-authored")
		check(row.get("threatens_player", false) and row.get("cells", []).has(state.player.pos), id + " really threatens player")
		check(row.get("inspected", false) == (id == "B"), id + " inspection is separate from threat")
	check(desc.get("current_cue", {}).is_empty() and desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(), "initial threats do not invent committed effects")
	check(not desc.get("busy", true) and desc.get("loop_phase", -1.0) == frame.loop_phase, "idle uses shared controller phase")
	check(presenter.compose(state, frame, 5, IDS, "") == {}, "stale generation returns empty descriptor")
	var saved := desc.duplicate(true)
	var mutated := source(desc, "A")
	if mutated.get("cells", []) is Array: mutated.get("cells", []).append([99, 99])
	check(presenter.compose(state, frame, 4, IDS, "B") == saved, "returned nested facts are detached")
	var assessed: Dictionary = model.assess({"type": "capture", "source": "A"})
	desc = compose(presenter, state, frame, "A")
	check(not assessed.get("legal", true) and desc.get("transfer", {}).is_empty(),
		"overlapping current threats forbid capture; inspection cannot create a transfer")
	var moved := commit(model, controller, {"type": "move", "to": [1, 2]})
	if moved.is_empty(): return
	desc = compose(presenter, moved, controller.frame(), "A")
	for id in IDS:
		var row := source(desc, id)
		check(row.get("slot", "") == ("left" if id == "A" else "right"), "movement does not change " + id + " identity slot")
		check(row.get("cells", []) == intent_cells(moved, id) and not row.get("threatens_player", true), id + " is watchful when footprint misses player")
	check(source(desc, "A").get("inspected", false) and not source(desc, "A").get("threatens_player", true), "inspection does not invent a hit")

func test_capture_and_fresh() -> void:
	for captured in IDS:
		var other: String = "B" if captured == "A" else "A"
		var model = game(true)
		var controller = Controller.new()
		controller.reset(model.snapshot(), 4)
		var presenter = presenter_script.new()
		var after := commit(model, controller, {"type": "capture", "source": captured})
		if after.is_empty(): continue
		var frame: Dictionary = controller.frame()
		var desc := compose(presenter, after, frame)
		check(source(desc, captured).get("occurrence", {}).is_empty(), captured + " captured occurrence stops")
		check(source(desc, other).get("occurrence", {}) == occurrence(other, after.turn), other + " remains announced")
		check(not source(desc, other).get("threatens_player", true),
			other + " retains its real announcement without inventing a player hit on the safe flank")
		check(desc.get("transfer", {}).get("occurrence", {}) == occurrence(captured, after.turn), captured + " actual acquired occurrence transfers")
		check(desc.get("held_occurrence", {}).is_empty(), "active transfer suppresses duplicate held occurrence")
		cue_check(desc, frame, after, "capture", captured)
		var bogus := after.duplicate(true)
		var event_index: int = frame.get("cue", {}).get("event_index", -1)
		if event_index >= 0 and event_index < bogus.events.size():
			bogus.events[event_index].type = "capture_failed"
			check(compose(presenter, bogus, frame).get("transfer", {}).is_empty(), "capture cue cannot invent acquisition without actual capture event")
		else:
			check(false, "controlled capture references a real event")
		controller.advance(60.0)
		desc = compose(presenter, after, controller.frame())
		check(desc.get("held_occurrence", {}) == occurrence(captured, after.turn), "settled held occurrence retains original capture turn")
		var next := commit(model, controller, {"type": "end_turn"})
		if next.is_empty(): continue
		frame = controller.frame()
		desc = compose(presenter, next, frame)
		cue_check(desc, frame, next, "resolve", other)
		controller.advance(60.0)
		desc = compose(presenter, next, controller.frame())
		check(source(desc, captured).get("occurrence", {}) == occurrence(captured, next.turn), "surviving source has fresh occurrence")
		check(desc.get("held_occurrence", {}) == occurrence(captured, after.turn), "fresh source and old held have different turn identity")

func test_release_and_replacement() -> void:
	var model = game(true)
	var controller = Controller.new()
	controller.reset(model.snapshot(), 4)
	var presenter = presenter_script.new()
	if commit(model, controller, {"type": "capture", "source": "A"}).is_empty(): return
	controller.advance(60.0)
	var released := commit(model, controller, {"type": "release", "target": [2, 3]})
	if released.is_empty(): return
	var frame: Dictionary = controller.frame()
	var desc := compose(presenter, released, frame)
	cue_check(desc, frame, released, "release", "player")
	check(desc.get("held_occurrence", {}).is_empty(), "released ability is no longer held")
	# A's backlash would otherwise push B out of capture reach. Block that
	# displacement only in the successful replacement fixture.
	var blocked_fixture := fixture(true)
	blocked_fixture.walls = [[2, 4]]
	model = Encounter.new()
	model.configure(blocked_fixture, "R2")
	controller = Controller.new()
	controller.reset(model.snapshot(), 4)
	if commit(model, controller, {"type": "capture", "source": "A"}).is_empty(): return
	controller.advance(60.0)
	var replaced := commit(model, controller, {"type": "capture", "source": "B"})
	if replaced.is_empty(): return
	frame = controller.frame()
	desc = compose(presenter, replaced, frame)
	cue_check(desc, frame, replaced, "backlash", "player")
	check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(), "queued new capture does not appear while old backlash resolves")
	controller.advance(Controller.DURATIONS.backlash + 0.01)
	frame = controller.frame()
	desc = compose(presenter, replaced, frame)
	cue_check(desc, frame, replaced, "capture", "B")
	check(desc.get("transfer", {}).get("occurrence", {}) == occurrence("B", replaced.turn), "actual replacement transfers B, not old A")
	# With the original wall-free board B survives, but is pushed out of reach.
	model = game(true)
	controller = Controller.new()
	controller.reset(model.snapshot(), 4)
	if commit(model, controller, {"type": "capture", "source": "A"}).is_empty(): return
	controller.advance(60.0)
	var pushed := commit(model, controller, {"type": "capture", "source": "B"})
	if pushed.is_empty(): return
	var pushed_out := false
	for event in pushed.events:
		if event.get("type", "") == "capture_failed" and event.get("source", "") == "B" and event.get("reason", "") == "out_of_reach":
			pushed_out = true
	var b_alive_at_destination := false
	for enemy in pushed.enemies:
		if enemy.get("id", "") == "B" and enemy.get("hp", 0) > 0 and enemy.get("pos", []) == [2, 4]:
			b_alive_at_destination = true
	check(pushed_out and b_alive_at_destination, "wall-free replacement leaves B alive but pushed out of reach")
	controller.advance(60.0)
	desc = compose(presenter, pushed, controller.frame())
	check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(), "out-of-reach replacement cannot invent B transfer or ownership")
	var failed_fixture := fixture(true)
	failed_fixture.enemies[1].hp = 1
	model = Encounter.new()
	model.configure(failed_fixture, "R2")
	controller = Controller.new()
	controller.reset(model.snapshot(), 4)
	if commit(model, controller, {"type": "capture", "source": "A"}).is_empty(): return
	controller.advance(60.0)
	var failed := commit(model, controller, {"type": "capture", "source": "B"})
	if failed.is_empty(): return
	var b_died := false
	var source_dead := false
	for event in failed.events:
		if event.get("type", "") == "death" and event.get("actor", "") == "B": b_died = true
		if event.get("type", "") == "capture_failed" and event.get("source", "") == "B" and event.get("reason", "") == "source_dead": source_dead = true
	check(b_died and source_dead, "backlash kills B and replacement reports source_dead")
	controller.advance(60.0)
	desc = compose(presenter, failed, controller.frame())
	check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(), "replacement killing B does not create a held or transferred B occurrence")

func test_movement_is_not_an_attack_or_fresh_rehearsal() -> void:
	var transition := MovementFixture.movement_transition()
	var controller = Controller.new()
	controller.reset(transition.before, 4)
	check(controller.observe(transition.before, {"type": "end_turn"}, transition.after, 4), "presenter receives shared ordered movement controller")
	var presenter = presenter_script.new()
	var moves: Array = []
	for _step in range(14400):
		var frame: Dictionary = controller.frame()
		if not frame.busy: break
		var desc := compose(presenter, transition.after, frame)
		check(source(desc, "A").get("occurrence", {}).is_empty(), "Director does not rehearse a fresh next-turn shove during prior attacks/slides")
		var cue: Dictionary = frame.cue
		if cue.get("type", "") == "move" and cue.get("actor", "") not in moves:
			moves.append(cue.actor)
			var actual: Dictionary = desc.get("current_cue", {})
			check(actual.get("type", "") == "move" and actual.get("actor", "") == cue.actor
				and actual.get("event_index", -1) == cue.event_index
				and actual.get("from", []) == cue.from and actual.get("to", []) == cue.to,
				"Director projection distinguishes the actual moving actor and event from a shove")
			check(desc.get("transfer", {}).is_empty(), "moving an opponent cannot fabricate a capture handoff")
		controller.advance(1.0 / 120.0)
	check(moves == ["A", "B"], "presenter receives both independent voluntary move stages")
	var settled := compose(presenter, transition.after, controller.frame())
	check(source(settled, "A").get("occurrence", {}).get("turn", -1) == transition.after.turn,
		"fresh Director rehearsal begins only when the common finite sequence settles")

func _run() -> void:
	if not setup():
		quit(2)
		return
	test_threats_and_inspection()
	test_capture_and_fresh()
	test_release_and_replacement()
	test_movement_is_not_an_attack_or_fresh_rehearsal()
	print("Two pursuer presentation: %d checks, %d failures. Controlled facts; no visual acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
