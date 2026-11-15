extends Control
## Native interaction coordinator; the model supplies all rules and predictions.

const Encounter = preload("res://model/encounter.gd")
const Board = preload("res://ui/board.gd")
const P = preload("res://ui/presentation.gd")
const Production = preload("res://content/escape.gd")
var model = Encounter.new()
var fixture: Dictionary
var state: Dictionary = {}
var invert_enabled := false
var pull := false
var mode := "inspect"
var selected: Array = []
var command: Dictionary = {}
var prediction: Dictionary = {}
var candidates: Array = []
var source := ""
var changed := false
var resolving := false
var generation := 0
var pending_invert := false
var active_tween: Tween
var history_lines: Array[String] = []

var board: Control
var objective: Label
var phase: Label
var budgets: Label
var stored: Label
var instruction: Label
var consequence: Label
var inspection: Label
var result: Label
var availability: Label
var rail: BoxContainer
var confirmation_row: BoxContainer
var intention_list: VBoxContainer
var preview_details: RichTextLabel
var event_tabs: TabContainer
var history: RichTextLabel
var new_events: Button
var confirm_button: Button
var cancel_button: Button
var restart_button: Button
var invert_switch: CheckButton
var pull_switch: CheckButton
var action_buttons: Dictionary = {}
var restart_dialog: ConfirmationDialog
var help_dialog: AcceptDialog

func _ready() -> void:
	theme = P.make_theme()
	fixture = Production.DATA.duplicate(true)
	for argument in OS.get_cmdline_user_args():
		if argument == "--invert": invert_enabled = true
		elif argument.begins_with("--variant="):
			push_warning("Borrowed Turns: legacy variant selection is unsupported. Running the revised baseline.")
	_build_interface()
	_start_encounter()

func _label(parent: Node, text: String = "", font_size: int = 16, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _box(parent: Node, vertical: bool = true) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	parent.add_child(box)
	return box

func _build_interface() -> void:
	var ground := ColorRect.new()
	ground.color = P.GROUND
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var page := _box(margin)
	page.add_theme_constant_override("separation", 8)
	var header := _box(page, false)
	_label(header, "Borrowed Turns", 28)
	objective = _label(header, "", 16, true)
	phase = _label(header)
	restart_button = _button(header, "Restart", func(): _request_restart(invert_enabled))
	_label(page, "They want the artifact back. Reach the exit.", 16)
	var economy := _box(page, false)
	budgets = _label(economy, "", 16, true)
	budgets.custom_minimum_size.y = 44
	invert_switch = CheckButton.new()
	invert_switch.text = "Invert preview"
	invert_switch.toggled.connect(func(enabled: bool):
		invert_switch.set_pressed_no_signal(invert_enabled)
		_request_restart(enabled))
	economy.add_child(invert_switch)
	_button(economy, "Controls", func(): help_dialog.popup_centered(Vector2i(650, 410)))
	var main := _box(page, false)
	main.add_theme_constant_override("separation", 20)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := _box(main)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board = Board.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.cell_selected.connect(_select_cell)
	board.cell_inspected.connect(_inspect_cell)
	board.cancel_requested.connect(_cancel)
	left.add_child(board)
	inspection = _label(left, "", 14, true)
	inspection.custom_minimum_size.y = 20
	result = _label(left, "", 18, true)
	result.visible = false
	var actions := _box(left, false)
	for entry in [["move", "Move · M"], ["capture", "Capture · C"], ["release", "Release · L"], ["end_turn", "End turn · E"]]:
		if entry[0] == "end_turn":
			var gap := Control.new()
			gap.custom_minimum_size.x = 10
			actions.add_child(gap)
		var button := _button(actions, entry[1], _choose_action.bind(entry[0]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		action_buttons[entry[0]] = button
	instruction = _label(left, "", 16, true)
	instruction.custom_minimum_size.y = 22
	consequence = _label(left, "", 16, true)
	consequence.custom_minimum_size.y = 48
	confirmation_row = _box(left, false)
	confirm_button = _button(confirmation_row, "Confirm", _confirm)
	confirm_button.custom_minimum_size.x = 174
	cancel_button = _button(confirmation_row, "Cancel", _cancel)
	pull_switch = CheckButton.new()
	pull_switch.text = "Pull instead of push"
	pull_switch.toggled.connect(_change_pull)
	confirmation_row.add_child(pull_switch)
	rail = _box(main)
	rail.custom_minimum_size.x = 316
	var details_scroll := ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_stretch_ratio = 2.5
	rail.add_child(details_scroll)
	var details := _box(details_scroll)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(details, "Stored ability", 18)
	stored = _label(details, "", 16, true)
	stored.add_theme_color_override("font_color", P.BORROWED)
	availability = _label(details, "", 14, true)
	_label(details, "Enemy intentions · in order", 18)
	intention_list = VBoxContainer.new()
	details.add_child(intention_list)
	event_tabs = TabContainer.new()
	event_tabs.custom_minimum_size.y = 150
	event_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(event_tabs)
	var recent := VBoxContainer.new()
	recent.name = "Recent events"
	event_tabs.add_child(recent)
	history = RichTextLabel.new()
	history.selection_enabled = true
	history.custom_minimum_size.y = 120
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history.add_theme_color_override("default_color", P.INK)
	history.add_theme_font_size_override("normal_font_size", 16)
	recent.add_child(history)
	new_events = _button(recent, "New events · show latest", _follow_history)
	new_events.visible = false
	preview_details = RichTextLabel.new()
	preview_details.name = "Preview"
	preview_details.selection_enabled = true
	preview_details.add_theme_color_override("default_color", P.INK)
	preview_details.add_theme_font_size_override("normal_font_size", 16)
	event_tabs.add_child(preview_details)
	_label(page, "Tab: controls · Arrows: inspect · Enter: select / confirm · Esc: cancel · E: End turn preview · Ctrl+R: restart", 14)
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.title = "Replace this encounter?"
	restart_dialog.ok_button_text = "Start again"
	restart_dialog.cancel_button_text = "Keep playing"
	restart_dialog.confirmed.connect(_apply_restart)
	add_child(restart_dialog)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Controls and the capture bargain"
	help_dialog.dialog_text = "Move and act in any order. AP (action points) and MP (movement points) are independent.\nCapture is free and unlimited across legal sources, even at zero AP/MP.\nRelease uses 1 AP and can happen on the capture turn.\nReplace a held ability or end its deadline turn: it discharges where you stand.\nEnemy plans resolve only when you End turn. There is no automatic turn ending.\n\nChoose an operation, choose its target, inspect, then Confirm.\nM: Move, C: Capture, L: Release, E: prepare End turn.\nTab / Shift+Tab: controls. Arrows on board: inspect.\nEnter selects a cell; a separate Enter confirms. Esc / right click: cancel.\nCtrl+R: restart. Nothing advances during inspection or preview.\n\nY: you; squares: pursuers; EXIT: escape.\nRust hatches/dashed routes: enemy intentions. Double rust border: held backlash here.\nTeal outlines: legal choices. Solid arrows/hollow pawns: exact command preview.\nPreview lists ordered effects; Recent events contains only confirmed commands.\nInvert changes released shove push to pull, never backlash or burst."
	add_child(help_dialog)
	resized.connect(_resize_rail)
	_resize_rail()

func _resize_rail() -> void:
	if rail: rail.custom_minimum_size.x = clampf(316 + (size.x - 1024) * 0.18, 316, 360)

func _start_encounter() -> void:
	generation += 1
	if active_tween and active_tween.is_valid(): active_tween.kill()
	model.configure(fixture, "R2", invert_enabled)
	state = model.snapshot()
	changed = false
	resolving = false
	board.clear_pulse()
	board.cursor = state.player.pos.duplicate()
	invert_switch.set_pressed_no_signal(invert_enabled)
	history_lines = ["Turn 1 · Revised baseline · Invert %s\nReach the exit. Capture is free; End turn when ready." % ("on" if invert_enabled else "off")]
	history.text = "\n".join(history_lines)
	new_events.visible = false
	_clear_selection()
	_refresh()
	print("Borrowed Turns UI: start baseline=R2 invert=%s" % invert_enabled)

func _request_restart(enabled: bool) -> void:
	pending_invert = enabled
	if changed and state.status == "playing":
		restart_dialog.dialog_text = "Restart the encounter with Invert %s?\nCurrent progress, budgets, storage and history will reset." % ("on" if enabled else "off")
		restart_dialog.popup_centered(Vector2i(550, 200))
	else: _apply_restart()

func _apply_restart() -> void:
	invert_enabled = pending_invert
	_start_encounter()

func _clear_selection() -> void:
	mode = "inspect"
	selected = []
	source = ""
	command = {}
	prediction = {}
	candidates = []
	pull = false
	pull_switch.set_pressed_no_signal(false)
	instruction.text = "Choose an operation. Capture is free; release uses 1 AP."
	consequence.text = "Move and act in any order. Enemies act only when you End turn."
	confirm_button.disabled = true
	confirm_button.text = "Confirm"
	event_tabs.current_tab = 0

func _refresh() -> void:
	objective.text = "%d HP · Exit %s\nReach %s%s" % [state.player.hp, "open" if state.turn >= state.exit.opens else "opens turn %d" % state.exit.opens, P.cell(state.exit.pos), "" if state.turn >= state.exit.opens else " when open"]
	var terminal: bool = state.status != "playing"
	phase.text = "Turn %d\n%s" % [state.turn, "Escaped" if state.status == "won" else ("Caught" if terminal else ("Resolving" if resolving else "Your turn"))]
	budgets.text = "AP %d / %d · MP %d / %d · Capture: free · Reach %d\n%s" % [state.action_points, state.rules.actions, state.movement_points, state.rules.movement, state.rules.capture_range, P.deadline(state)]
	stored.text = P.stored_text(state)
	var info: Array[String] = ["AP: action points · MP: movement points"]
	if state.action_points == 0: info.append("No AP: move/capture can still be available.")
	if state.movement_points == 0: info.append("No MP: capture/release can still be available.")
	if invert_enabled: info.append("Invert preview: on. Released shove only.")
	if not state.stored.is_empty() and state.stored.ability.kind != "shove": info.append("Invert unavailable for this ability.")
	availability.text = "\n".join(info)
	if not terminal and mode == "inspect" and state.action_points == 0 and state.movement_points == 0:
		consequence.text = "No AP or MP left. Capture is still free; End turn when ready."
	for action in action_buttons:
		action_buttons[action].set_pressed_no_signal(mode == action)
		action_buttons[action].disabled = terminal or resolving
	action_buttons.move.disabled = terminal or resolving or state.movement_points == 0
	action_buttons.release.disabled = terminal or resolving or state.action_points == 0 or state.stored.is_empty()
	cancel_button.disabled = mode == "inspect" or resolving
	pull_switch.visible = mode == "release" and invert_enabled and not state.stored.is_empty() and state.stored.ability.kind == "shove"
	result.visible = terminal
	result.text = "Escaped · The exit is yours." if state.status == "won" else "Caught · Your health reached zero. Inspect the recent events."
	instruction.visible = not terminal
	consequence.visible = not terminal
	confirmation_row.visible = not terminal
	restart_button.text = "Replay encounter" if terminal else "Restart"
	if terminal or resolving: confirm_button.disabled = true
	preview_details.text = P.preview_text(prediction)
	_refresh_intentions()
	_inspect_cell(selected if not selected.is_empty() else board.cursor)
	_update_board()

func _refresh_intentions() -> void:
	for child in intention_list.get_children():
		intention_list.remove_child(child)
		child.queue_free()
	for intent in state.intentions:
		for enemy in state.enemies:
			if enemy.id != intent.source: continue
			var row := _button(intention_list, "%s · %s" % [str(enemy.id).to_upper(), P.ability_text(enemy.ability)], _select_cell.bind(enemy.pos))
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.disabled = resolving
	if state.intentions.is_empty(): _label(intention_list, "No active enemy plans.")

func _inspect_cell(cell: Array) -> void:
	var occupants: Array[String] = []
	if state.player.pos == cell: occupants.append("You · %d HP" % state.player.hp)
	for enemy in state.enemies:
		if enemy.pos == cell: occupants.append("%s · %d HP" % [str(enemy.id).to_upper(), enemy.hp])
	if state.exit.pos == cell: occupants.append("Exit")
	var threats: Array[String] = []
	for intent in state.intentions:
		if cell in intent.cells: threats.append(str(intent.source).to_upper())
	if not state.backlash_footprint.is_empty() and cell in state.backlash_footprint.cells: threats.append("held backlash")
	inspection.text = "%s · %s · %s" % [P.cell(cell), ", ".join(occupants) if not occupants.is_empty() else "Empty", "Threats: " + ", ".join(threats) if not threats.is_empty() else "No announced threat"]

func _update_board() -> void:
	board.set_view(state, prediction, candidates, selected, source)

func _choose_action(action: String) -> void:
	if resolving or state.status != "playing": return
	_clear_selection()
	mode = action
	match mode:
		"move": instruction.text = "Move: choose a legal cell. Uses 1 MP, not AP."
		"capture": instruction.text = "Capture: choose a source. Free, including replacement."
		"release": instruction.text = "Release: choose a target within the held ability's range. Uses 1 AP."
		"end_turn":
			instruction.text = "End turn: inspect backlash and enemy effects before confirming."
			command = {"type": "end_turn"}
			_assess_command()
	if mode == "capture" and not state.stored.is_empty(): instruction.text = "Capture replaces %s. Inspect its discharge before confirming." % state.stored.ability.kind
	_rebuild_candidates()
	_refresh()
	if command.is_empty(): board.grab_focus()

func _rebuild_candidates() -> void:
	candidates = []
	if mode == "capture":
		for intent in state.intentions:
			if model.assess({"type": "capture", "source": intent.source}).legal:
				for enemy in state.enemies:
					if enemy.id == intent.source: candidates.append(enemy.pos)
	elif mode in ["move", "release"]:
		for y in range(state.height):
			for x in range(state.width):
				var option := {"type": mode}
				option["to" if mode == "move" else "target"] = [x, y]
				if mode == "release": option.invert = pull
				if model.assess(option).legal: candidates.append([x, y])

func _select_cell(cell: Array) -> void:
	_inspect_cell(cell)
	if resolving: return
	selected = cell.duplicate()
	if state.status != "playing" or mode == "inspect":
		source = ""
		for enemy in state.enemies:
			if enemy.pos == cell: source = enemy.id
		_update_board()
		return
	if mode == "move": command = {"type": "move", "to": cell}
	elif mode == "release": command = {"type": "release", "target": cell, "invert": pull}
	elif mode == "capture":
		source = ""
		for enemy in state.enemies:
			if enemy.pos == cell: source = enemy.id
		if source.is_empty():
			command = {}
			prediction = {}
			confirm_button.disabled = true
			consequence.text = "Choose an enemy square or its intention row, not a threatened floor cell."
			_refresh()
			return
		command = {"type": "capture", "source": source}
	else: return
	_assess_command()
	_refresh()

func _assess_command(focus_confirmation: bool = true) -> void:
	var assessment: Dictionary = model.assess(command)
	prediction = assessment.preview
	confirm_button.disabled = not assessment.legal
	confirm_button.text = "Confirm %s" % ("end turn" if command.type == "end_turn" else str(command.type))
	consequence.text = P.command_summary(state, prediction, command) if assessment.legal else assessment.reason
	var danger: bool = assessment.legal and (prediction.player.hp < state.player.hp or prediction.status == "lost")
	consequence.add_theme_color_override("font_color", P.DANGER if danger or not assessment.legal else P.BORROWED)
	if assessment.legal:
		event_tabs.current_tab = 1
		if focus_confirmation: confirm_button.grab_focus()

func _confirm() -> void:
	if command.is_empty() or resolving or state.status != "playing": return
	var assessed: Dictionary = model.assess(command)
	if not assessed.legal:
		_assess_command(false)
		_refresh()
		return
	var submitted := command.duplicate(true)
	print("Borrowed Turns UI: submit turn=%d command=%s" % [state.turn, JSON.stringify(submitted)])
	if not model.act(submitted):
		push_error("Borrowed Turns UI: model rejected reassessed command.")
		return
	state = model.snapshot()
	print("Borrowed Turns UI: resolved turn=%d status=%s AP=%d MP=%d HP=%d" % [state.turn, state.status, state.action_points, state.movement_points, state.player.hp])
	changed = true
	_append_events(state.events)
	_clear_selection()
	resolving = true
	_refresh()
	board.pulse(state.events)
	var submitted_generation := generation
	active_tween = create_tween()
	active_tween.tween_interval(0.16)
	active_tween.tween_callback(func():
		if generation != submitted_generation: return
		resolving = false
		_refresh()
		board.grab_focus())

func _append_events(events: Array) -> void:
	var scrollbar := history.get_v_scroll_bar()
	var following := scrollbar.value + scrollbar.page >= scrollbar.max_value - 8
	for event in events: history_lines.append(P.event_text(event))
	history.text = "\n".join(history_lines)
	if following: _follow_history.call_deferred()
	else: new_events.visible = true

func _follow_history() -> void:
	history.scroll_to_line(maxi(0, history.get_line_count() - 1))
	new_events.visible = false

func _cancel() -> void:
	if resolving: return
	_clear_selection()
	_refresh()
	board.grab_focus()

func _change_pull(enabled: bool) -> void:
	pull = enabled
	if command.get("type", "") == "release":
		command.invert = enabled
		_assess_command(false)
	_rebuild_candidates()
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if restart_dialog.visible or help_dialog.visible: return
	if event.ctrl_pressed and event.keycode == KEY_R:
		_request_restart(invert_enabled)
		get_viewport().set_input_as_handled()
		return
	var action := ""
	match event.keycode:
		KEY_M: action = "move"
		KEY_C: action = "capture"
		KEY_L: action = "release"
		KEY_E: action = "end_turn"
		KEY_ESCAPE:
			_cancel()
			get_viewport().set_input_as_handled()
	if not action.is_empty() and not action_buttons[action].disabled:
		_choose_action(action)
		get_viewport().set_input_as_handled()
