extends RefCounted
## Active two-opponent fight. Tuning is provisional, not evidence of enjoyment.
const DATA := {
	"width": 5, "height": 5, "walls": [],
	"objective": "defeat_all",
	"player": {"pos": [0, 2], "hp": 8},
	"rules": {"actions": 3},
	"enemies": [
		{"id": "A", "pos": [4, 0], "hp": 5, "kind": "shove", "dir": [-1, 0],
		 "movement_pattern": "chase_player", "movement_budget": 1,
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}},
		{"id": "B", "pos": [4, 4], "hp": 5, "kind": "shove", "dir": [-1, 0],
		 "movement_pattern": "keep_max_range", "movement_budget": 1,
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true, "width": 3}},
	],
}
