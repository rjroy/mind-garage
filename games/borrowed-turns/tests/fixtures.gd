extends RefCounted

# Controlled inputs, intentionally independent of production encounter tuning.
static func ability(kind: String, reach: int, damage: int, radius: int = 0, push: bool = false) -> Dictionary:
	return {"kind": kind, "range": reach, "damage": damage, "radius": radius, "push": push}

static func foe(id: String, pos: Array, direction: Array, skill: Dictionary, hp: int = 10) -> Dictionary:
	return {"id": id, "pos": pos, "dir": direction, "hp": hp, "kind": skill.kind, "ability": skill.duplicate(true)}

static func board() -> Dictionary:
	return {
		"objective": "defeat_all", "width": 8, "height": 7, "walls": [],
		"player": {"pos": [1, 3], "hp": 20},
		"rules": {"actions": 3},
		"enemies": [foe("a", [2, 3], [1, 0], ability("bolt", 3, 1))],
	}
