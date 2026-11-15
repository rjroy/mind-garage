extends RefCounted

var _fixture: Dictionary = {}
var _variant := ""
var _invert_enabled := false
var _state: Dictionary = {}


func configure(fixture: Dictionary, variant: String, invert_enabled: bool) -> void:
	_fixture = fixture.duplicate(true)
	_variant = variant
	_invert_enabled = invert_enabled
	reset()


func reset() -> void:
	_state = _fixture.duplicate(true)
	_state.merge({
		"turn": 1, "status": "playing", "variant": _variant,
		"invert_enabled": _invert_enabled, "cancelled": [],
		"free_capture_used": false, "stored": {}, "intentions": [], "events": [],
	}, true)
	_update_intentions()


func snapshot() -> Dictionary:
	return _state.duplicate(true)


func assess(action: Dictionary) -> Dictionary:
	var reason := _rejection(action)
	if not reason.is_empty():
		return {"legal": false, "reason": reason, "preview": {}}
	# Execute on a detached model so preview and actual resolution share exactly one path.
	var preview = get_script().new()
	preview._fixture = _fixture
	preview._variant = _variant
	preview._invert_enabled = _invert_enabled
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
	if _state.player.pos == pos and _state.player.hp > 0:
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


func _release_cells(origin: Array, target: Array) -> Array:
	var distance := _distance(origin, target)
	if distance < 1 or distance > 3 or (origin[0] != target[0] and origin[1] != target[1]):
		return []
	var direction := [signi(target[0] - origin[0]), signi(target[1] - origin[1])]
	var cells := _ray(origin, direction, distance)
	return cells if cells.size() == distance else []


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
		"wait", "discard":
			if not _keys_allowed(action, ["type"]):
				return "Unexpected action field."
			if action.type == "discard" and _state.stored.is_empty():
				return "There is no stored action."
		"move":
			if not _keys_allowed(action, ["type", "to"]) or not _cell(action.get("to")):
				return "Move requires a destination cell."
			if _distance(_state.player.pos, action.to) != 1 or not _walkable(action.to) or not _occupant(action.to).is_empty():
				return "Destination must be a free adjacent cell."
		"capture":
			return _capture_rejection(action)
		"release":
			return _release_rejection(action)
		_:
			return "Unknown action."
	return ""


func _capture_rejection(action: Dictionary) -> String:
	var allowed := ["type", "source"]
	if _variant == "V2":
		allowed.append("approach")
	if _variant == "V6":
		allowed.append("target")
	if not _keys_allowed(action, allowed) or not action.get("source") is String:
		return "Capture requires a source and valid fields."
	if not _state.stored.is_empty():
		return "The storage slot is occupied."
	if _variant == "V5" and _state.free_capture_used:
		return "Free capture was already used this turn."
	var source := _enemy(action.source)
	if source.is_empty() or _state.cancelled.has(action.source):
		return "That enemy has no available announcement."
	var origin: Array = _state.player.pos
	if _variant == "V2":
		if action.has("approach"):
			if not _cell(action.approach):
				return "Approach requires a cell."
			if _distance(origin, action.approach) != 1 or not _walkable(action.approach) or not _occupant(action.approach).is_empty():
				return "Approach must be a free adjacent cell."
			origin = action.approach
		if _distance(origin, source.pos) != 1:
			return "Capture requires adjacency to the source."
	elif _distance(origin, source.pos) > 3:
		return "Source is outside capture reach."
	if _variant == "V6":
		if not _cell(action.get("target")) or _release_cells(origin, action.target).is_empty():
			return "Commit a currently legal target cell."
	return ""


func _release_rejection(action: Dictionary) -> String:
	if not _keys_allowed(action, ["type", "target", "invert"]):
		return "Unexpected release field."
	if action.has("invert") and not action.invert is bool:
		return "Invert must be a boolean."
	if _state.stored.is_empty():
		return "There is no stored action."
	if _state.stored.captured_turn == _state.turn:
		return "Release must occur on a later turn."
	if action.get("invert", false) and (not _invert_enabled or _state.stored.kind != "shove"):
		return "This action cannot be inverted."
	var target: Variant = action.get("target", _state.stored.target if _variant == "V6" else null)
	if not _cell(target):
		return "Release requires a target cell."
	if _variant == "V6" and target != _state.stored.target:
		return "Release must use the committed cell."
	if _release_cells(_state.player.pos, target).is_empty():
		return "Target is outside an unobstructed release ray."
	return ""


func _event(type: String, details: Dictionary = {}) -> void:
	var event := {"type": type}
	event.merge(details)
	_state.events.append(event)


func _update_intentions() -> void:
	_state.intentions = []
	if _state.status != "playing":
		return
	for enemy in _state.enemies:
		if not _state.cancelled.has(enemy.id):
			_state.intentions.append({"source": enemy.id, "kind": enemy.kind, "cells": _ray(enemy.pos, enemy.dir, 3)})


func _apply(action: Dictionary) -> void:
	_state.events = []
	var had_slot: bool = not _state.stored.is_empty()
	match action.type:
		"move":
			_move_actor("player", action.to)
		"capture":
			_capture(action)
		"release":
			_release(action)
		"discard":
			_discard()
	# V5 capture is free, leaving the same turn's ordinary action pending.
	if action.type == "capture" and _variant == "V5":
		_update_intentions()
		return
	if had_slot and not _state.stored.is_empty():
		_state.stored.actions_elapsed += 1
	if _state.status != "playing":
		_update_intentions()
		return
	if _state.player.pos == _state.exit.pos and _state.turn >= _state.exit.opens:
		_finish("won")
		_update_intentions()
		return
	_resolve_enemies()
	if _state.status == "playing" and not _state.stored.is_empty() and _state.stored.actions_elapsed >= 2:
		if _variant == "V3":
			_lose_slot("expired")
		elif _variant == "V5":
			_backlash()
	if _state.status == "playing":
		_state.turn += 1
		_state.cancelled = []
		_state.free_capture_used = false
		_event("turn", {"number": _state.turn})
	_update_intentions()


func _capture(action: Dictionary) -> void:
	if action.has("approach"):
		_move_actor("player", action.approach)
	var source := _enemy(action.source)
	_state.stored = {
		"source": source.id, "kind": source.kind, "captured_turn": _state.turn,
		"actions_elapsed": 0, "target": action.get("target", []).duplicate(),
	}
	_state.cancelled.append(source.id)
	if _variant == "V5":
		_state.free_capture_used = true
	_event("capture", {"source": source.id, "kind": source.kind})


func _release(action: Dictionary) -> void:
	var stored: Dictionary = _state.stored
	var target: Array = action.get("target", stored.target)
	var inverted: bool = action.get("invert", false)
	_state.stored = {}
	_event("release", {"source": stored.source, "kind": stored.kind, "target": target.duplicate(), "invert": inverted})
	_resolve_ray("player", stored.kind, _state.player.pos, _release_cells(_state.player.pos, target), inverted)


func _discard() -> void:
	var source: String = _state.stored.source
	_event("discard", {"source": source})
	if _variant == "V5":
		_backlash()
	else:
		_state.stored = {}


func _backlash() -> void:
	var stored: Dictionary = _state.stored
	_state.stored = {}
	_event("backlash", {"source": stored.source, "kind": stored.kind, "amount": 1})
	_damage("player")


func _lose_slot(reason: String) -> void:
	var source: String = _state.stored.source
	_state.stored = {}
	_event("slot_lost", {"source": source, "reason": reason})


func _finish(outcome: String) -> void:
	_state.status = outcome
	_event("win" if outcome == "won" else "loss")


func _move_actor(id: String, target: Array) -> void:
	var actor: Dictionary = _state.player if id == "player" else _enemy(id)
	var previous: Array = actor.pos
	actor.pos = target.duplicate()
	_event("move", {"actor": id, "from": previous.duplicate(), "to": target.duplicate()})


func _damage(id: String) -> void:
	var actor: Dictionary = _state.player if id == "player" else _enemy(id)
	actor.hp = maxi(0, actor.hp - 1)
	_event("damage", {"actor": id, "amount": 1, "hp": actor.hp})
	if actor.hp == 0:
		_event("death", {"actor": id})
		if id == "player":
			_finish("lost")
		else:
			_state.enemies.erase(actor)
			if _variant == "V4" and not _state.stored.is_empty() and _state.stored.source == id:
				_lose_slot("source_dead")


func _resolve_enemies() -> void:
	# Take IDs, not dictionaries, so friendly fire can remove later attackers safely.
	var ids := []
	for enemy in _state.enemies:
		ids.append(enemy.id)
	for id in ids:
		if _state.status != "playing":
			return
		var enemy := _enemy(id)
		if not enemy.is_empty() and not _state.cancelled.has(id):
			_resolve_ray(id, enemy.kind, enemy.pos, _ray(enemy.pos, enemy.dir, 3), false)


func _resolve_ray(origin_id: String, kind: String, origin: Array, cells: Array, inverted: bool) -> void:
	_event("ray", {"actor": origin_id, "kind": kind, "cells": cells.duplicate(true)})
	var targets := []
	for cell in cells:
		var id := _occupant(cell)
		if not id.is_empty() and id != origin_id:
			targets.append(id)
	for id in targets:
		if _state.status != "playing":
			return
		_damage(id)
		if _state.status != "playing":
			return
		var actor: Dictionary = _state.player if id == "player" else _enemy(id)
		if kind == "shove" and not actor.is_empty():
			var direction := [signi(actor.pos[0] - origin[0]), signi(actor.pos[1] - origin[1])]
			if inverted:
				direction = [-direction[0], -direction[1]]
			var destination := _add(actor.pos, direction)
			if _walkable(destination) and _occupant(destination).is_empty():
				var previous: Array = actor.pos
				actor.pos = destination
				_event("displace", {"actor": id, "from": previous.duplicate(), "to": destination.duplicate()})
