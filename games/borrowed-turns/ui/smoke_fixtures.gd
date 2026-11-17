extends RefCounted
## Controlled UI integration inputs. No dependence on production tuning.

static func ability(kind: String, damage: int = 1, reach: int = 3, radius: int = 0, push: bool = false) -> Dictionary:
	return {"kind": kind, "damage": damage, "range": reach, "radius": radius, "push": push}

static func enemy(id: String, pos: Array, skill: Dictionary, hp: int = 12, direction: Array = [0, -1]) -> Dictionary:
	return {"id": id, "pos": pos, "hp": hp, "kind": skill.kind, "dir": direction, "ability": skill}

static func encounter(enemies: Array, movement: int = 4, health: int = 20, capture_range: int = 1) -> Dictionary:
	return {
		"objective": "escape",
		"width": 7, "height": 7, "walls": [], "player": {"pos": [1, 3], "hp": health},
		"exit": {"pos": [6, 6], "opens": 30},
		"rules": {"actions": 2, "movement": movement, "capture_range": capture_range}, "enemies": enemies,
	}

static func two_pursuers(overlap_inspection: bool = false) -> Dictionary:
	# Keep the old depth/overlap stress geometry, but successful capture starts
	# on a safe flank. Range two is test-owned access, not new game tuning.
	var data := encounter([
		enemy("A", [2, 1], ability("shove", 2, 3, 0, true), 19, [0, 1]),
		enemy("B", [2, 3], ability("shove", 2, 3, 0, true), 17, [0, -1]),
	], 3, 31, 2)
	data.width = 5
	data.height = 5
	data.player.pos = [2, 2] if overlap_inspection else [1, 2]
	data.exit = {"pos": [4, 4], "opens": 12}
	return data

static func movement_transition() -> Dictionary:
	# Test-owned ordered events, not an alternate enemy planner. A's shove
	# displaces B; B attacks from there; only then do both voluntarily move.
	var before := encounter([
		enemy("A", [3, 1], ability("shove", 2, 3, 0, true), 11, [0, 1]),
		enemy("B", [3, 2], ability("bolt", 1, 3), 13, [-1, 0]),
	], 3, 29)
	before.objective = "defeat_all"
	before.erase("exit")
	before.merge({"turn": 4, "status": "playing", "action_points": 2, "movement_points": 3,
		"stored": {}, "backlash_footprint": {}, "events": [],
		"intentions": [{"source": "A", "kind": "shove", "cells": [[3, 2], [3, 3], [3, 4]]},
			{"source": "B", "kind": "bolt", "cells": [[2, 2], [1, 2], [0, 2]]}]})
	var after := before.duplicate(true)
	after.turn = 5
	after.player.hp = 28
	after.enemies[0].pos = [2, 1]
	after.enemies[1].pos = [2, 3]
	after.enemies[1].hp = 11
	after.intentions = [{"source": "A", "kind": "shove", "cells": [[2, 2], [2, 3], [2, 4]]},
		{"source": "B", "kind": "bolt", "cells": [[1, 3], [0, 3]]}]
	after.events = [
		{"type": "ray", "actor": "A", "kind": "shove", "cells": [[3, 2], [3, 3], [3, 4]]},
		{"type": "damage", "actor": "B", "amount": 2, "hp": 11},
		{"type": "displace", "actor": "B", "from": [3, 2], "to": [3, 3]},
		{"type": "ray", "actor": "B", "kind": "bolt", "cells": [[2, 3], [1, 3], [0, 3]]},
		{"type": "damage", "actor": "player", "amount": 1, "hp": 28},
		{"type": "move", "actor": "A", "from": [3, 1], "to": [2, 1]},
		{"type": "move", "actor": "B", "from": [3, 3], "to": [2, 3]},
		{"type": "turn", "number": 5},
	]
	return {"before": before, "after": after}

static func active_fight() -> Dictionary:
	var data := encounter([
		enemy("A", [4, 1], ability("shove", 2, 2, 0, true), 11, [-1, 0]),
		enemy("B", [5, 5], ability("shove", 1, 3, 0, true), 13, [-1, 0]),
	], 3, 39, 2)
	data.objective = "defeat_all"
	data.enemies[0]["movement_pattern"] = "chase_player"
	data.enemies[1]["movement_pattern"] = "keep_max_range"
	for foe in data.enemies: foe["movement_budget"] = 1
	data.erase("exit")
	return data

static func shadow_single() -> Dictionary:
	return encounter([enemy("a", [2, 3], ability("shove", 1, 3, 0, true))])

static func shadow_replacement(outcome: String) -> Dictionary:
	return encounter([
		enemy("a", [1, 4], ability("shove", 3 if outcome == "lethal" else 1, 3, 0, true), 8, [1, 0]),
		enemy("b", [0, 3] if outcome == "acquired" else [2, 3], ability("shove", 1, 3, 0, true), 1 if outcome == "source_dead" else 8),
	], 4, 2 if outcome == "lethal" else 20)
