extends RefCounted
## Controlled UI integration inputs. No dependence on production tuning.

static func ability(kind: String, damage: int = 1, reach: int = 3, radius: int = 0, push: bool = false) -> Dictionary:
	return {"kind": kind, "damage": damage, "range": reach, "radius": radius, "push": push}

static func enemy(id: String, pos: Array, skill: Dictionary, hp: int = 12, direction: Array = [0, -1]) -> Dictionary:
	return {"id": id, "pos": pos, "hp": hp, "kind": skill.kind, "dir": direction, "ability": skill}

static func encounter(enemies: Array, movement: int = 4, health: int = 20, capture_range: int = 1) -> Dictionary:
	return {
		"width": 7, "height": 7, "walls": [], "player": {"pos": [1, 3], "hp": health},
		"exit": {"pos": [6, 6], "opens": 30},
		"rules": {"actions": 2, "movement": movement, "capture_range": capture_range}, "enemies": enemies,
	}

static func shadow_single() -> Dictionary:
	return encounter([enemy("a", [2, 3], ability("shove", 1, 3, 0, true))])

static func shadow_replacement(outcome: String) -> Dictionary:
	return encounter([
		enemy("a", [1, 4], ability("shove", 3 if outcome == "lethal" else 1, 3, 0, true), 8, [1, 0]),
		enemy("b", [0, 3] if outcome == "acquired" else [2, 3], ability("shove", 1, 3, 0, true), 1 if outcome == "source_dead" else 8),
	], 4, 2 if outcome == "lethal" else 20)
