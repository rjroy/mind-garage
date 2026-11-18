extends RefCounted
## Solo Switcher encounter for the first comparison.
const Opponents = preload("res://content/opponents.gd")
const DATA := {
	"width": 7, "height": 7, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 3], "hp": 8},
	"rules": {"actions": 3},
	"opponent_definitions": {"switcher": Opponents.SWITCHER},
	"enemies": [
		{"id": "A", "definition": "switcher", "pos": [6, 3], "dir": [-1, 0]},
	],
}
