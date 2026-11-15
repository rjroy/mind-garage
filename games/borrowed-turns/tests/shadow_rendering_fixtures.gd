extends RefCounted
## Controlled inputs for FY3-C01/C02/C03. Never import production encounter tuning.

const F = preload("res://tests/shadow_fixtures.gd")

static func deadline(later_lethal: bool = false) -> Dictionary:
	# Capture held, end T1, then end T2. Its right-facing backlash hits and
	# displaces victim before killer's downward bolt can kill the player.
	# The first bolt is survivable in both cases; the model owns all effects.
	return F.board([
		F.foe("held", [2, 4], [1, 0]),
		F.foe("victim", [3, 3], [1, 0]),
		F.foe("killer", [2, 1], [0, 1], 8, F.ability("bolt", 2)),
	], 4 if later_lethal else 20)

static func self_lethal() -> Dictionary:
	return F.replacement("lethal")

static func bolt_to_shove() -> Dictionary:
	# Two adjacent sources: old bolt backlash hits self and the new shover,
	# then the surviving shover is acquired. No push can move it out of reach.
	return F.board([
		F.foe("bolt", [2, 4], [1, 0], 8, F.ability("bolt")),
		F.foe("shove", [3, 3], [0, -1]),
	], 20)

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
