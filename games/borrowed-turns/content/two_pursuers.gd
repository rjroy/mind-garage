extends RefCounted
## Controlled visual experiment, not new rules or a balance finding.
const DATA := {
	"width": 5, "height": 5, "walls": [],
	"player": {"pos": [2, 2], "hp": 8},
	"exit": {"pos": [4, 4], "opens": 3},
	"rules": {"actions": 2, "movement": 2, "capture_range": 1},
	"enemies": [
		{"id": "A", "pos": [2, 1], "hp": 5, "kind": "shove", "dir": [0, 1],
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}},
		{"id": "B", "pos": [2, 3], "hp": 5, "kind": "shove", "dir": [0, -1],
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}},
	],
}
