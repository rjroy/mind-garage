extends SceneTree
## Actual rendering decisions: exact model footprints, event ownership and endpoints.
const Encounter = preload("res://model/encounter.gd")
const Shadow = preload("res://ui/shadow_presentation.gd")
const F = preload("res://tests/shadow_fixtures.gd")
const Mixed = preload("res://tests/shadow_rendering_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const Board = preload("res://ui/board.gd")

class ArrowProbe extends "res://ui/board.gd":
	var arrows: Array = []
	var tiles: Array = []
	func _arrow(from: Vector2, to: Vector2, _color: Color) -> void:
		arrows.append({"from": from, "to": to})
	func _tile(cell: Array, _inset: float, _color: Color, _filled: bool = false, _width: float = 1.0) -> void:
		tiles.append(cell.duplicate())

class PreviewDispatchProbe extends "res://ui/board.gd":
	# Record the real Canvas _draw consumer, not just effect_footprints() or a
	# direct helper call. Keep normal drawing and the authoritative link inputs.
	var dispatched: Array = []
	var finite_flags: Array = []
	var links: Array = []
	var draw_count := 0

	func _draw() -> void:
		draw_count += 1
		dispatched.clear()
		finite_flags.clear()
		links.clear()
		super._draw()

	func _draw_effect_footprint(footprint: Dictionary, active_shadow: bool = false) -> void:
		dispatched.append(footprint.duplicate(true))
		finite_flags.append(active_shadow)
		super._draw_effect_footprint(footprint, active_shadow)

	func _draw_exchange_link(origin: Array, target: Array, phase: float, color: Color) -> void:
		links.append({"from": origin.duplicate(), "target": target.duplicate()})
		super._draw_exchange_link(origin, target, phase, color)

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
		if event.type in ["ray", "area", "mask"]:
			rows.append({"type": event.type, "actor": event.actor,
				"stage": stage if event.actor == "player" else "enemy", "cells": event.cells.duplicate(true)})
	return rows

func drawn(board, label: String) -> Array:
	var rows: Array = board.effect_footprints()
	for row in rows:
		check(row.get("cells") is Array and row.get("type", "") in ["ray", "area", "mask"]
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
	var saved := t.duplicate(true)
	check(cue.get("type", "") == "resolve" and cue.get("cells", []) == t.after.events[0].cells,
		"later lethal attack cannot truncate the earlier shove's event-owned footprint")
	check(t == saved, "cue inspection never mutates authoritative ownership")
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

func test_explicit_swap_masks_not_rays_or_exchange_derived_fills() -> void:
	for t in [F.swap_hit(), F.swap_hit(true), F.swap_miss(), F.swap_miss(true), F.swap_shine(), F.swap_shine(true), F.swap_other_occupant()]:
		var p := Shadow.new()
		p.reset(t.before, 1)
		check(p.observe(t.before, t.command, t.after, 1), "explicit mask transition accepted")
		var expected := expected_from_events(t.after.events)
		check(expected[0].type == "mask" and expected[0].cells == t.after.events[1 if t.command.type == "shine" else 0].cells,
			"expected draw coverage comes ONLY from the real mask event, including misses and invalid empty masks")
		collect_feedback(p, t.after, expected, "Switcher mask-owned feedback")
		var probe := ArrowProbe.new()
		probe.size = Vector2(1008, 514)
		probe.set_view(t.before, t.after, [], t.command.get("target", []), "")
		var rows := drawn(probe, "Swap exact preview")
		check(rows == expected, "preview uses exact mask cells, not the source tile or a line between exchange endpoints")
		if not rows.is_empty() and rows[0].type == "mask":
			probe._draw_effect_footprint(rows[0])
			check(probe.tiles == rows[0].cells and probe.arrows.is_empty(),
				"actual targeted-mask drawing fills only its real victim cell and never draws a generic shove ray arrow")
		probe.free()

func swap_board():
	var board := Board.new()
	board.size = Vector2(1008, 514)
	var image := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var textures := {}
	var assembly := {}
	for id in ["player", "A", "B"]:
		textures[id] = texture
		assembly[id] = {"canvas": Vector2(8, 12), "foot": Vector2(4, 11), "height_fraction": 0.31}
	check(board.configure_standees(textures, assembly), "controlled standee geometry configures for atomic exchange")
	return board

func test_atomic_exchange_positions_depth_and_source_killing_shine() -> void:
	for t in [F.swap_hit(), F.swap_shine(), F.swap_shine(true), F.swap_other_occupant()]:
		var saved: Dictionary = t.duplicate(true)
		var exchange: Dictionary = {}
		for event in t.after.events:
			if event.type == "swap": exchange = event
		check(not exchange.is_empty(), "controlled exchange fixture supplies one actual atomic swap event")
		if exchange.is_empty(): continue
		var p := Shadow.new()
		p.reset(t.before, 1)
		p.observe(t.before, t.command, t.after, 1)
		var board = swap_board()
		board.set_view(t.after, {}, [], [], "")
		board.show_transition(t.before)
		var from := Vector2(exchange.from[0], exchange.from[1])
		var to := Vector2(exchange.to[0], exchange.to[1])
		var delta := to - from
		var saw_mid := false
		for _step in range(14400):
			var frame: Dictionary = p.frame()
			board.set_presentation(frame)
			if not frame.busy: break
			if frame.cue.get("kind", "") == "swap" and frame.cue.get("type", "") in ["resolve", "shine"]:
				var actor := actor_grid(board, exchange.actor)
				var other := actor_grid(board, exchange.other)
				var actor_progress := (actor - from).dot(delta) / delta.length_squared()
				if not other.is_finite():
					check(actor_progress >= 0.999, "defeated source disappears only AFTER the player's complete exchange, never as a moving corpse")
				else:
					var other_progress := (other - to).dot(-delta) / delta.length_squared()
					check(is_equal_approx(actor_progress, other_progress), "both participants share one atomic exchange progress, not two sequential moves")
					if actor_progress > 0.05 and actor_progress < 0.95:
						saw_mid = true
						var rows: Array = board.standee_layout()
						for i in range(1, rows.size()):
							check(rows[i - 1].foot.y <= rows[i].foot.y, "exchanging standees depth-sort from actual projected moving feet")
						for row in rows:
							var actual := actor_grid(board, row.actor) + Vector2(0.5, 0.5)
							check(row.foot.distance_to(board._ensure_projection().project(actual)) < 0.01,
								"body and source marker follow the common homography throughout exchange")
			p.advance(1.0 / 120.0)
		check(saw_mid, "actual board consumer exposes continuous paired exchange inside the owning finite ability")
		board.set_presentation(p.frame())
		check(actor_grid(board, "player") == Vector2(t.after.player.pos[0], t.after.player.pos[1]),
			"player keeps the exact final relocation even when Shine kills its source")
		if t.command.type == "shine" and t.after.stored.is_empty():
			check(board.standee_layout().size() == 1, "source death clears only the source actor after full exchange")
		for row in board.standee_layout():
			check(board._from_pixel(row.foot) == row.cell and board.pick_cell(row.tab_rect.get_center()) == row.cell,
				"settled exchanged feet and marker picking use authoritative destination cells")
		check(t == saved, "paired animation/depth/picking never mutates snapshots, HP, stored power or raw events")
		board.free()

func empty_mask_before_ray_preview() -> Dictionary:
	# Real commands create a self-target invalidated by the player's retained
	# Swap Shine. The wall only blocks B's ordinary push on the first End turn,
	# keeping the acquired source in legal cardinal range for that Shine.
	var data := MovementFixture.switcher(true)
	data.walls = [[1, 1]]
	var model = Encounter.new()
	model.configure(data, "R2")
	for command in [{"type": "capture"}, {"type": "end_turn"}, {"type": "shine", "target": [2, 3]}]:
		var assessment: Dictionary = model.assess(command)
		check(assessment.get("legal", false), "SW-C01 real empty-mask preparation is legal: " + str(command))
		if not assessment.get("legal", false): return {}
		check(model.act(command) and model.snapshot() == assessment.preview,
			"SW-C01 real preparation commits exactly the model preview without bypassing acquisition")
	var before: Dictionary = model.snapshot()
	var assessment: Dictionary = model.assess({"type": "end_turn"})
	check(assessment.get("legal", false) and model.snapshot() == before, "SW-C01 mixed empty-mask preview is legal and nonmutating")
	if not assessment.get("legal", false): return {}
	var after: Dictionary = assessment.preview
	check(after.events.size() >= 2 and after.events[0].type == "mask" and after.events[0].cells.is_empty()
		and after.events[1].type == "ray" and after.events[1].actor == "B",
		"SW-C01 actual producer emits an honest empty A mask BEFORE B's separate ray")
	return {"before": before, "after": after, "command": {"type": "end_turn"}}

func test_actual_preview_draw_dispatches_mask_and_later_ray() -> void:
	var cases: Array = [F.swap_shine(), F.swap_hit(true)]
	var empty_case := empty_mask_before_ray_preview()
	if not empty_case.is_empty(): cases.append(empty_case)
	var probe := PreviewDispatchProbe.new()
	probe.size = Vector2(1008, 514)
	root.add_child(probe)
	var saw_announcement := false
	var saw_empty_mask := false
	for t in cases:
		var saved: Dictionary = t.duplicate(true)
		var expected := expected_from_events(t.after.events)
		var expected_links: Array = []
		var expected_announcements: Array = []
		for intent in t.before.intentions:
			if intent.kind == "swap" and not intent.cells.is_empty():
				expected_announcements.append({"from": intent.from.duplicate(), "target": intent.target.duplicate()})
		for event in t.after.events:
			if event.type == "mask":
				if event.cells.is_empty():
					saw_empty_mask = true
				else:
					expected_links.append({"from": event.from.duplicate(), "target": event.target.duplicate()})
		var p := Shadow.new()
		p.reset(t.before, 1)
		var frame: Dictionary = p.frame()
		probe.bind_composition(t.before.enemies)
		probe.last_events = []
		probe.set_view(t.before, {}, [], [], "")
		probe.set_presentation(frame)
		var count := probe.draw_count
		probe.queue_redraw()
		await process_frame
		await process_frame
		check(probe.draw_count > count, "SW-C01 no-preview Stage announcement draw executed")
		check(probe.links.size() == expected_announcements.size() and probe.links == expected_announcements,
			"SW-C01 no-preview draw emits exactly the ordered live swap announcement endpoints")
		saw_announcement = saw_announcement or not expected_announcements.is_empty()
		var baseline: Array = probe.links.duplicate(true)
		probe.set_view(t.before, t.after, [], t.command.get("target", []), "")
		probe.set_presentation(frame)
		count = probe.draw_count
		probe.queue_redraw()
		await process_frame
		await process_frame
		check(probe.draw_count > count, "SW-C01 actual inherited Canvas preview draw executed")
		check(not probe._uses_shadow_effects() and not probe.finite_flags.has(true),
			"SW-C01 exercises preview dispatch, not the already-working finite-shadow path")
		check(probe.effect_footprints() == expected, "SW-C01 authoritative footprint projection still contains every exact mask/ray")
		check(probe.dispatched.size() == expected.size(),
			"SW-C01 actual preview drawing dispatches EVERY mask and ray, including empty mask rows")
		check(probe.dispatched == expected,
			"SW-C01 actual helper dispatch preserves exact source/type/stage/cells and order; B never consumes A's mask index")
		var all_links: Array = baseline + expected_links
		check(probe.links.size() == all_links.size() and probe.links == all_links,
			"SW-C01 preview preserves ordered announcement links and adds exactly the nonempty mask endpoints")
		if expected.size() == 2:
			check(expected[0].actor == "A" and expected[0].type == "mask"
				and expected[1].actor == "B" and expected[1].type == "ray" and expected[0].cells != expected[1].cells,
				"SW-C01 mixed fixture genuinely distinguishes both owners and their logical coverage")
		check(t == saved and p.frame() == frame, "SW-C01 real preview drawing preserves snapshots, event payloads and the shared clock")
	check(saw_announcement, "SW-C01 fixtures exercise a real live swap announcement")
	check(saw_empty_mask, "SW-C01 fixtures exercise an empty preview mask")
	probe.queue_free()
	await process_frame

func _run() -> void:
	test_attack_capture_and_later_loss()
	test_mixed_enemy_resolution()
	test_moves_do_not_leak_into_ability_motion()
	test_shine_arrow_owns_target_not_last_wide_cell()
	test_explicit_swap_masks_not_rays_or_exchange_derived_fills()
	test_atomic_exchange_positions_depth_and_source_killing_shine()
	await test_actual_preview_draw_dispatches_mask_and_later_ray()
	print("Shadow rendering: %d checks, %d failures. Drawing decisions only, not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
