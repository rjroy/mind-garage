extends RefCounted
## Picker metadata and authored encounter data share one registry.
const Opponents = preload("res://content/opponents.gd")
const Switcher = preload("res://content/switcher.gd")
const SwitcherB = preload("res://content/switcher_b.gd")
const TwoPursuers = preload("res://content/two_pursuers.gd")

const STOCK := {
	"flanker": {"name": "Flanker", "definition": Opponents.FLANKER, "pos": [4, 3]},
	"lantern-guard": {"name": "Lantern Guard", "definition": Opponents.LANTERN_GUARD, "pos": [4, 3]},
	"circler": {"name": "Circler", "definition": Opponents.CIRCLER, "pos": [4, 3]},
	"deadeye": {"name": "Deadeye", "definition": Opponents.DEADEYE, "pos": [5, 3]},
	"anchor": {"name": "Anchor", "definition": Opponents.ANCHOR, "pos": [5, 3]},
	"puller": {"name": "Puller", "definition": Opponents.PULLER, "pos": [5, 3]},
}

static func registry() -> Dictionary:
	var result := {
		"switcher": {"name": "Switcher", "data": Switcher.DATA},
		"switcher-b": {"name": "Switcher + B", "data": SwitcherB.DATA},
		"two-pursuers": {"name": "Two pursuers", "data": TwoPursuers.DATA},
	}
	for id in STOCK:
		var entry: Dictionary = STOCK[id]
		result[id] = {"name": entry.name, "data": {
			"width": 7, "height": 7, "walls": [], "objective": "defeat_all",
			"player": {"pos": [2, 3], "hp": 10}, "rules": {"actions": 3},
			"opponent_definitions": {id: entry.definition},
			"enemies": [{"id": "A", "definition": id, "pos": entry.pos, "dir": [-1, 0]}],
		}}
	return result
