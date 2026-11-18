extends SceneTree
## Actual chooser and Stage integration, not model tuning or visual acceptance.
const F = preload("res://ui/smoke_fixtures.gd")
const IDS := ["flanker", "lantern-guard", "circler", "deadeye", "anchor", "puller"]
const LEGACY := ["switcher", "switcher-b", "two-pursuers"]

var game: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func press(button: Button) -> void:
	check(not button.disabled, "enabled control: " + button.text)
	if not button.disabled: button.pressed.emit()

func settle() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while game.resolving and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not game.resolving, "finite feedback settles")
	await process_frame

func choose(id: String, accept: bool = true) -> bool:
	var picker: OptionButton = game.encounter_picker
	var index := -1
	for i in range(picker.item_count):
		if picker.get_item_metadata(i) == id: index = i
	check(index >= 0, "chooser exposes " + id)
	if index < 0: return false
	var before: Dictionary = game.model.snapshot()
	var previous: String = game.encounter_id
	picker.select(index)
	picker.item_selected.emit(index)
	await process_frame
	check(game.encounter_dialog.visible and game.model.snapshot() == before,
		id + ": selection requests confirmation without changing the fight")
	if not game.encounter_dialog.visible: return false
	if accept:
		game.encounter_dialog.confirmed.emit()
	else:
		game.encounter_dialog.get_cancel_button().pressed.emit()
	game.encounter_dialog.hide()
	await process_frame
	if not accept:
		check(game.encounter_id == previous and game.model.snapshot() == before
			and picker.get_selected_metadata() == previous, id + ": cancel preserves fight and selection")
		return false
	check(game.encounter_id == id and picker.get_selected_metadata() == id,
		id + ": confirmation loads the chosen encounter")
	return game.encounter_id == id

func arm() -> void:
	press(game.action_buttons.capture)
	check(game.command == {"type": "capture"} and not game.confirm_button.disabled,
		"Capture is prepared through the normal controls")
	if game.confirm_button.disabled: return
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	await settle()
	check(game.state == expected and game.state.get("capture_armed", false),
		"confirmed Capture commits the visible prediction")

func roster_row(id: String) -> Dictionary:
	for row in game.board.standee_layout():
		if row.get("actor", "") == id: return row
	return {}

func verify_start(id: String) -> void:
	var state: Dictionary = game.state
	check(game._stage_root != null and game._stage_root.visible
		and game.board.stage_renderer != null
		and game._puppet_rig != null and game._puppet_rig.visible,
		id + ": shared Stage and performer rig are ready")
	check(state.get("objective", "") == "defeat_all" and state.get("status", "") == "playing"
		and state.get("turn", 0) == 1 and not state.get("capture_armed", true)
		and state.get("stored", {}).is_empty(), id + ": fresh combat state")
	var enemies: Array = state.get("enemies", [])
	check(enemies.size() == 1, id + ": solo encounter has one opponent")
	if enemies.size() != 1: return
	var enemy: Dictionary = enemies[0]
	var actor: String = enemy.get("id", "")
	var name: String = enemy.get("name", "")
	var expected_name := id.replace("-", " ").to_lower()
	check(not actor.is_empty() and name.to_lower() == expected_name,
		id + ": defined actor has the encounter's visible name")
	var row := roster_row(actor)
	check(not row.is_empty() and str(row.get("name", "")) == name
		and game.board.standee_layout().size() == 2,
		id + ": shared roster shows the named opponent and player only")
	check(enemy.get("presentation", {}).get("kit", "") in ["A", "B"],
		id + ": reuses a shared presentation kit")
	var plans: Array = state.get("intentions", [])
	check(plans.size() == 1 and plans[0].get("source", "") == actor
		and plans[0].get("kind", "") == enemy.get("ability", {}).get("kind", ""),
		id + ": initial plan belongs to the actual opponent and ability")
	var visible_plan := false
	for child in game.intention_list.get_children():
		if child is Button and child.text.contains(name): visible_plan = true
	check(visible_plan, id + ": Details names the initial plan")
	if plans.size() == 1:
		var description: Dictionary = game._two_source_presentation.compose(
			state, game.shadow.frame(), game.generation, [actor], "")
		var source: Dictionary = description.get("sources", {}).get(actor, {})
		var occurrence := {"source": actor, "turn": state.turn, "kind": plans[0].get("kind", "")}
		check(source.get("occurrence", {}) == occurrence and source.get("cells", []) == plans[0].get("cells", []),
			id + ": Director announces the actual stock plan and its exact cells")

func test_stock() -> void:
	var picker: OptionButton = game.encounter_picker
	check(game.encounter_id == "switcher" and picker.get_selected_metadata() == "switcher",
		"default encounter and chooser selection remain switcher")
	check(not game.encounters.has("escape"), "retired escape is absent from the registry")
	for i in range(picker.item_count):
		check(picker.get_item_metadata(i) != "escape" and picker.get_item_text(i) != "Original encounter",
			"retired escape and its former label are absent from the chooser")
	for id in LEGACY:
		var count := 0
		for i in range(picker.item_count):
			if picker.get_item_metadata(i) == id: count += 1
		check(count == 1, "existing chooser entry remains present once: " + id)
	for id in IDS:
		if not await choose(id): continue
		verify_start(id)
		var initial: Dictionary = game.model.snapshot()
		await arm()
		press(game.restart_button)
		check(game.restart_dialog.visible, id + ": changed fight requests restart confirmation")
		if game.restart_dialog.visible:
			game.restart_dialog.confirmed.emit()
			game.restart_dialog.hide()
			await process_frame
		check(game.model.snapshot() == initial and game.history_lines.size() == 1
			and game.command.is_empty() and game.shadow.frame().held.is_empty(),
			id + ": confirmed reset restores the initial fight and clears presentation/history")
		# Leave a committed change for the next chooser transition.
		await arm()
	# Returning to an existing fight must not carry the last stock fight's arm.
	if await choose("switcher"):
		check(not game.state.get("capture_armed", true) and game.state.get("stored", {}).is_empty()
			and game.history_lines.size() == 1 and game.command.is_empty(),
			"switching fights clears arm, storage, history and pending command")

func test_cli() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	var base_args := PackedStringArray(["--headless", "--path", project_path, "--quit-after", "3"])
	var output: Array = []
	var args := base_args.duplicate()
	args.append_array(PackedStringArray(["--", "--encounter=escape"]))
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	var text := str(output[0]) if not output.is_empty() else ""
	check(exit_code == 2 and text.contains("unknown encounter escape")
		and not text.contains("Borrowed Turns UI: start baseline="),
		"retired escape CLI is rejected without starting a fallback encounter")
	for id in [""] + LEGACY + IDS:
		output.clear()
		args = base_args.duplicate()
		if not id.is_empty():
			args.append_array(PackedStringArray(["--", "--encounter=" + id]))
		exit_code = OS.execute(OS.get_executable_path(), args, output, true)
		text = str(output[0]) if not output.is_empty() else ""
		var expected: String = "switcher" if id.is_empty() else id
		check(exit_code == 0 and text.contains("Borrowed Turns UI: start baseline=R2 encounter=" + expected + " presentation=stage"),
			"CLI starts the requested encounter: " + ("default" if id.is_empty() else id))

func test_controlled_announcements() -> void:
	# Definitions and geometry are test-owned. The fixture exercises generic
	# existing ability kinds without depending on how the six fights are tuned.
	for kind in ["bolt", "burst"]:
		var skill := F.ability(kind, 1, 3, 1 if kind == "burst" else 0)
		var data := F.encounter([
			{"id": "A", "definition": "controlled", "pos": [2, 1], "dir": [0, 1]},
		], 3, 20)
		data.player.pos = [2, 3]
		data["opponent_definitions"] = {"controlled": {
			"name": "Controlled " + kind.capitalize(), "stats": {"max_hp": 12},
			"abilities": [skill], "decision": "fixed", "presentation": {"kit": "A"},
		}}
		game.fixture = data
		game._start_encounter()
		await process_frame
		var state: Dictionary = game.model.snapshot()
		var plans: Array = state.get("intentions", [])
		check(state.get("status", "") == "playing" and plans.size() == 1,
			kind + ": live controlled opponent produces one plan")
		if plans.size() != 1: continue
		var plan: Dictionary = plans[0]
		var desc: Dictionary = game._two_source_presentation.compose(
			state, game.shadow.frame(), game.generation, ["A"], "")
		var source: Dictionary = desc.get("sources", {}).get("A", {})
		check(source.get("occurrence", {}) == {"source": "A", "turn": state.turn, "kind": kind}
			and source.get("cells", []) == plan.cells,
			kind + ": definition-backed Stage Director retains the actual announcement")
		check(roster_row("A").get("name", "") == "Controlled " + kind.capitalize(),
			kind + ": reused kit identifies its actual opponent")

func _run() -> void:
	game = load("res://scenes/encounter.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if not game.encounter_picker is OptionButton or not game.encounter_dialog is ConfirmationDialog:
		printerr("SETUP REQUIRED: existing playable chooser controls")
		game.queue_free()
		quit(2)
		return
	await choose("flanker", false)
	await test_stock()
	await test_controlled_announcements()
	test_cli()
	print("Stocked scene: %d checks, %d failures. Injected controls, not physical input or visual acceptance." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
