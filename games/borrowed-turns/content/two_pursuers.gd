extends RefCounted
## Seven-by-seven practical extent candidate, not a universal board maximum.
const DATA := {
	"width": 7, "height": 7, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 3], "hp": 8},
	"rules": {"actions": 3},
	"enemies": [
		{"id": "A", "pos": [6, 0], "hp": 5, "kind": "shove", "dir": [-1, 0],
		 "movement_pattern": "chase_player", "movement_budget": 1,
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}},
		{"id": "B", "pos": [6, 6], "hp": 5, "kind": "shove", "dir": [-1, 0],
		 "movement_pattern": "keep_max_range", "movement_budget": 1,
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true, "width": 3}},
	],
}
