extends Control
## UI transaction coordinator. The encounter model owns every rule and prediction.

const Encounter = preload("res://model/encounter.gd")
const Board = preload("res://ui/board.gd")
const P = preload("res://ui/presentation.gd")
const Production = preload("res://content/escape.gd")

var model = Encounter.new()
var fixture: Dictionary
var state: Dictionary = {}
var variant := "V1"
var invert_enabled := false
var pull := false
var mode := "inspect"
var capture_source := ""
var selected: Array = []
var command: Dictionary = {}
var prediction: Dictionary = {}
var candidates: Array = []
var source_commands: Dictionary = {}
var changed := false
var resolving := false
var generation := 0
var pending_configuration: Dictionary = {}
var active_tween: Tween

var board: Control
var objective: Label
var phase: Label
var bargain: Label
var stored: Label
var instruction: Label
var consequence: Label
var inspection: Label
var result: Label
var release_status: Label
var preview_details: RichTextLabel
var event_tabs: TabContainer
var rail: BoxContainer
var confirmation_row: BoxContainer
var intention_list: VBoxContainer
var history: RichTextLabel
var new_events: Button
var confirm_button: Button
var cancel_button: Button
var restart_button: Button
var invert_switch: CheckButton
var pull_switch: CheckButton
var variant_buttons: Dictionary = {}
var action_buttons: Dictionary = {}
var restart_dialog: ConfirmationDialog
var help_dialog: AcceptDialog
var history_lines: Array[String] = []

func _ready() -> void:
	theme = P.make_theme()
	fixture = Production.DATA.duplicate(true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--variant="):
			var requested := argument.trim_prefix("--variant=").to_upper()
			if P.NAMES.has(requested): variant = requested
			else: push_warning("Unknown variant %s; using V1." % requested)
		elif argument == "--invert": invert_enabled = true
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

func _section(parent: Node, title: String) -> void:
	_label(parent, title, 18)

func _build_interface() -> void:
	var ground := ColorRect.new()
	ground.color = P.GROUND
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var page := _box(margin)
	page.add_theme_constant_override("separation", 10)
	var header := _box(page, false)
	_label(header, "Borrowed Turns", 28)
	objective = _label(header, "", 16, true)
	objective.size_flags_stretch_ratio = 1.4
	phase = _label(header, "", 16)
	restart_button = _button(header, "Restart", func(): _request_configuration(variant, invert_enabled))
	_label(page, "They want the artifact back. Reach the exit.", 16)
	var variants := _box(page, false)
	for id in P.NAMES:
		var button := _button(variants, id, _request_variant.bind(id))
		button.custom_minimum_size.x = 49
		button.toggle_mode = true
		button.tooltip_text = P.NAMES[id]
		variant_buttons[id] = button
	invert_switch = CheckButton.new()
	invert_switch.text = "Invert preview"
	invert_switch.toggled.connect(func(enabled: bool):
		invert_switch.set_pressed_no_signal(invert_enabled)
		_request_configuration(variant, enabled))
	variants.add_child(invert_switch)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variants.add_child(spacer)
	_button(variants, "Controls", func(): help_dialog.popup_centered(Vector2i(620, 350)))
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
	inspection = _label(left, "Select a cell to inspect it. Y = you; squares = pursuers.", 14)
	inspection.custom_minimum_size.y = 20
	result = _label(left, "", 18, true)
	result.visible = false
	var actions := _box(left, false)
	for entry in [["move", "Move · M"], ["capture", "Capture · C"], ["release", "Release · L"], ["wait", "Wait"], ["discard", "Discard"]]:
		var button := _button(actions, entry[1], _choose_action.bind(entry[0]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		action_buttons[entry[0]] = button
	instruction = _label(left, "", 16, true)
	instruction.custom_minimum_size.y = 24
	consequence = _label(left, "", 16, true)
	consequence.custom_minimum_size.y = 44
	consequence.add_theme_color_override("font_color", P.BORROWED)
	var confirmation := _box(left, false)
	confirmation_row = confirmation
	confirm_button = _button(confirmation, "Confirm", _confirm)
	confirm_button.custom_minimum_size.x = 174
	cancel_button = _button(confirmation, "Cancel", _cancel)
	pull_switch = CheckButton.new()
	pull_switch.text = "Pull instead of push"
	pull_switch.toggled.connect(_change_pull)
	confirmation.add_child(pull_switch)
	rail = _box(main)
	rail.custom_minimum_size.x = 316
	rail.size_flags_horizontal = Control.SIZE_FILL
	var details_scroll := ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_stretch_ratio = 2.5
	rail.add_child(details_scroll)
	var details := _box(details_scroll)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bargain = _label(details, "", 16, true)
	_section(details, "Stored action")
	stored = _label(details, "", 16, true)
	stored.add_theme_color_override("font_color", P.BORROWED)
	release_status = _label(details, "", 14, true)
	_section(details, "Enemy intentions · in order")
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
	history.bbcode_enabled = false
	history.selection_enabled = true
	history.scroll_following = false
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
	_label(page, "Tab: controls · Arrows: board cursor · Enter: select / confirm · Esc: cancel · Ctrl+R: restart", 14)
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.title = "Replace this encounter?"
	restart_dialog.ok_button_text = "Start again"
	restart_dialog.cancel_button_text = "Keep playing"
	restart_dialog.confirmed.connect(_apply_pending_configuration)
	restart_dialog.canceled.connect(_restore_configuration_controls)
	add_child(restart_dialog)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Controls and reading the board"
	help_dialog.dialog_text = "Choose an action, choose its target, then Confirm. Nothing advances until confirmation.\n\nMouse: click cells or enemy rows. Right click cancels.\nKeyboard: Tab / Shift+Tab through controls; Space / Enter activates.\nM: move, C: capture, L: release. Arrows inspect cells when the board has focus.\nEnter on the board selects; a separate Enter on Confirm commits. Esc backs out.\nCtrl+R: restart this same encounter.\n\nRust dashed arrows: enemy plans. Teal outlines: legal targets.\nTeal solid arrows and hollow circles: exact command preview, not the live board.\nCross: V6's fixed release cell. Y: you. Squares A/B: pursuers.\nAll captured plans can only be released on a later turn."
	add_child(help_dialog)
	resized.connect(_resize_rail)
	_resize_rail()

func _resize_rail() -> void:
	if rail:
		rail.custom_minimum_size.x = clampf(316 + (size.x - 1024) * 0.18, 316, 360)

func _start_encounter() -> void:
	generation += 1
	if active_tween and active_tween.is_valid(): active_tween.kill()
	model.configure(fixture, variant, invert_enabled)
	state = model.snapshot()
	changed = false
	resolving = false
	pull = false
	board.clear_pulse()
	board.cursor = state.player.pos.duplicate()
	history_lines = ["%s · %s · Invert %s\nTurn 1 · Reach the exit." % [variant, P.NAMES[variant], "on" if invert_enabled else "off"]]
	history.text = "\n".join(history_lines)
	new_events.visible = false
	_restore_configuration_controls()
	_clear_selection()
	_refresh()
	print("Borrowed Turns UI: encounter started variant=%s invert=%s" % [variant, invert_enabled])

func _request_variant(id: String) -> void:
	_restore_configuration_controls()
	if id != variant: _request_configuration(id, invert_enabled)

func _request_configuration(id: String, enabled: bool) -> void:
	pending_configuration = {"variant": id, "invert": enabled}
	if changed and state.get("status", "") == "playing":
		restart_dialog.dialog_text = "Start %s · %s with Invert %s?\nThe current encounter will be replaced.\n\n%s" % [id, P.NAMES[id], "on" if enabled else "off", P.RULES[id]]
		restart_dialog.popup_centered(Vector2i(540, 220))
	else:
		_apply_pending_configuration()

func _apply_pending_configuration() -> void:
	if pending_configuration.is_empty(): return
	variant = pending_configuration.variant
	invert_enabled = pending_configuration.invert
	pending_configuration = {}
	_start_encounter()

func _restore_configuration_controls() -> void:
	invert_switch.set_pressed_no_signal(invert_enabled)
	for id in variant_buttons: variant_buttons[id].set_pressed_no_signal(id == variant)

func _clear_selection() -> void:
	mode = "inspect"
	capture_source = ""
	selected = []
	command = {}
	prediction = {}
	candidates = []
	source_commands = {}
	pull = false
	pull_switch.set_pressed_no_signal(false)
	instruction.text = "Choose an action. Inspect the threats before you commit."
	consequence.text = "Dashed rust: enemy plans. Teal: your legal targets and preview."
	confirm_button.disabled = true
	confirm_button.text = "Confirm"
	event_tabs.current_tab = 0

func _refresh() -> void:
	if state.is_empty(): return
	objective.text = "%d HP · Exit %s\nReach %s%s" % [state.player.hp, "open" if state.turn >= state.exit.opens else "opens turn %d" % state.exit.opens, P.cell(state.exit.pos), "" if state.turn >= state.exit.opens else " when open"]
	var phase_text := "Your action"
	if variant == "V5":
		if state.free_capture_used: phase_text = "Your action remains"
		elif state.stored.is_empty(): phase_text = "Free capture available"
	if resolving: phase_text = "Resolving"
	if state.status == "won": phase_text = "Escaped"
	if state.status == "lost": phase_text = "Caught"
	phase.text = "Turn %d\n%s" % [state.turn, phase_text]
	bargain.text = "%s · %s\n%s\nRelease only on a later turn." % [variant, P.NAMES[variant], P.RULES[variant]]
	if variant == "V5": bargain.text += "\nCapture-turn action counts toward the deadline."
	stored.text = P.stored_text(state)
	_refresh_preview_details()
	var terminal: bool = state.status != "playing"
	result.visible = terminal
	instruction.visible = not terminal
	consequence.visible = not terminal
	confirmation_row.visible = not terminal
	if terminal:
		result.text = "Escaped · The exit is yours." if state.status == "won" else "Caught · Your health reached zero. Inspect the recent events."
		restart_button.text = "Replay this variant"
	else:
		restart_button.text = "Restart"
	for action in action_buttons:
		action_buttons[action].set_pressed_no_signal(action == mode)
		action_buttons[action].disabled = terminal or resolving
	var slot_empty: bool = state.stored.is_empty()
	action_buttons.release.disabled = terminal or resolving or slot_empty
	action_buttons.discard.disabled = terminal or resolving or slot_empty
	action_buttons.capture.disabled = terminal or resolving or not slot_empty
	if variant == "V5" and state.free_capture_used: action_buttons.capture.disabled = true
	var status_lines: Array[String] = []
	if slot_empty: status_lines.append("Release / discard: no stored action.")
	else:
		status_lines.append("Capture: slot occupied.")
		if state.stored.captured_turn == state.turn: status_lines.append("Release: wait until a later turn.")
	if variant == "V5" and state.free_capture_used: status_lines.append("Free capture used this turn.")
	if invert_enabled:
		status_lines.append("Invert preview: on. Shove can push or pull.")
		if not slot_empty and state.stored.kind != "shove": status_lines.append("Invert unavailable for bolt.")
	release_status.text = "\n".join(status_lines)
	pull_switch.visible = invert_enabled and not slot_empty and state.stored.kind == "shove" and mode == "release"
	cancel_button.disabled = mode == "inspect" or resolving
	if terminal or resolving: confirm_button.disabled = true
	_refresh_intentions()
	_inspect_cell(selected if not selected.is_empty() else board.cursor)
	_update_board()

func _refresh_preview_details() -> void:
	if not prediction.is_empty():
		var facts: Array[String] = ["Command preview · exact order"]
		for event in prediction.events: facts.append(P.event_text(event))
		preview_details.text = "\n".join(facts)
	else:
		preview_details.text = "Choose a legal command to inspect its exact ordered effects. Previewing never advances play."

func _refresh_intentions() -> void:
	for child in intention_list.get_children():
		intention_list.remove_child(child)
		child.queue_free()
	for intent in state.intentions:
		var text := "%s · %s · %d cells" % [str(intent.source).to_upper(), str(intent.kind).capitalize(), intent.cells.size()]
		var row := _button(intention_list, text, _select_source_row.bind(str(intent.source)))
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.tooltip_text = "Select source %s to inspect or capture this plan." % str(intent.source).to_upper()
		row.disabled = resolving
	if state.intentions.is_empty(): _label(intention_list, "No active enemy plans.", 16)

func _select_source_row(id: String) -> void:
	for enemy in state.enemies:
		if enemy.id == id:
			_select_cell(enemy.pos)
			return

func _update_board() -> void:
	board.set_view(state, prediction, candidates, selected, capture_source)

func _inspect_cell(cell: Array) -> void:
	var occupants: Array[String] = []
	if state.player.pos == cell: occupants.append("You · %d HP" % state.player.hp)
	for enemy in state.enemies:
		if enemy.pos == cell: occupants.append("%s · %d HP" % [str(enemy.id).to_upper(), enemy.hp])
	if state.exit.pos == cell: occupants.append("Exit")
	var sources: Array[String] = []
	for intent in state.intentions:
		if cell in intent.cells: sources.append(str(intent.source).to_upper())
	var contents := ", ".join(occupants) if not occupants.is_empty() else "Empty"
	inspection.text = "%s · %s%s" % [P.cell(cell), contents, " · Threats: " + ", ".join(sources) if not sources.is_empty() else " · No announced threat"]

func _choose_action(action: String) -> void:
	if resolving or state.status != "playing": return
	_clear_selection()
	mode = action
	match mode:
		"move": instruction.text = "Move: choose a teal-outlined cell, then Confirm."
		"capture": instruction.text = "Capture: choose an enemy square or its intention row."
		"release":
			instruction.text = "Release: choose a target cell. Inspect the full resolution."
			if variant == "V6":
				command = {"type": "release", "invert": pull}
				selected = state.stored.get("target", []).duplicate()
				_assess_command()
		"wait", "discard":
			command = {"type": mode}
			instruction.text = "%s uses your action. Inspect the result, then Confirm." % mode.capitalize()
			_assess_command()
	_rebuild_candidates()
	_refresh()
	if command.is_empty(): board.grab_focus()

func _capture_options(id: String) -> Array:
	var options: Array = []
	var base := {"type": "capture", "source": id}
	if variant != "V6" and model.assess(base).legal: options.append(base)
	if variant == "V2" or variant == "V6":
		for y in range(state.height):
			for x in range(state.width):
				var candidate := base.duplicate(true)
				candidate["approach" if variant == "V2" else "target"] = [x, y]
				if model.assess(candidate).legal: options.append(candidate)
	return options

func _rebuild_candidates() -> void:
	candidates = []
	source_commands = {}
	if mode == "capture":
		if capture_source.is_empty():
			for intent in state.intentions:
				var options := _capture_options(intent.source)
				source_commands[intent.source] = options
				if not options.is_empty():
					for enemy in state.enemies:
						if enemy.id == intent.source: candidates.append(enemy.pos)
		else:
			for option in _capture_options(capture_source):
				if option.has("approach"): candidates.append(option.approach)
				elif option.has("target"): candidates.append(option.target)
				else: candidates.append(state.player.pos)
	elif mode == "move" or (mode == "release" and variant != "V6"):
		for y in range(state.height):
			for x in range(state.width):
				var candidate := {"type": mode}
				candidate["to" if mode == "move" else "target"] = [x, y]
				if mode == "release": candidate.invert = pull
				if model.assess(candidate).legal: candidates.append([x, y])

func _select_cell(cell: Array) -> void:
	_inspect_cell(cell)
	if resolving: return
	selected = cell.duplicate()
	if state.status != "playing" or mode == "inspect":
		_update_board()
		return
	if mode == "move": command = {"type": "move", "to": cell}
	elif mode == "release":
		command = {"type": "release", "target": cell, "invert": pull}
	elif mode == "capture":
		if variant not in ["V2", "V6"]: capture_source = ""
		if capture_source.is_empty():
			var id := ""
			for enemy in state.enemies:
				if enemy.pos == cell: id = enemy.id
			if id.is_empty():
				command = {}
				prediction = {}
				confirm_button.disabled = true
				consequence.text = "Choose the enemy square or its intention row, not a threatened floor cell."
				_refresh()
				return
			capture_source = id
			var options := _capture_options(id)
			if options.is_empty():
				command = {"type": "capture", "source": id}
				_assess_command()
				_refresh()
				return
			if variant == "V6":
				instruction.text = "Capture %s: choose its fixed future release cell, then Confirm." % id.to_upper()
				_rebuild_candidates()
				_update_board()
				return
			command = {"type": "capture", "source": id}
			if variant == "V2" and not model.assess(command).legal and not options.is_empty():
				command = {}
				instruction.text = "Capture %s: choose a teal approach cell. Step + capture commit together." % id.to_upper()
				_rebuild_candidates()
				_update_board()
				return
		else:
			command = {"type": "capture", "source": capture_source}
			if variant == "V2" and cell != state.player.pos: command.approach = cell
			if variant == "V6": command.target = cell
	else: return
	_assess_command()
	_refresh()

func _assess_command(focus_confirmation: bool = true) -> void:
	var assessment: Dictionary = model.assess(command)
	confirm_button.disabled = not assessment.legal
	prediction = assessment.preview
	confirm_button.text = "Confirm %s" % str(command.type)
	if not assessment.legal:
		consequence.text = assessment.reason
		return
	var predicted: Dictionary = assessment.preview
	var prefix := "Free capture; your action remains." if mode == "capture" and variant == "V5" else "Uses your action."
	var outcome := "Next: turn %d, %d HP, at %s." % [predicted.turn, predicted.player.hp, P.cell(predicted.player.pos)]
	if predicted.status == "won": outcome = "You escape before further enemy attacks."
	if predicted.status == "lost": outcome = "This command ends in failure. Inspect the preview."
	consequence.text = "%s %s" % [prefix, outcome]
	consequence.text += "\nExact ordered effects: Preview tab. The live board has not changed."
	event_tabs.current_tab = 1
	if focus_confirmation: confirm_button.grab_focus()

func _confirm() -> void:
	if command.is_empty() or resolving or state.status != "playing": return
	var assessment: Dictionary = model.assess(command)
	if not assessment.legal:
		consequence.text = assessment.reason
		confirm_button.disabled = true
		return
	var submitted := command.duplicate(true)
	print("Borrowed Turns UI: submit variant=%s turn=%d command=%s" % [variant, state.turn, JSON.stringify(submitted)])
	if not model.act(submitted):
		push_error("Borrowed Turns UI: model rejected a reassessed legal command.")
		consequence.text = "The command was rejected. Choose it again. No action was submitted by the interface."
		return
	state = model.snapshot()
	changed = true
	print("Borrowed Turns UI: resolved turn=%d status=%s hp=%d" % [state.turn, state.status, state.player.hp])
	_append_events(state.events)
	_clear_selection()
	resolving = true
	_refresh()
	board.pulse(state.events)
	var current_generation := generation
	active_tween = create_tween()
	active_tween.tween_interval(0.18)
	active_tween.tween_callback(func():
		if generation != current_generation: return
		resolving = false
		_refresh()
		board.grab_focus())

func _append_events(events: Array) -> void:
	var scroll := history.get_v_scroll_bar()
	var following := scroll.value + scroll.page >= scroll.max_value - 8
	for event in events: history_lines.append(P.event_text(event))
	history.text = "\n".join(history_lines)
	if following: _follow_history.call_deferred()
	else: new_events.visible = true

func _follow_history() -> void:
	history.scroll_to_line(maxi(0, history.get_line_count() - 1))
	new_events.visible = false

func _cancel() -> void:
	if resolving: return
	if mode == "capture" and not capture_source.is_empty():
		capture_source = ""
		selected = []
		command = {}
		prediction = {}
		confirm_button.disabled = true
		instruction.text = "Capture: choose an enemy square or its intention row."
		consequence.text = "No action taken. Choose a source, or Cancel again."
		_rebuild_candidates()
	else: _clear_selection()
	_refresh()
	board.grab_focus()

func _change_pull(enabled: bool) -> void:
	pull = enabled
	if command.get("type", "") == "release":
		command.invert = enabled
		_assess_command(false)
		_refresh_preview_details()
	_rebuild_candidates()
	_update_board()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if restart_dialog.visible or help_dialog.visible: return
	if event.ctrl_pressed and event.keycode == KEY_R:
		_request_configuration(variant, invert_enabled)
		get_viewport().set_input_as_handled()
		return
	var action := ""
	match event.keycode:
		KEY_M: action = "move"
		KEY_C: action = "capture"
		KEY_L: action = "release"
		KEY_ESCAPE:
			_cancel()
			get_viewport().set_input_as_handled()
	if not action.is_empty() and not action_buttons[action].disabled:
		_choose_action(action)
		get_viewport().set_input_as_handled()
