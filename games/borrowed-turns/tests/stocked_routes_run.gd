extends SceneTree

const Encounter = preload("res://model/encounter.gd")
const Catalog = preload("res://content/encounters.gd")

# These are full replays from the shipped solo catalog, not adjusted fixtures.
const ROUTES := {
	"flanker": [
		{"type": "end_turn"}, {"type": "capture"}, {"type": "end_turn"},
		{"type": "shine", "target": [4, 3]}, {"type": "end_turn"},
		{"type": "shine", "target": [4, 3]}, {"type": "shine", "target": [4, 3]},
		{"type": "shine", "target": [4, 3]},
	],
	"lantern-guard": [
		{"type": "capture"}, {"type": "end_turn"}, {"type": "move", "to": [2, 3]},
		{"type": "shine", "target": [4, 3]}, {"type": "end_turn"},
		{"type": "move", "to": [3, 3]}, {"type": "shine", "target": [3, 1]},
		{"type": "shine", "target": [5, 3]}, {"type": "end_turn"},
		{"type": "move", "to": [4, 3]}, {"type": "shine", "target": [4, 1]},
		{"type": "shine", "target": [6, 3]},
	],
	"circler": [
		{"type": "capture"}, {"type": "move", "to": [2, 2]}, {"type": "end_turn"},
		{"type": "move", "to": [2, 2]}, {"type": "shine", "target": [2, 3]},
		{"type": "shine", "target": [4, 2]}, {"type": "end_turn"},
		{"type": "move", "to": [3, 2]}, {"type": "shine", "target": [3, 3]},
		{"type": "shine", "target": [5, 2]},
	],
	"deadeye": [
		{"type": "capture"}, {"type": "end_turn"}, {"type": "shine", "target": [6, 3]},
		{"type": "end_turn"}, {"type": "shine", "target": [6, 3]},
		{"type": "shine", "target": [6, 3]}, {"type": "shine", "target": [6, 3]},
	],
	"anchor": [
		{"type": "capture"}, {"type": "end_turn"},
		{"type": "shine", "target": [4, 3]}, {"type": "shine", "target": [4, 3]},
	],
	"puller": [
		{"type": "capture"}, {"type": "end_turn"},
		{"type": "shine", "target": [4, 3]}, {"type": "shine", "target": [4, 3]},
	],
}

var failures: Array[String] = []


func check(condition: bool, label: String) -> bool:
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)
	return condition


func replay(id: String, data: Dictionary, actions: Array) -> void:
	var game = Encounter.new()
	game.configure(data, "R2")
	var captured := false
	var damaging_shines := 0
	var captured_kind := ""
	print("\n", id, " commands=", JSON.stringify(actions))
	for index in range(actions.size()):
		var action: Dictionary = actions[index]
		var before: Dictionary = game.snapshot()
		var assessment: Dictionary = game.assess(action)
		var label := "%s step %d %s" % [id, index + 1, JSON.stringify(action)]
		if not check(assessment.get("legal", false), label + ": " + assessment.get("reason", "")):
			return
		if not check(game.act(action), label + ": commit"):
			return
		var state: Dictionary = game.snapshot()
		check(state == assessment.preview, label + ": preview matches commit")
		check(state.player.hp > 0 and state.status != "lost", label + ": player survives")
		var shine_event := false
		var enemy_damage := false
		for event in state.events:
			if event.type == "capture":
				captured = true
				captured_kind = event.kind
				check(event.source == "A" and state.stored.get("source") == "A", label + ": captured catalog opponent")
				check(state.stored.get("ability", {}).get("kind") == captured_kind, label + ": stored captured ability")
			if event.type == "shine":
				shine_event = true
				check(captured and event.source == "A" and event.kind == captured_kind, label + ": shines captured ability")
			if event.type == "damage" and event.actor == "A" and event.amount > 0:
				enemy_damage = true
		if action.type == "shine":
			check(captured and shine_event and enemy_damage, label + ": Shine damages opponent")
			if enemy_damage:
				damaging_shines += 1
		var enemy_hp = state.enemies[0].hp if not state.enemies.is_empty() else 0
		print("  ", index + 1, " ", JSON.stringify(action), " player_hp=", state.player.hp,
			" enemy_hp=", enemy_hp, " capture=", captured_kind if captured else "none",
			" shine_damage=", enemy_damage if action.type == "shine" else false,
			" status=", state.status)
		check(before.status == "playing", label + ": action starts in active encounter")
	var final_state: Dictionary = game.snapshot()
	check(captured, id + ": successful capture")
	check(damaging_shines > 0, id + ": useful Shine")
	check(final_state.status == "won" and final_state.player.hp > 0, id + ": surviving win")


func _initialize() -> void:
	var registry: Dictionary = Catalog.registry()
	check(ROUTES.size() == 6 and Catalog.STOCK.size() == 6, "six stocked routes")
	for id in Catalog.STOCK:
		if check(ROUTES.has(id) and registry.has(id), "route and catalog entry for " + id):
			replay(id, registry[id].data, ROUTES[id])
	print("\nStocked route failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
