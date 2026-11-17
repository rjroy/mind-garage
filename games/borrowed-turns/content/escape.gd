extends RefCounted
## Provisional R2 escape room. Not tuned evidence of balance or enjoyment.
const DATA := {
	"objective": "escape",
	"width": 7,
	"height": 7,
	"walls": [[4, 1], [4, 5]],
	"player": {"pos": [2, 3], "hp": 6},
	"exit": {"pos": [6, 3], "opens": 3},
	"rules": {"actions": 2, "movement": 1, "capture_range": 1},
	"enemies": [
		{"id": "a", "pos": [2, 2], "hp": 4, "kind": "bolt", "dir": [1, 0],
		 "ability": {"kind": "bolt", "range": 4, "damage": 1, "radius": 0, "push": false}},
		{"id": "b", "pos": [3, 3], "hp": 4, "kind": "shove", "dir": [0, 1],
		 "ability": {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}},
		{"id": "c", "pos": [2, 4], "hp": 4, "kind": "burst", "dir": [1, 0],
		 "ability": {"kind": "burst", "range": 3, "damage": 2, "radius": 1, "push": false}},
	],
}
