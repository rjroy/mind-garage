extends SceneTree
## Actual rendering decisions: exact model footprints, event ownership and endpoints.
const Encounter = preload("res://model/encounter.gd")
const Shadow = preload("res://ui/shadow_presentation.gd")
const F = preload("res://tests/shadow_fixtures.gd")
const Mixed = preload("res://tests/shadow_rendering_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const Renderer = preload("res://ui/shadow_renderer.gd")
const Board = preload("res://ui/board.gd")

class ArrowProbe extends "res://ui/board.gd":
	var arrows: Array = []
	var tiles: Array = []
	func _arrow(from: Vector2, to: Vector2, _color: Color, _dashed: bool) -> void:
		arrows.append({"from": from, "to": to})
	func _tile(cell: Array, _inset: float, _color: Color, _filled: bool = false, _width: float = 1.0) -> void:
		tiles.append(cell.duplicate())

class EnemyOwnershipProbe extends "res://ui/board.gd":
	# Observe the actual _draw -> _draw_enemy join during a normal Canvas draw.
	# Keep the production enemy drawing, including its independent inspection
	# emphasis, rather than calculating a second outline-selection rule.
	var ownership_inputs: Dictionary = {}
	var inspection_inputs: Dictionary = {}

	func _draw() -> void:
		ownership_inputs.clear()
		inspection_inputs.clear()
		super._draw()

	func _draw_enemy(enemy: Dictionary, stored: Dictionary) -> void:
		ownership_inputs[enemy.id] = stored.duplicate(true)
		inspection_inputs[enemy.id] = source
		super._draw_enemy(enemy, stored)

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func commit(model, p, command: Dictionary) -> Dictionary:
	var before: Dictionary = model.snapshot()
	var assessment: Dictionary = model.assess(command)
	check(assessment.get("legal", false), "controlled command is legal: " + str(command))
	if not assessment.get("legal", false): return {}
	check(model.act(command), "assessed command commits")
	var after: Dictionary = model.snapshot()
	check(after == assessment.get("preview", {}), "real commitment matches exact assessed preview")
	check(p.observe(before, command, after, 1), "shared controller accepts committed events")
	return after

func expected_from_events(events: Array) -> Array:
	var rows: Array = []
	var stage := "enemy"
	for event in events:
		if event.type == "shine": stage = "shine"
		if event.type in ["ray", "area"]:
			rows.append({"type": event.type, "actor": event.actor,
				"stage": stage if event.actor == "player" else "enemy", "cells": event.cells.duplicate(true)})
	return rows

func drawn(board, label: String) -> Array:
	var rows: Array = board.effect_footprints()
	for row in rows:
		check(row.get("cells") is Array and row.get("type", "") in ["ray", "area"]
			and row.get("stage", "") in ["shine", "enemy"] and row.get("actor") is String,
			label + ": footprint draw input retains actor/type/stage/cells")
	return rows

func collect_feedback(p, after: Dictionary, expected: Array, label: String) -> void:
	var board := Board.new()
	board.set_view(after, {}, [], [], "")
	board.last_events = after.events.duplicate(true)
	board.accent = 1.0
	var observed: Array = []
	var previous: Array = []
	var captured := false
	for step in range(14400):
		var frame: Dictionary = p.frame()
		board.set_presentation(frame)
		var rows := drawn(board, label)
		if step == 0 or rows != previous:
			check(rows.size() <= 1, label + ": queued later attacks never draw as an aggregate")
			if not rows.is_empty():
				var index := observed.size()
				check(index < expected.size() and rows[0] == expected[index], label + ": next draw stage matches exact event order")
				observed.append(rows[0].duplicate(true))
				var original := rows.duplicate(true)
				rows[0].cells.append([99, 99])
				check(board.effect_footprints() == original, "footprint readback is deeply detached")
				rows = original
		previous = rows.duplicate(true)
		if frame.get("cue", {}).get("type", "") == "capture" and not captured:
			captured = true
			check(observed.size() == 1 and rows.is_empty(), "full first strike completes before transfer; later attack still waits")
		if step == 0:
			board.clear_pulse()
			check(board.last_events.is_empty() and board.accent == 0.0, "legacy pulse can expire independently of finite feedback")
		if not frame.busy: break
		p.advance(1.0 / 240.0)
	check(not p.frame().busy and observed == expected, label + ": every model ray/area receives its own complete finite stage")
	if after.events.any(func(event): return event.type == "capture"):
		check(captured, "actual acquisition receives a distinct post-hit handoff")
	check(drawn(board, "settled").is_empty(), "finite completion leaves no stale tactical effect")
	var saved := after.duplicate(true)
	board.set_view(after, after, [], [], "")
	check(drawn(board, "preview") == expected and after == saved, "exact preview retains all ordered events without mutation")
	board.free()

func test_attack_capture_and_later_loss() -> void:
	var t := F.armed_hit()
	# Later death must not collapse the first complete damaging shove gesture.
	t.after.status = "lost"
	t.after.player.hp = 0
	t.before.enemies[1].ability.damage = 19
	t.after.enemies[1].ability.damage = 19
	t.after.events[5] = {"type": "damage", "actor": "player", "amount": 19, "hp": 0}
	t.after.events.append_array([{"type": "death", "actor": "player"}, {"type": "loss"}])
	var p := Shadow.new()
	p.reset(t.before, 1)
	p.observe(t.before, t.command, t.after, 1)
	var cue: Dictionary = p.frame().get("cue", {})
	var renderer := Renderer.new()
	var saved := t.duplicate(true)
	check(cue.get("type", "") == "resolve" and renderer.gesture_endpoint(t.after, cue) == t.after.events[0].cells.back(),
		"later lethal attack cannot truncate an earlier normal shove before its complete damage/displacement")
	check(t == saved, "gesture query never mutates authoritative cue ownership")
	collect_feedback(p, t.after, expected_from_events(t.after.events), "normal strike -> acquisition -> later attack")

func test_mixed_enemy_resolution() -> void:
	for order in [["bolt", "shove", "burst"], ["burst", "shove", "bolt"]]:
		var model = Encounter.new()
		model.configure(Mixed.mixed_resolution(order), "R2")
		var p := Shadow.new()
		p.reset(model.snapshot(), 1)
		var after := commit(model, p, {"type": "end_turn"})
		if after.is_empty(): continue
		var expected := expected_from_events(after.events)
		var actors: Array = []
		for row in expected: actors.append(row.actor)
		check(actors == order and expected.any(func(row): return row.type == "area"),
			"test-owned mixed geometry exercises each source, including burst area")
		collect_feedback(p, after, expected, "mixed " + str(order))
		check(model.snapshot() == after, "rendering clock cannot advance combat")

func actor_grid(board, id: String) -> Vector2:
	for row in board._visual_actors():
		if row.actor == id: return row.grid - Vector2(0.5, 0.5)
	return Vector2(INF, INF)

func test_moves_do_not_leak_into_ability_motion() -> void:
	var t := MovementFixture.movement_transition()
	var p := Shadow.new()
	p.reset(t.before, 51)
	p.observe(t.before, {"type": "end_turn"}, t.after, 51)
	var board := Board.new()
	board.size = Vector2(1024, 650)
	board.theatre_mode = true
	board.set_view(t.after, {}, [], [], "")
	board.show_transition(t.before)
	var seen: Array = []
	var sliding: Array = []
	for _step in range(14400):
		var frame: Dictionary = p.frame()
		board.set_presentation(frame)
		if not frame.busy: break
		var cue: Dictionary = frame.cue
		var index: int = cue.get("event_index", -1)
		if index not in seen:
			seen.append(index)
			check(board.announcement_marks().is_empty() and board.announcement_waves().is_empty(), "fresh warnings wait for old effects/slides")
		var a := actor_grid(board, "A")
		var b := actor_grid(board, "B")
		if index in [0, 3]:
			check(a == Vector2(3, 1) and is_equal_approx(b.x, 3.0), "voluntary moves cannot run inside preceding ability feedback")
		if cue.get("type", "") == "move":
			check(drawn(board, "slide").is_empty(), "voluntary slide does not invent a hit footprint")
			if cue.progress > 0.25 and cue.progress < 0.75:
				var id: String = cue.get("actor", "")
				if id not in sliding:
					sliding.append(id)
					if id == "A":
						check(a.x > 2.0 and a.x < 3.0 and is_equal_approx(a.y, 1.0) and b == Vector2(3, 3), "A slides while B waits after displacement")
					else:
						check(a == Vector2(2, 1) and b.x > 2.0 and b.x < 3.0 and is_equal_approx(b.y, 3.0), "B slides after A reaches its committed cell")
		p.advance(1.0 / 120.0)
	check(seen == [0, 3, 5, 6] and sliding == ["A", "B"], "both actual finite slides exercised")
	board.set_presentation(p.frame())
	check(actor_grid(board, "A") == Vector2(2, 1) and actor_grid(board, "B") == Vector2(2, 3), "settled actors match authoritative cells")
	check(board.announcement_marks().size() == 1, "settled board exposes actual fresh shove announcement")
	board.free()

func assert_shine_arrow(probe: ArrowProbe, row: Dictionary, origin: Array, target: Array, active: bool, label: String) -> void:
	probe.arrows.clear()
	probe.tiles.clear()
	var saved := row.duplicate(true)
	probe._draw_effect_footprint(row, active)
	check(probe.tiles == row.cells and row == saved, label + ": all exact cells are tiled without mutating footprint")
	check(probe.arrows.size() == 1, label + ": real drawing emits one Shine direction arrow")
	if probe.arrows.size() != 1: return
	var from: Vector2 = probe.cell_center(origin)
	var to: Vector2 = probe.cell_center(target)
	check(Rect2(Vector2.ZERO, probe.size).has_point(from) and Rect2(Vector2.ZERO, probe.size).has_point(to), "projected endpoints lie inside local board bounds")
	check(probe.arrows[0].from.distance_to(from) < 0.001 and probe.arrows[0].to.distance_to(to) < 0.001,
		label + ": G1 uses selected Shine target, never the off-center wide footprint tail")
	check(probe._from_pixel(probe.arrows[0].to) == target, "drawn endpoint maps back to exact chosen grid cell")

func test_shine_arrow_owns_target_not_last_wide_cell() -> void:
	for scenario in [
		{"width": 3, "target": [2, 3], "walls": [], "cells": [[1, 3], [2, 3], [3, 3]]},
		{"width": 3, "target": [2, 2], "walls": [], "cells": [[1, 3], [2, 3], [3, 3], [1, 2], [2, 2], [3, 2]]},
		{"width": 3, "target": [2, 2], "walls": [[1, 3]], "cells": [[2, 3], [3, 3], [2, 2], [3, 2]]},
		{"width": 1, "target": [2, 2], "walls": [], "cells": [[2, 3], [2, 2]]},
	]:
		var fixture := MovementFixture.wide_capture()
		fixture.player.pos = [2, 5]
		# Align the incoming hit with its source: radial push ties would push
		# sideways. Width still controls the outgoing Shine's lateral lanes.
		fixture.enemies[1].pos = [2, 6]
		fixture.enemies[1].ability.width = scenario.width
		fixture.walls = scenario.walls.duplicate(true)
		var model = Encounter.new()
		model.configure(fixture, "R2")
		var initial: Dictionary = model.snapshot()
		var p := Shadow.new()
		p.reset(initial, 1)
		if commit(model, p, {"type": "capture"}).is_empty(): continue
		p.advance(60.0)
		var armed: Dictionary = model.snapshot()
		var incoming: Array = []
		for intent in armed.intentions:
			if intent.source == "B": incoming = intent.cells
		check(armed.enemies[1].pos == [2, 6] and armed.enemies[1].dir == [0, -1]
			and armed.intentions == initial.intentions and armed.player.pos in incoming,
			"arming preserves B's locked upward announcement before the real acquisition hit")
		if commit(model, p, {"type": "end_turn"}).is_empty(): continue
		p.advance(60.0)
		var before: Dictionary = model.snapshot()
		var damage_index := -1
		var push_index := -1
		var capture_index := -1
		for i in range(before.events.size()):
			var event: Dictionary = before.events[i]
			if event.type == "damage" and event.actor == "player" and event.amount == fixture.enemies[1].ability.damage:
				damage_index = i
			if event.type == "displace" and event.actor == "player" and event.from == [2, 5] and event.to == [2, 4]:
				push_index = i
			if event.type == "capture" and event.source == "B": capture_index = i
		var acquired_at_origin: bool = before.player.pos == [2, 4] and before.stored.get("source", "") == "B"
		if not acquired_at_origin or damage_index < 0 or push_index <= damage_index or capture_index <= push_index:
			print("DIAG Shine acquisition: ", {"width": scenario.width, "target": scenario.target, "walls": scenario.walls,
				"initial_player": initial.player.pos, "locked_source": armed.enemies[1],
				"announced_cells": incoming, "actual_player": before.player, "held": before.stored,
				"events": before.events})
		check(acquired_at_origin,
			"real damaging acquisition leaves the controlled Shine origin at [2,4]")
		check(damage_index >= 0 and push_index > damage_index and capture_index > push_index
			and before.player.hp == initial.player.hp - fixture.enemies[1].ability.damage,
			"full actual B damage then upward push precede acquisition without bypassing the hit")
		var command := {"type": "shine", "target": scenario.target}
		var assessment: Dictionary = model.assess(command)
		check(assessment.get("legal", false) and model.snapshot() == before, "near/full/clipped Shine preview legal and nonmutating")
		if not assessment.get("legal", false): continue
		var after := commit(model, p, command)
		if after.is_empty(): continue
		var cells: Array = []
		for event in after.events:
			if event.type == "ray" and event.actor == "player": cells = event.cells
		check(cells == scenario.cells, "exact near/full/clipped/narrow model geometry preserved")
		if scenario.width == 3: check(cells.back() != scenario.target, "wide fixture genuinely separates lateral tail from target")
		var frame: Dictionary = p.frame()
		check(frame.get("cue", {}).get("type", "") == "shine"
			and frame.cue.get("from", []) == before.player.pos and frame.cue.get("to", []) == scenario.target,
			"finite Shine owns authoritative origin and selected endpoint")
		for extent in [Vector2(1008, 514), Vector2(1584, 694)]:
			var probe := ArrowProbe.new()
			probe.size = extent
			probe.set_view(before, assessment.preview, [], scenario.target, "")
			var rows := drawn(probe, "preview")
			check(rows.size() == 1 and rows[0].cells == cells, "preview draw receives exact wide cells")
			if rows.size() == 1: assert_shine_arrow(probe, rows[0], before.player.pos, scenario.target, false, "preview")
			probe.set_view(after, {}, [], [], "")
			probe.set_presentation(frame)
			rows = drawn(probe, "finite")
			check(rows.size() == 1 and rows[0].cells == cells and probe.selected.is_empty(), "finite draw retains footprint after command selection clears")
			if rows.size() == 1: assert_shine_arrow(probe, rows[0], before.player.pos, scenario.target, true, "finite")
			check(model.snapshot() == after, "draw commands never mutate real state")
			probe.free()

func check_enemy_draw_ownership(probe: EnemyOwnershipProbe, p, state: Dictionary, expected_source: String, inspected: String, label: String) -> void:
	var saved := state.duplicate(true)
	var frame: Dictionary = p.frame()
	check(frame.get("held", {}).get("source", "") == expected_source, label + ": shared timeline has the controlled boundary ownership")
	probe.set_view(state, {}, [], [], inspected)
	probe.set_presentation(frame)
	probe.queue_redraw()
	# Normal SceneTree draw dispatch, not manual _draw outside a Canvas callback.
	await process_frame
	await process_frame
	check(not probe.theatre_mode and probe.standee_layout().is_empty(),
		"C2 exercises the supported escape-profile enemy drawing, not standees or theatre")
	check(probe.ownership_inputs.size() == state.enemies.size(),
		label + ": inherited board drawing actually visits every current enemy")
	for enemy in state.enemies:
		check(probe.ownership_inputs.get(enemy.id, {"missing": true}) == frame.held,
			label + ": actual enemy outline consumer receives this boundary's held dictionary, not final storage")
		check(probe.inspection_inputs.get(enemy.id, "") == inspected and probe.source == inspected,
			label + ": independent inspected-source emphasis survives without becoming held ownership")
	check(state == saved and p.frame() == frame, label + ": drawing and SceneTree frames cannot mutate combat or advance the controller")

func test_enemy_outline_uses_event_boundary_ownership() -> void:
	var probe := EnemyOwnershipProbe.new()
	probe.size = Vector2(1008, 514)
	root.add_child(probe)
	var initial := F.state()
	var armed := initial.duplicate(true)
	armed.capture_armed = true
	armed.action_points = 2
	armed.events = [{"type": "capture_armed"}]
	var p := Shadow.new()
	p.reset(initial, 1)
	check(p.observe(initial, {"type": "capture"}, armed, 1), "C2 controlled targetless arm transition accepted")
	await check_enemy_draw_ownership(probe, p, armed, "", "B", "arm only")
	for replacement in [false, true]:
		var t := F.armed_hit(replacement)
		var saved := t.duplicate(true)
		p.reset(t.before, 2 if replacement else 1)
		check(p.observe(t.before, t.command, t.after, 2 if replacement else 1),
			"C2 complete ordinary hit -> acquisition -> independent later attack accepted")
		check(t.after.events[1].type == "damage" and t.after.events[2].type == "displace"
			and t.after.events[3].type == "capture" and t.after.stored.source == "A",
			"C2 fixture owns acquisition only AFTER full first-strike damage and push")
		var seen: Array = []
		for _step in range(14400):
			var frame: Dictionary = p.frame()
			if not frame.busy: break
			var index: int = frame.cue.event_index
			if index not in seen:
				seen.append(index)
				if index == 0:
					await check_enemy_draw_ownership(probe, p, t.after, "B" if replacement else "", "A", "before damaging strike completes")
				elif index == 3:
					await check_enemy_draw_ownership(probe, p, t.after, "", "B", "actual transfer")
				elif index == 4:
					await check_enemy_draw_ownership(probe, p, t.after, "A", "B", "after handoff during other attack")
			p.advance(1.0 / 240.0)
		check(seen == [0, 3, 4] and not p.frame().busy, "C2 visits every finite boundary on the existing controller clock")
		await check_enemy_draw_ownership(probe, p, t.after, "A", "B", "settled held ability")
		check(t == saved, "C2 ownership rendering leaves both supplied snapshots and all events unchanged")
	var lost := F.shine_transition("shove", true)
	p.reset(lost.before, 3)
	check(p.observe(lost.before, lost.command, lost.after, 3), "C2 source-killing Shine transition accepted")
	p.advance(60.0)
	await check_enemy_draw_ownership(probe, p, lost.after, "", "B", "settled source loss")
	probe.queue_free()
	await process_frame

func _run() -> void:
	test_attack_capture_and_later_loss()
	test_mixed_enemy_resolution()
	test_moves_do_not_leak_into_ability_motion()
	test_shine_arrow_owns_target_not_last_wide_cell()
	await test_enemy_outline_uses_event_boundary_ownership()
	print("Shadow rendering: %d checks, %d failures. Drawing decisions only, not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
