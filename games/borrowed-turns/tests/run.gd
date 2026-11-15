extends SceneTree

const Encounter = preload("res://model/encounter.gd")
const F = preload("res://tests/fixtures.gd")

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func model(board: Dictionary = {}):
	var g = Encounter.new()
	g.configure(F.board() if board.is_empty() else board, "R2")
	return g

func enemy(state: Dictionary, id: String) -> Dictionary:
	for item in state.get("enemies", []):
		if item.get("id") == id: return item
	return {}

func types(state: Dictionary) -> Array:
	var result := []
	for event in state.get("events", []): result.append(event.get("type"))
	return result

func events(state: Dictionary, name: String) -> Array:
	var result := []
	for event in state.get("events", []):
		if event.get("type") == name: result.append(event)
	return result

func apply(g, action: Dictionary, label: String) -> bool:
	var before: Dictionary = g.snapshot()
	var assessment: Dictionary = g.assess(action)
	check(g.snapshot() == before, label + ": assess is pure")
	check(assessment.get("legal", false), label + ": legal")
	if not assessment.get("legal", false): return false
	var ok: bool = g.act(action)
	check(ok, label + ": committed")
	check(ok and g.snapshot() == assessment.get("preview", {}), label + ": preview equals commit")
	return ok

func reject(g, action: Dictionary, label: String) -> void:
	var before: Dictionary = g.snapshot()
	var result: Dictionary = g.assess(action)
	check(not result.get("legal", false) and not str(result.get("reason", "")).is_empty() and result.get("preview", {}) == {}, label + ": explained rejection")
	check(not g.act(action) and g.snapshot() == before, label + ": atomic rejection")

func test_budget_boundary() -> void:
	var b := F.board()
	b.enemies[0].pos = [6, 5]
	var g = model(b)
	var before: Dictionary = g.snapshot()
	var action := {"type": "move", "to": [2, 3]}
	var result: Dictionary = g.assess(action)
	check(result.get("legal", false) and g.snapshot() == before, "move assessment is legal and nonmutating")
	check(g.act(action) and g.snapshot() == result.get("preview", {}), "move preview equals commit")
	var s: Dictionary = g.snapshot()
	check(s.get("turn", -1) == 1, "movement does not advance turn")
	check(s.get("movement_points", -1) == 3 and s.get("action_points", -1) == 2, "movement spends only one MP")
	check(not types(s).has("ray"), "enemy does not resolve on movement")

func test_interleaving() -> void:
	var b := F.board()
	b.enemies = [F.foe("a", [3, 2], [0, -1], F.ability("bolt", 3, 1))]
	var g = model(b)
	for pos in [[2, 3], [3, 3]]:
		if not apply(g, {"type": "move", "to": pos}, "example move"): return
	if not apply(g, {"type": "capture", "source": "a"}, "free capture"): return
	check(g.snapshot().get("turn", -1) == 1 and g.snapshot().get("action_points", -1) == 2 and g.snapshot().get("movement_points", -1) == 2, "capture costs neither budget")
	if not apply(g, {"type": "move", "to": [4, 3]}, "move after capture"): return
	if not apply(g, {"type": "release", "target": [6, 3]}, "same-turn release"): return
	check(g.snapshot().get("action_points", -1) == 1 and g.snapshot().get("movement_points", -1) == 1, "release spends AP not MP")
	if not apply(g, {"type": "move", "to": [5, 3]}, "move after release"): return
	check(g.snapshot().get("turn", -1) == 1 and g.snapshot().get("movement_points", -1) == 0 and g.snapshot().get("action_points", -1) == 1, "four steps and one AP interleave in one turn")
	reject(g, {"type": "move", "to": [6, 3]}, "exhausted MP")

func test_unlimited_occurrences() -> void:
	var b := F.board()
	b.player.pos = [3, 3]
	b.enemies = [
		F.foe("a", [4, 3], [1, 0], F.ability("bolt", 1, 1)),
		F.foe("b", [3, 4], [0, 1], F.ability("bolt", 1, 1)),
		F.foe("c", [2, 3], [-1, 0], F.ability("bolt", 1, 1)),
		F.foe("d", [3, 2], [0, -1], F.ability("bolt", 1, 1)),
	]
	var g = model(b)
	for id in ["a", "b", "c", "d"]:
		if not apply(g, {"type": "capture", "source": id}, "unlimited capture " + id): return
	var s: Dictionary = g.snapshot()
	check(s.get("cancelled", []) == ["a", "b", "c", "d"] and s.get("stored", {}).get("source") == "d", "four distinct occurrences captured")
	check(s.get("player", {}).get("hp") == 17 and s.get("action_points") == 2 and s.get("movement_points") == 4, "three replacements cost only ability backlash")
	reject(g, {"type": "capture", "source": "a"}, "same occurrence cannot be captured twice")
	if not apply(g, {"type": "end_turn"}, "refresh occurrences"): return
	check(g.snapshot().get("cancelled", []).is_empty(), "new turn clears captured occurrences")
	check(g.assess({"type": "capture", "source": "a"}).get("legal", false), "source may be captured again on a future turn")

func test_backlash_replacement() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("area", [2, 3], [1, 0], F.ability("burst", 2, 2, 1), 8),
		F.foe("new", [1, 4], [0, 1], F.ability("bolt", 4, 1), 8),
	]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "area"}, "hold burst"): return
	var s: Dictionary = g.snapshot()
	var footprint: Dictionary = s.get("backlash_footprint", {})
	check(footprint.get("type") == "area" and footprint.get("cells", []).has([1, 3]) and footprint.get("cells", []).has([1, 4]), "area backlash footprint is model-owned and includes player and neighbor")
	reject(g, {"type": "capture", "source": "absent"}, "invalid replacement does not discharge")
	var command := {"type": "capture", "source": "new"}
	if not apply(g, command, "area replacement"): return
	s = g.snapshot()
	check(s.get("player", {}).get("hp") == 18 and enemy(s, "new").get("hp") == 6, "actual burst damage hits player and adjacent source")
	check(s.get("stored", {}).get("source") == "new" and s.get("cancelled", []).has("new"), "surviving reachable source is acquired")
	check(types(s).find("backlash") < types(s).find("area") and types(s).find("area") < types(s).find("damage") and types(s).find("damage") < types(s).find("capture"), "replacement emits ordered discharge before capture")
	var area_events := events(s, "area")
	check(not area_events.is_empty() and area_events[0].get("cells") == footprint.get("cells"), "backlash event uses complete stored footprint")

func test_replacement_source_changes() -> void:
	var b := F.board()
	b.enemies = [F.foe("area", [2, 3], [1, 0], F.ability("burst", 2, 2, 1)), F.foe("new", [1, 4], [0, 1], F.ability("bolt", 2, 1), 1)]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "area"}, "hold lethal burst"): return
	if not apply(g, {"type": "capture", "source": "new"}, "source dies during replacement"): return
	var s: Dictionary = g.snapshot()
	check(enemy(s, "new").is_empty() and s.get("stored", {}).is_empty() and not s.get("cancelled", []).has("new"), "dead source is not acquired or canceled")
	var failed := events(s, "capture_failed")
	check(not failed.is_empty() and failed[0].get("reason") == "source_dead", "source death reported")
	b.enemies[0].ability.push = true
	b.enemies[1].hp = 8
	g = model(b)
	if not apply(g, {"type": "capture", "source": "area"}, "hold pushing burst"): return
	if not apply(g, {"type": "capture", "source": "new"}, "source moves during replacement"): return
	s = g.snapshot()
	failed = events(s, "capture_failed")
	check(enemy(s, "new").get("pos") == [1, 5] and s.get("stored", {}).is_empty(), "moved source is not acquired")
	check(not failed.is_empty() and failed[0].get("reason") == "out_of_reach" and not s.get("cancelled", []).has("new"), "out-of-reach source retains its occurrence")

func test_lethal_replacement() -> void:
	var b := F.board()
	b.player.hp = 2
	b.enemies = [F.foe("area", [2, 3], [1, 0], F.ability("burst", 2, 3, 1)), F.foe("new", [1, 4], [0, 1], F.ability("bolt", 2, 1))]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "area"}, "hold lethal backlash"): return
	var before: Dictionary = g.snapshot()
	var command := {"type": "capture", "source": "new"}
	var prediction: Dictionary = g.assess(command)
	var preview: Dictionary = prediction.get("preview", {})
	check(prediction.get("legal", false) and preview.get("status") == "lost" and g.snapshot() == before, "lethal replacement is legal and accurately previewed")
	var footprints := events(preview, "area")
	check(not footprints.is_empty() and footprints[0].get("cells") == before.get("backlash_footprint", {}).get("cells"), "lethal preview retains full area footprint")
	if not prediction.get("legal", false): return
	check(g.act(command) and g.snapshot() == preview, "lethal replacement commits predicted loss")
	check(g.snapshot().get("stored", {}).is_empty() and not g.snapshot().get("cancelled", []).has("new"), "death prevents new storage and cancellation")
	check(not g.act({"type": "end_turn"}), "loss rejects further commands")

func test_deadline() -> void:
	var b := F.board()
	b.enemies = [F.foe("a", [2, 3], [1, 0], F.ability("burst", 2, 2, 1))]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "a"}, "deadline capture"): return
	check(g.snapshot().get("stored", {}).get("deadline_turn") == 2, "deadline is end of next player turn")
	if not apply(g, {"type": "end_turn"}, "end capture turn"): return
	check(g.snapshot().get("turn") == 2 and not g.snapshot().get("stored", {}).is_empty(), "slot survives first turn boundary")
	if not apply(g, {"type": "release", "target": [3, 3]}, "release on final turn"): return
	check(g.snapshot().get("stored", {}).is_empty() and not types(g.snapshot()).has("backlash"), "last-turn release avoids backlash")
	g = model(b)
	if not apply(g, {"type": "capture", "source": "a"}, "expiry capture"): return
	if not apply(g, {"type": "end_turn"}, "expiry first end"): return
	var before: Dictionary = g.snapshot()
	if not apply(g, {"type": "end_turn"}, "expiry second end"): return
	var s: Dictionary = g.snapshot()
	check(s.get("stored", {}).is_empty() and s.get("player", {}).get("hp") == before.get("player", {}).get("hp") - 2, "deadline applies ability-scaled burst damage")
	check(types(s).find("backlash") >= 0 and types(s).find("backlash") < types(s).find("area"), "expiry discharges before area")
	var areas := events(s, "area")
	check(areas.size() == 2 and areas[0].get("actor") == "player" and areas[1].get("actor") == "a", "expiry resolves before enemy intention")
	b.enemies[0].hp = 1
	g = model(b)
	if not apply(g, {"type": "capture", "source": "a"}, "capture source before fatal expiry"): return
	if not apply(g, {"type": "end_turn"}, "first end before fatal expiry"): return
	if not apply(g, {"type": "end_turn"}, "fatal source expiry"): return
	areas = events(g.snapshot(), "area")
	check(enemy(g.snapshot(), "a").is_empty() and areas.size() == 1 and areas[0].get("actor") == "player", "enemy killed by expiry cannot resolve")

func test_range_sight_and_discard() -> void:
	var b := F.board()
	b.enemies[0].pos = [3, 3]
	var g = model(b)
	reject(g, {"type": "capture", "source": "a"}, "outside capture reach")
	if not apply(g, {"type": "move", "to": [2, 3]}, "approach"): return
	if not apply(g, {"type": "capture", "source": "a"}, "adjacent capture"): return
	reject(g, {"type": "discard"}, "discard absent")
	reject(g, {"type": "release", "target": [6, 3]}, "release exceeds ability range")
	reject(g, {"type": "release", "target": [3, 4]}, "diagonal target")
	if not apply(g, {"type": "release", "target": [5, 3]}, "ability range boundary"): return
	var rays := events(g.snapshot(), "ray")
	check(not rays.is_empty() and rays[0].get("cells") == [[3, 3], [4, 3], [5, 3]], "release preserves line geometry")
	b = F.board()
	b.walls = [[3, 3]]
	g = model(b)
	if not apply(g, {"type": "capture", "source": "a"}, "capture beside wall"): return
	reject(g, {"type": "release", "target": [4, 3]}, "wall blocks LOS")
	reject(g, {"type": "move", "to": "wrong"}, "malformed cell")
	reject(g, {"type": "capture", "source": 42}, "malformed source")

func test_action_budget() -> void:
	var b := F.board()
	b.player.pos = [3, 3]
	b.enemies = [F.foe("a", [4, 3], [1, 0], F.ability("bolt", 2, 1)), F.foe("b", [3, 4], [0, 1], F.ability("bolt", 2, 1)), F.foe("c", [2, 3], [-1, 0], F.ability("bolt", 2, 1))]
	var g = model(b)
	for entry in [["a", [4, 3]], ["b", [3, 4]]]:
		if not apply(g, {"type": "capture", "source": entry[0]}, "capture for AP"): return
		if not apply(g, {"type": "release", "target": entry[1]}, "spend AP"): return
	if not apply(g, {"type": "capture", "source": "c"}, "capture remains free at zero AP"): return
	check(g.snapshot().get("action_points") == 0 and g.snapshot().get("movement_points") == 4, "two releases exhaust AP but not MP")
	reject(g, {"type": "release", "target": [2, 3]}, "release with zero AP")

func test_area_release_and_moving_footprint() -> void:
	var b := F.board()
	b.enemies = [F.foe("a", [2, 3], [1, 0], F.ability("burst", 3, 2, 1)), F.foe("b", [2, 4], [0, 1], F.ability("bolt", 2, 1))]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "a"}, "capture burst for release"): return
	var before: Dictionary = g.snapshot().get("backlash_footprint", {})
	if not apply(g, {"type": "move", "to": [1, 2]}, "move with held burst"): return
	var after: Dictionary = g.snapshot().get("backlash_footprint", {})
	check(before != after and after.get("cells", []).has([1, 2]), "held backlash footprint follows player position")
	if not apply(g, {"type": "move", "to": [1, 3]}, "return for burst"): return
	if not apply(g, {"type": "release", "target": [2, 3]}, "release burst"): return
	var s: Dictionary = g.snapshot()
	check(s.get("player", {}).get("hp") == 20 and enemy(s, "a").get("hp") == 8 and enemy(s, "b").get("hp") == 8, "released burst damages both enemies but not player")
	check(not events(s, "area").is_empty(), "released burst reports area geometry")

func test_burst_push_axis() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("source", [1, 4], [1, 0], F.ability("burst", 3, 1, 3, true)),
		F.foe("tie", [2, 2], [1, 0], F.ability("bolt", 1, 1)),
		F.foe("xdom", [5, 4], [1, 0], F.ability("bolt", 1, 1)),
		F.foe("ydom", [4, 5], [1, 0], F.ability("bolt", 1, 1)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture", "source": "source"}, "capture axis-test burst"): return
	# The controlled radius reaches each actor, and their destination cells are free.
	if not apply(g, {"type": "release", "target": [3, 3]}, "axis-test burst release"): return
	var state: Dictionary = g.snapshot()
	var destinations := {}
	for event in events(state, "displace"):
		destinations[event.actor] = event.to
	for item in [["tie", [1, 2]], ["xdom", [6, 4]], ["ydom", [4, 6]]]:
		check(destinations.get(item[0], []) == item[1] and enemy(state, item[0]).get("pos") == item[1], "burst displacement destination: " + item[0])
		check(enemy(state, item[0]).get("hp") == 9, "burst affected axis-test actor: " + item[0])

func test_end_turn_intentions_and_reset() -> void:
	var b := F.board()
	b.player.hp = 1
	b.enemies = [F.foe("a", [3, 3], [-1, 0], F.ability("bolt", 3, 1)), F.foe("b", [6, 5], [1, 0], F.ability("shove", 2, 1, 0, true))]
	var g = model(b)
	var initial: Dictionary = g.snapshot()
	check(initial.get("intentions", []).size() == 2, "all intentions visible before lethal turn")
	check(initial.get("intentions", []) == [{"source": "a", "kind": "bolt", "cells": [[2, 3], [1, 3], [0, 3]]}, {"source": "b", "kind": "shove", "cells": [[7, 5]]}], "intention geometry remains complete in fixture order")
	var verdict: Dictionary = g.assess({"type": "end_turn"})
	check(verdict.get("legal", false) and verdict.get("preview", {}).get("status") == "lost" and g.snapshot() == initial, "lethal end turn preview is pure")
	check(events(verdict.get("preview", {}), "ray").size() == 1, "later enemy does not resolve after player death")
	b.player.hp = 10
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "ordered enemy turn"): return
	var rays := events(g.snapshot(), "ray")
	check(rays.size() == 2 and rays[0].get("actor") == "a" and rays[1].get("actor") == "b", "enemies resolve in fixture order")
	var original: Dictionary = F.board()
	var first = model(original)
	var second = model(original)
	var second_initial: Dictionary = second.snapshot()
	original.player.hp = 1
	var detached: Dictionary = first.snapshot()
	detached.player.hp = 1
	check(first.snapshot().get("player", {}).get("hp") == 20, "fixture and snapshot are deep copied")
	if not apply(first, {"type": "move", "to": [1, 2]}, "move before refresh"): return
	if not apply(first, {"type": "end_turn"}, "explicit end turn"): return
	check(first.snapshot().get("turn") == 2 and first.snapshot().get("action_points") == 2 and first.snapshot().get("movement_points") == 4, "end turn refreshes both budgets")
	check(second.snapshot() == second_initial, "runs are isolated")
	first.reset()
	check(first.snapshot() == second_initial, "reset restores exact independent initial state")
	var exit_board := F.board()
	exit_board.exit = {"pos": [1, 2], "opens": 1}
	g = model(exit_board)
	if not apply(g, {"type": "move", "to": [1, 2]}, "move onto open exit"): return
	check(g.snapshot().get("status") == "won", "open exit wins immediately")
	reject(g, {"type": "end_turn"}, "terminal state")

func test_no_invert() -> void:
	var b := F.board()
	b.enemies = [F.foe("a", [2, 3], [1, 0], F.ability("shove", 3, 1, 0, true))]
	var g = model(b)
	check(not g.snapshot().has("invert_enabled"), "active snapshot has no invert configuration")
	if not apply(g, {"type": "capture", "source": "a"}, "capture normal shove"): return
	if not apply(g, {"type": "release", "target": [2, 3]}, "normal shove"): return
	check(enemy(g.snapshot(), "a").get("pos") == [3, 3], "normal shove pushes away from origin")
	var release_events := events(g.snapshot(), "release")
	check(not release_events.is_empty() and not release_events[0].has("invert"), "release event has no invert configuration")
	for flag in [true, false]:
		g = model(b)
		if not apply(g, {"type": "capture", "source": "a"}, "capture for unsupported invert"): continue
		reject(g, {"type": "release", "target": [2, 3], "invert": flag}, "invert field %s is unsupported" % flag)

func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--focus=budget"):
		test_budget_boundary()
	elif OS.get_cmdline_user_args().has("--focus=no-invert"):
		test_no_invert()
	elif OS.get_cmdline_user_args().has("--focus=burst-axis"):
		test_burst_push_axis()
	else:
		test_budget_boundary()
		test_interleaving()
		test_unlimited_occurrences()
		test_backlash_replacement()
		test_replacement_source_changes()
		test_lethal_replacement()
		test_deadline()
		test_range_sight_and_discard()
		test_action_budget()
		test_area_release_and_moving_footprint()
		test_burst_push_axis()
		test_end_turn_intentions_and_reset()
		test_no_invert()
	print("Checks: ", checks, "; failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
