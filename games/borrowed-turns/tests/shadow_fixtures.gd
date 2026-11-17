extends RefCounted
## Test-owned inputs for the one-shove presentation controller, not production tuning.

static func ability(kind: String = "shove", damage: int = 1) -> Dictionary:
	return {"kind": kind, "range": 3, "damage": damage, "radius": 0, "push": kind == "shove"}

static func foe(id: String, pos: Array, direction: Array = [0, -1], hp: int = 8, skill: Dictionary = {}) -> Dictionary:
	var chosen := ability() if skill.is_empty() else skill.duplicate(true)
	return {"id": id, "pos": pos.duplicate(), "dir": direction.duplicate(), "hp": hp, "kind": chosen.kind, "ability": chosen}

static func board(enemies: Array = [], health: int = 12) -> Dictionary:
	return {
		"width": 7, "height": 7, "walls": [],
		"player": {"pos": [2, 3], "hp": health}, "exit": {"pos": [6, 6], "opens": 99},
		"rules": {"actions": 2, "capture_range": 1},
		"enemies": enemies.duplicate(true),
	}

static func single() -> Dictionary:
	return board([foe("shover", [3, 3])])

static func replacement(outcome: String) -> Dictionary:
	# The old action points right. A new source to the left survives in reach;
	# a source to the right can die or be pushed out of reach by real model effects.
	var new_pos := [1, 3] if outcome == "acquired" else [3, 3]
	var new_hp := 1 if outcome == "source_dead" else 8
	var old_damage := 3 if outcome == "lethal" else 1
	return board([
		foe("old", [2, 4], [1, 0], 8, ability("shove", old_damage)),
		foe("new", new_pos, [0, -1], new_hp),
	], 2 if outcome == "lethal" else 12)

static func source_death() -> Dictionary:
	return board([
		foe("shover", [3, 3], [1, 0], 1),
		foe("other", [3, 5], [0, -1], 8, ability("bolt")),
	])
