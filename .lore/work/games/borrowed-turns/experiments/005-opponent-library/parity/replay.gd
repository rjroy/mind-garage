extends SceneTree
## Disposable mechanical differential runner. Production sources are never edited.
## Defaults to historical DATA constants; --adapter=PATH may implement fixture(id).
const Encounter = preload("res://model/encounter.gd")
const IDS = ["two-pursuers", "switcher", "switcher-b"]
const PATHS = {
	"two-pursuers": "res://content/two_pursuers.gd",
	"switcher": "res://content/switcher.gd",
	"switcher-b": "res://content/switcher_b.gd",
}
const EVENT_FIELDS = {
	"move": ["actor", "from", "to"],
	"capture_armed": [],
	"shine": ["source", "kind", "target"],
	"ray": ["actor", "kind", "cells"],
	"area": ["actor", "kind", "cells"],
	"mask": ["actor", "kind", "cells", "from", "target"],
	"swap": ["actor", "other", "from", "to"],
	"damage": ["actor", "amount", "hp"],
	"death": ["actor"],
	"displace": ["actor", "from", "to"],
	"ability_lost": ["source", "reason"],
	"capture": ["source", "kind"],
	"turn": ["number"],
	"win": ["objective"],
	"loss": [],
}
var adapter = null
var failures: Array[String] = []
var checks := 0

func option(name: String, fallback: String = "") -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--" + name + "="):
			return arg.substr(name.length() + 3)
	return fallback

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ", label)

func fixture(id: String) -> Dictionary:
	if adapter != null:
		return adapter.fixture(id).duplicate(true)
	return load(PATHS[id]).DATA.duplicate(true)

func model(data: Dictionary):
	var game = Encounter.new()
	game.configure(data, "R2")
	return game

func fields(value: Dictionary, names: Array) -> Dictionary:
	var result := {}
	for name in names:
		if value.has(name):
			result[name] = value[name]
	return result

func ability(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var result := fields(value, ["kind", "range", "damage", "radius", "push"])
	# An omitted width and explicit width=1 describe the same inherited payload.
	result["width"] = value.get("width", 1)
	return result

func project(state: Dictionary) -> Dictionary:
	var result := fields(state, [
		"width", "height", "walls", "objective", "turn", "status", "variant",
		"action_points", "capture_armed",
	])
	result["player"] = fields(state.player, ["pos", "hp"])
	result["rules"] = fields(state.rules, ["actions"])
	if state.has("exit"):
		result["exit"] = fields(state.exit, ["pos", "opens"])
	result["stored"] = {}
	if not state.stored.is_empty():
		result["stored"] = fields(state.stored, ["source", "dir", "captured_turn"])
		result.stored["ability"] = ability(state.stored.ability)
	result["enemies"] = []
	for enemy in state.enemies:
		var item := fields(enemy, ["id", "pos", "hp", "dir"])
		item["announced_target"] = enemy.get("announced_target", [])
		item["ability"] = ability(enemy.ability)
		result.enemies.append(item)
	result["intentions"] = []
	for intent in state.intentions:
		result.intentions.append(fields(intent, ["source", "kind", "cells", "from", "target"]))
	result["events"] = []
	for event in state.events:
		var item := fields(event, EVENT_FIELDS.get(event.type, []))
		item["type"] = event.type
		result.events.append(item)
	return result

func as_ints(value: Variant) -> Variant:
	# Godot JSON numbers are floats, but the public action contract requires ints.
	if value is float and value == floor(value):
		return int(value)
	if value is Array:
		var result := []
		for item in value:
			result.append(as_ints(item))
		return result
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = as_ints(value[key])
		return result
	return value

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("Cannot write " + path)
		return
	file.store_string(JSON.stringify(value, "\t", true) + "\n")

func replay(corpus: Dictionary, output: String) -> void:
	var rows := []
	for episode in corpus.episodes:
		var game = model(fixture(episode.fixture))
		var initial: Dictionary = game.snapshot()
		rows.append({"episode": episode.id, "step": -1, "fixture": episode.fixture, "state": project(initial)})
		for index in range(episode.actions.size()):
			var action: Dictionary = episode.actions[index]
			if action.type == "$reset":
				game.reset()
				check(game.snapshot() == initial, episode.id + ": reset")
				rows.append({"episode": episode.id, "step": index, "action": action, "state": project(game.snapshot())})
				continue
			var before: Dictionary = game.snapshot()
			var assessment: Dictionary = game.assess(action)
			check(game.snapshot() == before, episode.id + ": assess pure at " + str(index))
			var accepted: bool = game.act(action)
			check(accepted == assessment.legal, episode.id + ": assess/act agree at " + str(index))
			if accepted:
				check(game.snapshot() == assessment.preview, episode.id + ": exact preview at " + str(index))
			else:
				check(game.snapshot() == before, episode.id + ": atomic reject at " + str(index))
				check(not assessment.reason.is_empty() and assessment.preview.is_empty(), episode.id + ": explained reject at " + str(index))
			rows.append({
				"episode": episode.id, "step": index, "action": action,
				"legal": assessment.legal, "committed": accepted, "state": project(game.snapshot()),
			})
	write_json(output, {"schema": "borrowed-turns-mechanics-v1", "rows": rows})
	print("Replay: ", corpus.episodes.size(), " episodes; ", rows.size(), " rows; ", checks, " checks; ", failures.size(), " failures; ", output)

func _initialize() -> void:
	var adapter_path := option("adapter")
	if not adapter_path.is_empty():
		adapter = load(adapter_path).new()
	var corpus_path := option("corpus")
	var output := option("out")
	if corpus_path.is_empty() or output.is_empty():
		printerr("Required: -- --corpus=PATH --out=PATH [--adapter=PATH]")
		quit(2)
		return
	var corpus: Dictionary = as_ints(JSON.parse_string(FileAccess.get_file_as_string(corpus_path)))
	replay(corpus, output)
	quit(0 if failures.is_empty() else 1)
