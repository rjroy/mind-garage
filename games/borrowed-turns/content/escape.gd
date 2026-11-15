extends RefCounted
## Shared provisional production content. Tests own their independent fixtures.
const DATA := {
	"width": 7,
	"height": 7,
	"walls": [],
	"player": {"pos": [1, 3], "hp": 4},
	"exit": {"pos": [6, 3], "opens": 4},
	"enemies": [
		{"id": "a", "pos": [4, 1], "hp": 2, "kind": "bolt", "dir": [0, 1]},
		{"id": "b", "pos": [4, 5], "hp": 2, "kind": "shove", "dir": [0, -1]},
	],
}
