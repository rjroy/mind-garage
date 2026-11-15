extends RefCounted

# Test-owned board: deliberately not the production level.
static func board() -> Dictionary:
	return {
		"width": 7, "height": 7, "walls": [],
		"player": {"pos": [1, 3], "hp": 6},
		"exit": {"pos": [6, 6], "opens": 20},
		"enemies": [
			{"id": "a", "pos": [3, 3], "hp": 2, "kind": "bolt", "dir": [0, -1]},
			{"id": "b", "pos": [5, 5], "hp": 2, "kind": "shove", "dir": [1, 0]},
		],
	}

static func capture(source: String, extra: Dictionary = {}) -> Dictionary:
	var action := {"type": "capture", "source": source}
	action.merge(extra, true)
	return action
