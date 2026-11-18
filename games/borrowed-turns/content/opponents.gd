extends RefCounted
## Authored components and definitions shared by the shipped encounters.
const CHASE := {"pattern": "chase_player", "budget": 1}
const KEEP_RANGE := {"pattern": "keep_max_range", "budget": 1}
const SHOVE := {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true}
const WIDE_SHOVE := {"kind": "shove", "range": 2, "damage": 1, "radius": 0, "push": true, "width": 3}
const SWAP := {"kind": "swap", "range": 2, "damage": 1, "radius": 0, "push": false}
const BOLT := {"kind": "bolt", "range": 4, "damage": 1, "radius": 0, "push": false}
const BURST := {"kind": "burst", "range": 3, "damage": 2, "radius": 1, "push": false}
const PULL := {"kind": "pull", "range": 3, "damage": 2, "radius": 0, "push": false}

const FLANKER := {
	"name": "Flanker", "stats": {"max_hp": 4},
	"movement": {"pattern": "seek_firing_line", "budget": 1},
	"abilities": [SHOVE, BOLT], "decision": "first_in_range", "presentation": {"kit": "A"},
}
const LANTERN_GUARD := {
	"name": "Lantern Guard", "stats": {"max_hp": 5},
	"movement": {"pattern": "patrol", "budget": 1, "route": [[0, 0], [0, -2], [2, -2], [2, 0]]},
	"abilities": [WIDE_SHOVE], "decision": "fixed", "presentation": {"kit": "B"},
}
const CIRCLER := {
	"name": "Circler", "stats": {"max_hp": 4},
	"movement": {"pattern": "orbit_player", "budget": 1, "radius": 2, "clockwise": true},
	"abilities": [WIDE_SHOVE], "decision": "fixed", "presentation": {"kit": "A"},
}
const DEADEYE := {
	"name": "Deadeye", "stats": {"max_hp": 4}, "movement": KEEP_RANGE,
	"abilities": [SWAP, BOLT], "decision": "first_in_range", "presentation": {"kit": "B"},
}
const ANCHOR := {
	"name": "Anchor", "stats": {"max_hp": 4},
	"abilities": [BURST], "decision": "fixed", "presentation": {"kit": "A"},
}
const PULLER := {
	"name": "Puller", "stats": {"max_hp": 4}, "movement": CHASE,
	"abilities": [PULL], "decision": "fixed", "presentation": {"kit": "B"},
}

const CHASER := {
	"name": "Pursuer A", "stats": {"max_hp": 5}, "movement": CHASE,
	"abilities": [SHOVE], "decision": "fixed", "presentation": {"kit": "A"},
}
const RANGER := {
	"name": "Pursuer B", "stats": {"max_hp": 5}, "movement": KEEP_RANGE,
	"abilities": [WIDE_SHOVE], "decision": "fixed", "presentation": {"kit": "B"},
}
const SWITCHER := {
	"name": "Switcher", "stats": {"max_hp": 5}, "movement": CHASE,
	"abilities": [SWAP], "decision": "fixed", "presentation": {"kit": "A"},
}
