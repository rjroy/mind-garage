extends SceneTree

const Encounter = preload("res://model/encounter.gd")
const Fixtures = preload("res://tests/fixtures.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func model(variant: String = "V1", board: Dictionary = {}, invert: bool = false):
	var game = Encounter.new()
	game.configure(Fixtures.board() if board.is_empty() else board, variant, invert)
	return game

func event_types(state: Dictionary) -> Array:
	var types := []
	for event in state.events:
		types.append(event.type)
	return types

func enemy(state: Dictionary, id: String) -> Dictionary:
	for item in state.enemies:
		if item.id == id:
			return item
	return {}

func test_actions_and_preview() -> void:
	var g = model()
	var before: Dictionary = g.snapshot()
	var invalid := {"type": "move", "to": [3, 3]}
	var rejection: Dictionary = g.assess(invalid)
	check(not rejection.legal and not rejection.reason.is_empty() and rejection.preview.is_empty(), "illegal move explains rejection")
	check(not g.act(invalid) and g.snapshot() == before, "illegal move is atomic")
	var action := {"type": "move", "to": [2, 3]}
	var verdict: Dictionary = g.assess(action)
	check(verdict.legal and verdict.reason.is_empty() and g.snapshot() == before, "assessment is nonmutating")
	check(g.act(action) and g.snapshot() == verdict.preview, "preview predicts exact outcome")
	check(g.snapshot().turn == 2 and g.snapshot().player.pos == [2, 3], "movement advances turn")
	var snapshot: Dictionary = g.snapshot()
	snapshot.player.hp = 99
	check(g.snapshot().player.hp == 6, "snapshots are isolated")
	check(not g.act({"type": "dance"}), "unknown action rejected")

func test_capture_and_release() -> void:
	var b := Fixtures.board()
	b.enemies[0].dir = [-1, 0]
	b.enemies[1].pos = [1, 5]
	b.enemies[1].dir = [0, -1]
	b.enemies[1].kind = "bolt"
	var g = model("V1", b)
	check(g.act(Fixtures.capture("a")), "capture succeeds")
	var s: Dictionary = g.snapshot()
	check(s.player.hp == 5 and s.stored.source == "a", "one occurrence canceled, other enemy resolves")
	check(not g.act(Fixtures.capture("b")), "occupied slot rejects replacement")
	check(g.act({"type": "wait"}), "wait with stored action")
	check(g.snapshot().player.hp == 3, "captured source attacks again next turn")
	check(not g.act({"type": "release", "target": [2, 4]}), "diagonal release rejected")
	check(g.act({"type": "release", "target": [3, 3]}), "aligned release accepted")
	check(enemy(g.snapshot(), "a").hp == 1 and g.snapshot().stored.is_empty(), "release hits enemy and empties slot")
	var discard_game = model()
	discard_game.act(Fixtures.capture("a"))
	check(discard_game.act({"type": "discard"}) and discard_game.snapshot().stored.is_empty(), "V1 discard clears slot")
	check(discard_game.act(Fixtures.capture("a")), "V1 can capture again after discard")

func test_los_and_rays() -> void:
	var b := Fixtures.board()
	b.walls = [[2, 3]]
	var g = model("V1", b)
	check(g.act(Fixtures.capture("a")), "walls do not block capture reach")
	check(not g.act({"type": "release", "target": [3, 3]}), "wall blocks release target")
	var a := {"type": "release", "target": [1, 1]}
	var verdict: Dictionary = g.assess(a)
	check(verdict.legal, "empty aligned target is legal")
	var rays := []
	for e in verdict.preview.events:
		if e.type == "ray" and e.actor == "player":
			rays = e.cells
	check(rays == [[1, 2], [1, 1]], "preview exposes ordered release geometry")

func test_v2() -> void:
	var g = model("V2")
	var before: Dictionary = g.snapshot()
	check(not g.act(Fixtures.capture("a")), "V2 requires adjacency")
	check(not g.act(Fixtures.capture("a", {"approach": [1, 2]})) and g.snapshot() == before, "V2 invalid approach is atomic")
	check(g.act(Fixtures.capture("a", {"approach": [2, 3]})), "V2 approach and capture")
	check(g.snapshot().player.pos == [2, 3] and g.snapshot().stored.source == "a", "V2 approach ends adjacent")
	check(event_types(g.snapshot()).slice(0, 2) == ["move", "capture"], "V2 event order")
	var b := Fixtures.board()
	b.walls = [[2, 3]]
	var blocked = model("V2", b)
	check(not blocked.act(Fixtures.capture("a", {"approach": [2, 3]})), "V2 blocked approach rejected")
	b.walls = []
	b.player.pos = [2, 3]
	var adjacent = model("V2", b)
	check(adjacent.act(Fixtures.capture("a")), "V2 capture from adjacency")

func test_v3() -> void:
	var g = model("V3")
	check(g.act(Fixtures.capture("a")), "V3 capture")
	check(g.snapshot().stored.actions_elapsed == 0, "capture does not age V3 slot")
	check(g.act({"type": "wait"}) and g.snapshot().stored.actions_elapsed == 1, "first action retains V3 slot")
	check(g.act({"type": "release", "target": [3, 3]}) and g.snapshot().stored.is_empty(), "V3 release on second action")
	g.reset()
	g.act(Fixtures.capture("a"))
	g.act({"type": "wait"})
	check(g.act({"type": "wait"}) and g.snapshot().stored.is_empty(), "V3 expires after second action")
	check("slot_lost" in event_types(g.snapshot()), "V3 expiry reported")

func test_v4() -> void:
	var b := Fixtures.board()
	b.enemies[0].hp = 1
	var g = model("V4", b)
	g.act(Fixtures.capture("a"))
	check(g.act({"type": "release", "target": [3, 3]}), "V4 release can kill its own source")
	check(enemy(g.snapshot(), "a").is_empty() and not ("slot_lost" in event_types(g.snapshot())), "V4 consumes before source death")
	b.enemies[1].pos = [3, 5]
	b.enemies[1].dir = [0, -1]
	g = model("V4", b)
	check(g.act(Fixtures.capture("a")), "V4 source targeted by other enemy")
	check(enemy(g.snapshot(), "a").is_empty() and g.snapshot().stored.is_empty(), "V4 source death destroys stored action")
	check("slot_lost" in event_types(g.snapshot()), "V4 source loss reported")
	b = Fixtures.board()
	b.enemies[1].hp = 1
	b.enemies.append({"id": "c", "pos": [5, 3], "hp": 2, "kind": "bolt", "dir": [0, 1]})
	g = model("V4", b)
	g.act(Fixtures.capture("a"))
	check(enemy(g.snapshot(), "b").is_empty() and g.snapshot().stored.source == "a", "V4 unrelated death preserves stored action")

func test_v5() -> void:
	var g = model("V5")
	check(g.act(Fixtures.capture("a")), "V5 free capture")
	check(g.snapshot().turn == 1 and g.snapshot().stored.actions_elapsed == 0 and g.snapshot().free_capture_used, "V5 capture uses once-per-turn allowance without advancing")
	check(not g.act(Fixtures.capture("b")), "V5 cannot replace occupied slot")
	check(not g.act({"type": "release", "target": [3, 3]}), "V5 cannot release on capture turn")
	check(g.act({"type": "wait"}) and g.snapshot().stored.actions_elapsed == 1, "V5 capture-turn action is first subsequent action")
	check(g.act({"type": "release", "target": [3, 3]}) and g.snapshot().player.hp == 6, "V5 final-action release avoids backlash")
	g.reset()
	g.act(Fixtures.capture("a"))
	g.act({"type": "wait"})
	check(g.act({"type": "wait"}) and g.snapshot().player.hp == 5 and g.snapshot().stored.is_empty(), "V5 deadline backlashes")
	check("backlash" in event_types(g.snapshot()), "V5 deadline reports backlash")
	g.reset()
	g.act(Fixtures.capture("a"))
	check(g.act({"type": "discard"}) and g.snapshot().player.hp == 5, "V5 discard backlashes")
	var b := Fixtures.board()
	b.enemies[0].hp = 1
	var v4 = model("V4", b)
	check(not v4.act({"type": "discard"}), "discard empty slot is invalid")
	b = Fixtures.board()
	b.enemies[1].pos = [3, 3]
	b.enemies[0].pos = [5, 5]
	g = model("V5", b)
	g.act(Fixtures.capture("b"))
	check(g.act({"type": "discard"}) and g.snapshot().player.hp == 5 and g.snapshot().player.pos == [1, 3], "V5 shove backlash damages without displacement")

func test_v6() -> void:
	var g = model("V6")
	var before: Dictionary = g.snapshot()
	check(not g.act(Fixtures.capture("a", {"target": [2, 4]})) and g.snapshot() == before, "V6 illegal commitment is atomic")
	check(g.act(Fixtures.capture("a", {"target": [3, 3]})), "V6 commits legal cell")
	check(g.snapshot().stored.target == [3, 3], "V6 stores cell not actor")
	check(g.act({"type": "move", "to": [1, 2]}), "V6 can reposition")
	check(not g.act({"type": "release"}) and not g.act({"type": "release", "target": [1, 1]}), "V6 invalid geometry and retarget rejected")
	check(g.act({"type": "move", "to": [1, 3]}), "V6 can recover geometry")
	check(g.act({"type": "release"}), "V6 releases at fixed cell")
	g.reset()
	g.act(Fixtures.capture("a", {"target": [3, 3]}))
	g.act({"type": "move", "to": [1, 2]})
	check(g.act({"type": "discard"}) and g.snapshot().stored.is_empty(), "V6 discard recovers from invalid commitment")
	var b := Fixtures.board()
	b.walls = [[4, 2]]
	g = model("V6", b)
	check(g.act(Fixtures.capture("a", {"target": [4, 3]})), "V6 commits initially unobstructed cell")
	for cell in [[1, 2], [2, 2], [3, 2], [3, 1], [4, 1]]:
		check(g.act({"type": "move", "to": cell}), "V6 reposition toward obstructed line")
	check(not g.act({"type": "release"}), "V6 later wall blocks committed line")

func test_invert() -> void:
	var b := Fixtures.board()
	b.enemies[1].pos = [3, 3]
	b.enemies[0].pos = [5, 5]
	var g = model("V1", b, true)
	g.act(Fixtures.capture("b"))
	check(g.act({"type": "release", "target": [3, 3], "invert": true}), "Invert accepts shove")
	check(enemy(g.snapshot(), "b").pos == [2, 3], "Invert pulls toward origin")
	g = model("V1", b, false)
	g.act(Fixtures.capture("b"))
	check(not g.act({"type": "release", "target": [3, 3], "invert": true}), "Invert requires preview mode")
	g = model("V1", Fixtures.board(), true)
	g.act(Fixtures.capture("a"))
	check(not g.act({"type": "release", "target": [3, 3], "invert": true}), "bolt is not reversible")

func test_end_and_isolation() -> void:
	var b := Fixtures.board()
	b.exit = {"pos": [2, 3], "opens": 1}
	var g = model("V1", b)
	check(g.act({"type": "move", "to": [2, 3]}) and g.snapshot().status == "won", "escape wins")
	check(not g.act({"type": "wait"}), "terminal state rejects action")
	g.reset()
	check(g.snapshot().status == "playing" and g.snapshot().turn == 1, "reset restores run")
	b = Fixtures.board()
	b.player.hp = 1
	b.enemies[0].dir = [-1, 0]
	g = model("V1", b)
	check(g.act({"type": "wait"}) and g.snapshot().status == "lost", "enemy damage causes failure")
	check(event_types(g.snapshot()).has("loss"), "failure reported")
	var first = model("V1")
	var second = model("V3")
	var initial: Dictionary = second.snapshot()
	first.act(Fixtures.capture("a"))
	check(second.snapshot() == initial, "variant instances isolated")
	first.reset()
	check(first.snapshot().stored.is_empty() and first.snapshot().variant == "V1", "reset retains variant and clears slot")

func test_complete_intentions() -> void:
	var b := Fixtures.board()
	b.player.hp = 1
	b.enemies[0].dir = [-1, 0]
	var g = model("V5", b)
	var initial: Dictionary = g.snapshot()
	check(initial.intentions == [
		{"source": "a", "kind": "bolt", "cells": [[2, 3], [1, 3], [0, 3]]},
		{"source": "b", "kind": "shove", "cells": [[6, 5]]},
	], "initial intentions include every alive enemy and ordered cells")
	var verdict: Dictionary = g.assess({"type": "wait"})
	check(verdict.legal and verdict.preview.status == "lost", "first enemy can end the run")
	var rays := []
	for e in verdict.preview.events:
		if e.type == "ray":
			rays.append(e.actor)
	check(rays == ["a"] and g.snapshot() == initial, "lethal preview stops resolution without removing current telegraphs")
	check(g.act(Fixtures.capture("a")), "free capture cancels lethal occurrence")
	check(g.snapshot().intentions == [{"source": "b", "kind": "shove", "cells": [[6, 5]]}], "free capture removes only canceled intention")
	g.reset()
	check(g.snapshot().intentions == initial.intentions, "reset restores all current intentions")

func _initialize() -> void:
	test_actions_and_preview()
	test_capture_and_release()
	test_los_and_rays()
	test_v2()
	test_v3()
	test_v4()
	test_v5()
	test_v6()
	test_invert()
	test_end_and_isolation()
	test_complete_intentions()
	print("Checks: ", checks, "; failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
