extends RefCounted

var _fixture: Dictionary = {}
var _state: Dictionary = {}


func configure(fixture: Dictionary, variant: String) -> void:
	assert(variant == "R2", "Only the revision 02 baseline is supported.")
	_fixture = fixture.duplicate(true)
	_validate_opponents()
	reset()


func _validate_opponents() -> void:
	var definitions: Dictionary = _fixture.get("opponent_definitions", {})
	var ids := {}
	for enemy in _fixture.enemies:
		assert(enemy.get("id") is String and not enemy.id.is_empty() and enemy.id != "player", "Enemy IDs must be nonempty and distinct from player.")
		assert(not ids.has(enemy.id), "Enemy IDs must be unique.")
		ids[enemy.id] = true
		assert(_cell(enemy.get("pos")) and _cell(enemy.get("dir")), "Enemy placement requires a position and direction.")
		if not enemy.has("definition"):
			assert(enemy.get("ability") is Dictionary and enemy.get("hp") is int, "Flattened enemies require HP and an ability.")
			continue
		assert(enemy.definition is String and definitions.has(enemy.definition), "Enemy references an unknown definition.")
		var definition: Dictionary = definitions[enemy.definition]
		assert(definition.get("name") is String and not definition.name.is_empty(), "Opponent definition requires a name.")
		assert(definition.get("stats") is Dictionary and definition.stats.get("max_hp") is int and definition.stats.max_hp > 0, "Opponent definition requires positive max HP.")
		assert(definition.get("abilities") is Array and not definition.abilities.is_empty(), "Opponent definition requires abilities.")
		assert(definition.get("decision") in ["fixed", "first_in_range"], "Unknown opponent decision.")
		assert(definition.get("presentation") is Dictionary and definition.presentation.get("kit") is String, "Opponent definition requires a presentation kit.")
		if definition.has("movement"):
			assert(definition.movement is Dictionary and definition.movement.get("pattern") in ["chase_player", "keep_max_range", "seek_firing_line", "orbit_player", "patrol"] and definition.movement.get("budget") is int and definition.movement.budget >= 0, "Invalid opponent movement.")
			var movement: Dictionary = definition.movement
			if movement.pattern == "orbit_player":
				assert(movement.get("radius", 2) is int and movement.get("radius", 2) > 0 and movement.get("clockwise", true) is bool, "Invalid orbit configuration.")
			if movement.pattern == "patrol":
				assert(movement.get("route") is Array and movement.route.size() >= 2 and movement.route[0] == [0, 0], "Patrol requires a spawn-relative route.")
				for offset in movement.route:
					assert(_cell(offset), "Patrol waypoints must be integer offsets.")
		for ability in definition.abilities:
			assert(ability is Dictionary and ability.get("kind") in ["bolt", "shove", "burst", "swap", "pull"] and ability.get("range") is int and ability.range > 0 and ability.get("damage") is int and ability.get("radius") is int and ability.get("push") is bool and not (ability.kind == "pull" and ability.push), "Invalid opponent ability.")


func reset() -> void:
	_state = _fixture.duplicate(true)
	_state.erase("opponent_definitions")
	for enemy in _state.enemies:
		if enemy.has("definition"):
			var definition: Dictionary = _fixture.opponent_definitions[enemy.definition]
			enemy["name"] = definition.name
			enemy["presentation"] = definition.presentation.duplicate(true)
			enemy["hp"] = definition.stats.max_hp
			enemy.erase("movement_pattern")
			enemy.erase("movement_budget")
			if definition.has("movement"):
				enemy["movement_pattern"] = definition.movement.pattern
				enemy["movement_budget"] = definition.movement.budget
				if definition.movement.pattern == "orbit_player":
					enemy["orbit_radius"] = definition.movement.get("radius", 2)
					enemy["orbit_clockwise"] = definition.movement.get("clockwise", true)
				elif definition.movement.pattern == "patrol":
					enemy["patrol_spawn"] = enemy.pos.duplicate()
					enemy["patrol_route"] = definition.movement.route.duplicate(true)
					enemy["patrol_next"] = 1
			enemy["ability"] = definition.abilities[0].duplicate(true)
			enemy["kind"] = enemy.ability.kind
	_state["objective"] = "defeat_all"
	_state.merge({
		"turn": 1, "status": "playing", "variant": "R2",
		"action_points": _fixture.rules.actions,
		"capture_armed": false, "stored": {},
		"intentions": [], "events": [],
	}, true)
	for enemy in _state.enemies:
		_announce(enemy)
	_refresh_footprints()


func snapshot() -> Dictionary:
	return _state.duplicate(true)


func assess(action: Dictionary) -> Dictionary:
	var reason := _rejection(action)
	if not reason.is_empty():
		return {"legal": false, "reason": reason, "preview": {}}
	var preview = get_script().new()
	preview._fixture = _fixture
	preview._state = _state.duplicate(true)
	preview._apply(action)
	return {"legal": true, "reason": "", "preview": preview.snapshot()}


func act(action: Dictionary) -> bool:
	if not _rejection(action).is_empty():
		return false
	_apply(action)
	return true


func _cell(value: Variant) -> bool:
	return value is Array and value.size() == 2 and value[0] is int and value[1] is int


func _add(a: Array, b: Array) -> Array:
	return [a[0] + b[0], a[1] + b[1]]


func _distance(a: Array, b: Array) -> int:
	return absi(a[0] - b[0]) + absi(a[1] - b[1])


func _walkable(pos: Array) -> bool:
	return pos[0] >= 0 and pos[1] >= 0 and pos[0] < _state.width and pos[1] < _state.height and not _state.walls.has(pos)


func _occupant(pos: Array) -> String:
	if _state.player.hp > 0 and _state.player.pos == pos:
		return "player"
	for enemy in _state.enemies:
		if enemy.pos == pos:
			return enemy.id
	return ""


func _enemy(id: String) -> Dictionary:
	for enemy in _state.enemies:
		if enemy.id == id:
			return enemy
	return {}


func _ray(origin: Array, direction: Array, length: int) -> Array:
	return _front(origin, direction, length, 1)


func _front(origin: Array, direction: Array, length: int, width: int) -> Array:
	var cells := []
	var blocked := {}
	var half := int(width / 2)
	var lateral := [-direction[1], direction[0]]
	for depth in range(1, length + 1):
		for offset in range(-half, half + 1):
			if blocked.has(offset):
				continue
			var pos := [
				origin[0] + direction[0] * depth + lateral[0] * offset,
				origin[1] + direction[1] * depth + lateral[1] * offset,
			]
			if not _walkable(pos):
				blocked[offset] = true
			else:
				cells.append(pos)
	return cells


func _area(center: Array, radius: int) -> Array:
	var cells := []
	for y in range(maxi(0, center[1] - radius), mini(_state.height, center[1] + radius + 1)):
		for x in range(maxi(0, center[0] - radius), mini(_state.width, center[0] + radius + 1)):
			var pos := [x, y]
			if _distance(center, pos) <= radius and _walkable(pos):
				cells.append(pos)
	return cells


func _target_ray(origin: Array, target: Array, reach: int, width: int = 1) -> Array:
	var distance := _distance(origin, target)
	if distance < 1 or distance > reach or (origin[0] != target[0] and origin[1] != target[1]):
		return []
	var direction := [signi(target[0] - origin[0]), signi(target[1] - origin[1])]
	var cells := _ray(origin, direction, distance)
	return _front(origin, direction, distance, width) if cells.size() == distance else []


func _enemy_footprint(enemy: Dictionary) -> Array:
	var ability: Dictionary = enemy.ability
	if ability.kind == "swap":
		var target: Array = enemy.get("announced_target", [])
		if _cell(target) and not _target_ray(enemy.pos, target, ability.range).is_empty():
			return [target.duplicate()]
		return []
	var width: int = ability.get("width", 1) if ability.kind == "shove" else 1
	var cells := _front(enemy.pos, enemy.dir, ability.range, width)
	if ability.kind == "burst" and not cells.is_empty():
		return _area(cells.back(), ability.radius)
	return cells


func _refresh_footprints() -> void:
	_state.intentions = []
	if _state.status != "playing":
		return
	for enemy in _state.enemies:
		if enemy.ability.kind == "swap" and enemy.get("announced_target", []).is_empty():
			continue
		var intention := {"source": enemy.id, "kind": enemy.ability.kind, "cells": _enemy_footprint(enemy)}
		if enemy.ability.kind == "swap":
			intention["from"] = enemy.pos.duplicate()
			intention["target"] = enemy.get("announced_target", []).duplicate()
		_state.intentions.append(intention)


func _announce_swap(enemy: Dictionary) -> void:
	if enemy.ability.kind != "swap":
		return
	var target: Array = _state.player.pos
	enemy["announced_target"] = target.duplicate() if not _target_ray(enemy.pos, target, enemy.ability.range).is_empty() else []


func _selected_ability(enemy: Dictionary) -> Dictionary:
	if not enemy.has("definition"):
		return enemy.ability
	var definition: Dictionary = _fixture.opponent_definitions[enemy.definition]
	if definition.decision == "first_in_range":
		for ability in definition.abilities:
			var candidate := enemy.duplicate(true)
			candidate.ability = ability
			candidate["announced_target"] = _state.player.pos.duplicate()
			if _enemy_footprint(candidate).has(_state.player.pos):
				return ability
	return definition.abilities[0]


func _announce(enemy: Dictionary) -> void:
	if enemy.has("definition"):
		enemy.ability = _selected_ability(enemy).duplicate(true)
		enemy.kind = enemy.ability.kind
	enemy.erase("announced_target")
	_announce_swap(enemy)


func _keys_allowed(action: Dictionary, allowed: Array) -> bool:
	for key in action:
		if not allowed.has(key):
			return false
	return true


func _rejection(action: Dictionary) -> String:
	if _state.is_empty() or _state.status != "playing":
		return "The run is not active."
	if not action.has("type") or not action.type is String:
		return "An action type is required."
	match action.type:
		"move":
			if not _keys_allowed(action, ["type", "to"]) or not _cell(action.get("to")):
				return "Move requires a destination cell."
			if _state.action_points <= 0:
				return "No action points remain."
			if _distance(_state.player.pos, action.to) != 1 or not _walkable(action.to) or not _occupant(action.to).is_empty():
				return "Destination must be a free adjacent cell."
		"capture":
			if not _keys_allowed(action, ["type"]):
				return "Unexpected capture field."
			if _state.capture_armed:
				return "Capture is already armed."
			if _state.action_points <= 0:
				return "No action points remain."
		"shine":
			return _shine_rejection(action)
		"end_turn":
			if not _keys_allowed(action, ["type"]):
				return "Unexpected action field."
		_:
			return "Unknown action."
	return ""


func _shine_rejection(action: Dictionary) -> String:
	if not _keys_allowed(action, ["type", "target"]) or not _cell(action.get("target")):
		return "Shine requires a target cell and valid fields."
	if _state.stored.is_empty():
		return "There is no stored action."
	if _state.action_points <= 0:
		return "No action points remain."
	var ability: Dictionary = _state.stored.ability
	if _target_ray(_state.player.pos, action.target, ability.range).is_empty():
		return "Target is outside an unobstructed ability range."
	if ability.kind == "swap" and _enemy(_occupant(action.target)).is_empty():
		return "Swap requires an enemy target."
	return ""


func _event(type: String, details: Dictionary = {}) -> void:
	var event := {"type": type}
	event.merge(details)
	_state.events.append(event)


func _apply(action: Dictionary) -> void:
	_state.events = []
	match action.type:
		"move":
			var previous: Array = _state.player.pos
			_state.player.pos = action.to.duplicate()
			_state.action_points -= 1
			_event("move", {"actor": "player", "from": previous.duplicate(), "to": action.to.duplicate()})
		"capture":
			_state.action_points -= 1
			_state.capture_armed = true
			_event("capture_armed")
		"shine": _shine(action)
	if _state.status == "playing":
		_check_objective()
	if action.type == "end_turn" and _state.status == "playing":
		_end_turn()
	_refresh_footprints()


func _shine(action: Dictionary) -> void:
	var held: Dictionary = _state.stored
	_state.action_points -= 1
	var ability: Dictionary = held.ability
	var origin: Array = _state.player.pos.duplicate()
	if ability.kind == "swap":
		_event("shine", {"source": held.source, "kind": ability.kind, "target": action.target.duplicate()})
		_resolve_swap("player", ability, action.target)
		return
	var center: Array = action.target if ability.kind == "burst" else origin
	var cells: Array
	if ability.kind == "burst":
		cells = _area(center, ability.radius)
	else:
		var width: int = ability.get("width", 1) if ability.kind == "shove" else 1
		cells = _target_ray(origin, action.target, ability.range, width)
	_event("shine", {"source": held.source, "kind": ability.kind, "target": action.target.duplicate()})
	_resolve_ability("player", ability, cells, center)


func _end_turn() -> void:
	var ids := []
	for enemy in _state.enemies:
		ids.append(enemy.id)
	for id in ids:
		if _state.status != "playing":
			return
		var enemy := _enemy(id)
		if enemy.is_empty():
			continue
		var ability: Dictionary = enemy.ability
		if ability.kind == "swap":
			_resolve_swap(id, ability, enemy.get("announced_target", []))
			continue
		var ray := _ray(enemy.pos, enemy.dir, ability.range)
		var center: Array = ray.back() if ability.kind == "burst" and not ray.is_empty() else enemy.pos
		_resolve_ability(id, ability, _enemy_footprint(enemy), center)
	if _state.status != "playing":
		return
	_check_objective()
	if _state.status != "playing":
		return
	for enemy in _state.enemies:
		_move_enemy(enemy)
	for enemy in _state.enemies:
		enemy.dir = _aim(enemy.pos)
		_announce(enemy)
	_state.turn += 1
	_state.action_points = _state.rules.actions
	_event("turn", {"number": _state.turn})
	_check_objective()


func _check_objective() -> void:
	if _state.enemies.is_empty():
		_state.status = "won"
		_event("win", {"objective": _state.objective})


func _aim(origin: Array) -> Array:
	var dx: int = _state.player.pos[0] - origin[0]
	var dy: int = _state.player.pos[1] - origin[1]
	return [signi(dx), 0] if absi(dx) >= absi(dy) else [0, signi(dy)]


func _reachable_paths(enemy: Dictionary) -> Array:
	# Breadth-first traversal fixes both shortest paths and tie order.
	var start: Array = enemy.pos.duplicate()
	var queue: Array = [{"pos": start, "path": []}]
	var visited := [start]
	var index := 0
	while index < queue.size():
		var entry: Dictionary = queue[index]
		index += 1
		var pos: Array = entry.pos
		for direction in [[-1, 0], [0, -1], [0, 1], [1, 0]]:
			var next := _add(pos, direction)
			if visited.has(next) or not _walkable(next) or not _occupant(next).is_empty():
				continue
			visited.append(next)
			var path: Array = entry.path.duplicate()
			path.append(next)
			queue.append({"pos": next, "path": path})
	return queue


func _prospective_hit(enemy: Dictionary, pos: Array) -> bool:
	var candidate := enemy.duplicate(true)
	candidate.pos = pos
	candidate.dir = _aim(pos)
	candidate.ability = _selected_ability(candidate)
	if candidate.ability.kind == "swap":
		candidate["announced_target"] = _state.player.pos.duplicate()
	return _enemy_footprint(candidate).has(_state.player.pos)


func _move_enemy(enemy: Dictionary) -> void:
	var pattern: String = enemy.get("movement_pattern", "")
	if pattern not in ["chase_player", "keep_max_range", "seek_firing_line", "orbit_player", "patrol"]:
		return
	var budget: int = maxi(0, enemy.get("movement_budget", 1))
	if budget == 0:
		return
	if pattern == "orbit_player":
		_orbit_enemy(enemy, budget)
		return
	# Occupancy is evaluated after all earlier movers have settled.
	var paths := _reachable_paths(enemy)
	var best_path: Array = []
	var best_range := -1
	var found := false
	var waypoint: Array = []
	if pattern == "patrol":
		waypoint = _add(enemy.patrol_spawn, enemy.patrol_route[enemy.patrol_next])
	for entry in paths:
		var pos: Array = entry.pos
		if pattern == "patrol":
			if pos == waypoint:
				best_path = entry.path
				found = true
				break
		elif pattern == "chase_player":
			if _distance(pos, _state.player.pos) == 1:
				best_path = entry.path
				break
		elif _prospective_hit(enemy, pos):
			if pattern == "seek_firing_line":
				best_path = entry.path
				found = true
				break
			var distance := _distance(pos, _state.player.pos)
			if distance > best_range:
				best_range = distance
				best_path = entry.path
	if pattern == "seek_firing_line" and not found:
		for entry in paths:
			if _distance(entry.pos, _state.player.pos) == 1:
				best_path = entry.path
				break
	for step in range(mini(budget, best_path.size())):
		var previous: Array = enemy.pos.duplicate()
		enemy.pos = best_path[step].duplicate()
		_event("move", {"actor": enemy.id, "from": previous, "to": enemy.pos.duplicate()})
	if pattern == "patrol" and found and enemy.pos == waypoint:
		enemy.patrol_next = (enemy.patrol_next + 1) % enemy.patrol_route.size()


func _orbit_enemy(enemy: Dictionary, budget: int) -> void:
	var radius: int = enemy.get("orbit_radius", 2)
	var rotation: int = 1 if enemy.get("orbit_clockwise", true) else -1
	var visited := [enemy.pos.duplicate()]
	for step in range(budget):
		var origin: Array = enemy.pos
		var player: Array = _state.player.pos
		var distance := _distance(origin, player)
		var best: Array = []
		var best_error := 2147483647
		for direction in [[-1, 0], [0, -1], [0, 1], [1, 0]]:
			var next := _add(origin, direction)
			if visited.has(next) or not _walkable(next) or not _occupant(next).is_empty():
				continue
			var next_distance := _distance(next, player)
			var error := absi(next_distance - radius)
			if absi(distance - radius) > 1:
				if error >= absi(distance - radius):
					continue
			else:
				var cross: int = (origin[0] - player[0]) * direction[1] - (origin[1] - player[1]) * direction[0]
				if error > 1 or cross * rotation <= 0:
					continue
			if error < best_error:
				best_error = error
				best = next
		if best.is_empty():
			break
		var previous: Array = enemy.pos.duplicate()
		enemy.pos = best
		visited.append(best)
		_event("move", {"actor": enemy.id, "from": previous, "to": best.duplicate()})


func _targets(actor_id: String, cells: Array, is_area: bool) -> Array:
	var targets := []
	if is_area:
		if cells.has(_state.player.pos) and actor_id != "player":
			targets.append("player")
		for enemy in _state.enemies:
			if enemy.id != actor_id and cells.has(enemy.pos):
				targets.append(enemy.id)
	else:
		for cell in cells:
			var id := _occupant(cell)
			if not id.is_empty() and id != actor_id:
				targets.append(id)
	return targets


func _resolve_swap(actor_id: String, ability: Dictionary, target: Array) -> void:
	if not _cell(target):
		return
	var actor: Dictionary = _state.player if actor_id == "player" else _enemy(actor_id)
	if actor.is_empty():
		return
	var origin: Array = actor.pos.duplicate()
	var valid := not _target_ray(origin, target, ability.range).is_empty()
	_event("mask", {
		"actor": actor_id, "kind": "swap", "cells": [target.duplicate()] if valid else [],
		"from": origin.duplicate(), "target": target.duplicate(),
	})
	if not valid:
		return
	var other_id := _occupant(target)
	if other_id.is_empty() or other_id == actor_id:
		return
	var other: Dictionary = _state.player if other_id == "player" else _enemy(other_id)
	actor.pos = target.duplicate()
	other.pos = origin.duplicate()
	_event("swap", {"actor": actor_id, "other": other_id, "from": origin, "to": target.duplicate()})
	_damage(other_id, ability.damage)
	_finish_ability(actor_id, ability, other_id == "player" and actor_id != "player")


func _resolve_ability(actor_id: String, ability: Dictionary, cells: Array, center: Array) -> void:
	var is_area: bool = ability.kind == "burst"
	_event("area" if is_area else "ray", {"actor": actor_id, "kind": ability.kind, "cells": cells.duplicate(true)})
	var targets := _targets(actor_id, cells, is_area)
	var player_hit := false
	for id in targets:
		if _state.status != "playing":
			break
		if id == "player" and actor_id != "player":
			player_hit = true
		_damage(id, ability.damage)
		if _state.status != "playing":
			break
		var actor: Dictionary = _state.player if id == "player" else _enemy(id)
		if not actor.is_empty():
			if ability.kind == "pull":
				_displace(id, actor, center, true)
			elif ability.push:
				_displace(id, actor, center)
	_finish_ability(actor_id, ability, player_hit)


func _finish_ability(actor_id: String, ability: Dictionary, player_hit: bool) -> void:
	# A source can die partway through an area effect. Finish the entire effect
	# before invalidating its held ability or acquiring a new one.
	if not _state.stored.is_empty() and _enemy(_state.stored.source).is_empty():
		var lost_source: String = _state.stored.source
		_state.stored = {}
		_event("ability_lost", {"source": lost_source, "reason": "source_dead"})
	if player_hit and _state.capture_armed and _state.status == "playing":
		var source := _enemy(actor_id)
		if not source.is_empty():
			_state.stored = {
				"source": actor_id, "ability": ability.duplicate(true), "dir": source.dir.duplicate(),
				"captured_turn": _state.turn,
			}
			_state.capture_armed = false
			_event("capture", {"source": actor_id, "kind": ability.kind})


func _damage(id: String, amount: int) -> void:
	var actor: Dictionary = _state.player if id == "player" else _enemy(id)
	actor.hp = maxi(0, actor.hp - amount)
	_event("damage", {"actor": id, "amount": amount, "hp": actor.hp})
	if actor.hp == 0:
		_event("death", {"actor": id})
		if id == "player":
			_state.status = "lost"
			_event("loss")
		else:
			_state.enemies.erase(actor)


func _displace(id: String, actor: Dictionary, center: Array, toward: bool = false) -> void:
	var dx: int = actor.pos[0] - center[0]
	var dy: int = actor.pos[1] - center[1]
	# Off-axis area pushes choose the dominant axis, with horizontal winning ties.
	var direction := [signi(dx), 0] if absi(dx) >= absi(dy) else [0, signi(dy)]
	if toward:
		direction = [-direction[0], -direction[1]]
	if direction == [0, 0]:
		return
	var destination := _add(actor.pos, direction)
	if _walkable(destination) and _occupant(destination).is_empty():
		var previous: Array = actor.pos
		actor.pos = destination
		_event("displace", {"actor": id, "from": previous.duplicate(), "to": destination.duplicate()})
