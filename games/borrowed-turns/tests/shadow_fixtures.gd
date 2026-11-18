extends RefCounted
## Controlled presentation inputs, not production tuning or an alternate planner.

static func ability(kind: String = "shove", damage: int = 1) -> Dictionary:
	return {"kind": kind, "range": 3, "damage": damage, "radius": 1 if kind == "burst" else 0, "push": kind == "shove", "width": 1}

static func foe(id: String, pos: Array, direction: Array = [0, -1], hp: int = 8, skill: Dictionary = {}) -> Dictionary:
	var chosen := ability() if skill.is_empty() else skill.duplicate(true)
	return {"id": id, "pos": pos.duplicate(), "dir": direction.duplicate(), "hp": hp, "kind": chosen.kind, "ability": chosen}

static func board(enemies: Array = [], health: int = 20) -> Dictionary:
	return {
		"objective": "defeat_all", "width": 7, "height": 7, "walls": [],
		"player": {"pos": [2, 3], "hp": health},
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

static func swap_state(pair: bool = false) -> Dictionary:
	var skill := {"kind": "swap", "range": 2, "damage": 1, "radius": 0, "push": false, "width": 1}
	var switcher := foe("A", [2, 1], [0, 1], 5, skill)
	switcher["name"] = "Switcher"
	switcher["announced_target"] = [2, 3]
	var value := board([switcher])
	value.merge({"turn": 1, "status": "playing", "variant": "R2", "action_points": 2,
		"capture_armed": true, "stored": {}, "events": [],
		"intentions": [{"source": "A", "kind": "swap", "from": [2, 1], "target": [2, 3], "cells": [[2, 3]]}]})
	if pair:
		var wide := ability()
		wide.range = 2
		wide.width = 3
		value.enemies.append(foe("B", [4, 1], [-1, 0], 5, wide))
		value.intentions.append({"source": "B", "kind": "shove",
			"cells": [[3, 2], [3, 1], [3, 0], [2, 2], [2, 1], [2, 0]]})
	return value

static func swap_hit(pair: bool = false, replacement: bool = false) -> Dictionary:
	var before := swap_state(pair)
	if replacement: before.stored = {"source": "B", "captured_turn": 0, "dir": [-1, 0], "ability": before.enemies[1].ability.duplicate(true)}
	var after := before.duplicate(true)
	after.turn = 2
	after.action_points = 3
	after.capture_armed = false
	after.enemies[0].pos = [2, 3]
	after.enemies[0].dir = [0, -1]
	after.enemies[0].announced_target = [2, 1]
	after.player = {"pos": [2, 1], "hp": 19}
	after.stored = {"source": "A", "captured_turn": 1, "dir": [0, 1], "ability": before.enemies[0].ability.duplicate(true)}
	after.events = [
		{"type": "mask", "actor": "A", "kind": "swap", "from": [2, 1], "target": [2, 3], "cells": [[2, 3]]},
		{"type": "swap", "actor": "A", "other": "player", "from": [2, 1], "to": [2, 3]},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 19},
		{"type": "capture", "source": "A", "kind": "swap"},
	]
	after.intentions = [{"source": "A", "kind": "swap", "from": [2, 3], "target": [2, 1], "cells": [[2, 1]]}]
	if pair:
		after.player = {"pos": [1, 1], "hp": 18}
		after.events.append_array([
			{"type": "ray", "actor": "B", "kind": "shove", "cells": before.intentions[1].cells.duplicate(true)},
			{"type": "damage", "actor": "player", "amount": 1, "hp": 18},
			{"type": "displace", "actor": "player", "from": [2, 1], "to": [1, 1]},
		])
		# Fresh Switcher aim is diagonal, so it has no eligible new target.
		after.intentions = [before.intentions[1].duplicate(true)]
		after.enemies[0].announced_target = []
	after.events.append({"type": "turn", "number": 2})
	return {"before": before, "after": after, "command": {"type": "end_turn"}}

static func swap_miss(invalid_geometry: bool = false) -> Dictionary:
	var before := swap_state()
	before.player.pos = [3, 3] # The announced cell remains [2,3], now empty.
	if invalid_geometry:
		before.enemies[0].pos = [0, 1]
		before.intentions[0].from = [0, 1]
	var after := before.duplicate(true)
	after.turn = 2
	after.action_points = 3
	after.intentions = []
	after.enemies[0].announced_target = []
	after.events = [
		{"type": "mask", "actor": "A", "kind": "swap", "from": before.enemies[0].pos.duplicate(),
			"target": [2, 3], "cells": [] if invalid_geometry else [[2, 3]]},
		{"type": "turn", "number": 2},
	]
	return {"before": before, "after": after, "command": {"type": "end_turn"}}

static func swap_shine(loses_source: bool = false) -> Dictionary:
	var before := swap_state()
	before.turn = 2
	before.action_points = 3
	before.capture_armed = false
	if loses_source: before.enemies[0].hp = 1
	before.stored = {"source": "A", "captured_turn": 1, "dir": [0, 1], "ability": before.enemies[0].ability.duplicate(true)}
	var after := before.duplicate(true)
	after.action_points = 2
	after.player.pos = [2, 1]
	after.enemies[0].pos = [2, 3]
	after.enemies[0].hp -= 1
	after.intentions = [{"source": "A", "kind": "swap", "from": [2, 3], "target": [2, 3], "cells": []}]
	after.events = [
		{"type": "shine", "source": "A", "kind": "swap", "target": [2, 1]},
		{"type": "mask", "actor": "player", "kind": "swap", "from": [2, 3], "target": [2, 1], "cells": [[2, 1]]},
		{"type": "swap", "actor": "player", "other": "A", "from": [2, 3], "to": [2, 1]},
		{"type": "damage", "actor": "A", "amount": 1, "hp": 0 if loses_source else 4},
	]
	if loses_source:
		after.enemies = []
		after.intentions = []
		after.stored = {}
		after.events.append_array([{"type": "death", "actor": "A"},
			{"type": "ability_lost", "source": "A", "reason": "source_dead"}])
	return {"before": before, "after": after, "command": {"type": "shine", "target": [2, 1]}}

static func swap_other_occupant() -> Dictionary:
	var before := swap_state(true)
	before.intentions[0].target = [4, 1]
	before.intentions[0].cells = [[4, 1]]
	before.enemies[0].announced_target = [4, 1]
	before.enemies[0].dir = [1, 0]
	before.enemies[1].dir = [1, 0]
	before.intentions[1].cells = [[5, 0], [5, 1], [5, 2], [6, 0], [6, 1], [6, 2]]
	var after := before.duplicate(true)
	after.turn = 2
	after.action_points = 3
	after.enemies[0].pos = [5, 1] # B's later normal shove hits/pushes A.
	after.enemies[0].hp = 4
	after.enemies[1].pos = [2, 1]
	after.enemies[1].hp = 4
	after.enemies[0].dir = [-1, 0]
	after.enemies[0].announced_target = []
	after.enemies[1].dir = [0, 1]
	after.intentions = [{"source": "B", "kind": "shove",
		"cells": [[3, 2], [2, 2], [1, 2], [3, 3], [2, 3], [1, 3]]}]
	after.events = [
		{"type": "mask", "actor": "A", "kind": "swap", "from": [2, 1], "target": [4, 1], "cells": [[4, 1]]},
		{"type": "swap", "actor": "A", "other": "B", "from": [2, 1], "to": [4, 1]},
		{"type": "damage", "actor": "B", "amount": 1, "hp": 4},
		{"type": "ray", "actor": "B", "kind": "shove", "cells": [[3, 0], [3, 1], [3, 2], [4, 0], [4, 1], [4, 2]]},
		{"type": "damage", "actor": "A", "amount": 1, "hp": 4},
		{"type": "displace", "actor": "A", "from": [4, 1], "to": [5, 1]},
		{"type": "turn", "number": 2},
	]
	return {"before": before, "after": after, "command": {"type": "end_turn"}}
