extends SceneTree
## Source facts and exact logical overlay regions, not glow/style pixel budgets.
## Synthetic snapshots deliberately differ from live content. No asset loading.

const BOARD := "res://ui/board.gd"
const Regions = preload("res://ui/telegraph_regions.gd")
const Overlay = preload("res://ui/wavefront_overlay.gd")
const ShadowPresentation = preload("res://ui/shadow_presentation.gd")
var board_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ", label)

func setup() -> bool:
	board_script = load(BOARD)
	if board_script == null or not board_script.can_instantiate():
		printerr("SETUP REQUIRED: loadable board; not behavioral RED")
		return false
	var board = board_script.new()
	var required := {"announcement_marks": 0, "announcement_regions": 0, "announcement_waves": 0}
	for name in required:
		var found := false
		for method in board.get_method_list():
			if method.name == name and method.args.size() == required[name]: found = true
		if not found:
			printerr("SETUP REQUIRED: board.", name, "; see angled-wavefront-slice-contract.md")
			board.free()
			return false
	board.free()
	var overlay = Overlay.new()
	var wave_seam := false
	for method in overlay.get_method_list():
		if method.name == "wave_geometry" and method.args.size() == 2: wave_seam = true
	if not wave_seam:
		printerr("SETUP REQUIRED: Overlay.wave_geometry(region, phase); not behavioral RED")
		return false
	var neutral: Dictionary = Overlay.wave_geometry({}, 0.0)
	if not neutral.get("fills") is Array or not neutral.get("fronts") is Array:
		printerr("SETUP REQUIRED: wave geometry has loadable fills/fronts arrays; not behavioral RED")
		return false
	return true

func snapshot() -> Dictionary:
	# Explicit footprints are intentionally truncated independently of range.
	# This catches a renderer that invents geometry rather than copying cells.
	return {
		"turn": 7, "width": 8, "height": 6, "walls": [[3, 5]],
		"player": {"pos": [3, 2], "hp": 29}, "exit": {"pos": [7, 5], "opens": 19},
		"enemies": [
			{"id": "B", "pos": [3, 4], "dir": [0, -1], "hp": 13, "kind": "shove"},
			{"id": "A", "pos": [3, 1], "dir": [0, 1], "hp": 17, "kind": "shove"},
		],
		"intentions": [
			{"source": "B", "kind": "shove", "cells": [[3, 3], [3, 2]]},
			{"source": "A", "kind": "shove", "cells": [[3, 2], [3, 3], [3, 4]]},
		],
		"stored": {}, "backlash_footprint": {},
	}

func make_board():
	var board = board_script.new()
	# Outside the tree: no stage textures, rig or mutable production assembly.
	board.size = Vector2(1008, 514)
	board.set_stage_mode(true)
	board.theatre_mode = true
	board.set_view(snapshot(), {}, [], [], "")
	return board

func mark(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if row.get("source", "") == id: return row
	return {}

func test_region_projection_and_preservation() -> void:
	var board = make_board()
	board.cursor = [6, 2]
	board.hover_cell = [5, 2]
	board._focused_actor = "A"
	board._hover_actor = "B"
	var predicted := {"events": [{"type": "ray", "actor": "player", "cells": [[4, 2]]}],
		"player": {"pos": [3, 2]}, "enemies": []}
	board.set_view(snapshot(), predicted, [[4, 2]], [4, 2], "B")
	var before := {"state": board.state.duplicate(true), "preview": board.preview.duplicate(true),
		"candidates": board.candidates.duplicate(true), "selected": board.selected.duplicate(),
		"source": board.source, "cursor": board.cursor.duplicate(), "hover": board.hover_cell.duplicate()}
	for extent in [Vector2(1008, 514), Vector2(1584, 694)]:
		board.size = extent
		assert_regions(board)
		check(board.state == before.state and board.preview == before.preview
			and board.candidates == before.candidates and board.selected == before.selected
			and board.source == before.source and board.cursor == before.cursor and board.hover_cell == before.hover,
			"region projection/resize preserve authoritative facts, target, preview and inspection")
		check(board._focused_actor == "A" and board._hover_actor == "B", "region readback preserves rear focus and hover")
	board.set_stage_mode(false)
	check(board.announcement_marks().is_empty() and board.announcement_regions().is_empty(),
		"non-Stage views have no new warning descriptors or regions")
	board.set_stage_mode(true)
	board.theatre_mode = false
	check(board.announcement_marks().is_empty() and board.announcement_regions().is_empty(),
		"other Stage profiles keep the existing renderer")
	board.free()

func region_area(contours: Array) -> float:
	var area := 0.0
	for polygon in contours:
		var doubled := 0.0
		for i in range(polygon.size()): doubled += polygon[i].cross(polygon[(i + 1) % polygon.size()])
		area += absf(doubled) / 2.0
	return area

func inside(point: Vector2, contours: Array) -> bool:
	for polygon in contours:
		if Geometry2D.is_point_in_polygon(point, polygon): return true
	return false

func check_coverage(cells: Array, contours: Array, label: String) -> void:
	var unique: Array = []
	for cell in cells:
		if cell not in unique: unique.append(cell)
	check(is_equal_approx(region_area(contours), float(unique.size())), label + ": exact unit-cell union area")
	var exact := true
	for y in range(-1, 7):
		for x in range(-1, 9):
			for offset in [Vector2(0.07, 0.13), Vector2(0.51, 0.49), Vector2(0.93, 0.87)]:
				if inside(Vector2(x, y) + offset, contours) != ([x, y] in unique): exact = false
	check(exact, label + ": full-cell coverage without source, gap, hull or invented destination")

func test_cell_unions() -> void:
	for fixture in [
		{"cells": [], "components": 0},
		{"cells": [[1, 1], [1, 2], [1, 3]], "components": 1},
		{"cells": [[3, 2], [2, 2], [1, 2]], "components": 1},
		{"cells": [[0, 0], [2, 0]], "components": 2},
		{"cells": [[1, 1], [1, 1], [1, 2]], "components": 1},
	]:
		var cells: Array = fixture.cells.duplicate(true)
		var before := cells.duplicate(true)
		var contours: Array = Regions.boundaries(cells)
		check(contours.size() == fixture.components, "connected threatened cells form one broad region, disconnected runs stay separate")
		check_coverage(cells, contours, "controlled union")
		check(cells == before, "union geometry does not mutate input footprint")
		var baseline: Array = contours.duplicate(true)
		if not contours.is_empty() and contours[0].size() > 0: contours[0][0] = Vector2(999, 999)
		check(Regions.boundaries(cells) == baseline, "returned logical contours are detached and deterministic")

func assert_regions(board) -> void:
	var facts: Array = board.announcement_marks()
	var regions: Array = board.announcement_regions()
	check(regions.size() == facts.size(), "one broad overlay row per current supported source")
	for fact in facts:
		var row := mark(regions, fact.source)
		var metadata := row.duplicate(true)
		metadata.erase("contours")
		metadata.erase("projected")
		check(metadata == fact, "overlay retains exact source, occurrence, direction, origin and ordered cells")
		var contours = row.get("contours", [])
		check(contours is Array, "overlay exposes logical contours for the shared plane")
		if not contours is Array: continue
		check_coverage(fact.cells, contours, fact.source)
		var projected: Array = row.get("projected", [])
		check(projected.size() == contours.size(), "real draw polygons join every logical region to the shared plane")
		for i in range(mini(projected.size(), contours.size())):
			check(projected[i].size() == contours[i].size(), "projected boundary keeps logical contour topology")
			for j in range(mini(projected[i].size(), contours[i].size())):
				check(projected[i][j].distance_to(board._ensure_projection().project(contours[i][j])) < 0.002,
					"overlay draw vertices share the actual floor projection")
		var baseline: Array = contours.duplicate(true)
		if not contours.is_empty() and contours[0].size() > 0: contours[0][0] = Vector2(999, 999)
		if not projected.is_empty() and projected[0].size() > 0: projected[0][0] = Vector2(999, 999)
		if row.get("cells") is Array: row.cells.append([99, 99])
		if row.get("origin") is Array and row.origin.size() == 2: row.origin[0] = 99
		if row.get("direction") is Array and row.direction.size() == 2: row.direction[1] = 99
		var fresh := mark(board.announcement_regions(), fact.source)
		check(fresh.get("contours", []) == baseline, "returned logical contours cannot mutate later geometry")
		var fresh_metadata := fresh.duplicate(true)
		fresh_metadata.erase("contours")
		fresh_metadata.erase("projected")
		check(fresh_metadata == fact, "returned overlay source/cell facts are detached from model and later calls")
		if not fresh.get("projected", []).is_empty():
			check(fresh.projected[0][0] != Vector2(999, 999), "returned screen contours are detached too")

func assert_marks(board, expected: Dictionary) -> void:
	var rows: Array = board.announcement_marks()
	check(rows.size() == expected.size(), "one row per current supported announcement, no merged or duplicate threat")
	for id in expected:
		check(mark(rows, id) == expected[id], id + ": exact source, occurrence, origin, direction, cells and stable lane")
	var owners: Array = []
	for row in rows:
		if [3, 2] in row.get("cells", []): owners.append(row.source)
	owners.sort()
	var wanted: Array = []
	for id in expected:
		if [3, 2] in expected[id].cells: wanted.append(id)
	wanted.sort()
	check(owners == wanted, "shared cells retain each independent source")

func test_exact_facts_and_lanes() -> void:
	var board = make_board()
	var expected := {
		"A": {"source": "A", "turn": 7, "kind": "shove", "origin": [3, 1], "direction": [0, 1],
			"cells": [[3, 2], [3, 3], [3, 4]], "lane": 0},
		"B": {"source": "B", "turn": 7, "kind": "shove", "origin": [3, 4], "direction": [0, -1],
			"cells": [[3, 3], [3, 2]], "lane": 1},
	}
	for extent in [Vector2(1008, 514), Vector2(1584, 694)]:
		board.size = extent
		var before: Dictionary = board.state.duplicate(true)
		assert_marks(board, expected)
		assert_regions(board)
		check(board.state == before, "projection never mutates incoming model facts")
		var rows: Array = board.announcement_marks()
		if not rows.is_empty():
			rows[0].cells.append([99, 99])
			rows[0].origin[0] = 99
			rows[0].direction[1] = 99
		assert_marks(board, expected)
	var reordered := snapshot()
	reordered.enemies.reverse()
	reordered.intentions.reverse()
	board.set_view(reordered, {"events": []}, [[1, 1]], [1, 1], "A")
	assert_marks(board, expected)
	var unsupported := snapshot()
	unsupported.intentions.append({"source": "C", "kind": "shove", "cells": [[3, 2]]})
	unsupported.intentions[0].kind = "bolt"
	board.set_view(unsupported, {}, [], [], "")
	assert_marks(board, {"A": expected.A})
	var horizontal := snapshot()
	horizontal.enemies[0].pos = [5, 2]
	horizontal.enemies[0].dir = [-1, 0]
	horizontal.enemies[1].pos = [1, 2]
	horizontal.enemies[1].dir = [1, 0]
	horizontal.intentions[0].cells = [[4, 2], [3, 2]]
	horizontal.intentions[1].cells = [[2, 2], [3, 2]]
	board.set_view(horizontal, {}, [], [], "")
	assert_marks(board, {
		"A": {"source": "A", "turn": 7, "kind": "shove", "origin": [1, 2], "direction": [1, 0],
			"cells": [[2, 2], [3, 2]], "lane": 0},
		"B": {"source": "B", "turn": 7, "kind": "shove", "origin": [5, 2], "direction": [-1, 0],
			"cells": [[4, 2], [3, 2]], "lane": 1},
	})
	var removed := snapshot()
	removed.enemies.remove_at(0)
	board.set_view(removed, {}, [], [], "")
	assert_marks(board, {"A": expected.A})
	var empty := snapshot()
	empty.intentions[0].cells = []
	board.set_view(empty, {}, [], [], "")
	var empty_expected := expected.duplicate(true)
	empty_expected.B.cells = []
	assert_marks(board, empty_expected)
	board.free()

func test_suppression_and_fresh_while_held() -> void:
	for captured in ["A", "B"]:
		var other := "B" if captured == "A" else "A"
		var board = make_board()
		var after := snapshot()
		after.intentions = after.intentions.filter(func(row): return row.source != captured)
		after.stored = {"source": captured, "captured_turn": 7, "dir": [0, 1],
			"ability": {"kind": "shove", "range": 4}}
		after.backlash_footprint = {"type": "ray", "cells": [[3, 2], [4, 2], [5, 2]]}
		board.set_view(after, {}, [], [], "")
		var rows: Array = board.announcement_marks()
		check(rows.size() == 1 and mark(rows, captured).is_empty() and not mark(rows, other).is_empty(),
			captured + ": only the captured announcement disappears; standee/storage do not invent one")
		check(mark(rows, other).get("lane", -1) == (0 if other == "A" else 1),
			"remaining source keeps its overlap ordering when the other disappears")
		assert_regions(board)
		check(board.effect_footprints().is_empty(), "held backlash is not relabeled as a committed/preview effect")
		var fresh := snapshot()
		fresh.turn = 8
		fresh.stored = after.stored.duplicate(true)
		fresh.backlash_footprint = after.backlash_footprint.duplicate(true)
		board.set_view(fresh, {}, [], [], captured)
		rows = board.announcement_marks()
		check(rows.size() == 2 and mark(rows, captured).get("turn", -1) == 8
			and board.state.stored.captured_turn == 7, "fresh current warning coexists with an older held occurrence")
		assert_regions(board)
		var marks_before: Array = rows.duplicate(true)
		var preview := {"events": [
			{"type": "release", "source": captured},
			{"type": "ray", "actor": "player", "cells": [[4, 2], [5, 2]]},
		], "player": {"pos": [3, 2]}, "enemies": []}
		board.set_view(fresh, preview, [[4, 2]], [4, 2], captured)
		check(board.announcement_marks() == marks_before, "selected prediction never suppresses or replaces current enemy warnings")
		assert_regions(board)
		check(board.effect_footprints() == [{"type": "ray", "actor": "player", "stage": "release",
			"cells": [[4, 2], [5, 2]]}], "release uses its existing exact prediction path, separate from announcement ownership")
		board.set_view({}, {}, [], [], "")
		check(board.announcement_marks().is_empty() and board.announcement_regions().is_empty(), "clearing state removes stale warning facts/regions")
		board.free()

# The user superseded the static nine-candidate/head-visibility objective:
# waves now travel from the source, below actors. Retain exact clipping and
# isolation coverage below without retaining assertions that require arrows.

func wave_fixture(direction: Vector2i = Vector2i.RIGHT, length: int = 12) -> Dictionary:
	var origin := Vector2i(3, 3)
	var cells: Array = []
	for step in range(1, length + 1):
		var cell := origin + direction * step
		cells.append([cell.x, cell.y])
	return {"source": "A", "turn": 17, "origin": [origin.x, origin.y],
		"direction": [direction.x, direction.y], "cells": cells,
		"contours": Regions.boundaries(cells), "kind": "shove", "lane": 0}

func wave(region: Dictionary, phase: float) -> Dictionary:
	var before := region.duplicate(true)
	var result: Dictionary = Overlay.wave_geometry(region, phase)
	check(region == before, "wave construction does not mutate source facts or exact union")
	check(result.get("fills") is Array and result.get("fronts") is Array,
		"wave draw inputs are full logical fill polygons and front rows")
	return result

func curve_points(front: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	for part in front.get("curves", []): points.append_array(part)
	return points

func mean(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point in points: sum += point
	return sum / maxf(1.0, points.size())

func test_wave_phase_direction_and_curvature() -> void:
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var region := wave_fixture(direction)
		var first := wave(region, 0.375)
		var next := wave(region, 0.390625)
		check(first.fills == region.contours, "fill is the entire affected-cell union, not an inset lane")
		check(not first.fronts.is_empty(), "a nonempty line has repeating curved front descriptors")
		check(first.fronts.size() == next.fronts.size(), "phase advance retains front identities across the loop")
		check(first == wave(region, 1.375), "whole cycles repeat the same logical geometry")
		var advancing := false
		var curved := false
		for i in range(mini(first.fronts.size(), next.fronts.size())):
			var a: Dictionary = first.fronts[i]
			var b: Dictionary = next.fronts[i]
			check(a.get("progress") is float and b.get("progress") is float,
				"each front exposes its normalized source-to-end progress")
			var p: float = a.get("progress", -1.0)
			check(p >= 0.0 and p < 1.0 and is_equal_approx(float(b.get("progress", -1.0)), fposmod(p + 0.015625, 1.0)),
				"front progress follows only the supplied phase, wraps and never reverses")
			check(a.get("curves") is Array, "each front exposes clipped logical polyline parts")
			var before := curve_points(a)
			var after := curve_points(b)
			if p > 0.15 and p < 0.85 and not before.is_empty() and not after.is_empty():
				var travel := mean(after) - mean(before)
				check(travel.dot(Vector2(direction)) > 0.0 and absf(travel.cross(Vector2(direction))) < 0.0001,
					"the actual front moves along the attack's grid direction, not screen-right or toward a player")
				advancing = true
			for part in a.get("curves", []):
				if part.size() < 3: continue
				var chord: Vector2 = part[-1] - part[0]
				for point in part:
					if absf(chord.cross(point - part[0])) > 0.00001: curved = true
		check(advancing, "controlled phase pair contains an actual advancing front")
		check(curved, "front geometry is curved across the lane, not a detached straight arrow")

func test_wave_exact_clipping_and_isolation() -> void:
	# Broad disjoint regions and a genuine hole across the front stress exact
	# clipping, rather than assuming all footprints are one contiguous column.
	var region := wave_fixture()
	region.cells = [[4, 2], [4, 4], [5, 2], [5, 4], [7, 2], [7, 4]]
	region.contours = Regions.boundaries(region.cells)
	var baseline := wave(region, 0.41)
	var pristine := baseline.duplicate(true)
	check_coverage(region.cells, baseline.fills, "wave wash")
	var samples := 0
	for phase in [0.11, 0.29, 0.47, 0.63, 0.89]:
		var geometry := wave(region, phase)
		check(geometry.fills == baseline.fills, "wave phase never grows/shrinks which cells will be hit")
		for front in geometry.fronts:
			for part in front.get("curves", []):
				var exact := true
				for i in range(part.size() - 1):
					for step in range(1, 10):
						if not inside(part[i].lerp(part[i + 1], float(step) / 10.0), region.contours): exact = false
						samples += 1
				check(exact, "every moving front segment stays inside the exact union, never crossing its holes/gaps")
	check(samples > 0, "controlled disjoint fixture actually exercises drawable clipped fronts")
	if not baseline.fills.is_empty(): baseline.fills[0][0] = Vector2(999, 999)
	if not baseline.fronts.is_empty():
		baseline.fronts[0]["progress"] = -999.0
		if not baseline.fronts[0].get("curves", []).is_empty():
			baseline.fronts[0].curves[0][0] = Vector2(999, 999)
	check(wave(region, 0.41) == pristine, "same input wave geometry is deterministic and detached from mutated prior output")
	check(wave(region, 0.41).fills == region.contours, "returned wave fill polygons are detached")
	check(wave(region, 0.41).fronts != baseline.fronts or baseline.fronts.is_empty(),
		"returned front phase and curves are detached")
	var empty := wave_fixture()
	empty.cells = []
	empty.contours = []
	var nothing := wave(empty, 0.4)
	check(nothing.fills.is_empty() and nothing.fronts.is_empty(), "empty affected region draws no invented source tile or front")

func test_wave_source_origin_and_translation() -> void:
	var region := wave_fixture()
	var geometry := wave(region, 0.43)
	var shift := Vector2i(9, -7)
	var moved := region.duplicate(true)
	moved.origin = [region.origin[0] + shift.x, region.origin[1] + shift.y]
	for cell in moved.cells:
		cell[0] += shift.x
		cell[1] += shift.y
	moved.contours = Regions.boundaries(moved.cells)
	var translated := wave(moved, 0.43)
	check(translated.fronts.size() == geometry.fronts.size(), "translation preserves the source's front identities")
	for i in range(mini(translated.fronts.size(), geometry.fronts.size())):
		var a := curve_points(geometry.fronts[i])
		var b := curve_points(translated.fronts[i])
		check(a.size() == b.size(), "translated source/region retain front sampling topology")
		var shifted := true
		for j in range(mini(a.size(), b.size())):
			if a[j].distance_to(b[j] - Vector2(shift)) > 0.0001: shifted = false
		check(shifted, "wave geometry translates with the actual source and footprint, not a screen anchor")
	var farther_source := region.duplicate(true)
	farther_source.origin = [0, 3]
	check(wave(farther_source, 0.43).fronts != geometry.fronts,
		"source-to-end progress begins at the actual attacker, not at an arbitrary footprint edge")

func assert_waves(board, phase: float) -> Array:
	var regions: Array = board.announcement_regions()
	var rows: Array = board.announcement_waves()
	check(rows.size() == regions.size(), "real renderer wave rows follow each current source occurrence independently")
	for region in regions:
		var row := mark(rows, region.source)
		check(not row.is_empty(), region.source + ": real wave draw row exists")
		if row.is_empty(): continue
		var metadata := row.duplicate(true)
		metadata.erase("fills")
		metadata.erase("fronts")
		check(metadata == region, "wave draw row preserves exact origin, direction, cells, turn and shared projection")
		var geometry := wave(region, phase)
		check(row.get("fills", []) == region.contours and row.get("fills", []) == geometry.fills,
			"actual full-cell wash consumes the exact logical union")
		check(row.get("fronts", []) == geometry.fronts and not row.get("fronts", []).is_empty(),
			"actual moving front draw inputs consume the existing controller loop phase")
	return rows

func test_board_wave_phase_and_ownership() -> void:
	var board = make_board()
	board.set_presentation(true, {"loop_phase": 0.31})
	var before: Dictionary = board.state.duplicate(true)
	var initial := assert_waves(board, 0.31)
	board.set_presentation(true, {"loop_phase": 0.42})
	var later := assert_waves(board, 0.42)
	check(mark(initial, "A").get("fronts", []) != mark(later, "A").get("fronts", [])
		and mark(initial, "B").get("fronts", []) != mark(later, "B").get("fronts", []),
		"both opposing sources animate from the supplied shared phase")
	check(board.state == before, "visual phase never advances combat, turn, damage or budgets")
	var away := snapshot()
	away.player.pos = [7, 0]
	var predicted := {"player": {"pos": [0, 5]}, "enemies": [], "events": []}
	board.set_view(away, predicted, [[4, 2]], [4, 2], "B")
	check(board.announcement_waves() == later, "moving player/preview/selection does not home or redirect current source waves")
	for captured in ["A", "B"]:
		var other := "B" if captured == "A" else "A"
		var held := snapshot()
		held.intentions = held.intentions.filter(func(row): return row.source != captured)
		held.stored = {"source": captured, "captured_turn": 7, "dir": [0, 1],
			"ability": {"kind": "shove", "range": 4}}
		board.set_view(held, {}, [], [], "")
		var rows := assert_waves(board, 0.42)
		check(mark(rows, captured).is_empty() and mark(rows, other) == mark(later, other),
			"capture removes only its current waves; surviving source keeps its geometry and phase")
		var fresh := snapshot()
		fresh.turn = 8
		fresh.stored = held.stored.duplicate(true)
		board.set_view(fresh, {}, [], [], "")
		rows = assert_waves(board, 0.42)
		check(mark(rows, captured).get("turn", -1) == 8 and board.state.stored.captured_turn == 7,
			"fresh waves identify the new occurrence while the older ability remains held")
		if not rows.is_empty():
			rows[0].origin[0] = 999
			rows[0].fills[0][0] = Vector2(999, 999)
			rows[0].fronts[0]["progress"] = -99.0
		check(board.announcement_waves() != rows or rows.is_empty(), "real wave draw readback is detached")
	board.set_stage_mode(false)
	check(board.announcement_waves().is_empty(), "baseline views have no invisible source-wave rows")
	board.set_stage_mode(true)
	board.theatre_mode = false
	check(board.announcement_waves().is_empty(), "original escape Stage retains its existing warning profile")
	board.free()

func wave_progress(board, frame: Dictionary) -> float:
	board.set_presentation(true, frame)
	var row := mark(board.announcement_waves(), "A")
	var fronts: Array = row.get("fronts", [])
	if fronts.is_empty():
		check(false, "controlled source A exposes a wave front")
		return -1.0
	return fronts[0].get("progress", -1.0)

func test_wave_pacing_against_director() -> void:
	var board = make_board()
	var state := snapshot()
	var controller = ShadowPresentation.new()
	controller.reset(state, 7)
	var start := controller.frame()
	var initial := wave_progress(board, start)
	# Measure the Director's period from a controlled small advance rather than
	# making its current tuning a permanent requirement of this test.
	var step := 0.125
	controller.advance(step)
	var phase_step: float = controller.frame().get("loop_phase", 0.0)
	if phase_step <= 0.0 or phase_step >= 1.0:
		check(false, "controlled advance measures the Director's positive loop rate")
		board.free()
		return
	var period := step / phase_step
	controller.advance(period * 0.99 - step)
	var before_wrap := controller.frame()
	var before_progress := wave_progress(board, before_wrap)
	controller.advance(period * 0.02)
	var after_wrap := controller.frame()
	var after_progress := wave_progress(board, after_wrap)
	check(is_equal_approx(float(before_wrap.loop_phase), 0.99)
		and is_equal_approx(float(after_wrap.loop_phase), 0.01),
		"Director retains its own wrapped period across the boundary")
	check(is_equal_approx(fposmod(after_progress - before_progress, 1.0), 0.02 / 1.5),
		"wave advances smoothly across the Director's wrap at two-thirds its rate")
	controller.advance(period * 0.49)
	var cycle_frame := controller.frame()
	var cycle_progress := wave_progress(board, cycle_frame)
	check(is_equal_approx(float(cycle_frame.loop_phase), 0.5),
		"Director is halfway through its next cycle when the longer wave cycle completes")
	check(absf(fposmod(cycle_progress - initial + 0.5, 1.0) - 0.5) < 0.00001,
		"wave completes one full cycle in one and a half Director periods")
	check(board.state == state, "wave and Director pacing do not advance gameplay")
	controller.reset(state, 6)
	check(controller.frame() == cycle_frame, "stale generation cannot reset either visual phase")
	controller.reset(state, 8)
	var reset_frame := controller.frame()
	check(reset_frame.get("generation", -1) == 8
		and is_equal_approx(float(reset_frame.loop_phase), float(start.loop_phase))
		and is_equal_approx(wave_progress(board, reset_frame), initial),
		"new generation resets both visual phases without changing Director reset semantics")
	board.free()

func _run() -> void:
	if not setup():
		quit(2)
		return
	test_cell_unions()
	test_region_projection_and_preservation()
	test_exact_facts_and_lanes()
	test_suppression_and_fresh_while_held()
	test_wave_phase_direction_and_curvature()
	test_wave_exact_clipping_and_isolation()
	test_wave_source_origin_and_translation()
	test_board_wave_phase_and_ownership()
	test_wave_pacing_against_director()
	print("Board warnings: %d checks, %d failures. Controlled facts, not visual acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
