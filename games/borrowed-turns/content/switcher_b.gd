extends RefCounted
## Switcher and the retained wide-shove opponent.
const Opponents = preload("res://content/opponents.gd")
const DATA := {
	"width": 7, "height": 7, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 3], "hp": 8},
	"rules": {"actions": 3},
	"opponent_definitions": {"switcher": Opponents.SWITCHER, "ranger": Opponents.RANGER},
	"enemies": [
		{"id": "A", "definition": "switcher", "pos": [6, 0], "dir": [-1, 0]},
		{"id": "B", "definition": "ranger", "pos": [6, 6], "dir": [-1, 0]},
	],
}
