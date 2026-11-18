extends SceneTree
## Real scene controls with controlled inputs. Not physical OS input or model unit tests.

const F = preload("res://ui/smoke_fixtures.gd")
const P = preload("res://ui/presentation.gd")
const Production = preload("res://content/escape.gd")
var game: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("R2 UI smoke: " + description)

func press(button: Button) -> void:
	check(not button.disabled, "enabled control: " + button.text)
	if not button.disabled: button.pressed.emit()

func click(cell: Array) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.board.cell_center(cell)
	game.board.gui_input.emit(event)

func settle() -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while game.resolving and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not game.resolving, "finite feedback completes without persistent-loop lock")
	await process_frame

func load_fixture(data: Dictionary) -> void:
	game.fixture = data.duplicate(true)
	game._start_encounter()
	await process_frame

func select(action: String, target: Array = []) -> void:
	press(game.action_buttons[action])
	if not target.is_empty(): click(target)

func commit() -> void:
	if game.confirm_button.disabled:
		check(false, "legal confirmation: " + game.consequence.text)
		return
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	await settle()
	check(game.state == expected and game.model.snapshot() == expected, "confirmed state matches exact visible prediction")

func move(to: Array) -> void:
	var before: Dictionary = game.model.snapshot()
	select("move", to)
	check(game.model.snapshot() == before, "selection and assessment do not mutate")
	await commit()

func preview_matches() -> bool:
	return game.preview_details.text == P.preview_text(game.prediction)

func ap_only(text: String) -> bool:
	var legacy := RegEx.new()
	legacy.compile("(?i)\\bMP\\b|movement points")
	return legacy.search(text) == null

func _prepare_arm() -> bool:
	var before: Dictionary = game.model.snapshot()
	var history: Array = game.history_lines.duplicate()
	select("capture")
	var ready: bool = game.command == {"type": "capture"} and not game.confirm_button.disabled
	check(ready, "Capture prepares a targetless one-AP arm operation without choosing an attacker")
	check(game.model.snapshot() == before and game.history_lines == history,
		"preparing Capture is a nonmutating assessment, never immediate acquisition")
	if ready:
		check(game.prediction.get("capture_armed", false)
			and game.prediction.get("action_points", -1) == before.action_points - 1
			and game.prediction.get("stored", {}) == before.stored
			and game.prediction.get("intentions", []) == before.intentions,
			"arm preview spends one AP, preserves held power and every dangerous attack")
		check(preview_matches() and game.consequence.text.contains("1 AP"),
			"arming has the exact ordered model preview and visible AP cost")
	return ready

func _prepare_shine(target: Array) -> bool:
	var available: bool = game.action_buttons.has("shine")
	check(available, "Shine replaces the Release operation")
	if not available: return false
	select("shine")
	await _stage_gui_click(game.board.cell_center(target), true)
	check(game.command == {"type": "shine", "target": target}, "Shine uses the chosen endpoint without a chosen attacker")
	check(not game.confirm_button.disabled and preview_matches(), "legal Shine has a synchronized model preview")
	return not game.confirm_button.disabled

func _test_arm_damage_and_reuse() -> void:
	await load_fixture(F.armed_fight())
	var initial: Dictionary = game.model.snapshot()
	check(not initial.get("capture_armed", true) and initial.stored.is_empty(),
		"new fight starts unarmed with no borrowed ability")
	check(game.action_buttons.keys() == ["move", "capture", "shine", "end_turn"],
		"only Move/Capture/Shine/End turn exist; Release is retired")
	var help: String = game.help_dialog.dialog_text.to_lower()
	check(help.contains("shine") and not help.contains("backlash") and not help.contains("deadline")
		and not help.contains("capture and end turn are free"),
		"controls explain paid arming and reusable Shine, not the removed bargain")
	if not await _prepare_arm(): return
	game._cancel()
	check(game.model.snapshot() == initial and game.command.is_empty(), "Cancel before confirmation does not arm or spend AP")
	if not await _prepare_arm(): return
	await commit()
	check(game.state.get("capture_armed", false) and game.state.stored.is_empty()
		and game.state.action_points == 2 and game.state.turn == 1,
		"confirming Capture spends exactly one AP without acquiring or ending turn")
	check(game.state.intentions == initial.intentions and game.board.announcement_marks().size() == 1,
		"arming does not remove the actual shove warning or normal danger")
	check(game.budgets.text.to_lower().contains("armed") or game.stored.text.to_lower().contains("armed"),
		"armed state is visible outside the scrollable Details sheet")
	game._cancel()
	check(game.state.get("capture_armed", false) and game.state.action_points == 2,
		"preview Cancel is not disarm and never refunds a committed arm")
	var armed: Dictionary = game.model.snapshot()
	var history: Array = game.history_lines.duplicate()
	game._choose_action("capture")
	game._confirm()
	check(game.model.snapshot() == armed and game.history_lines == history,
		"duplicate arm is rejected atomically without acquisition or extra AP")
	game._cancel()
	select("end_turn")
	check(game.prediction.get("player", {}).get("hp", 20) == 18
		and game.prediction.get("player", {}).get("pos", []) == [2, 4]
		and game.prediction.get("stored", {}).get("source", "") == "A",
		"actual two-source preview includes full hit/push, then acquisition, then second hit")
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	var seen: Array = []
	var handoff_after_strike := false
	var time_limit := Time.get_ticks_msec() + 10000
	while game.resolving and Time.get_ticks_msec() < time_limit:
		var frame: Dictionary = game.shadow.frame()
		var cue: Dictionary = frame.get("cue", {})
		var index: int = cue.get("event_index", -1)
		if frame.get("busy", false) and index not in seen:
			seen.append(index)
			var desc: Dictionary = game._two_source_presentation.compose(game.state, frame, game.generation, ["A", "B"], "")
			if cue.get("type", "") == "resolve" and cue.get("source", "") == "A":
				check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(),
					"no motif leaves attacker before its ordinary damaging strike")
			if cue.get("type", "") == "capture":
				handoff_after_strike = seen.size() > 1
				check(cue.get("to", []) == [2, 4], "real handoff follows the player's actual pushed position")
			var once: Dictionary = game.model.snapshot()
			var committed_history: Array = game.history_lines.duplicate()
			game._confirm()
			check(game.model.snapshot() == once and game.history_lines == committed_history, "finite feedback locks repeat commitment")
		await process_frame
	check(not game.resolving and handoff_after_strike and seen.size() == 3,
		"normal first strike, handoff and second attack have distinct finite stages")
	check(game.state == expected and game.model.snapshot() == expected
		and game.state.player.hp == 18 and not game.state.get("capture_armed", true),
		"damage is not prevented; acquisition settles exactly to model prediction")
	var held: Dictionary = game.state.stored.duplicate(true)
	for _repeat in range(2):
		if not await _prepare_shine([2, 2]): return
		check(game.prediction.get("stored", {}) == held and game.consequence.text.contains("1 AP"),
			"each one-AP Shine retains the held ability, not a consumed shot")
		await commit()
		check(game.state.stored == held and game.shadow.frame().held == held, "same held motif survives repeated Shine")
	await move([3, 4])
	check(game.state.action_points == 0 and game.state.turn == 2
		and game.action_buttons.capture.disabled and game.action_buttons.shine.disabled
		and not game.action_buttons.end_turn.disabled, "zero AP blocks both paid actions, keeps explicit free End turn")
	var zero: Dictionary = game.model.snapshot()
	select("end_turn")
	check(game.model.snapshot() == zero, "exhausting AP never auto-advances combat")
	game._cancel()
	for _turn in range(3):
		select("end_turn")
		await commit()
		check(game.state.stored == held, "holding past the old deadline neither expires nor discharges the ability")
	check(not game.budgets.text.to_lower().contains("deadline")
		and not game.stored.text.to_lower().contains("backlash")
		and not game.stage_held_details.text.to_lower().contains("backlash"),
		"HUD and Details contain reusable held source/ability, not deadline or backlash")

func _test_shine_source_loss_and_replay() -> void:
	await load_fixture(F.shine_victory())
	if not await _prepare_arm(): return
	await commit()
	select("end_turn")
	await commit()
	check(game.state.player.hp == 19 and game.state.stored.get("source", "") == "A", "winning fixture first pays the full real acquisition hit")
	var generation: int = game.generation
	for remaining in [1, 0]:
		if not await _prepare_shine([2, 1]): return
		var after: Dictionary = game.prediction
		var lost := false
		for event in after.get("events", []):
			if event.type == "ability_lost":
				lost = event.get("source", "") == "A" and event.get("reason", "") == "source_dead"
		check(lost == (remaining == 0), "only the actual source-defeating Shine loses the borrowed power")
		if remaining == 0:
			check(game.preview_details.text.to_lower().contains("source")
				and game.preview_details.text.to_lower().contains("lost"),
				"source-death loss reason is visible in exact preview")
		await commit()
		check(game.state.stored.is_empty() == (remaining == 0), "held power lasts until its source actually falls")
	check(game.state.status == "won" and game.result.visible
		and not game.result.text.to_lower().contains("escape") and game.shadow.frame().held.is_empty(),
		"source-death victory clears held presentation without restoring danger-cancel mechanics")
	check(not game.history.text.to_lower().contains("canceled")
		and not game.history.text.to_lower().contains("backlash"), "committed history never claims capture prevented a strike")
	press(game.restart_button)
	check(game.generation > generation and game.state.status == "playing"
		and not game.state.get("capture_armed", true) and game.state.stored.is_empty(),
		"terminal Replay clears arming, held power and old finite work")

func _test_shine_keys_and_cancellation() -> void:
	await load_fixture(F.shine_victory())
	if not await _prepare_arm(): return
	await commit()
	select("end_turn")
	press(game.confirm_button)
	var old_generation: int = game.generation
	game._apply_restart()
	await settle()
	check(game.generation > old_generation and not game.state.get("capture_armed", true)
		and game.state.stored.is_empty() and not game.shadow.frame().busy, "restart during hit/handoff cancels stale acquisition")
	if not await _prepare_arm(): return
	await commit()
	select("end_turn")
	await commit()
	var before: Dictionary = game.model.snapshot()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_S
	game._unhandled_key_input(key)
	check(game.mode == "shine" and game.model.snapshot() == before, "S selects Shine without committing it")
	game._cancel()
	key.keycode = KEY_L
	game._unhandled_key_input(key)
	check(game.mode == "inspect" and game.command.is_empty(), "retired L does not alias Release/Shine")
	check(game.model.snapshot() == before, "keyboard selection/cancel preserves authoritative state")

func _stage_resize(viewport_size: Vector2i) -> void:
	root.size = viewport_size
	await process_frame
	await process_frame

func _stage_gui_click(local_point: Vector2, floor_only: bool = false) -> void:
	# Through the actual viewport GUI path, so decorative layers cannot silently
	# eat clicks. This is still injected input, not physical OS input evidence.
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.alt_pressed = floor_only
	event.position = game.board.get_global_transform() * local_point
	game.get_viewport().push_input(event)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.alt_pressed = floor_only
	event.position = game.board.get_global_transform() * local_point
	game.get_viewport().push_input(event)
	await process_frame

func _stage_controls_fit(label: String) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(game.get_viewport_rect().size))
	check(game.board.size.x > game.size.x * 0.8, label + ": theatre gets full-width allocation, not the legacy board column")
	for control in [game.budgets, game.stored, game.phase, game.objective, game.instruction, game.consequence]:
		check(control.is_visible_in_tree(), label + ": persistent tactical information stays visible: " + str(control.name))
		var bounds: Rect2 = control.get_global_rect()
		check(viewport_rect.encloses(bounds) and bounds.size.x > 0 and bounds.size.y > 0, label + ": tactical information is within the viewport")
	for action in game.action_buttons:
		var bounds: Rect2 = game.action_buttons[action].get_global_rect()
		check(game.action_buttons[action].is_visible_in_tree() and viewport_rect.encloses(bounds), label + ": operation remains visible and in bounds: " + action)

func _test_stage_integration() -> void:
	for viewport_size in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(viewport_size)
		for dimensions in [Vector2i(4, 3), Vector2i(9, 5)]:
			var data := F.encounter([F.enemy("a", [2, 1], F.ability("shove", 1, 3, 0, true), 12, [0, -1])])
			data.width = dimensions.x
			data.height = dimensions.y
			data.player.pos = [1, 1]
			data.exit.pos = [dimensions.x - 1, dimensions.y - 1]
			await load_fixture(data)
			var before: Dictionary = game.model.snapshot()
			_stage_controls_fit("stage %s / %s" % [viewport_size, dimensions])
			for cell in [[0, 0], [dimensions.x - 1, 0], [0, dimensions.y - 1], [dimensions.x - 1, dimensions.y - 1]]:
				var center: Vector2 = game.board.cell_center(cell)
				# This checks floor mapping, including under opaque standee art.
				# Ordinary clicks elsewhere retain the real actor/tab priority.
				await _stage_gui_click(center, true)
				if not (game.selected == cell and game.model.snapshot() == before):
					print("DIAG stage corner: ", {"requested_viewport": viewport_size, "viewport": game.get_viewport_rect(),
						"dimensions": dimensions, "cell": cell, "selected": game.selected,
						"center_local": center, "center_global": game.board.get_global_transform() * center,
						"floor_cell": game.board._from_pixel(center), "actor": game.board.actor_at(center),
						"picked_cell": game.board.pick_cell(center), "input_cell": game.board._input_cell(center),
						"floor_only_cell": game.board._input_cell(center, true),
						"board_bounds": game.board.get_global_rect(), "sheet_visible": game._stage_sheet.visible,
						"state_unchanged": game.model.snapshot() == before})
				check(game.selected == cell and game.model.snapshot() == before, "actual viewport targeting reaches every corner without spending a turn")
			var selected_before: Array = game.selected.duplicate()
			await _stage_gui_click(Vector2(1, 1))
			check(game.selected == selected_before and game.model.snapshot() == before, "decorative stage background does not select a board cell")
			game._cancel()
			await _stage_gui_click(game.board.cell_center([2, 1]))
			check(game.source == "a" and game.command.is_empty(), "stage actor selection inspects its true identity, not a capture target")
			if not await _prepare_arm(): continue
			check(preview_matches(), "ordered preview stays synchronized before commitment")
			# Details are explicit in the playable theatre, rather than automatically
			# covering the performers after every board selection.
			if not game._stage_sheet.visible: press(game._stage_plans)
			await process_frame # Let Containers lay out the newly visible sheet.
			check(game.preview_details.is_visible_in_tree(), "ordered preview is visibly accessible through Details before commitment")
			for control in [game.preview_details, game.confirm_button, game.cancel_button]:
				check(control.is_visible_in_tree() and game.get_viewport_rect().encloses(control.get_global_rect()),
					"stage preview/confirmation remains within the actual viewport")
			var selected_command: Dictionary = game.command.duplicate(true)
			var selected_prediction: Dictionary = game.prediction.duplicate(true)
			var paper_piece: Dictionary = game.board.piece_appearance([1, 1])
			await _stage_resize(Vector2i(1280, 800))
			check(game.command == selected_command and game.prediction == selected_prediction and game.model.snapshot() == before, "resize preserves target, preview and authoritative state")
			check(game.board._from_pixel(game.board.cell_center([2, 1])) == [2, 1], "resized stage shares drawing/target mapping")
			check(game.board.piece_appearance([1, 1]) == paper_piece, "resizing leaves stable cell paper unchanged")
			press(game.confirm_button)
			check(game.resolving, "stage command starts existing finite feedback")
			check(game.board.piece_appearance([1, 1]) == paper_piece, "capture outcomes do not change the paper field")
			await settle()
			select("end_turn")
			press(game.confirm_button)
			check(game.resolving and game.board.piece_appearance([1, 1]) == paper_piece, "new-turn feedback preserves the same visual paper seed")
			var old_generation: int = game.generation
			game._apply_restart()
			await settle()
			check(game.generation > old_generation and game.state == before and game.shadow.frame().held.is_empty() and not game.shadow.frame().busy, "stage restart during feedback removes old held state and stale work")
			check(game.board.piece_appearance([1, 1]) == paper_piece, "restart does not reshuffle the same visual field")
			await _stage_resize(viewport_size)
	# Real authored escape content plus controlled hit acquisition at each size.
	for viewport_size in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(viewport_size)
		await load_fixture(Production.DATA)
		_stage_controls_fit("actual encounter " + str(viewport_size))
		await load_fixture(F.armed_fight())
		if not await _prepare_arm(): continue
		await commit()
		select("end_turn")
		await commit()
		check(game.state.stored.get("source", "") == "A" and game.state.player.hp == 18,
			"minimum and wide Stage support full damaging acquisition, not a capture-only pose")
	await _stage_resize(Vector2i(1280, 800))

func _two_pursuers_setup() -> bool:
	var properties: Array[String] = []
	for property in game.get_property_list(): properties.append(property.name)
	for name in ["encounter_id", "encounter_picker", "encounter_dialog"]:
		if name not in properties:
			printerr("SETUP REQUIRED: loadable playable encounter UI seam: " + name + "; not behavioral RED")
			return false
	if not game.has_method("request_encounter") or not game.encounter_picker is OptionButton \
		or not game.encounter_dialog is ConfirmationDialog:
		printerr("SETUP REQUIRED: request_encounter(id), real encounter_picker and encounter_dialog controls")
		return false
	for method in ["configure_standees", "standee_layout", "actor_at", "pick_cell", "focus_actor"]:
		if not game.board.has_method(method):
			printerr("SETUP REQUIRED: board." + method + "; not behavioral RED")
			return false
	return true

func _choose_encounter_ui(id: String) -> void:
	var picker: OptionButton = game.encounter_picker
	var index := -1
	for item in range(picker.item_count):
		if picker.get_item_metadata(item) == id: index = item
	check(index >= 0, "visible encounter chooser exposes " + id)
	if index >= 0:
		picker.select(index)
		picker.item_selected.emit(index)
	await process_frame

func _check_default_puppet_pack() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--puppet-pack="): return
	var directory := "res://assets/puppets/two-pursuers"
	check(game._puppet_pack == directory, "default puppet pack is a shipped resource path")
	for name in ["a-body", "a-hands", "b-body", "b-hands", "p-lantern"]:
		var path := directory.path_join(name + ".png")
		check(ResourceLoader.exists(path, "Texture2D"), "shipped puppet resource exists: " + path)
		var source = load(path) if ResourceLoader.exists(path, "Texture2D") else null
		var actual = game._puppet_art.get(name.replace("-", "_"))
		if not source is Texture2D or not actual is Texture2D:
			check(false, "puppet source and loaded texture exist: " + name)
			continue
		var source_image: Image = source.get_image()
		var actual_image: Image = actual.get_image()
		var expected := Vector2i(145, 145) if name == "p-lantern" else Vector2i(290, 145)
		check(source_image != null and not source_image.is_empty() and source_image.get_size() == expected
			and source_image.detect_alpha() != Image.ALPHA_NONE, "shipped puppet source has native alpha canvas: " + name)
		check(actual_image != null and source_image != null and actual_image.get_size() == source_image.get_size()
			and actual_image.get_data() == source_image.get_data(), "runtime puppet pixels match shipped source: " + name)

func _standee_entry(id: String) -> Dictionary:
	for row in game.board.standee_layout():
		if row.get("actor", "") == id: return row
	return {}

func _standee_body_point(id: String) -> Vector2:
	var row := _standee_entry(id)
	if not row.get("rect") is Rect2 or not row.get("texture") is Texture2D:
		return Vector2(INF, INF)
	var texture: Texture2D = row.texture
	var pixels := texture.get_image()
	var rect: Rect2 = row.rect
	if pixels == null or pixels.is_empty(): return Vector2(INF, INF)
	# Find actual visible body, above its floor cell, not a synthetic rectangle
	# or its separate foot marker. No portrait-specific facial coordinates.
	for y in range(0, pixels.get_height(), 24):
		for x in range(0, pixels.get_width(), 24):
			if pixels.get_pixel(x, y).a < 0.5: continue
			var point := rect.position + Vector2(x + 0.5, y + 0.5) / Vector2(pixels.get_size()) * rect.size
			if game.board.actor_at(point) == id and game.board._from_pixel(point) != row.cell:
				return point
	return Vector2(INF, INF)

func _test_two_pursuers_startup() -> void:
	_check_default_puppet_pack()
	check(game.encounter_id == "two-pursuers",
		"actual command-line encounter and presentation select the normal playable scene")
	check(game.state.get("objective", "") == "defeat_all", "normal fight objective is explicitly defeat all opponents")
	check(game.state.rules.actions == 3 and game.state.action_points == 3
		and not game.state.has("movement_points") and not game.state.rules.has("movement"),
		"actual candidate starts with three shared AP and no player MP schema")
	var player: Array = game.state.player.pos
	check(player == [0, int(game.state.height / 2.0)], "actual fight starts at the left edge midpoint")
	var corners: Array = []
	var patterns: Array = []
	for enemy in game.state.enemies:
		corners.append(enemy.pos)
		patterns.append(enemy.get("movement_pattern", ""))
		check(enemy.ability.get("width", 1) == (3 if enemy.id == "B" else 1),
			"actual B uses the three-wide shove while A remains narrow")
	for intent in game.state.intentions:
		if intent.source == "B":
			check([game.state.width - 2, game.state.height - 2] in intent.cells
				and [game.state.width - 2, game.state.height - 1] in intent.cells
				and [game.state.width - 1, game.state.height - 2] not in intent.cells,
				"actual corner B warning includes its in-bounds side lane, not origin-side cells")
	check(corners.size() == 2 and [game.state.width - 1, 0] in corners
		and [game.state.width - 1, game.state.height - 1] in corners,
		"actual opponents start at the opposite edge's two corners")
	check("chase_player" in patterns and "keep_max_range" in patterns,
		"default fight exposes both requested active opponent roles")
	var picker: OptionButton = game.encounter_picker
	check(picker.get_selected_metadata() == "two-pursuers", "visible chooser reflects the command-line encounter")
	check(not game.objective.text.to_lower().contains("exit"), "default visible objective is combat, not bypassing enemies")
	check(game.board.standee_layout().size() == 3, "command-line entry loads all three approved standee actors")

func _test_shared_ap_and_ranges() -> void:
	await load_fixture(F.encounter([], 3))
	await move([2, 3])
	await move([3, 3])
	if not await _prepare_arm(): return
	await commit()
	check(game.state.action_points == 0 and game.state.turn == 1 and game.state.capture_armed,
		"two single-tile moves plus paid arming exhaust three AP without automatic End turn")
	var before: Dictionary = game.model.snapshot()
	var history: Array = game.history_lines.duplicate()
	game._choose_action("move")
	click([3, 2])
	game._confirm()
	check(game.confirm_button.disabled and game.prediction.is_empty()
		and game.model.snapshot() == before and game.history_lines == history,
		"over-budget move is atomic and never prepares a stale legal preview")
	game._cancel()
	select("end_turn")
	game._cancel()
	check(game.model.snapshot() == before, "canceling free End turn does not advance combat")
	select("end_turn")
	await commit()
	check(game.state.turn == 2 and game.state.action_points == 3 and game.state.capture_armed,
		"explicit End turn refreshes AP; a missed armed attack does not consume the arm")
	check(ap_only(game.budgets.text + game.availability.text + game.history.text + game.help_dialog.dialog_text),
		"budget/help/history have one AP resource and no MP")
	await load_fixture(F.encounter([], 0))
	before = game.model.snapshot()
	history = game.history_lines.duplicate()
	game._choose_action("capture")
	game._confirm()
	check(game.confirm_button.disabled and game.prediction.is_empty()
		and game.model.snapshot() == before and game.history_lines == history,
		"unarmed Capture at zero AP rejects atomically, not a free acquisition")
	game._cancel()
	for skill in [F.ability("bolt", 1, 4), F.ability("shove", 1, 3, 0, true), F.ability("burst", 1, 2, 1)]:
		var data := F.encounter([F.enemy("A", [2, 1], skill, 12, [0, 1])], 3)
		data.width = 9 # Both max-range and one-beyond are in bounds.
		data.player.pos = [2, 3]
		await load_fixture(data)
		if not await _prepare_arm(): continue
		await commit()
		select("end_turn")
		await commit()
		check(game.state.stored.get("ability", {}) == skill, "real hit acquires the authored ray/area ability unchanged")
		if skill.kind == "shove":
			before = game.model.snapshot()
			if not await _prepare_shine([2, 1]): continue
			check(game.prediction.events.any(func(event):
				return event.type == "displace" and event.actor == "A" and event.from == [2, 1] and event.to == [2, 0])
				and game.model.snapshot() == before, "normal borrowed shove previews actual source displacement away, without mutating it")
			await commit()
			check(_standee_entry("A").cell == [2, 0] and game.state.stored.get("source", "") == "A",
				"confirmed borrowed shove moves the accepted source actor away and keeps its reusable power")
		var origin: Array = game.state.player.pos
		var target := [origin[0] + skill.range, origin[1]]
		if not await _prepare_shine(target): continue
		check(game.board.preview == game.prediction and game.board.selected == target,
			"Shine uses the model's exact inherited-range prediction and board target")
		var kind := "area" if skill.kind == "burst" else "ray"
		check(game.prediction.events.any(func(event): return event.type == kind and event.actor == "player"),
			"borrowed burst stays an area; line abilities stay rays")
		before = game.model.snapshot()
		history = game.history_lines.duplicate()
		await _stage_gui_click(game.board.cell_center([target[0] + 1, target[1]]), true)
		game._confirm()
		check(game.prediction.is_empty() and game.confirm_button.disabled and game.model.snapshot() == before
			and game.history_lines == history, "in-bounds target beyond inherited range rejects without stale preview or mutation")
		if not await _prepare_shine(target): continue
		check(not game.command.has("invert") and not game.model.snapshot().has("invert_enabled"),
			"normal Shine has no retired Invert/adjust command")
		await commit()
		check(game.state.stored.get("ability", {}) == skill, "nonlethal Shine retains the complete borrowed ability")

func _test_actor_access() -> void:
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		await load_fixture(F.two_pursuers(true))
		var before: Dictionary = game.model.snapshot()
		for id in ["A", "B"]:
			var row := _standee_entry(id)
			var body := _standee_body_point(id)
			check(body.is_finite(), id + ": actual opaque body is reachable above its owning cell")
			if body.is_finite():
				check(game.board.actor_at(body) == id and game.board._from_pixel(body) != row.cell,
					"ordinary body selection has priority over the different floor cell behind it")
				await _stage_gui_click(body)
				check(game.source == id and game.selected == row.cell, "body GUI input inspects the true actor identity")
			for hit_rect in [row.tab_rect, row.roster_rect]:
				await _stage_gui_click(hit_rect.get_center())
				check(game.source == id and game.selected == row.cell
					and game.command.is_empty() and game.prediction.is_empty(),
					"foot marker and off-grid roster inspect the same actor without inventing a capture target")
			check(game.model.snapshot() == before, "all actor access paths leave budgets, threats and storage unchanged")
		press(game._stage_plans)
		game.event_tabs.current_tab = game.event_tabs.get_tab_idx_from_control(game.details_scroll)
		await process_frame
		var plan: Button
		for child in game.intention_list.get_children():
			if child is Button: plan = child; break
		check(plan != null, "Details exposes a real current-source intention control")
		if plan:
			press(plan)
			check(game.source == before.intentions[0].source and game.command.is_empty()
				and game.model.snapshot() == before, "intention-row selection inspects the actual source without advancing or acquiring")
		press(game._stage_plans)
		var ordered: Array = game.board.standee_layout()
		var target_index := -1
		for i in range(ordered.size()):
			if ordered[i].actor == "A": target_index = i
		check(target_index >= 0, "keyboard fixture contains the rear source")
		if target_index >= 0:
			game.board.cursor = ordered[posmod(target_index - 1, ordered.size())].cell.duplicate()
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_BRACKETRIGHT
			game.board.gui_input.emit(key)
			key.keycode = KEY_ENTER
			game.board.gui_input.emit(key)
			check(game.source == "A" and game.command.is_empty() and game.model.snapshot() == before,
				"bracket/Enter reaches an obscured actor for inspection, never an implicit acquisition")
		if not await _prepare_arm(): continue
		await _stage_gui_click(game.board.cell_center([0, 0]), true)
		check(game.command == {"type": "capture"} and game.model.snapshot() == before,
			"arming has no chosen source even after body/marker/floor inspection")
		game._cancel()
	await _stage_resize(Vector2i(1280, 800))

func _test_chooser() -> void:
	var original: Dictionary = game.model.snapshot()
	var original_id: String = game.encounter_id
	await _choose_encounter_ui("escape")
	check(game.encounter_dialog.visible and game.model.snapshot() == original,
		"chooser requests replacing the encounter without mutating the live fight")
	game.encounter_dialog.get_cancel_button().pressed.emit()
	game.encounter_dialog.hide()
	check(game.encounter_id == original_id and game.model.snapshot() == original, "canceling chooser preserves the current run")
	await _choose_encounter_ui("escape")
	game.encounter_dialog.confirmed.emit()
	game.encounter_dialog.hide()
	await process_frame
	check(game.encounter_id == "escape" and game.fixture == Production.DATA
		and game.state.objective == "escape", "explicit escape chooser uses the real retained authored content")
	await _choose_encounter_ui("two-pursuers")
	game.encounter_dialog.confirmed.emit()
	game.encounter_dialog.hide()
	await process_frame
	_test_two_pursuers_startup()

func _test_active_motion() -> void:
	await load_fixture(F.active_fight())
	var initial: Dictionary = game.model.snapshot()
	var history: Array = game.history_lines.duplicate()
	check(not initial.has("exit") and not game.objective.text.to_lower().contains("exit"), "no-exit combat uses explicit defeat-all facts")
	select("end_turn")
	var assessment: Dictionary = game.model.assess({"type": "end_turn"})
	check(game.prediction == assessment.preview and preview_matches()
		and game.model.snapshot() == initial and game.history_lines == history,
		"UI previews old attacks and voluntary movement through the model, not another planner")
	var movement: Array = []
	for event in game.prediction.events:
		if event.type == "move" and event.actor != "player":
			movement.append(event)
			check(game.preview_details.text.contains(P.event_text(event)), "ordered preview names actual moving actors and destinations")
	check(movement.size() == 2, "controlled mobile encounter exercises both opponent roles")
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	var seen: Array = []
	var fresh_early := false
	var time_limit := Time.get_ticks_msec() + 10000
	history = game.history_lines.duplicate()
	while game.resolving and Time.get_ticks_msec() < time_limit:
		var frame: Dictionary = game.shadow.frame()
		if frame.busy:
			fresh_early = fresh_early or not frame.announcements.is_empty() or not game.board.announcement_waves().is_empty()
		if frame.cue.get("type", "") == "move" and frame.cue.get("actor", "") not in seen:
			seen.append(frame.cue.actor)
			var event: Dictionary = expected.events[frame.cue.event_index]
			check(event.type == "move" and event.actor == frame.cue.actor
				and event.from == frame.cue.from and event.to == frame.cue.to, "slide references its actual model event and endpoints")
			game._confirm()
			game._select_cell([0, 0])
			check(game.model.snapshot() == expected and game.history_lines == history, "input stays locked throughout each finite slide")
		await process_frame
	check(not game.resolving and seen == ["A", "B"] and not fresh_early
		and game.state == expected, "both event-owned slides settle exactly before fresh rehearsal")
	for enemy in expected.enemies:
		var row := _standee_entry(enemy.id)
		check(row.cell == enemy.pos and row.foot.distance_to(game.board.cell_center(enemy.pos)) < 0.01,
			"settled accepted standee ends on its exact authoritative cell")
	select("end_turn")
	press(game.confirm_button)
	var generation: int = game.generation
	game._apply_restart()
	await settle()
	check(game.generation > generation and game.state == initial and not game.shadow.frame().busy
		and game.history_lines.size() == 1, "restart cancels old slides and restores this fixture, not stale events")

func _test_escape_keyboard_and_replay() -> void:
	await load_fixture(F.encounter([], 2))
	var before: Dictionary = game.model.snapshot()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_E
	game._unhandled_key_input(key)
	check(game.command == {"type": "end_turn"} and game.model.snapshot() == before, "E prepares free End turn without commitment")
	key.keycode = KEY_ESCAPE
	game._unhandled_key_input(key)
	check(game.command.is_empty() and game.model.snapshot() == before, "Escape cancels preview without advancing the game")
	select("move")
	game.board.cursor = [2, 3]
	key.keycode = KEY_ENTER
	game.board.gui_input.emit(key)
	check(game.model.snapshot() == before and game.confirm_button.has_focus(), "board Enter selects; separate confirmation commits")
	await commit()
	check(game.state.action_points == 1, "single move spends exactly one shared AP")
	var winning := F.encounter([], 2)
	winning.exit = {"pos": [2, 3], "opens": 1}
	await load_fixture(winning)
	await move([2, 3])
	check(game.state.status == "won" and game.result.visible and game.result.text.to_lower().contains("escape")
		and game.history.text.to_lower().contains("escaped") and game.action_buttons.capture.disabled,
		"explicit escape victory keeps terminal board/history and escape wording")
	var generation: int = game.generation
	press(game.restart_button)
	check(game.generation > generation and game.state.status == "playing" and game.state.stored.is_empty()
		and not game.state.capture_armed and game.history_lines.size() == 1, "terminal escape Replay restores the same fixture and clears old work")
	await move([2, 3]) # Win again, then use a non-winning fixture for restart protection.
	await load_fixture(F.encounter([], 2))
	await move([2, 3])
	before = game.model.snapshot()
	press(game.restart_button)
	check(game.restart_dialog.visible, "changed unfinished encounter requests restart confirmation")
	game.restart_dialog.get_cancel_button().pressed.emit()
	game.restart_dialog.hide()
	check(game.model.snapshot() == before and game.changed, "canceling restart preserves progress")
	press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	check(game.state.turn == 1 and game.state.action_points == 2 and game.history_lines.size() == 1, "confirmed restart isolates budgets and history")

func _test_switcher_startup() -> void:
	check(game.encounter_id == "switcher" and game.encounter_picker.get_selected_metadata() == "switcher",
		"normal entry opens solo Switcher, without a hidden study mode or forced unlock")
	var kinds: Array = []
	for enemy in game.state.enemies: kinds.append(enemy.ability.kind)
	check(kinds == ["swap"] and game.state.objective == "defeat_all" and game.state.action_points == 3,
		"actual solo entry uses one damaging Swap opponent and the existing three-AP fight")
	check(game.board.standee_layout().size() == 2 and _standee_entry("B").is_empty(), "solo profile has player and Switcher only, no phantom B")
	if not _standee_entry("A").is_empty():
		check(_standee_entry("A").name.to_lower().contains("switcher"), "provisional A source art has an explicit Switcher roster identity")
	var ids: Array = []
	for i in range(game.encounter_picker.item_count): ids.append(game.encounter_picker.get_item_metadata(i))
	for id in ["switcher", "switcher-b", "two-pursuers", "escape"]:
		check(id in ids, "existing encounter selector offers " + id)

func _choose_switcher_profile(id: String) -> bool:
	var available := false
	for i in range(game.encounter_picker.item_count):
		if game.encounter_picker.get_item_metadata(i) == id: available = true
	check(available, "real chooser contains " + id + " without installing a separate sandbox")
	if not available:
		print("MASKED Switcher chooser path: missing ", id)
		return false
	if game.encounter_id != id:
		await _choose_encounter_ui(id)
		if game.encounter_dialog.visible:
			game.encounter_dialog.confirmed.emit()
			game.encounter_dialog.hide()
		await process_frame
	check(game.encounter_id == id and game.encounter_picker.get_selected_metadata() == id, "confirmed chooser loads the requested Switcher encounter")
	return game.encounter_id == id

func _test_switcher_profiles() -> void:
	_test_switcher_startup()
	for id in ["switcher-b", "switcher"]:
		if not await _choose_switcher_profile(id): continue
		check(game.state.enemies.size() == (2 if id == "switcher-b" else 1), "actual selected profile has only its authored opponents")
		check(game.state.enemies[0].ability.kind == "swap" and _standee_entry("A").name.to_lower().contains("switcher"),
			"Switcher kind and visible role agree when accepted A artwork is reused")
		if id == "switcher-b":
			check(game.state.enemies[1].ability.kind == "shove" and game.state.enemies[1].ability.get("width", 1) == 3,
				"paired B remains the existing wide shove, not another Swap opponent")
		else:
			check(_standee_entry("B").is_empty(), "return to solo removes B's standee and roster hit target")

func _test_switcher_real_hit_and_shine() -> void:
	for pair in [false, true]:
		await load_fixture(F.switcher(pair, 2 if not pair else 5))
		var initial: Dictionary = game.model.snapshot()
		check(_standee_entry("A").get("name", "").to_lower().contains("switcher"), "real active Switcher uses its name, not Pursuer A")
		var initial_row := _standee_entry("A")
		check(initial_row.get("texture") is Texture2D and initial_row.texture.resource_path == "res://assets/standees/two-pursuers/enemy-a.png",
			"new role reuses the exact accepted A PNG, not generated artwork or a primitive substitute")
		if game._puppet_rig:
			var labels := ""
			for row in game._puppet_rig._labels: labels += str(row.get("text", "")) + "\n"
			check(labels.to_lower().contains("switcher"), "Director labels the active reused source as Switcher")
			if not pair: check(not game._puppet_rig._bodies["B"].visible, "solo Director does not show phantom B")
		if not await _prepare_arm(): continue
		await commit()
		select("end_turn")
		var expected: Dictionary = game.prediction.duplicate(true)
		var types: Array = []
		for event in expected.events: types.append(event.type)
		check(types.slice(0, 4) == ["mask", "swap", "damage", "capture"]
			and expected.player.hp == (18 if pair else 19), "real exact preview exchanges first, then applies full hit, then acquires; B remains independently dangerous")
		var exchange: Dictionary = expected.events[1]
		check(game.preview_details.text.to_lower().contains("swap")
			and game.preview_details.text.contains(P.cell(exchange.from)) and game.preview_details.text.contains(P.cell(exchange.to)),
			"exact preview explicitly explains both exchanged positions, not a generic shove")
		var rows: Array = game.board.effect_footprints()
		check(not rows.is_empty() and rows[0].type == "mask" and rows[0].cells == [[2, 3]],
			"actual live preview shows the single model target, never the line or source cell")
		press(game.confirm_button)
		var history: Array = game.history_lines.duplicate()
		var saw_exchange := false
		var time_limit := Time.get_ticks_msec() + 10000
		while game.resolving and Time.get_ticks_msec() < time_limit:
			var frame: Dictionary = game.shadow.frame()
			if frame.cue.get("kind", "") == "swap" and frame.cue.get("type", "") == "resolve":
				var a: Array = game.board._visual_actors()
				var points := {}
				for row in a: points[row.actor] = row.grid - Vector2(0.5, 0.5)
				if points.has("A") and points.has("player"):
					saw_exchange = saw_exchange or (points.A.y > 1.01 and points.A.y < 2.99
						and points.player.y > 1.01 and points.player.y < 2.99)
				game._confirm()
				game._select_cell([0, 0])
				check(game.model.snapshot() == expected and game.history_lines == history, "both relocation participants remain input-locked in one owning ability")
			await process_frame
		check(not game.resolving and saw_exchange and game.state == expected,
			"actual paired standees move continuously together, then settle exactly to the committed model")
		check(game.state.stored.get("ability", {}).get("kind", "") == "swap"
			and _standee_entry("A").rect.size == initial_row.rect.size, "full damaging exchange acquires Swap without resizing the accepted source")
		if pair: continue
		for invalid in [[3, 1], [2, 1], [3, 2], [-1, 1], [2, 4], [1, 1]]:
			var before: Dictionary = game.model.snapshot()
			history = game.history_lines.duplicate()
			select("shine")
			await _stage_gui_click(game.board.cell_center(invalid), true)
			if invalid[0] < 0: game._select_cell(invalid) # Explicit off-board assessment, no injected external input.
			game._confirm()
			check(game.confirm_button.disabled and game.prediction.is_empty() and game.model.snapshot() == before
				and game.history_lines == history, "empty/self/diagonal/off-board/range/wall Swap Shine rejects atomically in the real UI")
		var held: Dictionary = game.state.stored.duplicate(true)
		for target in [[2, 3], [2, 1]]:
			if not await _prepare_shine(target): break
			var mask: Dictionary = game.prediction.events[1]
			check(mask.type == "mask" and mask.cells == [target] and game.prediction.events[2].type == "swap",
				"reusable Swap Shine consumes the real mask then atomic exchange, not a ray")
			await commit()
			check(game.state.player.pos == target, "source-killing Shine still completes the player's actual relocation")
			if game.state.status == "playing": check(game.state.stored == held, "nonlethal Swap Shine retains its source-linked ability")
		check(game.state.status == "won" and game.state.stored.is_empty() and game.shadow.frame().held.is_empty(),
			"second damaging exchange defeats its source and clears power after the full relocation")
		press(game.restart_button)
		check(game.state == initial and not game.state.capture_armed and not game.shadow.frame().busy, "Switcher terminal Replay clears all paired animation and held ownership")

func _test_switcher_real_miss_and_restart() -> void:
	await load_fixture(F.switcher())
	if not await _prepare_arm(): return
	await commit()
	await move([3, 3])
	var before: Dictionary = game.model.snapshot()
	select("end_turn")
	check(game.prediction.events[0].type == "mask" and game.prediction.events[0].cells == [[2, 3]]
		and not game.prediction.events.any(func(event): return event.type in ["swap", "damage", "capture"]),
		"leaving the locked tile previews an honest singleton mask miss, not homing or hidden acquisition")
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	var generation: int = game.generation
	game._apply_restart()
	await settle()
	check(game.generation > generation and not game.shadow.frame().busy and game.state.player.pos == [2, 3],
		"restart during a finite Swap/miss cancels old generation and both actor motions")
	if not await _prepare_arm(): return
	await commit()
	await move([3, 3])
	select("end_turn")
	await commit()
	check(game.state == expected and game.state.player.hp == before.player.hp and game.state.capture_armed,
		"miss keeps normal HP/position and armed capture after exact settlement")

func _run() -> void:
	game = load("res://scenes/encounter.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.action_buttons.keys() == ["move", "capture", "shine", "end_turn"], "only the current four operations exist")
	check(not game.has_method("set_presentation_mode") and not game.board.has_method("set_stage_mode"), "retired presentation selectors remain absent")
	for picker in game.find_children("*", "OptionButton", true, false):
		check(picker == game.encounter_picker, "only the encounter selector remains")
	var focus := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--focus="): focus = arg.trim_prefix("--focus=")
	if focus not in ["", "armed-capture-shine", "stage", "two-pursuers-cli", "switcher"]:
		printerr("Unknown smoke focus: ", focus)
		game.queue_free()
		await process_frame
		quit(2)
		return
	if focus == "two-pursuers-cli":
		_test_two_pursuers_startup()
	elif focus == "armed-capture-shine":
		await _test_arm_damage_and_reuse()
		await _test_shine_source_loss_and_replay()
		await _test_shine_keys_and_cancellation()
	elif focus == "stage":
		await _test_stage_integration()
	elif focus == "switcher":
		await _test_switcher_profiles()
		await _test_switcher_real_hit_and_shine()
		await _test_switcher_real_miss_and_restart()
	else:
		_test_switcher_startup()
		await _test_chooser()
		await _test_switcher_real_hit_and_shine()
		await _test_switcher_real_miss_and_restart()
		await _test_arm_damage_and_reuse()
		await _test_shine_source_loss_and_replay()
		await _test_shine_keys_and_cancellation()
		await _test_shared_ap_and_ranges()
		await _test_actor_access()
		await _test_active_motion()
		await _test_stage_integration()
		await _test_escape_keyboard_and_replay()
	print("Stage UI smoke [%s]: %d checks, %d failures. Injected GUI input, not physical input or enjoyment." % [focus, checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
