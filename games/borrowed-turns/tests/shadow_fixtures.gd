extends RefCounted
## Controlled presentation inputs, not production tuning or an alternate planner.

static func ability(kind: String = "shove", damage: int = 1) -> Dictionary:
	return {"kind": kind, "range": 3, "damage": damage, "radius": 1 if kind == "burst" else 0, "push": kind == "shove", "width": 1}

static func foe(id: String, pos: Array, direction: Array = [0, -1], hp: int = 8, skill: Dictionary = {}) -> Dictionary:
	var chosen := ability() if skill.is_empty() else skill.duplicate(true)
	return {"id": id, "pos": pos.duplicate(), "dir": direction.duplicate(), "hp": hp, "kind": chosen.kind, "ability": chosen}

static func board(enemies: Array = [], health: int = 20) -> Dictionary:
	return {
		"objective": "escape", "width": 7, "height": 7, "walls": [],
		"player": {"pos": [2, 3], "hp": health}, "exit": {"pos": [6, 6], "opens": 99},
		"rules": {"actions": 3}, "enemies": enemies.duplicate(true),
	}

static func single() -> Dictionary:
	return board([foe("A", [2, 1], [0, 1])])

static func stored(id: String = "A", kind: String = "shove") -> Dictionary:
	return {"source": id, "captured_turn": 1, "ability": ability(kind)}

static func state() -> Dictionary:
	var value := board([
		foe("A", [2, 1], [0, 1]),
		foe("B", [0, 4], [1, 0], 9, ability("bolt")),
	])
	value.merge({"turn": 1, "status": "playing", "action_points": 3,
		"stored": {}, "capture_armed": false, "events": [],
		"intentions": [
			{"source": "A", "kind": "shove", "cells": [[2, 2], [2, 3], [2, 4]]},
			{"source": "B", "kind": "bolt", "cells": [[1, 4], [2, 4], [3, 4]]},
		]})
	return value

static func armed_hit(old_held: bool = false) -> Dictionary:
	var before := state()
	before.capture_armed = true
	before.action_points = 2
	if old_held: before.stored = stored("B", "bolt")
	var after := before.duplicate(true)
	after.turn = 2
	after.action_points = 3
	after.capture_armed = false
	after.player = {"pos": [2, 4], "hp": 18}
	after.stored = stored()
	after.events = [
		{"type": "ray", "actor": "A", "kind": "shove", "cells": [[2, 2], [2, 3], [2, 4]]},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 19},
		{"type": "displace", "actor": "player", "from": [2, 3], "to": [2, 4]},
		{"type": "capture", "source": "A", "kind": "shove"},
		{"type": "ray", "actor": "B", "kind": "bolt", "cells": [[1, 4], [2, 4], [3, 4]]},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 18},
		{"type": "turn", "number": 2},
	]
	return {"before": before, "after": after, "command": {"type": "end_turn"}}

static func shine_transition(kind: String = "shove", loses_source: bool = false) -> Dictionary:
	var before := state()
	before.player.pos = [2, 4]
	before.stored = stored("A", kind)
	before.enemies[0].kind = kind
	before.enemies[0].ability = ability(kind)
	before.intentions[0].kind = kind
	if loses_source:
		before.stored.ability.damage = 8
		before.enemies[0].ability.damage = 8
	var after := before.duplicate(true)
	after.action_points = 2
	var effect := "area" if kind == "burst" else "ray"
	var target := [2, 1] if loses_source else [2, 2]
	var cells := [[2, 1], [1, 2], [2, 2], [3, 2], [2, 3]] if kind == "burst" else [[2, 3], [2, 2]]
	if loses_source: cells.append([2, 1])
	after.events = [
		{"type": "shine", "source": "A", "kind": kind, "target": target},
		{"type": effect, "actor": "player", "kind": kind, "cells": cells},
	]
	if loses_source:
		after.enemies = after.enemies.filter(func(row): return row.id != "A")
		after.intentions = after.intentions.filter(func(row): return row.source != "A")
		after.stored = {}
		after.events.append_array([
			{"type": "damage", "actor": "A", "amount": 8, "hp": 0},
			{"type": "death", "actor": "A"},
			{"type": "ability_lost", "source": "A", "reason": "source_dead"},
		])
	return {"before": before, "after": after, "command": {"type": "shine", "target": target}}
