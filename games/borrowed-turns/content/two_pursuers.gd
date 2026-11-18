extends RefCounted
## Seven-by-seven practical extent candidate, not a universal board maximum.
const Opponents = preload("res://content/opponents.gd")
const DATA := {
	"width": 7, "height": 7, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 3], "hp": 8},
	"rules": {"actions": 3},
	"opponent_definitions": {"chaser": Opponents.CHASER, "ranger": Opponents.RANGER},
	"enemies": [
		{"id": "A", "definition": "chaser", "pos": [6, 0], "dir": [-1, 0]},
		{"id": "B", "definition": "ranger", "pos": [6, 6], "dir": [-1, 0]},
	],
}
