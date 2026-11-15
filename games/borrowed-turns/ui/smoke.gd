extends SceneTree
## Focused UI integration checks through real scene controls and board GUI events.
## Not a mechanical test suite or a substitute for independent native input testing.

const Presentation = preload("res://ui/presentation.gd")

var checks := 0
var failures := 0
var game: Control
var capture_dir := ""
var capture_view: SubViewport

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("UI smoke: " + description)

func _press(button: Button) -> void:
	_check(not button.disabled, "control enabled: " + button.text)
	if not button.disabled: button.pressed.emit()

func _click_cell(cell: Array) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.board.cell_center(cell)
	game.board.gui_input.emit(event)

func _settle() -> void:
	await create_timer(0.24).timeout
	await process_frame

func _move(cell: Array) -> void:
	var before: Dictionary = game.model.snapshot()
	_press(game.action_buttons.move)
	_click_cell(cell)
	_check(game.model.snapshot() == before, "targeting and assessment do not mutate the model")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.player.pos == cell, "confirmed move appears in live UI snapshot")

func _capture_image(filename: String) -> void:
	if capture_dir.is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := capture_dir.path_join(filename)
	var image := capture_view.get_texture().get_image()
	_check(image.get_size() == capture_view.size, "capture matches its explicit viewport dimensions")
	var error := image.save_png(path)
	_check(error == OK, "rendered screenshot saved: " + path)

func _preview_text(predicted: Dictionary) -> String:
	var lines: Array[String] = ["Command preview · exact order"]
	for event in predicted.events:
		lines.append(Presentation.event_text(event))
	return "\n".join(lines)

func _displacement(predicted: Dictionary, actor: String) -> Array:
	for event in predicted.events:
		if event.type == "displace" and event.actor == actor:
			return event.to
	return []

func _test_invert_preview_toggle(initial_pull: bool) -> void:
	# Controlled UI fixture, independent of the tuned production encounter.
	game.fixture = {
		"width": 7, "height": 7, "walls": [],
		"player": {"pos": [1, 3], "hp": 6},
		"exit": {"pos": [6, 6], "opens": 20},
		"enemies": [{"id": "shover", "pos": [3, 3], "hp": 3, "kind": "shove", "dir": [0, -1]}],
	}
	game.variant = "V1"
	game.invert_enabled = true
	game._start_encounter()
	_press(game.action_buttons.capture)
	_click_cell([3, 3])
	_check(not game.confirm_button.disabled, "controlled shove capture is legal")
	if game.confirm_button.disabled: return
	_press(game.confirm_button)
	await _settle()
	_check(game.state.stored.get("kind", "") == "shove", "controlled fixture stores shove")
	if game.state.stored.get("kind", "") != "shove": return
	_press(game.action_buttons.release)
	game.pull_switch.set_pressed(initial_pull)
	_click_cell([3, 3])
	var before: Dictionary = game.model.snapshot()
	var selected_before: Array = game.selected.duplicate()
	var initial: Dictionary = game.model.assess(game.command)
	_check(initial.legal and not game.prediction.is_empty(), "controlled initial release is legal")
	if not initial.legal or game.prediction.is_empty(): return
	_check(game.preview_details.text == _preview_text(initial.preview), "initial ordered preview matches model events")
	_check(_displacement(initial.preview, "shover") == ([2, 3] if initial_pull else [4, 3]), "initial shove has the expected unobstructed endpoint")
	game.pull_switch.set_pressed(not initial_pull)
	var toggled: Dictionary = game.model.assess(game.command)
	_check(toggled.legal and game.prediction == toggled.preview, "toggle reassesses the selected release")
	_check(game.selected == selected_before and game.model.snapshot() == before, "toggle neither reselects a target nor changes live state")
	if not toggled.legal: return
	_check(_displacement(toggled.preview, "shover") == ([4, 3] if initial_pull else [2, 3]), "toggled shove has the distinct unobstructed endpoint")
	_check(game.event_tabs.current_tab == 1 and game.preview_details.is_visible_in_tree(), "ordered Preview tab is visible")
	_check(game.preview_details.text == _preview_text(toggled.preview), "ordered Preview text reflects %s after toggle" % ("push" if initial_pull else "pull"))
	var expected: Dictionary = toggled.preview.duplicate(true)
	_press(game.confirm_button)
	await _settle()
	_check(game.model.snapshot() == expected and game.state == expected, "confirmation matches toggled prediction")

func _run() -> void:
	game = load("res://scenes/encounter.tscn").instantiate()
	if capture_dir.is_empty():
		root.add_child(game)
	else:
		# A tiling compositor can refuse native window dimensions. Capture a real
		# fixed-size rendered viewport instead of mislabeling the compositor's size.
		capture_view = SubViewport.new()
		capture_view.size = Vector2i(1280, 800)
		capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_view.gui_embed_subwindows = true
		root.add_child(capture_view)
		capture_view.add_child(game)
	await process_frame
	await process_frame
	_check(game.state.status == "playing", "scene opens to a usable encounter")
	_check(game.variant_buttons.size() == 6, "all six variant controls exist")
	_check(game.state.intentions.size() == 2, "current complete intentions are wired")
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		capture_view.size = Vector2i(1280, 800)
		await _capture_image("ui-1280-start.png")
		capture_view.size = Vector2i(1024, 720)
		await _capture_image("ui-1024-start.png")
		capture_view.size = Vector2i(1600, 900)
		await _capture_image("ui-1600-start.png")
		capture_view.size = Vector2i(1280, 800)
		await process_frame
	for id in game.variant_buttons:
		_press(game.variant_buttons[id])
		_check(game.state.variant == id, "variant selection configures " + id)
		_check(game.state.stored.is_empty(), "variant starts with an isolated empty slot")
	_press(game.variant_buttons.V1)
	await _move([2, 3])
	await _move([3, 3])
	_press(game.action_buttons.capture)
	_click_cell([4, 1])
	_check(not game.prediction.is_empty(), "capture has a complete model preview")
	await _capture_image("ui-capture-preview.png")
	_press(game.cancel_button)
	_check(game.state.stored.is_empty(), "canceling capture leaves the slot empty")
	_press(game.action_buttons.capture)
	_click_cell([4, 5])
	_press(game.confirm_button)
	await _settle()
	_check(game.state.stored.get("kind", "") == "shove", "confirmed capture populates stored display")
	_check(game.history_lines.size() > 4, "actual ordered events accumulate in history")
	await _capture_image("ui-stored-plan.png")
	_press(game.action_buttons.release)
	_click_cell([4, 3])
	_check(not game.prediction.is_empty(), "release preview uses exact model assessment")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.stored.is_empty(), "release consumes slot through model")
	_press(game.restart_button)
	_check(game.restart_dialog.visible, "restart protects a changed unfinished encounter")
	game.restart_dialog.get_cancel_button().pressed.emit()
	game.restart_dialog.hide()
	_check(game.changed, "canceling restart preserves run")
	_press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	_check(game.state.turn == 1 and game.state.stored.is_empty(), "restart isolates initial state")
	# Native board keyboard events only select; a separate control activation commits.
	_press(game.action_buttons.move)
	game.board.cursor = [2, 3]
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	game.board.gui_input.emit(key)
	_check(game.state.turn == 1 and game.confirm_button.has_focus(), "board Enter selects and focuses Confirm without advancing")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.turn == 2, "separate confirmation advances exactly once")
	# Exercise the two multistage capture flows through the same visible controls.
	_press(game.variant_buttons.V2)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	await _move([2, 3])
	await _move([3, 3])
	await _move([3, 2])
	_press(game.action_buttons.capture)
	_click_cell([4, 1])
	_check(game.command.is_empty() and not game.candidates.is_empty(), "V2 asks for an approach before submission")
	_click_cell([4, 2])
	_check(game.command.get("approach", []) == [4, 2], "V2 approach belongs to the capture transaction")
	_check(game.state.player.pos == [3, 2], "V2 preview did not move the live pawn")
	await _capture_image("ui-v2-approach.png")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.player.pos == [4, 2] and not game.state.stored.is_empty(), "V2 commits approach and capture together")
	_press(game.variant_buttons.V6)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	await _move([2, 3])
	await _move([3, 3])
	_press(game.action_buttons.capture)
	_click_cell([4, 1])
	_check(game.command.is_empty(), "V6 source selection alone does not submit")
	_click_cell([3, 1])
	_check(game.command.get("target", []) == [3, 1], "V6 target cell belongs to atomic capture")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.stored.get("target", []) == [3, 1], "V6 stores the committed cell")
	await _capture_image("ui-v6-commitment.png")
	# Freely enable preview mode through the actual configuration control.
	game.invert_switch.toggled.emit(true)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	_check(game.state.invert_enabled, "Invert configuration starts a clean independent encounter")
	_press(game.variant_buttons.V5)
	await _move([2, 3])
	await _move([3, 3])
	var capture_turn: int = game.state.turn
	_press(game.action_buttons.capture)
	_click_cell([4, 5])
	_press(game.confirm_button)
	await _settle()
	_check(game.state.turn == capture_turn and game.state.free_capture_used, "V5 free capture leaves the ordinary action")
	_press(game.action_buttons.release)
	_click_cell([4, 3])
	_check(game.prediction.is_empty() and game.confirm_button.disabled, "same-turn release rejection remains visible and uncommittable")
	_press(game.action_buttons.wait)
	_press(game.confirm_button)
	await _settle()
	_press(game.action_buttons.release)
	_click_cell([4, 3])
	game.pull_switch.set_pressed(true)
	_check(game.command.get("invert", false) and not game.prediction.is_empty(), "Pull switch reassesses the real release command")
	await _capture_image("ui-v5-invert.png")
	_press(game.confirm_button)
	await _settle()
	_check(game.state.stored.is_empty(), "confirmed inverted release consumes the stored plan")
	_press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	await _move([2, 3])
	await _move([3, 3])
	_press(game.action_buttons.move)
	_click_cell([4, 3])
	_press(game.confirm_button)
	await _settle()
	await _move([5, 2])
	await _move([6, 2])
	await _move([6, 3])
	_check(game.state.status == "won" and game.result.visible, "winning board remains visible with an outcome strip")
	_check(game.action_buttons.move.disabled and not game.restart_button.disabled, "terminal input is locked but replay remains available")
	await _capture_image("ui-escaped.png")
	_press(game.restart_button)
	_check(game.state.turn == 1 and not game.restart_dialog.visible, "finished encounter replays without destructive confirmation")
	await _move([2, 3])
	await _move([3, 3])
	await _move([3, 2])
	await _move([4, 2])
	_press(game.action_buttons.wait)
	_press(game.confirm_button)
	await _settle()
	_check(game.state.status == "lost" and game.result.visible, "failure leaves final board, result and event history inspectable")
	if capture_view:
		capture_view.size = Vector2i(1024, 720)
		await _capture_image("ui-1024-failure.png")
	await _test_invert_preview_toggle(false)
	await _test_invert_preview_toggle(true)
	print("UI smoke: %d checks, %d failures. Native OS pointer/keyboard acceptance remains independent." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
