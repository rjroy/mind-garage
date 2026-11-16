extends SceneTree
## Board warning facts, not hand illustration, contour taste or pixel budgets.
## Synthetic snapshots deliberately differ from live content. No asset loading.

const BOARD := "res://ui/board.gd"
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
	var required := {"set_board_comparison": 2, "board_comparison": 0, "announcement_marks": 0}
	for name in required:
		var found := false
		for method in board.get_method_list():
			if method.name == name and method.args.size() == required[name]: found = true
		if not found:
			printerr("SETUP REQUIRED: board.", name, "; see board-comparison-contract.md")
			board.free()
			return false
	board.free()
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

func test_options_and_preservation() -> void:
	var board = make_board()
	check(board.board_comparison() == {"telegraph": "current", "contour": "current"},
		"current/current is an honest unchanged comparison default")
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
	for telegraph in ["current", "ribbons", "stamps"]:
		for contour in ["current", "black", "rim"]:
			check(board.set_board_comparison(telegraph, contour), "accepts valid pair " + telegraph + "/" + contour)
			check(board.board_comparison() == {"telegraph": telegraph, "contour": contour},
				"getter reports the actually selected pair")
			check(board.state == before.state and board.preview == before.preview
				and board.candidates == before.candidates and board.selected == before.selected
				and board.source == before.source and board.cursor == before.cursor and board.hover_cell == before.hover,
				"appearance preserves authoritative facts, target, preview and inspection")
			check(board._focused_actor == "A" and board._hover_actor == "B",
				"appearance does not clear rear-actor focus or hover")
			var preferences: Dictionary = board.board_comparison()
			preferences.telegraph = "corrupt"
			check(board.board_comparison().get("telegraph", "") == telegraph, "returned preferences are detached")
	var prior: Dictionary = board.board_comparison()
	for pair in [["unknown", "rim"], ["ribbons", "unknown"], ["RIBBONS", "black"], ["", ""]]:
		check(not board.set_board_comparison(pair[0], pair[1]), "invalid pairs reject explicitly")
		check(board.board_comparison() == prior, "invalid pair cannot partially change the comparison")
	check(board.set_board_comparison("stamps", "rim") and board.set_board_comparison("stamps", "rim"),
		"reapplying a valid pair succeeds without side effects")
	board.set_stage_mode(false)
	check(board.announcement_marks().is_empty(), "non-Stage views have no new warning descriptors")
	check(board.board_comparison() == {"telegraph": "stamps", "contour": "rim"},
		"leaving Stage preserves preferences")
	board.set_stage_mode(true)
	board.theatre_mode = false
	check(board.announcement_marks().is_empty(), "other Stage profiles keep the existing renderer")
	board.free()

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
	for telegraph in ["current", "ribbons", "stamps"]:
		board.set_board_comparison(telegraph, "rim")
		for extent in [Vector2(1008, 514), Vector2(1584, 694)]:
			board.size = extent
			var before: Dictionary = board.state.duplicate(true)
			assert_marks(board, expected)
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
		board.set_board_comparison("ribbons", "rim")
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
			"remaining warning does not swap lanes when the other source disappears")
		check(board.effect_footprints().is_empty(), "held backlash is not relabeled as a committed/preview effect")
		var fresh := snapshot()
		fresh.turn = 8
		fresh.stored = after.stored.duplicate(true)
		fresh.backlash_footprint = after.backlash_footprint.duplicate(true)
		board.set_view(fresh, {}, [], [], captured)
		rows = board.announcement_marks()
		check(rows.size() == 2 and mark(rows, captured).get("turn", -1) == 8
			and board.state.stored.captured_turn == 7, "fresh current warning coexists with an older held occurrence")
		var marks_before: Array = rows.duplicate(true)
		var preview := {"events": [
			{"type": "release", "source": captured},
			{"type": "ray", "actor": "player", "cells": [[4, 2], [5, 2]]},
		], "player": {"pos": [3, 2]}, "enemies": []}
		board.set_view(fresh, preview, [[4, 2]], [4, 2], captured)
		check(board.announcement_marks() == marks_before, "selected prediction never suppresses or replaces current enemy warnings")
		check(board.effect_footprints() == [{"type": "ray", "actor": "player", "stage": "release",
			"cells": [[4, 2], [5, 2]]}], "release uses its existing exact prediction path, separate from announcement ownership")
		board.set_view({}, {}, [], [], "")
		check(board.announcement_marks().is_empty(), "clearing state removes stale warning facts")
		board.free()

func _run() -> void:
	if not setup():
		quit(2)
		return
	test_options_and_preservation()
	test_exact_facts_and_lanes()
	test_suppression_and_fresh_while_held()
	print("Board warnings: %d checks, %d failures. Controlled facts, not visual acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
