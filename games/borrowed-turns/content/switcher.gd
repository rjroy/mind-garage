extends RefCounted
## Solo Switcher encounter for the first comparison.
const DATA := {
	"width": 7, "height": 7, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 3], "hp": 8},
	"rules": {"actions": 3},
	"enemies": [
		{"id": "A", "pos": [6, 3], "hp": 5, "kind": "swap", "dir": [-1, 0],
		 "movement_pattern": "chase_player", "movement_budget": 1,
		 "ability": {"kind": "swap", "range": 2, "damage": 1, "radius": 0, "push": false}},
	],
}
