extends RefCounted
## Controlled UI integration inputs. No dependence on production tuning.

static func ability(kind: String, damage: int = 1, reach: int = 3, radius: int = 0, push: bool = false, width: int = 1) -> Dictionary:
	return {"kind": kind, "damage": damage, "range": reach, "radius": radius, "push": push, "width": width}

static func enemy(id: String, pos: Array, skill: Dictionary, hp: int = 12, direction: Array = [0, -1]) -> Dictionary:
	return {"id": id, "pos": pos, "hp": hp, "kind": skill.kind, "dir": direction, "ability": skill}

static func encounter(enemies: Array, actions: int = 4, health: int = 20) -> Dictionary:
	return {
		"objective": "escape",
		"width": 7, "height": 7, "walls": [], "player": {"pos": [1, 3], "hp": health},
		"exit": {"pos": [6, 6], "opens": 30},
		"rules": {"actions": actions}, "enemies": enemies,
	}

static func two_pursuers(center_player: bool = false) -> Dictionary:
	# Depth/overlap stress geometry. Acquisition still requires a real hit.
	var data := encounter([
		enemy("A", [2, 1], ability("shove", 2, 3, 0, true), 19, [0, 1]),
		enemy("B", [2, 3], ability("shove", 2, 3, 0, true), 17, [0, -1]),
	], 3, 31)
	data.width = 5
	data.height = 5
	data.player.pos = [2, 2] if center_player else [1, 2]
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
	before.merge({"turn": 4, "status": "playing", "action_points": 3,
		"stored": {}, "capture_armed": false, "events": [],
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
	], 3, 39)
	data.objective = "defeat_all"
	data.enemies[0]["movement_pattern"] = "chase_player"
	data.enemies[1]["movement_pattern"] = "keep_max_range"
	for foe in data.enemies: foe["movement_budget"] = 1
	data.erase("exit")
	return data

static func wide_capture() -> Dictionary:
	var data := encounter([
		enemy("A", [1, 2], ability("shove", 1, 2, 0, true), 11, [0, -1]),
		enemy("B", [3, 4], ability("shove", 2, 2, 0, true, 3), 13, [0, -1]),
	], 3, 29)
	data.objective = "defeat_all"
	data.player.pos = [2, 3] # B's side lane, never its narrow center column.
	data.erase("exit")
	return data

static func armed_fight(push: bool = true) -> Dictionary:
	# A hits first; B hits the displaced cell (or the original cell when no push).
	# Three AP suffice to arm and move twice; End turn refreshes for repeated Shine.
	return {
		"objective": "defeat_all", "width": 7, "height": 7, "walls": [],
		"player": {"pos": [2, 3], "hp": 20}, "rules": {"actions": 3},
		"enemies": [
			enemy("A", [2, 1], ability("shove", 1, 3, 0, push), 8, [0, 1]),
			enemy("B", [5, 4] if push else [5, 3], ability("bolt", 1, 3), 9, [-1, 0]),
		],
	}

static func shine_victory() -> Dictionary:
	var data := armed_fight(false)
	data.enemies = [enemy("A", [2, 1], ability("shove", 1, 3), 2, [0, 1])]
	return data
