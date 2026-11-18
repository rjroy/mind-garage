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

func board(movement: Dictionary, ability: Dictionary = {}) -> Dictionary:
	var b := F.board()
	var skill := F.ability("bolt", 1, 0) if ability.is_empty() else ability
	b.opponent_definitions = {
		"test": {
			"name": "Fixture opponent", "stats": {"max_hp": 10},
			"abilities": [skill.duplicate(true)], "decision": "fixed",
			"presentation": {"kit": "fixture"}, "movement": movement.duplicate(true),
		},
	}
	b.enemies = [{"id": "a", "definition": "test", "pos": [5, 3], "dir": [1, 0]}]
	return b

func model(b: Dictionary):
	var g = Encounter.new()
	g.configure(b.duplicate(true), "R2")
	return g

func enemy(s: Dictionary, id: String) -> Dictionary:
	for item in s.get("enemies", []):
		if item.get("id") == id: return item
	return {}

func intention(s: Dictionary, id: String) -> Dictionary:
	for item in s.get("intentions", []):
		if item.get("source") == id: return item
	return {}

func types(s: Dictionary) -> Array:
	var result := []
	for event in s.get("events", []): result.append(event.get("type"))
	return result

func apply(g, action: Dictionary, label: String) -> bool:
	var before: Dictionary = g.snapshot()
	var assessment: Dictionary = g.assess(action)
	check(g.snapshot() == before, label + ": assessment is pure")
	check(assessment.get("legal", false), label + ": legal")
	if not assessment.get("legal", false): return false
	var ok: bool = g.act(action)
	check(ok and g.snapshot() == assessment.get("preview", {}), label + ": preview equals commit")
	return ok

func test_seek_firing_line() -> void:
	var b := board({"pattern": "seek_firing_line", "budget": 3}, F.ability("bolt", 3, 0))
	var g = model(b)
	if not apply(g, {"type": "end_turn"}, "seek nearest firing line"): return
	check(enemy(g.snapshot(), "a").get("pos") == [4, 3], "seek stops at nearest usable firing cell, not adjacency")
	check(intention(g.snapshot(), "a").get("cells", []).has([1, 3]), "seek announces a footprint hitting player")
	if not apply(g, {"type": "end_turn"}, "seek holds firing line"): return
	check(enemy(g.snapshot(), "a").get("pos") == [4, 3], "seek stays when already able to hit")
	b.walls = [[3, 3]]
	b.enemies[0].pos = [4, 3]
	b.opponent_definitions.test.movement.budget = 5
	g = model(b)
	var twin = model(b)
	if not apply(g, {"type": "end_turn"}, "seek detour"): return
	if not apply(twin, {"type": "end_turn"}, "repeat seek detour"): return
	check(g.snapshot() == twin.snapshot() and enemy(g.snapshot(), "a").get("pos") != [4, 3], "blocked line produces deterministic detour")
	check(intention(g.snapshot(), "a").get("cells", []).has([1, 3]), "detour reaches usable firing line")
	# Enclosing the player leaves neither a firing position nor a chase goal.
	b = board({"pattern": "seek_firing_line", "budget": 1}, F.ability("bolt", 1, 0))
	b.player.pos = [1, 3]
	b.walls = [[0, 3], [1, 2], [1, 4], [2, 3]]
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "seek unreachable player"): return
	check(enemy(g.snapshot(), "a").get("pos") == [5, 3], "seek and chase hold when player is enclosed")

func test_multi_ability_movement_uses_next_selection() -> void:
	for pattern in ["seek_firing_line", "keep_max_range"]:
		var shove := F.ability("shove", 2, 1)
		var bolt := F.ability("bolt", 3, 2)
		var b := board({"pattern": pattern, "budget": 2}, shove)
		b.player.pos = [2, 3]
		b.enemies[0].pos = [4, 3]
		b.enemies[0].dir = [-1, 0]
		b.opponent_definitions.test.abilities = [shove, bolt]
		b.opponent_definitions.test.decision = "first_in_range"
		var g = model(b)
		var locked := intention(g.snapshot(), "a")
		check(locked.get("kind") == "shove" and locked.get("cells") == [[3, 3], [2, 3]], pattern + ": initial shove is committed")
		if not apply(g, {"type": "move", "to": [1, 3]}, pattern + ": move beyond shove range"): continue
		check(intention(g.snapshot(), "a") == locked and enemy(g.snapshot(), "a").get("ability") == shove, pattern + ": player movement does not change committed shove")
		if not apply(g, {"type": "end_turn"}, pattern + ": resolve and reposition"): continue
		var s: Dictionary = g.snapshot()
		var rays: Array = s.get("events", []).filter(func(event): return event.get("type") == "ray" and event.get("actor") == "a")
		check(rays.size() == 1 and rays[0].get("kind") == "shove" and rays[0].get("cells") == locked.get("cells") and s.get("player", {}).get("hp") == 20, pattern + ": old shove resolves unchanged and misses")
		check(enemy(s, "a").get("pos") == [4, 3], pattern + ": holds existing maximum-range bolt firing position")
		check(enemy(s, "a").get("ability") == bolt and intention(s, "a").get("kind") == "bolt" and intention(s, "a").get("cells", []).has([1, 3]), pattern + ": next announcement selects bolt and reaches current player")

func test_orbit() -> void:
	var b := board({"pattern": "orbit_player", "budget": 1, "radius": 2, "clockwise": true})
	b.player.pos = [2, 3]
	b.enemies[0].pos = [4, 3]
	var clockwise = model(b)
	if not apply(clockwise, {"type": "end_turn"}, "clockwise orbit"): return
	check(enemy(clockwise.snapshot(), "a").get("pos") == [4, 4], "clockwise orbit advances below eastern position")
	b.opponent_definitions.test.movement.clockwise = false
	var counter = model(b)
	if not apply(counter, {"type": "end_turn"}, "counterclockwise orbit"): return
	check(enemy(counter.snapshot(), "a").get("pos") == [4, 2], "counterclockwise orbit advances above eastern position")
	b.opponent_definitions.test.movement.erase("clockwise")
	b.opponent_definitions.test.movement.erase("radius")
	var defaults = model(b)
	if not apply(defaults, {"type": "end_turn"}, "default orbit"): return
	check(enemy(defaults.snapshot(), "a").get("pos") == [4, 4], "orbit defaults to radius two and clockwise")
	b.opponent_definitions.test.movement.clockwise = true
	b.walls = [[4, 4], [3, 3], [5, 3], [4, 2]]
	var blocked = model(b)
	if not apply(blocked, {"type": "end_turn"}, "blocked orbit"): return
	check(enemy(blocked.snapshot(), "a").get("pos") == [4, 3], "orbit stays when all steps are blocked")
	b.walls = []
	b.enemies[0].pos = [6, 3]
	var distant = model(b)
	if not apply(distant, {"type": "end_turn"}, "orbit closes distance"): return
	check(enemy(distant.snapshot(), "a").get("pos") == [5, 3], "orbit closes radial error outside band")
	b.enemies[0].pos = [4, 3]
	b.enemies.append(F.foe("blocker", [4, 4], [1, 0], F.ability("bolt", 1, 0)))
	var occupied = model(b)
	if not apply(occupied, {"type": "end_turn"}, "occupied orbit"): return
	check(enemy(occupied.snapshot(), "a").get("pos") != [4, 4], "orbit never enters an occupied cell")

func test_patrol() -> void:
	var b := board({"pattern": "patrol", "budget": 1, "route": [[0, 0], [0, 2]]})
	b.enemies[0].pos = [4, 1]
	b.enemies.append({"id": "b", "definition": "test", "pos": [6, 1], "dir": [1, 0]})
	var g = model(b)
	var initial: Dictionary = g.snapshot()
	for step in [[4, 2], [4, 3], [4, 2], [4, 1]]:
		if not apply(g, {"type": "end_turn"}, "patrol route step"): return
		check(enemy(g.snapshot(), "a").get("pos") == step, "patrol follows and loops relative waypoints at %s" % [step])
	check(enemy(g.snapshot(), "b").get("pos") == [6, 1], "second patrol uses its own spawn-relative route")
	g.reset()
	check(g.snapshot() == initial, "reset restores patrol state")
	if not apply(g, {"type": "end_turn"}, "patrol after reset"): return
	check(enemy(g.snapshot(), "a").get("pos") == [4, 2], "reset restarts patrol route")
	b.walls = [[4, 3]]
	b.enemies.resize(1)
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "unreachable patrol waypoint"): return
	check(enemy(g.snapshot(), "a").get("pos") == [4, 1], "patrol holds rather than advancing past unreachable waypoint")
	b.walls = []
	b.enemies.append(F.foe("blocker", [4, 3], [1, 0], F.ability("bolt", 1, 0)))
	g = model(b)
	if not apply(g, {"type": "end_turn"}, "occupied patrol waypoint"): return
	check(enemy(g.snapshot(), "a").get("pos") == [4, 1], "patrol holds at occupied waypoint")

func test_pull() -> void:
	var pull := F.ability("pull", 3, 2)
	var b := board({"pattern": "chase_player", "budget": 0}, pull)
	b.enemies[0].pos = [4, 3]
	b.enemies[0].dir = [-1, 0]
	var g = model(b)
	check(intention(g.snapshot(), "a").get("cells") == [[3, 3], [2, 3], [1, 3]], "pull announces its cardinal ray")
	if not apply(g, {"type": "capture"}, "arm pull"): return
	if not apply(g, {"type": "end_turn"}, "enemy pull"): return
	var s: Dictionary = g.snapshot()
	check(s.get("player", {}).get("hp") == 18 and s.get("player", {}).get("pos") == [2, 3], "pull damages then moves surviving player toward enemy")
	check(s.get("stored", {}).get("source") == "a" and s.get("stored", {}).get("ability") == pull, "capture stores actual pull source and payload")
	var order := types(s)
	check(order.find("damage") >= 0 and order.find("displace") > order.find("damage") and order.find("capture") > order.find("displace"), "damage and pull precede acquisition")
	if not apply(g, {"type": "shine", "target": [4, 3]}, "shine borrowed pull"): return
	s = g.snapshot()
	check(enemy(s, "a").get("hp") == 8 and enemy(s, "a").get("pos") == [3, 3], "shine damages and pulls enemy toward player, not original source")
	check(s.get("stored", {}).get("source") == "a", "surviving source remains linked after shine")
	b.enemies[0].pos = [2, 3]
	g = model(b)
	if not apply(g, {"type": "capture"}, "arm adjacent pull"): return
	if not apply(g, {"type": "end_turn"}, "adjacent pull"): return
	s = g.snapshot()
	check(s.get("player", {}).get("pos") == [1, 3] and s.get("player", {}).get("hp") == 18 and s.get("stored", {}).get("source") == "a", "occupied source cell blocks pull but not damage or capture")
	b.enemies[0].pos = [4, 3]
	g = model(b)
	var locked := intention(g.snapshot(), "a")
	if not apply(g, {"type": "capture"}, "arm before leaving pull"): return
	if not apply(g, {"type": "move", "to": [1, 2]}, "leave pull line"): return
	check(intention(g.snapshot(), "a") == locked, "pull footprint remains locked after player moves")
	if not apply(g, {"type": "end_turn"}, "missed pull"): return
	s = g.snapshot()
	check(s.get("player", {}).get("hp") == 20 and s.get("player", {}).get("pos") == [1, 2] and s.get("capture_armed", false), "missed pull causes no damage or displacement and leaves capture armed")
	b.player.hp = 2
	g = model(b)
	if not apply(g, {"type": "capture"}, "arm lethal pull"): return
	if not apply(g, {"type": "end_turn"}, "lethal pull"): return
	s = g.snapshot()
	check(s.get("status") == "lost" and s.get("player", {}).get("pos") == [1, 3] and s.get("stored", {}).is_empty(), "lethal pull does not displace or acquire")

func _initialize() -> void:
	test_seek_firing_line()
	test_multi_ability_movement_uses_next_selection()
	test_orbit()
	test_patrol()
	test_pull()
	print("Checks: ", checks, "; failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
