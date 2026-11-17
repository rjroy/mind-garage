extends SceneTree
## Source identities and finite event segments, independent of production tuning.
const F = preload("res://tests/shadow_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const Controller = preload("res://ui/shadow_presentation.gd")
const Presenter = preload("res://ui/two_pursuer_presentation.gd")
const IDS := ["A", "B"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func occurrence(id: String, turn: int) -> Dictionary:
	return {"source": id, "turn": turn, "kind": "shove"}

func compose(p, state: Dictionary, frame: Dictionary, inspected: String = "") -> Dictionary:
	var state_copy := state.duplicate(true)
	var frame_copy := frame.duplicate(true)
	var result: Dictionary = p.compose(state, frame, 4, IDS, inspected)
	check(state == state_copy and frame == frame_copy, "presenter never mutates authoritative inputs")
	return result

func source(desc: Dictionary, id: String) -> Dictionary:
	return desc.get("sources", {}).get(id, {})

func cue_check(desc: Dictionary, frame: Dictionary, state: Dictionary, type: String, actor: String) -> void:
	var cue: Dictionary = desc.get("current_cue", {})
	var actual: Dictionary = frame.get("cue", {})
	check(cue.get("type", "") == type and cue.get("actor", "") == actor,
		"projected cue distinguishes acting owner and " + type)
	for field in ["source", "event_index", "progress", "cells", "from", "to"]:
		check(cue.get(field) == actual.get(field), "current cue preserves controller " + field)
	var start: int = actual.get("event_index", -1)
	var end: int = state.events.size()
	for planned in frame.get("cues", []):
		if planned.get("event_index", -1) > start: end = mini(end, planned.event_index)
	check(start >= 0 and start < end and cue.get("events", []) == state.events.slice(start, end),
		"cue segment includes all owned damage/displacement, never the next ability")

func test_inspection_arming_and_detachment() -> void:
	var state := F.state()
	# Both are shoves here so both source-slot/occurrence projections are exercised.
	state.enemies[1].kind = "shove"
	state.enemies[1].ability = F.ability()
	state.intentions[1].kind = "shove"
	var controller := Controller.new()
	controller.reset(state, 4)
	var p := Presenter.new()
	var frame: Dictionary = controller.frame()
	var desc := compose(p, state, frame, "B")
	check(desc.get("player_slot", "") == "center", "player has stable identity slot")
	for id in IDS:
		var row := source(desc, id)
		var index := IDS.find(id)
		check(row.get("slot", "") == ("left" if id == "A" else "right")
			and row.get("occurrence", {}) == occurrence(id, 1), id + ": source slot and occurrence are stable")
		check(row.get("cells", []) == state.intentions[index].cells
			and row.get("threatens_player", false) == state.intentions[index].cells.has(state.player.pos),
			id + ": threat is exact model geometry, not inspection")
		check(row.get("inspected", false) == (id == "B"), "inspection is not an acquisition command")
	var saved := desc.duplicate(true)
	source(desc, "A").cells.append([99, 99])
	check(p.compose(state, frame, 4, IDS, "B") == saved, "nested descriptor output detached")
	check(p.compose(state, frame, 5, IDS, "") == {}, "stale generation cannot project active facts")
	var armed := state.duplicate(true)
	armed.capture_armed = true
	armed.action_points = 2
	armed.events = [{"type": "capture_armed"}]
	controller.observe(state, {"type": "capture"}, armed, 4)
	desc = compose(p, armed, controller.frame())
	check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(),
		"arming does not make a motif depart from either attacker")
	for id in IDS:
		check(source(desc, id).get("occurrence", {}) == occurrence(id, 1),
			"arming never suppresses the living source's warning")

func test_attack_handoff_and_other_attack() -> void:
	var t := F.armed_hit()
	var controller := Controller.new()
	controller.reset(t.before, 4)
	controller.observe(t.before, t.command, t.after, 4)
	var p := Presenter.new()
	var seen: Array = []
	var acquisition_checked := false
	for _step in range(14400):
		var frame: Dictionary = controller.frame()
		if not frame.busy: break
		var desc := compose(p, t.after, frame)
		var index: int = frame.cue.get("event_index", -1)
		if index not in seen:
			seen.append(index)
			var type: String = frame.cue.get("type", "")
			cue_check(desc, frame, t.after, type, "A" if index in [0, 3] else "B")
			if index == 0:
				check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(),
					"first normal strike is complete before any incoming handoff or held motif")
			if index == 3:
				acquisition_checked = true
				check(desc.get("transfer", {}).get("occurrence", {}) == occurrence("A", 1)
					and desc.get("held_occurrence", {}).is_empty(), "actual post-hit acquisition transfers one A motif")
				var bogus: Dictionary = t.after.duplicate(true)
				bogus.events[3].type = "capture_armed"
				check(compose(p, bogus, frame).get("transfer", {}).is_empty(), "no transfer without a matching actual acquisition event")
			if index == 4:
				check(desc.get("held_occurrence", {}) == occurrence("A", 1) and desc.get("transfer", {}).is_empty(),
					"completed acquisition remains held while B's full damaging attack follows")
		check(source(desc, "A").get("occurrence", {}).is_empty(), "fresh next-turn rehearsal waits for old strikes and handoff")
		controller.advance(1.0 / 120.0)
	check(seen == [0, 3, 4] and acquisition_checked, "both attacks and the between-attacks handoff are independently visited")
	var settled := compose(p, t.after, controller.frame())
	check(source(settled, "A").get("occurrence", {}) == occurrence("A", 2)
		and settled.get("held_occurrence", {}) == occurrence("A", 1),
		"fresh attack and retained borrowed occurrence coexist with distinct turn identity")

func test_reusable_shine_and_loss() -> void:
	var p := Presenter.new()
	for loss in [false, true]:
		var t := F.shine_transition("shove", loss)
		var controller := Controller.new()
		controller.reset(t.before, 4)
		controller.observe(t.before, t.command, t.after, 4)
		var frame: Dictionary = controller.frame()
		var desc := compose(p, t.after, frame)
		cue_check(desc, frame, t.after, "shine", "player")
		check(desc.get("held_occurrence", {}) == occurrence("A", 1),
			"Shine keeps source identity through the complete ability, including source-killing effects")
		check(desc.get("transfer", {}).is_empty(), "Shine is not reacquisition")
		controller.advance(60.0)
		desc = compose(p, t.after, controller.frame())
		check(desc.get("held_occurrence", {}) == ({} if loss else occurrence("A", 1)),
			"only an actual source-death loss clears the settled borrowed motif")
		if loss:
			check(source(desc, "A").get("occurrence", {}).is_empty(), "defeated source cannot rehearse")

func test_movement_is_not_a_fresh_attack() -> void:
	var t := MovementFixture.movement_transition()
	var controller := Controller.new()
	controller.reset(t.before, 4)
	controller.observe(t.before, {"type": "end_turn"}, t.after, 4)
	var p := Presenter.new()
	var moves: Array = []
	for _step in range(14400):
		var frame: Dictionary = controller.frame()
		if not frame.busy: break
		var desc := compose(p, t.after, frame)
		check(source(desc, "A").get("occurrence", {}).is_empty(), "Director waits for all old attacks and slides")
		if frame.cue.get("type", "") == "move" and frame.cue.get("actor", "") not in moves:
			moves.append(frame.cue.actor)
			cue_check(desc, frame, t.after, "move", frame.cue.actor)
			check(desc.get("transfer", {}).is_empty(), "slide cannot fabricate acquisition")
		controller.advance(1.0 / 120.0)
	check(moves == ["A", "B"], "both event-owned enemy slides retained")
	check(source(compose(p, t.after, controller.frame()), "A").get("occurrence", {}).get("turn", -1) == t.after.turn,
		"fresh Director warning begins at settlement")

func _run() -> void:
	test_inspection_arming_and_detachment()
	test_attack_handoff_and_other_attack()
	test_reusable_shine_and_loss()
	test_movement_is_not_a_fresh_attack()
	print("Two-source presentation: %d checks, %d failures. Controlled facts, not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
