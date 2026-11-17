extends RefCounted
## Mixed ray/area inputs. Never import production encounter tuning.

const F = preload("res://tests/shadow_fixtures.gd")

static func mixed_resolution(order: Array) -> Dictionary:
	var area := F.ability("burst")
	area.range = 2
	area.radius = 1
	var sources := {
		"bolt": F.foe("bolt", [0, 1], [1, 0], 8, F.ability("bolt")),
		"shove": F.foe("shove", [3, 5], [-1, 0]),
		"burst": F.foe("burst", [5, 0], [0, 1], 8, area),
	}
	var enemies: Array = []
	for id in order: enemies.append(sources[id])
	# Separated footprints avoid player death or friendly-fire interruption.
	# Source order alone changes which non-shove footprint precedes/follows shove.
	return F.board(enemies, 20)
