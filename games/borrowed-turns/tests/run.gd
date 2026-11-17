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
	var fixture: Dictionary = (F.board() if board.is_empty() else board).duplicate(true)
	if not fixture.has("objective"):
		fixture.objective = "escape"
	g.configure(fixture, "R2")
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
	check(s.get("action_points", -1) == 2 and not s.has("movement_points") and not s.get("rules", {}).has("movement"), "movement spends one shared AP without player MP")
	check(not types(s).has("ray"), "enemy does not resolve on movement")

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
	check(first.snapshot().get("turn") == 2 and first.snapshot().get("action_points") == 3 and not first.snapshot().has("movement_points"), "end turn refreshes shared AP")
	check(second.snapshot() == second_initial, "runs are isolated")
	first.reset()
	check(first.snapshot() == second_initial, "reset restores exact independent initial state")
	var exit_board := F.board()
	exit_board.exit = {"pos": [1, 2], "opens": 1}
	g = model(exit_board)
	if not apply(g, {"type": "move", "to": [1, 2]}, "move onto open exit"): return
	check(g.snapshot().get("status") == "won", "open exit wins immediately")
	var wins := events(g.snapshot(), "win")
	check(g.snapshot().get("objective") == "escape" and not wins.is_empty() and wins[0].get("objective") == "escape", "escape snapshot and win event identify objective")
	reject(g, {"type": "end_turn"}, "terminal state")

func mobile(id: String, pos: Array, direction: Array, skill: Dictionary, pattern: String, budget: int = 1, hp: int = 10) -> Dictionary:
	var result := F.foe(id, pos, direction, skill, hp)
	result.movement_pattern = pattern
	result.movement_budget = budget
	return result

func intention(state: Dictionary, id: String) -> Dictionary:
	for item in state.get("intentions", []):
		if item.get("source") == id: return item
	return {}

func test_movement_and_aim() -> void:
	var b := F.board()
	b.player.pos = [1, 3]
	b.enemies = [mobile("chaser", [4, 3], [1, 0], F.ability("bolt", 2, 1), "chase_player")]
	var g = model(b)
	if not apply(g, {"type": "end_turn"}, "chaser end turn"): return
	var s: Dictionary = g.snapshot()
	var moves := events(s, "move")
	check(enemy(s, "chaser").get("pos") == [3, 3], "chaser takes shortest step toward adjacency")
	check(moves.size() == 1 and moves[0].get("actor") == "chaser" and moves[0].get("from") == [4, 3] and moves[0].get("to") == [3, 3], "enemy movement event carries endpoints")
	check(types(s).find("ray") < types(s).find("move") and types(s).find("move") < types(s).find("turn"), "old attack resolves before movement and budget refresh")
	check(enemy(s, "chaser").get("dir") == [-1, 0] and intention(s, "chaser").get("cells", []).has([1, 3]), "new announcement aims at player from moved source")
	if not apply(g, {"type": "move", "to": [1, 2]}, "move after announcement"): return
	check(enemy(g.snapshot(), "chaser").get("dir") == [-1, 0] and intention(g.snapshot(), "chaser").get("cells", []).has([1, 3]), "announcement direction remains locked during player turn")

	b.walls = [[3, 3]]
	g = model(b)
	var twin = model(b)
	if not apply(g, {"type": "end_turn"}, "wall detour"): return
	if not apply(twin, {"type": "end_turn"}, "repeat wall detour"): return
	var destination: Array = enemy(g.snapshot(), "chaser").get("pos", [])
	check(destination in [[4, 2], [4, 4]] and g.snapshot() == twin.snapshot(), "blocked direct route uses deterministic equal-length detour")
	b.walls = [[3, 3], [4, 2], [4, 4], [5, 3]]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "fully blocked chaser"): return
	check(enemy(g.snapshot(), "chaser").get("pos") == [4, 3] and events(g.snapshot(), "move").is_empty(), "fully blocked chaser does not move")
	b = F.board()
	b.player.pos = [2, 3]
	b.enemies = [mobile("diagonal", [4, 1], [1, 0], F.ability("bolt", 3, 1), "chase_player", 0)]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "diagonal aim"): return
	check(enemy(g.snapshot(), "diagonal").get("dir") == [-1, 0] and not intention(g.snapshot(), "diagonal").get("cells", []).has([2, 3]), "diagonal aim uses horizontal tie and cardinal ray")
	b.player.hp = 1
	b.player.pos = [1, 3]
	b.enemies = [mobile("killer", [3, 3], [-1, 0], F.ability("bolt", 3, 1), "chase_player"), mobile("later", [6, 5], [1, 0], F.ability("bolt", 1, 1), "chase_player")]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "death stops movement phase"): return
	check(g.snapshot().get("status") == "lost" and events(g.snapshot(), "move").is_empty() and events(g.snapshot(), "ray").size() == 1, "death stops later attacks and all movement")

func test_max_range_and_occupancy() -> void:
	var b := F.board()
	b.player.pos = [1, 3]
	b.enemies = [mobile("ranger", [3, 3], [1, 0], F.ability("bolt", 3, 1), "keep_max_range")]
	var g = model(b)
	if not apply(g, {"type": "end_turn"}, "ranger finds usable range"): return
	var s: Dictionary = g.snapshot()
	check(enemy(s, "ranger").get("pos") == [4, 3] and intention(s, "ranger").get("cells", []).has([1, 3]), "ranger selects farthest usable firing cell, not endless retreat")
	if not apply(g, {"type": "end_turn"}, "ranger holds usable range"): return
	check(enemy(g.snapshot(), "ranger").get("pos") == [4, 3], "ranger does not flee beyond usable range")
	b.walls = [[2, 3]]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "ranger blocked sight"): return
	check(enemy(g.snapshot(), "ranger").get("pos") != [4, 3], "ranger does not select blocked firing line")
	b = F.board()
	b.player.pos = [1, 3]
	b.enemies = [
		mobile("first", [4, 3], [1, 0], F.ability("bolt", 1, 0), "chase_player"),
		mobile("second", [5, 3], [1, 0], F.ability("bolt", 1, 0), "chase_player"),
	]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "sequential enemy movement"): return
	s = g.snapshot()
	var moves := events(s, "move")
	check(moves.size() == 2 and moves[0].get("actor") == "first" and moves[1].get("actor") == "second", "movement follows fixture order")
	check(enemy(s, "first").get("pos") == [3, 3] and enemy(s, "second").get("pos") == [4, 3], "later mover uses vacated cell without overlap")

func wide_shove() -> Dictionary:
	var skill := F.ability("shove", 2, 1, 0, true)
	skill.width = 3
	return skill

func same_cells(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for cell in expected:
		if not actual.has(cell): return false
	return true

func test_wide_intention_geometry() -> void:
	var b := F.board()
	b.player.pos = [0, 0]
	for direction in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		b.enemies = [F.foe("wide", [3, 3], direction, wide_shove())]
		var g = model(b)
		var cells: Array = intention(g.snapshot(), "wide").get("cells", [])
		var expected := []
		var lateral := [-direction[1], direction[0]]
		for depth in [1, 2]:
			for offset in [-1, 0, 1]:
				expected.append([3 + direction[0] * depth + lateral[0] * offset, 3 + direction[1] * depth + lateral[1] * offset])
		check(same_cells(cells, expected), "wide front covers exactly six forward cells for %s" % [direction])
		check(intention(model(b).snapshot(), "wide").get("cells", []) == cells, "wide front order is deterministic for %s" % [direction])
	b.enemies = [F.foe("narrow", [3, 3], [1, 0], F.ability("shove", 2, 1, 0, true))]
	check(intention(model(b).snapshot(), "narrow").get("cells") == [[4, 3], [5, 3]], "missing width keeps narrow shove unchanged")
	b.enemies = [F.foe("wide", [3, 3], [1, 0], wide_shove())]
	b.walls = [[4, 2]]
	check(same_cells(intention(model(b).snapshot(), "wide").get("cells", []), [[4, 3], [5, 3], [4, 4], [5, 4]]), "wall blocks only its lane and cells behind it")
	b.walls = []
	b.enemies = [F.foe("wide", [0, 0], [1, 0], wide_shove())]
	b.player.pos = [7, 6]
	check(same_cells(intention(model(b).snapshot(), "wide").get("cells", []), [[1, 0], [2, 0], [1, 1], [2, 1]]), "wide front clips cleanly at board edge")

func test_wide_ranger_goal() -> void:
	var b := F.board()
	b.player.pos = [1, 3]
	b.enemies = [mobile("ranger", [3, 2], [1, 0], wide_shove(), "keep_max_range")]
	var g = model(b)
	if not apply(g, {"type": "end_turn"}, "wide ranger usable lateral firing position"): return
	check(enemy(g.snapshot(), "ranger").get("pos") == [3, 2] and intention(g.snapshot(), "ranger").get("cells", []).has([1, 3]), "range policy recognizes usable wide lateral cell")

func test_arm_and_contact() -> void:
	var b := F.board()
	b.enemies = [F.foe("far", [4, 3], [-1, 0], F.ability("bolt", 3, 2))]
	var g = model(b)
	var initial: Dictionary = g.snapshot()
	if not apply(g, {"type": "capture"}, "arm while threatened and outside old reach"): return
	var armed: Dictionary = g.snapshot()
	check(armed.get("capture_armed", false) and armed.get("action_points") == 2 and armed.get("stored", {}).is_empty(), "arming costs one AP and waits for contact")
	check(armed.get("intentions") == initial.get("intentions"), "arming does not cancel the announced attack")
	reject(g, {"type": "capture"}, "duplicate arm is atomic")
	if not apply(g, {"type": "end_turn"}, "enemy hits armed player"): return
	var s: Dictionary = g.snapshot()
	check(s.get("player", {}).get("hp") == 18 and s.get("stored", {}).get("source") == "far", "contact deals full damage and captures source")
	check(not s.get("capture_armed", true) and s.get("stored", {}).get("ability") == b.enemies[0].ability, "contact consumes arm and copies payload")
	check(s.get("stored", {}).get("captured_turn") == 1 and not s.get("stored", {}).has("deadline_turn"), "captured turn identifies occurrence without expiry")
	check(not events(s, "ray").is_empty() and not intention(s, "far").is_empty(), "captured living source still attacks and announces")
	check(not s.has("backlash_footprint") and not s.has("cancelled") and not types(s).has("backlash"), "capture has no backlash or cancellation bookkeeping")

func test_arm_persists_on_miss_and_budget() -> void:
	var b := F.board()
	b.enemies = [F.foe("miss", [6, 5], [1, 0], F.ability("bolt", 1, 1))]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm before misses"): return
	for turn in range(3):
		if not apply(g, {"type": "end_turn"}, "missed enemy turn %d" % turn): return
		var s: Dictionary = g.snapshot()
		check(s.get("capture_armed", false) and s.get("stored", {}).is_empty() and s.get("player", {}).get("hp") == 20, "miss leaves arm ready across turn %d" % turn)
		check(not types(s).has("backlash"), "miss has no expiry backlash")
	if not apply(g, {"type": "move", "to": [1, 2]}, "move while armed"): return
	check(g.snapshot().get("capture_armed", false), "movement does not consume arm")
	b.rules.actions = 1
	g = model(b)
	if not apply(g, {"type": "move", "to": [1, 2]}, "spend last AP"): return
	reject(g, {"type": "capture"}, "arming at zero AP")
	reject(g, {"type": "shine", "target": [2, 2]}, "shine at zero AP without held skill")
	check(g.snapshot().get("turn") == 1, "zero AP does not end turn")

func test_first_hit_and_full_enemy_effects() -> void:
	var b := F.board()
	b.player.pos = [3, 3]
	b.enemies = [
		mobile("first", [5, 3], [-1, 0], wide_shove(), "chase_player"),
		F.foe("second", [0, 3], [1, 0], F.ability("bolt", 3, 1)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm for two attacks"): return
	if not apply(g, {"type": "end_turn"}, "resolve two enemy attacks"): return
	var s: Dictionary = g.snapshot()
	check(s.get("player", {}).get("hp") == 18 and s.get("player", {}).get("pos") == [2, 3], "first shove damages and displaces before second attack")
	check(s.get("stored", {}).get("source") == "first" and s.get("stored", {}).get("ability", {}).get("width") == 3, "first hit captures its actual wide payload, not later hit")
	var rays := events(s, "ray")
	check(rays.size() == 2 and rays[0].get("actor") == "first" and rays[1].get("actor") == "second", "both enemy attacks resolve in order")
	check(types(s).find("displace") >= 0 and types(s).find("capture") > types(s).find("displace") and types(s).find("capture") < types(s).rfind("ray"), "acquisition follows complete shove before next attack")
	check(enemy(s, "first").get("pos") != [5, 3] and not intention(s, "first").is_empty(), "captured source still moves and announces")
	b.player.hp = 1
	g = model(b)
	if not apply(g, {"type": "capture"}, "arm before lethal contact"): return
	if not apply(g, {"type": "end_turn"}, "lethal contact"): return
	check(g.snapshot().get("status") == "lost" and g.snapshot().get("stored", {}).is_empty(), "lethal hit loses without acquiring skill")

func test_shine_persistence_and_source_death() -> void:
	var b := F.board()
	b.enemies = [F.foe("source", [4, 3], [-1, 0], F.ability("bolt", 3, 1), 1)]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm persistent skill"): return
	if not apply(g, {"type": "end_turn"}, "acquire persistent skill"): return
	for n in range(2):
		if not apply(g, {"type": "shine", "target": [2, 3]}, "repeated shine %d" % n): return
		check(g.snapshot().get("stored", {}).get("source") == "source" and g.snapshot().get("action_points") == 2 - n, "shine costs one AP and retains skill %d" % n)
	if not apply(g, {"type": "shine", "target": [2, 3]}, "spend last AP shining"): return
	reject(g, {"type": "shine", "target": [2, 3]}, "held shine at zero AP")
	reject(g, {"type": "capture"}, "arm at zero AP with held skill")
	check(g.snapshot().get("turn") == 2, "zero AP does not advance held-skill turn")
	if not apply(g, {"type": "end_turn"}, "hold through another turn"): return
	check(g.snapshot().get("stored", {}).get("source") == "source" and not types(g.snapshot()).has("backlash"), "skill persists across turns without backlash")
	if not apply(g, {"type": "shine", "target": [4, 3]}, "shine defeats own source"): return
	check(enemy(g.snapshot(), "source").is_empty() and g.snapshot().get("stored", {}).is_empty(), "source death clears held skill after shine")
	reject(g, {"type": "shine", "target": [2, 3]}, "cannot shine after source death")

func test_source_death_and_full_burst() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("source", [4, 3], [-1, 0], F.ability("bolt", 3, 1), 1),
		F.foe("killer", [4, 5], [0, -1], F.ability("bolt", 2, 1)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm before source dies to another enemy"): return
	if not apply(g, {"type": "end_turn"}, "captured source killed by later enemy"): return
	check(enemy(g.snapshot(), "source").is_empty() and g.snapshot().get("stored", {}).is_empty(), "another enemy killing held source clears skill")
	b.player.pos = [3, 3]
	b.enemies = [
		F.foe("burst", [5, 3], [-1, 0], F.ability("burst", 2, 1, 1), 1),
		F.foe("other", [4, 2], [0, -1], F.ability("bolt", 1, 1), 5),
	]
	g = model(b)
	if not apply(g, {"type": "capture"}, "arm burst"): return
	if not apply(g, {"type": "end_turn"}, "capture burst on contact"): return
	if not apply(g, {"type": "shine", "target": [4, 3]}, "burst kills own source first"): return
	var s: Dictionary = g.snapshot()
	check(enemy(s, "burst").is_empty() and s.get("stored", {}).is_empty(), "burst source death clears held ability")
	check(enemy(s, "other").get("hp") == 4, "burst completes remaining targets after source death")
	var death_index := -1
	var other_damage_index := -1
	var lost_index := -1
	for i in range(s.get("events", []).size()):
		var event: Dictionary = s.events[i]
		if event.get("type") == "death" and event.get("actor") == "burst": death_index = i
		if event.get("type") == "damage" and event.get("actor") == "other": other_damage_index = i
		if event.get("type") == "ability_lost": lost_index = i
	check(death_index >= 0 and other_damage_index > death_index and lost_index > other_damage_index, "source loss event follows death and complete burst effects")

func test_rearm_replaces_only_on_contact() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("first", [4, 3], [-1, 0], F.ability("bolt", 3, 2)),
		F.foe("second", [1, 5], [0, 1], F.ability("bolt", 2, 1)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm first ability"): return
	if not apply(g, {"type": "end_turn"}, "acquire first ability"): return
	if not apply(g, {"type": "capture"}, "arm replacement"): return
	check(g.snapshot().get("stored", {}).get("source") == "first" and g.snapshot().get("capture_armed", false), "arming replacement preserves held ability until contact")
	if not apply(g, {"type": "move", "to": [1, 4]}, "enter second announcement"): return
	if not apply(g, {"type": "end_turn"}, "second source hits"): return
	var s: Dictionary = g.snapshot()
	check(s.get("stored", {}).get("source") == "second" and not s.get("capture_armed", true), "new contact replaces old held ability")
	check(s.get("player", {}).get("hp") == 17 and not types(s).has("backlash"), "replacement causes no backlash, only enemy damage")

func test_dead_source_cannot_be_acquired() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("killer", [4, 5], [0, -1], F.ability("bolt", 2, 1)),
		F.foe("doomed", [4, 3], [-1, 0], F.ability("bolt", 3, 1), 1),
		F.foe("survivor", [3, 3], [-1, 0], F.ability("bolt", 2, 1)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm while enemy dies before attack"): return
	if not apply(g, {"type": "end_turn"}, "dead source skipped"): return
	check(enemy(g.snapshot(), "doomed").is_empty() and g.snapshot().get("stored", {}).get("source") == "survivor", "dead source cannot consume arm; next actual hit is captured")

func test_shine_borrowed_wide_endpoint() -> void:
	var b := F.board()
	b.player.pos = [3, 3]
	b.enemies = [F.foe("wide", [5, 3], [-1, 0], wide_shove())]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm for wide shove"): return
	if not apply(g, {"type": "end_turn"}, "capture wide shove on hit"): return
	check(g.snapshot().get("player", {}).get("pos") == [2, 3] and g.snapshot().get("stored", {}).get("ability", {}).get("width") == 3, "wide hit pushes player and preserves width")
	if not apply(g, {"type": "shine", "target": [3, 3]}, "shine wide to near endpoint"): return
	var rays := events(g.snapshot(), "ray")
	check(not rays.is_empty() and same_cells(rays[0].get("cells", []), [[3, 2], [3, 3], [3, 4]]), "wide shine retains width and selected endpoint")
	check(g.snapshot().get("stored", {}).get("source") == "wide", "wide shine retains captured ability")

func test_reset_new_states() -> void:
	var b := F.board()
	b.enemies = [F.foe("source", [4, 3], [-1, 0], F.ability("bolt", 3, 1))]
	var g = model(b)
	var initial: Dictionary = g.snapshot()
	if not apply(g, {"type": "capture"}, "arm before reset"): return
	g.reset()
	check(g.snapshot() == initial and not g.snapshot().get("capture_armed", true) and g.snapshot().get("stored", {}).is_empty(), "reset clears armed state and restores fixture")
	if not apply(g, {"type": "capture"}, "arm before held reset"): return
	if not apply(g, {"type": "end_turn"}, "hold before reset"): return
	check(not g.snapshot().get("stored", {}).is_empty(), "held reset setup acquired ability")
	g.reset()
	check(g.snapshot() == initial and g.snapshot().get("action_points") == 3 and g.snapshot().get("player", {}).get("hp") == 20, "held reset restores AP, HP and all initial positions")
	b.player.hp = 1
	g = model(b)
	initial = g.snapshot()
	if not apply(g, {"type": "capture"}, "arm before terminal reset"): return
	if not apply(g, {"type": "end_turn"}, "lose before reset"): return
	check(g.snapshot().get("status") == "lost", "terminal reset setup lost")
	g.reset()
	check(g.snapshot() == initial and g.snapshot().get("status") == "playing" and not g.snapshot().get("capture_armed", true) and g.snapshot().get("stored", {}).is_empty(), "terminal reset restores clean initial state")

func test_shine_validation_and_combat_win() -> void:
	var b := F.board()
	b.objective = "defeat_all"
	b.erase("exit")
	b.enemies = [F.foe("source", [4, 3], [-1, 0], F.ability("bolt", 3, 1), 1)]
	var default_board: Dictionary = b.duplicate(true)
	default_board.erase("objective")
	var default_game = Encounter.new()
	default_game.configure(default_board, "R2")
	if not apply(default_game, {"type": "capture"}, "arm default combat objective"): return
	if not apply(default_game, {"type": "end_turn"}, "acquire for default objective"): return
	if not apply(default_game, {"type": "shine", "target": [4, 3]}, "defeat default objective source"): return
	check(default_game.snapshot().get("status") == "won", "unspecified objective defaults to defeat all")
	var g = model(b)
	reject(g, {"type": "shine", "target": [2, 3]}, "shine without ability")
	reject(g, {"type": "capture", "source": "source"}, "retired source selection")
	reject(g, {"type": "release", "target": [2, 3]}, "retired release command")
	if not apply(g, {"type": "capture"}, "arm combat skill"): return
	if not apply(g, {"type": "end_turn"}, "acquire combat skill"): return
	reject(g, {"type": "shine", "target": [5, 3]}, "shine outside range")
	reject(g, {"type": "shine", "target": [2, 4]}, "diagonal shine")
	reject(g, {"type": "shine", "target": [2, 3], "invert": true}, "unsupported invert")
	reject(g, {"type": "move", "to": "wrong"}, "malformed move")
	if not apply(g, {"type": "shine", "target": [4, 3]}, "shine final enemy"): return
	var s: Dictionary = g.snapshot()
	var wins := events(s, "win")
	check(s.get("status") == "won" and not wins.is_empty() and wins[0].get("objective") == "defeat_all", "last enemy defeated wins combat")
	check(types(s).find("death") < types(s).find("win") and s.get("stored", {}).is_empty(), "final death clears skill before terminal win")
	reject(g, {"type": "end_turn"}, "combat terminal rejects commands")
	b = F.board()
	b.walls = [[3, 3]]
	b.enemies = [F.foe("source", [1, 1], [0, 1], F.ability("bolt", 3, 1))]
	g = model(b)
	if not apply(g, {"type": "capture"}, "arm beside wall"): return
	if not apply(g, {"type": "end_turn"}, "capture beside wall"): return
	reject(g, {"type": "shine", "target": [4, 3]}, "wall blocks shine target")

func test_wide_shine_wall_and_push_once() -> void:
	var b := F.board()
	b.player.pos = [3, 3]
	b.walls = [[3, 2]]
	b.enemies = [
		F.foe("source", [5, 3], [-1, 0], wide_shove()),
		F.foe("side", [4, 4], [0, 1], F.ability("bolt", 1, 0)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm for wide wall test"): return
	if not apply(g, {"type": "end_turn"}, "capture wide wall test"): return
	check(enemy(g.snapshot(), "side").get("pos") == [3, 4], "enemy wide shove moves side target into shine lane")
	if not apply(g, {"type": "shine", "target": [4, 3]}, "shine with blocked lateral lane"): return
	var s: Dictionary = g.snapshot()
	var rays := events(s, "ray")
	check(not rays.is_empty() and same_cells(rays[0].get("cells", []), [[3, 3], [4, 3], [3, 4], [4, 4]]), "wide shine stops at wall only in blocked lane")
	check(enemy(s, "side").get("hp") == 8 and enemy(s, "side").get("pos") == [4, 4] and events(s, "displace").size() == 1, "wide shine hits and pushes side actor exactly once")

func test_displaced_source_footprint() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("source", [4, 3], [-1, 0], F.ability("shove", 3, 1, 0, true)),
		F.foe("target", [2, 3], [1, 0], F.ability("bolt", 1, 0)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm displacement source"): return
	if not apply(g, {"type": "end_turn"}, "acquire displacement source"): return
	if not apply(g, {"type": "shine", "target": [2, 3]}, "displace announced source"): return
	var s: Dictionary = g.snapshot()
	check(enemy(s, "target").get("pos") == [3, 3] and enemy(s, "target").get("dir") == [-1, 0], "displacement leaves freshly aimed direction locked")
	check(intention(s, "target").get("cells") == [[2, 3]], "announced footprint follows source displacement")

func test_burst_push_axes() -> void:
	var b := F.board()
	b.enemies = [
		F.foe("source", [1, 4], [0, -1], F.ability("burst", 2, 1, 3, true)),
		F.foe("tie", [3, 2], [1, 0], F.ability("bolt", 1, 0)),
		F.foe("xdom", [5, 4], [1, 0], F.ability("bolt", 1, 0)),
		F.foe("ydom", [4, 5], [1, 0], F.ability("bolt", 1, 0)),
	]
	var g = model(b)
	if not apply(g, {"type": "capture"}, "arm burst axis test"): return
	if not apply(g, {"type": "end_turn"}, "capture burst axis test"): return
	if not apply(g, {"type": "shine", "target": [3, 3]}, "shine burst axis test"): return
	var s: Dictionary = g.snapshot()
	var destinations := {}
	for event in events(s, "displace"): destinations[event.actor] = event.to
	for item in [["tie", [5, 2]], ["xdom", [6, 4]], ["ydom", [4, 6]]]:
		check(destinations.get(item[0], []) == item[1] and enemy(s, item[0]).get("pos") == item[1], "burst push axis destination: " + item[0])

func _initialize() -> void:
	var focused := OS.get_cmdline_user_args().has("--focus=armed-capture-shine")
	if not focused:
		test_budget_boundary()
		test_end_turn_intentions_and_reset()
		test_movement_and_aim()
		test_max_range_and_occupancy()
		test_wide_intention_geometry()
		test_wide_ranger_goal()
		test_reset_new_states()
		test_shine_validation_and_combat_win()
		test_wide_shine_wall_and_push_once()
		test_displaced_source_footprint()
		test_burst_push_axes()
	test_arm_and_contact()
	test_arm_persists_on_miss_and_budget()
	test_first_hit_and_full_enemy_effects()
	test_shine_persistence_and_source_death()
	test_source_death_and_full_burst()
	test_rearm_replaces_only_on_contact()
	test_dead_source_cannot_be_acquired()
	test_shine_borrowed_wide_endpoint()
	print("Checks: ", checks, "; failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
