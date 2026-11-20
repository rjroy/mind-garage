extends "replay.gd"
## Baseline-only bounded deterministic policy exploration; actions are frozen to
## corpus.json afterwards. Candidate replay never depends on these private seams.
const LIMIT := 64
const PROBES = [
	{"type": "shine", "target": [0, 0]},
	{"type": "move", "to": [-1, 0]},
	{"type": "capture", "source": "retired-target"},
]

func enemy(state: Dictionary, id: String) -> Dictionary:
	for value in state.enemies:
		if value.id == id:
			return value
	return {}

func clone_at(game, pos: Array):
	var copy = model(fixture(_current_fixture))
	copy._state = game.snapshot()
	copy._state.player.pos = pos.duplicate()
	copy._state.action_points = 3
	return copy

var _current_fixture := ""

func reachable(state: Dictionary) -> Array:
	var queue := [{"pos": state.player.pos, "path": []}]
	var visited := [state.player.pos]
	var index := 0
	while index < queue.size():
		var entry: Dictionary = queue[index]
		index += 1
		for direction in [[-1, 0], [0, -1], [0, 1], [1, 0]]:
			var pos := [entry.pos[0] + direction[0], entry.pos[1] + direction[1]]
			if visited.has(pos) or pos[0] < 0 or pos[1] < 0 or pos[0] >= state.width or pos[1] >= state.height or state.walls.has(pos):
				continue
			var occupied := false
			for value in state.enemies:
				if value.pos == pos:
					occupied = true
			if occupied:
				continue
			visited.append(pos)
			var path: Array = entry.path.duplicate()
			path.append(pos)
			queue.append({"pos": pos, "path": path})
	return queue

func damage_score(preview: Dictionary) -> int:
	var score := 0
	for event in preview.events:
		if event.type == "damage" and event.actor != "player":
			score += event.amount * 10
		if event.type == "death" and event.actor != "player":
			score += 20
		if event.type == "win":
			score += 100
	return score

func best_shine(game) -> Dictionary:
	var state: Dictionary = game.snapshot()
	var best := {}
	var score := 0
	if state.stored.is_empty() or state.action_points == 0:
		return best
	for y in range(state.height):
		for x in range(state.width):
			var action := {"type": "shine", "target": [x, y]}
			var verdict: Dictionary = game.assess(action)
			if not verdict.legal:
				continue
			var candidate := damage_score(verdict.preview)
			if candidate > score:
				score = candidate
				best = action
	return best

func toward_source(game, target_id: String) -> Dictionary:
	var state: Dictionary = game.snapshot()
	var target := enemy(state, target_id)
	if target.is_empty() and not state.enemies.is_empty():
		target = state.enemies[0]
	if target.is_empty():
		return {"type": "end_turn"}
	var distance: int = absi(state.player.pos[0] - target.pos[0]) + absi(state.player.pos[1] - target.pos[1])
	# Pause to let the source re-aim/lock rather than orbiting a locked miss.
	if distance <= target.ability.range:
		return {"type": "end_turn"}
	for entry in reachable(state):
		var candidate: int = absi(entry.pos[0] - target.pos[0]) + absi(entry.pos[1] - target.pos[1])
		if candidate < distance and not entry.path.is_empty():
			return {"type": "move", "to": entry.path[0]}
	return {"type": "end_turn"}

func capture_target(game, target: String) -> Dictionary:
	var state: Dictionary = game.snapshot()
	var verdict: Dictionary = game.assess({"type": "end_turn"})
	if verdict.legal and verdict.preview.stored.get("source", "") == target:
		return {"type": "end_turn"}
	for entry in reachable(state):
		if entry.path.is_empty():
			continue
		var copy = clone_at(game, entry.pos)
		var result: Dictionary = copy.assess({"type": "end_turn"})
		if result.legal and result.preview.stored.get("source", "") == target:
			return {"type": "move", "to": entry.path[0]}
	return toward_source(game, target)

func hunt(game) -> Dictionary:
	var state: Dictionary = game.snapshot()
	if state.enemies.is_empty():
		return {"type": "end_turn"}
	var shine := best_shine(game)
	if not shine.is_empty():
		return shine
	if state.stored.is_empty():
		if not state.capture_armed:
			return {"type": "capture"}
		var end: Dictionary = game.assess({"type": "end_turn"})
		if not end.preview.stored.is_empty():
			return {"type": "end_turn"}
		return capture_target(game, state.enemies[0].id)
	for entry in reachable(state):
		if entry.path.is_empty():
			continue
		var copy = clone_at(game, entry.pos)
		if not best_shine(copy).is_empty():
			return {"type": "move", "to": entry.path[0]}
	return toward_source(game, state.stored.source)

func episode(id: String, policy: String, target: String = "") -> Dictionary:
	_current_fixture = id
	var game = model(fixture(id))
	var actions := PROBES.duplicate(true)
	for action in actions:
		game.act(action)
	for index in range(LIMIT):
		var state: Dictionary = game.snapshot()
		if state.status != "playing":
			break
		var action: Dictionary
		if state.action_points == 0:
			for probe in [
				{"type": "move", "to": [state.player.pos[0] + 1, state.player.pos[1]]},
				{"type": "capture"},
				{"type": "shine", "target": state.player.pos.duplicate()},
			]:
				check(not game.act(probe), id + ": generated zero-AP rejection")
				actions.append(probe)
			action = {"type": "end_turn"}
		elif policy == "wait":
			action = {"type": "capture"} if not state.capture_armed and state.stored.is_empty() else {"type": "end_turn"}
		elif not target.is_empty() and state.stored.get("source", "") != target and not enemy(state, target).is_empty():
			action = {"type": "capture"} if not state.capture_armed else capture_target(game, target)
		else:
			action = hunt(game)
		check(game.act(action), id + "/" + policy + "/" + target + ": generated legal action " + str(index))
		actions.append(action)
	if game.snapshot().status != "playing":
		actions.append({"type": "end_turn"})
		actions.append({"type": "capture"})
		actions.append({"type": "shine", "target": [0, 0]})
	actions.append({"type": "$reset"})
	return {"id": id + "/" + policy + ("/" + target if not target.is_empty() else ""), "fixture": id, "policy": policy, "actions": actions}

func _initialize() -> void:
	var episodes := []
	for id in IDS:
		episodes.append(episode(id, "wait"))
		episodes.append(episode(id, "hunt"))
		for value in fixture(id).enemies:
			episodes.append(episode(id, "target", value.id))
	var unique := []
	var seen := {}
	for value in episodes:
		var key: String = value.fixture + JSON.stringify(value.actions)
		if not seen.has(key):
			seen[key] = true
			unique.append(value)
	episodes = unique
	var output := option("out")
	if output.is_empty():
		printerr("Required: -- --out=PATH")
		quit(2)
		return
	write_json(output, {
		"schema": "borrowed-turns-actions-v1",
		"source_commit": "6def00f9027cfc481ac2840abc376fbb07dea146",
		"policy_limit_per_episode": LIMIT,
		"episodes": episodes,
	})
	print("Corpus: ", episodes.size(), " episodes; ", checks, " checks; ", failures.size(), " failures; ", output)
	quit(0 if failures.is_empty() else 1)
