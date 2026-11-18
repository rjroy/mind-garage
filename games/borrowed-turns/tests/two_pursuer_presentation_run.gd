extends SceneTree
## Source identities and finite event segments, independent of production tuning.
const F = preload("res://tests/shadow_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const Controller = preload("res://ui/shadow_presentation.gd")
const Presenter = preload("res://ui/two_pursuer_presentation.gd")
const Rig = preload("res://ui/two_pursuer_rig.gd")
const Board = preload("res://ui/board.gd")
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

func test_switcher_identity_locked_target_and_atomic_event_segment() -> void:
	var p := Presenter.new()
	var t := F.swap_hit()
	var controller := Controller.new()
	controller.reset(t.before, 4)
	var desc := compose(p, t.before, controller.frame(), "A")
	var row := source(desc, "A")
	check(row.get("name", "") == "Switcher" and row.get("occurrence", {}) == {"source": "A", "turn": 1, "kind": "swap"},
		"provisional A artwork is explicitly a Switcher with Swap occurrence identity, never a shove disguise")
	check(row.get("cells", []) == [[2, 3]] and row.get("from", []) == [2, 1] and row.get("target", []) == [2, 3],
		"Director receives exact source and locked single-cell target, not a filled ray")
	check(source(desc, "B").get("occurrence", {}).is_empty(), "solo Switcher never invents a second active source")
	controller.observe(t.before, t.command, t.after, 4)
	var seen: Array = []
	for _step in range(14400):
		var frame: Dictionary = controller.frame()
		if not frame.busy: break
		desc = compose(p, t.after, frame)
		var index: int = frame.cue.event_index
		if index not in seen:
			seen.append(index)
			if index == 0:
				cue_check(desc, frame, t.after, "resolve", "A")
				check(desc.get("current_cue", {}).get("events", []) == t.after.events.slice(0, 3),
					"owning resolve exposes mask -> atomic swap -> damage, without stealing later capture")
				check(desc.get("held_occurrence", {}).is_empty() and desc.get("transfer", {}).is_empty(),
					"actual exchange and hit occur before any acquisition motif")
			if index == 3:
				check(desc.get("transfer", {}).get("occurrence", {}) == {"source": "A", "turn": 1, "kind": "swap"},
					"actual acquired Swap transfers only after exchange and damage")
		controller.advance(1.0 / 120.0)
	check(seen == [0, 3], "Switcher visits exactly its owning attack then acquisition, not fake generic move stages")
	desc = compose(p, t.after, controller.frame())
	check(desc.get("held_occurrence", {}) == {"source": "A", "turn": 1, "kind": "swap"}
		and source(desc, "A").get("occurrence", {}) == {"source": "A", "turn": 2, "kind": "swap"},
		"held Swap and source's fresh eligible plan retain different occurrence identities")
	for invalid in [false, true]:
		var miss := F.swap_miss(invalid)
		controller.reset(miss.before, 4)
		controller.observe(miss.before, miss.command, miss.after, 4)
		desc = compose(p, miss.after, controller.frame())
		check(desc.get("current_cue", {}).get("events", []) == miss.after.events
			and desc.get("current_cue", {}).get("cells", [99]) == miss.after.events[0].cells,
			"honest finite miss is owned by its actual singleton or empty mask, with locked target metadata intact")
		check(desc.get("transfer", {}).is_empty(), "empty target never produces a fictitious handoff")

func test_switcher_shine_owner_and_source_loss() -> void:
	var p := Presenter.new()
	for loss in [false, true]:
		var t := F.swap_shine(loss)
		var controller := Controller.new()
		controller.reset(t.before, 4)
		controller.observe(t.before, t.command, t.after, 4)
		var desc := compose(p, t.after, controller.frame())
		cue_check(desc, controller.frame(), t.after, "shine", "player")
		check(desc.get("current_cue", {}).get("events", []) == t.after.events,
			"Shine owns the complete mask/exchange/damage/death segment rather than a shove animation")
		check(desc.get("held_occurrence", {}) == {"source": "A", "turn": 1, "kind": "swap"},
			"source-linked Swap identity remains through its full killing exchange")
		controller.advance(60.0)
		desc = compose(p, t.after, controller.frame())
		check(desc.get("held_occurrence", {}) == ({} if loss else {"source": "A", "turn": 1, "kind": "swap"}),
			"only actual source death clears the completed Swap motif")

func make_rig(enemies: Array):
	var art := {}
	for key in ["a_body", "a_hands", "b_body", "b_hands", "p_lantern"]:
		var dimensions := Vector2i(145, 145) if key == "p_lantern" else Vector2i(290, 145)
		var image := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		art[key] = ImageTexture.create_from_image(image)
	var rig := Rig.new()
	check(rig.configure_assets(art), "controlled Director artwork configures")
	rig.bind_composition(enemies)
	return rig

func check_source_body(before: Dictionary, after: Dictionary, frame: Dictionary, visible: bool, label: String) -> void:
	var board := Board.new()
	board.bind_composition(before.enemies)
	board.set_view(after, {}, [], [], "")
	board.show_transition(before)
	board.set_presentation(frame)
	var board_visible := false
	for actor in board._visual_actors():
		if actor.actor == "A": board_visible = true
	check(board_visible == visible, label + ": Board reflects ordered source death")
	var rig = make_rig(before.enemies)
	rig.present(compose(Presenter.new(), after, frame), Rect2(0, 0, 1000, 500))
	var body: Sprite2D = rig._bodies.get("A")
	check(body != null and body.visible == visible,
		label + ": Director source body matches Board and ordered source death")
	rig.free()
	board.free()

func test_named_swap_resolve_caption() -> void:
	var t := F.swap_hit()
	for snapshot in [t.before, t.after]:
		snapshot.enemies[0]["name"] = "Mirror Courier"
		snapshot.enemies[0]["definition"] = "courier"
		snapshot.enemies[0]["presentation"] = {"kit": "A"}
	var controller := Controller.new()
	controller.reset(t.before, 4)
	controller.observe(t.before, t.command, t.after, 4)
	var desc := compose(Presenter.new(), t.after, controller.frame())
	check(source(desc, "A").get("name", "") == "Mirror Courier",
		"named Swap source reaches the Director descriptor")
	var rig = make_rig(t.before.enemies)
	rig.present(desc, Rect2(0, 0, 1000, 500))
	check(rig._caption.text.contains("Mirror Courier") and not rig._caption.text.contains("Switcher"),
		"Swap resolve caption names the actual opponent, not a hardcoded Switcher")
	rig.free()

func test_definition_shine_source_loss_timeline() -> void:
	var p := Presenter.new()
	for kind in ["bolt", "burst", "pull"]:
		for loss in [false, true]:
			var t := F.shine_transition(kind, loss)
			t.before.enemies[0]["definition"] = "paper"
			t.before.enemies[0]["presentation"] = {"kit": "A"}
			if not loss:
				t.after.enemies[0]["definition"] = "paper"
				t.after.enemies[0]["presentation"] = {"kit": "A"}
			var controller := Controller.new()
			controller.reset(t.before, 4)
			controller.observe(t.before, t.command, t.after, 4)
			var frame: Dictionary = controller.frame()
			var desc := compose(p, t.after, frame)
			check(desc.get("current_cue", {}).get("type", "") == "shine",
				kind + ": actual Shine cue is projected")
			check(desc.get("held_occurrence", {}) == {"source": "A", "turn": 1, "kind": kind},
				kind + ": held cast remains visible during Shine, including lethal source damage")
			if loss:
				check_source_body(t.before, t.after, frame, true, kind + " lethal Shine start")
			controller.advance(60.0)
			desc = compose(p, t.after, controller.frame())
			check(desc.get("held_occurrence", {}) == ({} if loss else {"source": "A", "turn": 1, "kind": kind}),
				kind + ": settled held motif clears only on source loss")
			if loss:
				check_source_body(t.before, t.after, controller.frame(), false, kind + " lethal Shine settled")

func test_capture_before_later_source_death() -> void:
	var before := F.state()
	before.capture_armed = true
	before.enemies[0].kind = "bolt"
	before.enemies[0].ability = F.ability("bolt")
	before.enemies[0].hp = 1
	before.enemies[0]["definition"] = "paper"
	before.enemies[0]["presentation"] = {"kit": "A"}
	before.intentions[0].kind = "bolt"
	# B's later line passes through A before reaching the player.
	before.enemies[1].pos = [2, 0]
	before.enemies[1].dir = [0, 1]
	before.enemies[1].kind = "shove"
	before.enemies[1].ability = F.ability("shove")
	before.intentions[1] = {"source": "B", "kind": "shove", "cells": [[2, 1], [2, 2], [2, 3]]}
	var after := before.duplicate(true)
	after.turn = 2
	after.capture_armed = false
	after.player.hp = 18
	after.player.pos = [2, 4]
	after.enemies = [after.enemies[1]]
	after.intentions = []
	after.stored = {}
	after.events = [
		{"type": "ray", "actor": "A", "kind": "bolt", "cells": [[2, 2], [2, 3]]},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 19},
		{"type": "capture", "source": "A", "kind": "bolt"},
		{"type": "ray", "actor": "B", "kind": "shove", "cells": [[2, 1], [2, 2], [2, 3]]},
		{"type": "damage", "actor": "A", "amount": 1, "hp": 0},
		{"type": "death", "actor": "A"},
		{"type": "ability_lost", "source": "A", "reason": "source_dead"},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 18},
		{"type": "displace", "actor": "player", "from": [2, 3], "to": [2, 4]},
		{"type": "turn", "number": 2},
	]
	var controller := Controller.new()
	controller.reset(before, 4)
	controller.observe(before, {"type": "end_turn"}, after, 4)
	var p := Presenter.new()
	var visited := []
	for _step in range(100):
		var frame: Dictionary = controller.frame()
		if not frame.busy: break
		var type: String = frame.cue.type
		if type not in visited:
			visited.append(type)
			var desc := compose(p, after, frame)
			if type == "capture":
				check(desc.get("transfer", {}).get("occurrence", {}) == {"source": "A", "turn": 1, "kind": "bolt"},
					"actual capture transfer survives a later attacker killing its definition source")
		controller.advance(0.02)
	# Both resolve cues have the same type, so explicitly check the later cue too.
	controller.reset(before, 4)
	controller.observe(before, {"type": "end_turn"}, after, 4)
	controller.advance(0.37)
	var later: Dictionary = controller.frame()
	check(later.get("cue", {}).get("source", "") == "B", "later attacker cue reached")
	check_source_body(before, after, later, true, "later source-killing attack start")
	check(compose(p, after, later).get("held_occurrence", {}) == {"source": "A", "turn": 1, "kind": "bolt"},
		"held motif survives until B's ordered attack and source loss")
	controller.advance(60.0)
	check_source_body(before, after, controller.frame(), false, "later source-killing attack settled")
	check(compose(p, after, controller.frame()).get("held_occurrence", {}).is_empty(),
		"source loss clears the motif after the finite timeline")
	check("capture" in visited, "actual capture cue was visited before source death")

func test_settled_cue_with_pending_board_pulse() -> void:
	var t := F.shine_transition("bolt", true)
	t.before.enemies[0]["definition"] = "paper"
	t.before.enemies[0]["presentation"] = {"kit": "A"}
	var controller := Controller.new()
	controller.reset(t.before, 4)
	controller.observe(t.before, t.command, t.after, 4)
	var board := Board.new()
	board.size = Vector2(1280, 650)
	var art := {}
	var assembly := {}
	for id in ["A", "B", "player"]:
		var image := Image.create(12, 20, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		art[id] = ImageTexture.create_from_image(image)
		assembly[id] = {"canvas": Vector2(12, 20), "foot": Vector2(6, 19), "height_fraction": 0.4}
	check(board.configure_standees(art, assembly), "pending-pulse Board standees configure")
	board.bind_composition(t.before.enemies)
	board.set_view(t.after, {}, [], [], "")
	# _confirm pulses and then records the pre-command state; the tween can
	# still be at its initial value when the finite clock first settles.
	board.accent = 1.0
	board.show_transition(t.before)
	board.set_presentation(controller.frame())
	check(board.standee_layout().any(func(row): return row.actor == "A"),
		"lethal cue starts with the source visibly on the Board")
	controller.advance(0.181)
	var settled: Dictionary = controller.frame()
	check(not settled.busy and board.accent > 0.0,
		"finite Bolt cue settles while the Board pulse is still pending")
	board.set_presentation(settled)
	var rig = make_rig(t.before.enemies)
	rig.present(compose(Presenter.new(), t.after, settled), Rect2(0, 0, 1000, 500))
	check(not rig._bodies["A"].visible, "settled Director hides the defeated source")
	check(not board.standee_layout().any(func(row): return row.actor == "A"),
		"same settled update removes the defeated Board standee despite a pending pulse")
	rig.free()
	board.free()

	# A player step has no finite Director cue. Its ordinary Board pulse must
	# still interpolate the player rather than jumping to the final cell.
	var before := F.state()
	var after := before.duplicate(true)
	after.player.pos = [3, 3]
	after.events = [{"type": "move", "actor": "player", "from": [2, 3], "to": [3, 3]}]
	controller.reset(before, 4)
	controller.observe(before, {"type": "move", "to": [3, 3]}, after, 4)
	check(not controller.frame().busy, "ordinary player step has no finite cue")
	board = Board.new()
	board.set_view(after, {}, [], [], "")
	board.accent = 0.56
	board.show_transition(before)
	board.set_presentation(controller.frame())
	var player_grid := Vector2.ZERO
	for actor in board._visual_actors():
		if actor.actor == "player": player_grid = actor.grid
	check(player_grid.x > 2.5 and player_grid.x < 3.5 and is_equal_approx(player_grid.y, 3.5),
		"no-finite-cue step retains pulse interpolation between the two cells")
	board.accent = 0.0
	board.set_presentation(controller.frame())
	for actor in board._visual_actors():
		if actor.actor == "player": player_grid = actor.grid
	check(player_grid == Vector2(3.5, 3.5), "step pulse settles at the committed cell")
	board.free()

func _run() -> void:
	test_inspection_arming_and_detachment()
	test_attack_handoff_and_other_attack()
	test_reusable_shine_and_loss()
	test_movement_is_not_a_fresh_attack()
	test_switcher_identity_locked_target_and_atomic_event_segment()
	test_switcher_shine_owner_and_source_loss()
	test_named_swap_resolve_caption()
	test_definition_shine_source_loss_timeline()
	test_capture_before_later_source_death()
	test_settled_cue_with_pending_board_pulse()
	print("Two-source presentation: %d checks, %d failures. Controlled facts, not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
