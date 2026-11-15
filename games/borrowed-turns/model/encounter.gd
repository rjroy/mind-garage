extends RefCounted

var _fixture: Dictionary = {}
var _state: Dictionary = {}


func configure(fixture: Dictionary, variant: String) -> void:
	assert(variant == "R2", "Only the revision 02 baseline is supported.")
	_fixture = fixture.duplicate(true)
	reset()


func reset() -> void:
	_state = _fixture.duplicate(true)
	_state.merge({
		"turn": 1, "status": "playing", "variant": "R2",
		"action_points": _fixture.rules.actions,
		"movement_points": _fixture.rules.movement, "cancelled": [], "stored": {},
		"intentions": [], "backlash_footprint": {}, "events": [],
	}, true)
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
	var cells := []
	var pos := origin
	for step in range(length):
		pos = _add(pos, direction)
		if not _walkable(pos):
			break
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


func _target_ray(origin: Array, target: Array, reach: int) -> Array:
	var distance := _distance(origin, target)
	if distance < 1 or distance > reach or (origin[0] != target[0] and origin[1] != target[1]):
		return []
	var direction := [signi(target[0] - origin[0]), signi(target[1] - origin[1])]
	var cells := _ray(origin, direction, distance)
	return cells if cells.size() == distance else []


func _enemy_footprint(enemy: Dictionary) -> Array:
	var ability: Dictionary = enemy.ability
	var cells := _ray(enemy.pos, enemy.dir, ability.range)
	if ability.kind == "burst" and not cells.is_empty():
		return _area(cells.back(), ability.radius)
	return cells


func _held_footprint() -> Dictionary:
	if _state.stored.is_empty():
		return {}
	var skill: Dictionary = _state.stored.ability
	var origin: Array = _state.player.pos
	if skill.kind == "burst":
		return {"type": "area", "cells": _area(origin, skill.radius)}
	var cells := [origin.duplicate()]
	cells.append_array(_ray(origin, _state.stored.dir, skill.range))
	return {"type": "ray", "cells": cells}


func _refresh_footprints() -> void:
	_state.intentions = []
	_state.backlash_footprint = _held_footprint()
	if _state.status != "playing":
		return
	for enemy in _state.enemies:
		if not _state.cancelled.has(enemy.id):
			_state.intentions.append({"source": enemy.id, "kind": enemy.ability.kind, "cells": _enemy_footprint(enemy)})


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
			if _state.movement_points <= 0:
				return "No movement points remain."
			if _distance(_state.player.pos, action.to) != 1 or not _walkable(action.to) or not _occupant(action.to).is_empty():
				return "Destination must be a free adjacent cell."
		"capture":
			if not _keys_allowed(action, ["type", "source"]) or not action.get("source") is String:
				return "Capture requires a source."
			var source := _enemy(action.source)
			if source.is_empty() or _state.cancelled.has(action.source):
				return "That enemy has no available announcement."
			if _distance(_state.player.pos, source.pos) > _state.rules.capture_range:
				return "Source is outside capture reach."
		"release":
			return _release_rejection(action)
		"end_turn":
			if not _keys_allowed(action, ["type"]):
				return "Unexpected action field."
		_:
			return "Unknown action."
	return ""


func _release_rejection(action: Dictionary) -> String:
	if not _keys_allowed(action, ["type", "target"]) or not _cell(action.get("target")):
		return "Release requires a target cell and valid fields."
	if _state.stored.is_empty():
		return "There is no stored action."
	if _state.action_points <= 0:
		return "No action points remain."
	var ability: Dictionary = _state.stored.ability
	if _target_ray(_state.player.pos, action.target, ability.range).is_empty():
		return "Target is outside an unobstructed ability range."
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
			_state.movement_points -= 1
			_event("move", {"actor": "player", "from": previous.duplicate(), "to": action.to.duplicate()})
		"capture": _capture(action.source)
		"release": _release(action)
		"end_turn":
			if not _state.stored.is_empty() and _state.turn >= _state.stored.deadline_turn:
				_backlash()
	if _state.status == "playing":
		_check_escape()
	if action.type == "end_turn" and _state.status == "playing":
		_end_turn()
	_refresh_footprints()


func _capture(id: String) -> void:
	if not _state.stored.is_empty():
		_backlash()
		if _state.status != "playing":
			return
	var source := _enemy(id)
	if source.is_empty():
		_event("capture_failed", {"source": id, "reason": "source_dead"})
		return
	if _distance(_state.player.pos, source.pos) > _state.rules.capture_range:
		_event("capture_failed", {"source": id, "reason": "out_of_reach"})
		return
	_state.stored = {
		"source": id, "ability": source.ability.duplicate(true), "dir": source.dir.duplicate(),
		"captured_turn": _state.turn, "deadline_turn": _state.turn + 1,
	}
	_state.cancelled.append(id)
	_event("capture", {"source": id, "kind": source.ability.kind})


func _release(action: Dictionary) -> void:
	var held: Dictionary = _state.stored
	_state.stored = {}
	_state.action_points -= 1
	var ability: Dictionary = held.ability
	var origin: Array = _state.player.pos.duplicate()
	var center: Array = action.target if ability.kind == "burst" else origin
	var cells: Array = _area(center, ability.radius) if ability.kind == "burst" else _target_ray(origin, action.target, ability.range)
	_event("release", {"source": held.source, "kind": ability.kind, "target": action.target.duplicate()})
	_resolve_ability("player", ability, cells, center, false)


func _backlash() -> void:
	var held: Dictionary = _state.stored
	var footprint := _held_footprint()
	var origin: Array = _state.player.pos.duplicate()
	_state.stored = {}
	_event("backlash", {"source": held.source, "kind": held.ability.kind})
	_resolve_ability("player", held.ability, footprint.cells, origin, true)


func _end_turn() -> void:
	var ids := []
	for enemy in _state.enemies:
		ids.append(enemy.id)
	for id in ids:
		if _state.status != "playing":
			return
		var enemy := _enemy(id)
		if enemy.is_empty() or _state.cancelled.has(id):
			continue
		var ability: Dictionary = enemy.ability
		var ray := _ray(enemy.pos, enemy.dir, ability.range)
		var center: Array = ray.back() if ability.kind == "burst" and not ray.is_empty() else enemy.pos
		_resolve_ability(id, ability, _enemy_footprint(enemy), center, false)
	if _state.status != "playing":
		return
	_state.turn += 1
	_state.action_points = _state.rules.actions
	_state.movement_points = _state.rules.movement
	_state.cancelled = []
	_event("turn", {"number": _state.turn})
	_check_escape()


func _check_escape() -> void:
	if _state.player.pos == _state.exit.pos and _state.turn >= _state.exit.opens:
		_state.status = "won"
		_event("win")


func _targets(actor_id: String, cells: Array, is_area: bool, backlash: bool) -> Array:
	var targets := []
	if is_area:
		if cells.has(_state.player.pos) and (actor_id != "player" or backlash):
			targets.append("player")
		for enemy in _state.enemies:
			if enemy.id != actor_id and cells.has(enemy.pos):
				targets.append(enemy.id)
	else:
		for cell in cells:
			var id := _occupant(cell)
			if not id.is_empty() and (id != actor_id or (backlash and id == "player")):
				targets.append(id)
	return targets


func _resolve_ability(actor_id: String, ability: Dictionary, cells: Array, center: Array, backlash: bool) -> void:
	var is_area: bool = ability.kind == "burst"
	_event("area" if is_area else "ray", {"actor": actor_id, "kind": ability.kind, "cells": cells.duplicate(true)})
	var targets := _targets(actor_id, cells, is_area, backlash)
	for id in targets:
		if _state.status != "playing":
			return
		_damage(id, ability.damage)
		if _state.status != "playing":
			return
		var actor: Dictionary = _state.player if id == "player" else _enemy(id)
		if ability.push and not actor.is_empty() and not (backlash and id == "player"):
			_displace(id, actor, center)


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


func _displace(id: String, actor: Dictionary, center: Array) -> void:
	var dx: int = actor.pos[0] - center[0]
	var dy: int = actor.pos[1] - center[1]
	# Off-axis area pushes choose the dominant axis, with horizontal winning ties.
	var direction := [signi(dx), 0] if absi(dx) >= absi(dy) else [0, signi(dy)]
	if direction == [0, 0]:
		return
	var destination := _add(actor.pos, direction)
	if _walkable(destination) and _occupant(destination).is_empty():
		var previous: Array = actor.pos
		actor.pos = destination
		_event("displace", {"actor": id, "from": previous.duplicate(), "to": destination.duplicate()})
