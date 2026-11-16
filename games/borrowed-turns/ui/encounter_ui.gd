extends Control
## Native interaction coordinator; the model supplies all rules and predictions.

const Encounter = preload("res://model/encounter.gd")
const Board = preload("res://ui/board.gd")
const P = preload("res://ui/presentation.gd")
const Production = preload("res://content/escape.gd")
const Shadow = preload("res://ui/shadow_presentation.gd")
const TwoPursuers = preload("res://content/two_pursuers.gd")
const SliceAssets = preload("res://ui/two_pursuer_assets.gd")
const TwoSourcePresentation = preload("res://ui/two_pursuer_presentation.gd")
const TwoSourceRig = preload("res://ui/two_pursuer_rig.gd")
var model = Encounter.new()
var shadow = Shadow.new()
var presentation_mode := "paper"
var encounter_id := "escape"
var encounter_picker: OptionButton
var encounter_dialog: ConfirmationDialog
var _pending_encounter := ""
var _puppet_pack := ""
var _slice_art: Dictionary = {}
var _puppet_art: Dictionary = {}
var _asset_error := ""
var _asset_dialog: AcceptDialog
var _puppet_rig: Node2D
var _two_source_presentation = TwoSourcePresentation.new()
var baseline_feedback_left := 0.0
var fixture: Dictionary
var state: Dictionary = {}
var mode := "inspect"
var selected: Array = []
var command: Dictionary = {}
var prediction: Dictionary = {}
var candidates: Array = []
var source := ""
var changed := false
var resolving := false
var generation := 0
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
var action_buttons: Dictionary = {}
var restart_dialog: ConfirmationDialog
var help_dialog: AcceptDialog
var paper_switch: CheckButton
var details_scroll: ScrollContainer
var stage_held_details: Label
var _flat_root: Control
var _stage_root: Control
var _stage_sheet: PanelContainer
var _stage_sheet_margin: MarginContainer
var _stage_title: Label
var _stage_picker: OptionButton
var _stage_plans: Button
var _stage_controls: Button
var _flat_positions: Array[Dictionary] = []

func _ready() -> void:
	theme = P.make_theme()
	fixture = Production.DATA.duplicate(true)
	_puppet_pack = ProjectSettings.globalize_path("res://../../.lore/local/experiments/002-shadow-paper/dual-layer/puppets")
	for argument in OS.get_cmdline_user_args():
		if argument == "--invert" or argument.begins_with("--invert="):
			push_error("Borrowed Turns: --invert is no longer supported.")
			get_tree().quit(2)
			return
		elif argument.begins_with("--variant="):
			push_warning("Borrowed Turns: legacy variant selection is unsupported. Running the revised baseline.")
		elif argument.begins_with("--presentation="):
			presentation_mode = argument.trim_prefix("--presentation=")
			if presentation_mode not in ["plain", "paper", "stage"]:
				push_error("Borrowed Turns: presentation must be plain, paper or stage.")
				get_tree().quit(2)
				return
		elif argument.begins_with("--encounter="):
			encounter_id = argument.trim_prefix("--encounter=")
			if encounter_id not in ["escape", "two-pursuers"]:
				push_error("Borrowed Turns: encounter must be escape or two-pursuers.")
				get_tree().quit(2)
				return
		elif argument.begins_with("--puppet-pack="):
			_puppet_pack = argument.trim_prefix("--puppet-pack=")
	if encounter_id == "two-pursuers":
		if not _prepare_slice_assets():
			push_error("Borrowed Turns: " + _asset_error)
			get_tree().quit(2)
			return
		fixture = TwoPursuers.DATA.duplicate(true)
	_build_interface()
	_start_encounter()

func _process(delta: float) -> void:
	if state.is_empty(): return
	shadow.advance(delta)
	if presentation_mode != "plain": board.set_presentation(true, shadow.frame())
	_present_theatre()
	if resolving:
		baseline_feedback_left = maxf(0, baseline_feedback_left - delta)
		if baseline_feedback_left <= 0 and (presentation_mode == "plain" or not shadow.frame().busy):
			resolving = false
			_refresh()
			board.grab_focus()

func set_presentation_mode(value: String) -> void:
	if value not in ["plain", "paper", "stage"] or value == presentation_mode: return
	presentation_mode = value
	# A view switch cancels visual work only. Model, target, preview and history stay intact.
	generation += 1
	shadow.reset(state, generation)
	baseline_feedback_left = 0.0
	resolving = false
	board.clear_pulse()
	paper_switch.set_pressed_no_signal(value == "paper")
	_apply_view_layout()
	_refresh()
	print("Borrowed Turns UI: presentation=%s; gameplay unchanged" % value)

func _prepare_slice_assets() -> bool:
	_asset_error = ""
	if _slice_art.is_empty():
		var standees: Dictionary = SliceAssets.standees()
		if standees.has("error"):
			_asset_error = standees.error
			return false
		_slice_art = standees
	if _puppet_art.is_empty():
		var puppets: Dictionary = SliceAssets.puppets(_puppet_pack)
		if puppets.has("error"):
			_asset_error = puppets.error
			return false
		_puppet_art = puppets.textures
	return true

func _sync_encounter_picker() -> void:
	for i in range(encounter_picker.item_count):
		if encounter_picker.get_item_metadata(i) == encounter_id: encounter_picker.select(i)

func request_encounter(id: String) -> void:
	if id not in ["escape", "two-pursuers"] or id == encounter_id:
		_sync_encounter_picker()
		return
	_pending_encounter = id
	print("Borrowed Turns UI: encounter change requested current=%s candidate=%s" % [encounter_id, id])
	encounter_dialog.dialog_text = "Start %s?\nThis replaces the current run, including held actions, budgets and history." % ("Two pursuers" if id == "two-pursuers" else "the original encounter")
	# A cancel button can still have a deferred hide pending. Reopening after
	# that notification prevents the new request being hidden by the old one.
	encounter_dialog.popup_centered.call_deferred(Vector2i(560, 210))

func _cancel_encounter_request() -> void:
	if not _pending_encounter.is_empty(): print("Borrowed Turns UI: encounter change canceled candidate=", _pending_encounter)
	_pending_encounter = ""
	_sync_encounter_picker()

func _confirm_encounter_request() -> void:
	var id := _pending_encounter
	print("Borrowed Turns UI: encounter change confirmation candidate=", id)
	if id.is_empty(): return
	if id == "two-pursuers" and not _prepare_slice_assets():
		push_warning("Borrowed Turns: encounter unchanged; " + _asset_error)
		_asset_dialog.dialog_text = _asset_error + "\nThe current encounter has been kept."
		_asset_dialog.popup_centered(Vector2i(660, 260))
		_cancel_encounter_request()
		return
	print("Borrowed Turns UI: replacing encounter %s -> %s" % [encounter_id, id])
	encounter_id = id
	fixture = (TwoPursuers.DATA if id == "two-pursuers" else Production.DATA).duplicate(true)
	_pending_encounter = ""
	_sync_encounter_picker()
	_start_encounter()

func _configure_theatre() -> void:
	if encounter_id != "two-pursuers":
		board.configure_standees({}, {})
		board.theatre_mode = false
		if _puppet_rig: _puppet_rig.visible = false
		return
	if not board.configure_standees(_slice_art.textures, _slice_art.assembly):
		push_error("Borrowed Turns: approved standee assembly failed; no substitute will be used.")
		get_tree().quit(2)
		return
	if _puppet_rig == null:
		_puppet_rig = TwoSourceRig.new()
		_puppet_rig.name = "TwoSourcePerformance"
		_puppet_rig.show_behind_parent = true
		board.add_child(_puppet_rig)
		if not _puppet_rig.configure_assets(_puppet_art):
			push_error("Borrowed Turns: temporary puppet assembly failed.")
			get_tree().quit(2)
			return
	_present_theatre()

func _present_theatre() -> void:
	if _puppet_rig == null: return
	var active := encounter_id == "two-pursuers" and presentation_mode == "stage"
	board.theatre_mode = active
	if not active:
		_puppet_rig.visible = false
		return
	if board.stage_renderer:
		# Explicit source-layer order: backdrop / performers / floor / board /
		# foreground. All three approved stage source textures stay unchanged.
		board.move_child(board.stage_renderer.backdrop, 0)
		board.move_child(_puppet_rig, 1)
	var description: Dictionary = _two_source_presentation.compose(state, shadow.frame(), generation, ["A", "B"], source)
	_puppet_rig.present(description, board._stage_rect())

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
	encounter_picker = OptionButton.new()
	encounter_picker.add_item("Original encounter")
	encounter_picker.set_item_metadata(0, "escape")
	encounter_picker.add_item("Two pursuers")
	encounter_picker.set_item_metadata(1, "two-pursuers")
	encounter_picker.item_selected.connect(func(index: int): request_encounter(encounter_picker.get_item_metadata(index)))
	_sync_encounter_picker()
	encounter_dialog = ConfirmationDialog.new()
	encounter_dialog.title = "Start a different encounter?"
	encounter_dialog.confirmed.connect(_confirm_encounter_request)
	encounter_dialog.canceled.connect(_cancel_encounter_request)
	encounter_dialog.get_cancel_button().pressed.connect(_cancel_encounter_request)
	add_child(encounter_dialog)
	_asset_dialog = AcceptDialog.new()
	_asset_dialog.title = "Temporary artwork unavailable"
	add_child(_asset_dialog)
	var ground := ColorRect.new()
	ground.color = P.GROUND
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var margin := MarginContainer.new()
	_flat_root = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 20)
	add_child(margin)
	var page := _box(margin)
	page.add_theme_constant_override("separation", 8)
	var header := _box(page, false)
	_label(header, "Borrowed Turns", 28)
	objective = _label(header, "", 16, true)
	phase = _label(header)
	restart_button = _button(header, "Restart", func(): _request_restart())
	_label(page, "They want the artifact back. Reach the exit.", 16)
	var economy := _box(page, false)
	budgets = _label(economy, "", 16, true)
	budgets.custom_minimum_size.y = 44
	paper_switch = CheckButton.new()
	paper_switch.text = "Paper pilot"
	paper_switch.tooltip_text = "Experimental paper figures and shove action-shadows. Off: plain baseline. Changes no rules or progress."
	paper_switch.set_pressed_no_signal(presentation_mode == "paper")
	paper_switch.toggled.connect(func(enabled: bool): set_presentation_mode("paper" if enabled else "plain"))
	economy.add_child(paper_switch)
	_button(economy, "Stage view", func(): set_presentation_mode("stage"))
	_button(economy, "Controls", func(): help_dialog.popup_centered(Vector2i(650, 410)))
	economy.add_child(encounter_picker)
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
	rail = _box(main)
	rail.custom_minimum_size.x = 316
	details_scroll = ScrollContainer.new()
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
	stage_held_details = _label(details, "", 14, true)
	stage_held_details.visible = false
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
	help_dialog.dialog_text = "Move and act in any order. AP (action points) and MP (movement points) are independent.\nCapture is free and unlimited across legal sources, even at zero AP/MP.\nRelease uses 1 AP and can happen on the capture turn.\nReplace a held ability or end its deadline turn: it discharges where you stand.\nEnemy plans resolve only when you End turn. There is no automatic turn ending.\n\nChoose an operation, choose its target, inspect, then Confirm.\nM: Move, C: Capture, L: Release, E: prepare End turn.\nTab / Shift+Tab: controls. Arrows on board: inspect.\nEnter selects a cell; a separate Enter confirms. Esc / right click: cancel.\nCtrl+R: restart. Nothing advances during inspection or preview.\n\nY: you; squares: pursuers; EXIT: escape.\nRust hatches/dashed routes: enemy intentions. Double rust border: held backlash here.\nTeal outlines: legal choices. Solid arrows/hollow pawns: exact command preview.\nPreview lists ordered effects; Recent events contains only confirmed commands."
	help_dialog.dialog_text += "\n\nStage: click figure or foot marker; [ / ] cycles figures.\nAlt-click targets floor through figures. Details opens exact effects.\nTheatre positions identify actors, not compass directions; rehearsal does not advance time."
	add_child(help_dialog)
	_build_stage_shell()
	resized.connect(_resize_rail)
	_apply_view_layout()
	_resize_rail()

func _resize_rail() -> void:
	if presentation_mode == "stage": _layout_stage()
	elif rail: rail.custom_minimum_size.x = clampf(316 + (size.x - 1024) * 0.18, 316, 360)

func _stage_theme() -> Theme:
	var result_theme := P.make_theme()
	result_theme.default_font_size = 14
	result_theme.set_color("font_color", "Label", Color("f2ddba"))
	for type in ["Button", "OptionButton"]:
		for visual_state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var box := StyleBoxFlat.new()
			box.set_content_margin_all(6)
			box.bg_color = Color("ead6b2")
			box.border_color = Color("ad8575")
			box.set_border_width_all(1)
			if visual_state == "hover": box.bg_color = Color("f7e7c9")
			if visual_state == "pressed": box.bg_color = Color("493144")
			if visual_state == "disabled": box.bg_color = Color("51414c")
			if visual_state == "focus":
				box.bg_color = Color.TRANSPARENT
				box.border_color = Color("ffdea4")
				box.set_border_width_all(2)
			result_theme.set_stylebox(visual_state, type, box)
		result_theme.set_color("font_color", type, P.INK)
		result_theme.set_color("font_hover_color", type, P.INK)
		result_theme.set_color("font_pressed_color", type, Color("f7e7c9"))
		result_theme.set_color("font_disabled_color", type, Color("c8b7b1"))
	return result_theme

func _build_stage_shell() -> void:
	_stage_root = Control.new()
	_stage_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_root.theme = _stage_theme()
	add_child(_stage_root)
	var background := ColorRect.new()
	background.color = Color("241b29")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_root.add_child(background)
	_stage_title = _label(_stage_root, "Borrowed Turns", 18)
	_stage_picker = OptionButton.new()
	for text in ["Plain", "Paper pilot", "Stage"]: _stage_picker.add_item(text)
	_stage_picker.item_selected.connect(func(index: int): set_presentation_mode(["plain", "paper", "stage"][index]))
	_stage_root.add_child(_stage_picker)
	_stage_plans = _button(_stage_root, "Details", func():
		_stage_sheet.visible = not _stage_sheet.visible
		if _stage_sheet.visible: event_tabs.current_tab = 1 if not prediction.is_empty() else 2
	)
	_stage_controls = _button(_stage_root, "Controls", func(): help_dialog.popup_centered(Vector2i(650, 410)))
	_stage_sheet = PanelContainer.new()
	_stage_sheet.z_index = 5
	_stage_sheet.theme = P.make_theme()
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color("f3e1c1")
	sheet_style.border_color = Color("754958")
	sheet_style.set_border_width_all(2)
	_stage_sheet.add_theme_stylebox_override("panel", sheet_style)
	_stage_root.add_child(_stage_sheet)
	_stage_sheet_margin = MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]: _stage_sheet_margin.add_theme_constant_override("margin_" + edge, 7)
	_stage_sheet.add_child(_stage_sheet_margin)
	_stage_root.visible = false
	_stage_sheet.visible = false

func _apply_view_layout() -> void:
	var stage := presentation_mode == "stage"
	if stage and _flat_positions.is_empty():
		var moved: Array = [board, objective, phase, budgets, stored, instruction, consequence, inspection,
			result, confirm_button, cancel_button, restart_button, rail, details_scroll, encounter_picker]
		moved.append_array(action_buttons.values())
		# Capture every original parent/index before moving siblings.
		for node in moved:
			_flat_positions.append({"node": node, "parent": node.get_parent(), "index": node.get_index(),
				"minimum": node.custom_minimum_size, "font": node.get_theme_font_size("font_size"), "visible": node.visible})
		for entry in _flat_positions:
			var node: Control = entry.node
			if node == rail: node.reparent(_stage_sheet_margin, false)
			elif node == details_scroll:
				node.reparent(event_tabs, false)
				node.name = "Plans"
			else: node.reparent(_stage_root, false)
			node.custom_minimum_size = Vector2.ZERO
			if node is Label or node is Button: node.add_theme_font_size_override("font_size", 13)
		event_tabs.custom_minimum_size.y = 0
		history.custom_minimum_size.y = 0
	elif not stage and not _flat_positions.is_empty():
		for entry in _flat_positions:
			var node: Control = entry.node
			node.reparent(entry.parent, false)
			entry.parent.move_child(node, mini(entry.index, entry.parent.get_child_count() - 1))
			node.custom_minimum_size = entry.minimum
			# TabContainer hides inactive children; that flag does not belong to the rail.
			if node == details_scroll: node.visible = entry.visible
			if node is Label or node is Button: node.add_theme_font_size_override("font_size", entry.font)
		_flat_positions.clear()
		event_tabs.custom_minimum_size.y = 150
		history.custom_minimum_size.y = 120
	_flat_root.visible = not stage
	_stage_root.visible = stage
	stage_held_details.visible = stage
	_stage_picker.select(["plain", "paper", "stage"].find(presentation_mode))
	_stage_sheet.visible = false
	if stage: _layout_stage()
	else: _resize_rail()

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _layout_stage() -> void:
	if _stage_root == null or presentation_mode != "stage": return
	var width := maxf(1, size.x - 16)
	var x := 8.0
	_place(_stage_title, Rect2(x, 8, 145, 32))
	_place(phase, Rect2(x + 153, 8, 80, 34))
	_place(encounter_picker, Rect2(size.x - 628, 8, 164, 32))
	_place(_stage_picker, Rect2(size.x - 456, 8, 112, 32))
	_place(_stage_plans, Rect2(size.x - 336, 8, 104, 32))
	_place(_stage_controls, Rect2(size.x - 224, 8, 80, 32))
	_place(restart_button, Rect2(size.x - 136, 8, 128, 32))
	_place(objective, Rect2(x, 46, width * 0.25, 36))
	_place(budgets, Rect2(x + width * 0.26, 46, width * 0.36, 36))
	_place(stored, Rect2(x + width * 0.64, 46, width * 0.36, 36))
	_place(board, Rect2(x, 86, width, maxf(1, size.y - 206)))
	var action_y := size.y - 112
	var action_width := (width - 250) / 4.0
	var index := 0
	for action in action_buttons:
		_place(action_buttons[action], Rect2(x + index * (action_width + 6), action_y, action_width, 36))
		index += 1
	_place(confirm_button, Rect2(size.x - 234, action_y, 140, 36))
	_place(cancel_button, Rect2(size.x - 88, action_y, 80, 36))
	_place(instruction, Rect2(x, action_y + 42, width * 0.38, 44))
	_place(consequence, Rect2(x + width * 0.40, action_y + 42, width * 0.60, 44))
	_place(inspection, Rect2(x, size.y - 23, width, 18))
	_place(result, Rect2(x, action_y + 44, width, 42))
	var stage_rect: Rect2 = board._stage_rect()
	_place(_stage_sheet, Rect2(board.position + stage_rect.position + stage_rect.size * Vector2(0.17, 0.12),
		stage_rect.size * Vector2(0.66, 0.26)))

func _start_encounter() -> void:
	generation += 1
	model.configure(fixture, "R2")
	state = model.snapshot()
	shadow.reset(state, generation)
	baseline_feedback_left = 0.0
	changed = false
	resolving = false
	board.clear_pulse()
	_configure_theatre()
	board.cursor = state.player.pos.duplicate()
	history_lines = ["Turn 1 · %s\nReach the exit. Capture is free; End turn when ready." % ("Two pursuers" if encounter_id == "two-pursuers" else "Revised baseline")]
	history.text = "\n".join(history_lines)
	new_events.visible = false
	_clear_selection()
	_refresh()
	print("Borrowed Turns UI: start baseline=R2 encounter=%s presentation=%s" % [encounter_id, presentation_mode])

func _request_restart() -> void:
	if changed and state.status == "playing":
		restart_dialog.dialog_text = "Restart the encounter?\nCurrent progress, budgets, storage and history will reset."
		restart_dialog.popup_centered(Vector2i(550, 200))
	else: _apply_restart()

func _apply_restart() -> void:
	_start_encounter()

func _clear_selection() -> void:
	mode = "inspect"
	selected = []
	source = ""
	command = {}
	prediction = {}
	candidates = []
	instruction.text = "Choose an operation. Capture is free; release uses 1 AP."
	consequence.text = "Move and act in any order. Enemies act only when you End turn."
	consequence.add_theme_color_override("font_color", P.SECONDARY)
	confirm_button.disabled = true
	confirm_button.text = "Confirm"
	event_tabs.current_tab = 0
	if _stage_sheet: _stage_sheet.visible = false

func _refresh() -> void:
	objective.text = "%d HP · Exit %s\nReach %s%s" % [state.player.hp, "open" if state.turn >= state.exit.opens else "opens turn %d" % state.exit.opens, P.cell(state.exit.pos), "" if state.turn >= state.exit.opens else " when open"]
	var terminal: bool = state.status != "playing"
	phase.text = "Turn %d\n%s" % [state.turn, "Escaped" if state.status == "won" else ("Caught" if terminal else ("Resolving" if resolving else "Your turn"))]
	budgets.text = "AP %d / %d · MP %d / %d · Capture: free · Reach %d\n%s" % [state.action_points, state.rules.actions, state.movement_points, state.rules.movement, state.rules.capture_range, P.deadline(state)]
	stage_held_details.text = P.stored_text(state)
	stored.text = P.stored_text(state)
	stored.add_theme_color_override("font_color", Color("ade4d1") if presentation_mode == "stage" else P.BORROWED)
	if presentation_mode == "stage":
		if state.stored.is_empty(): stored.text = "Held: empty\nCapture an announced action; release uses 1 AP."
		else:
			var held: Dictionary = state.stored
			stored.text = "Held %s · %s · %d damage / range %d\nDeadline T%d · backlash here: %d%s" % [
				str(held.source).to_upper(), str(held.ability.kind).capitalize(), held.ability.damage,
				held.ability.range, held.deadline_turn, held.ability.damage, " + push" if held.ability.push else ""]
	var info: Array[String] = ["AP: action points · MP: movement points"]
	if state.action_points == 0: info.append("No AP: move/capture can still be available.")
	if state.movement_points == 0: info.append("No MP: capture/release can still be available.")
	availability.text = "\n".join(info)
	if not terminal and mode == "inspect" and state.action_points == 0 and state.movement_points == 0:
		consequence.text = "No AP or MP left. Capture is still free; End turn when ready."
	for action in action_buttons:
		action_buttons[action].set_pressed_no_signal(mode == action)
		action_buttons[action].disabled = terminal or resolving
	action_buttons.move.disabled = terminal or resolving or state.movement_points == 0
	action_buttons.release.disabled = terminal or resolving or state.action_points == 0 or state.stored.is_empty()
	cancel_button.disabled = mode == "inspect" or resolving
	result.visible = terminal
	result.text = "Escaped · The exit is yours." if state.status == "won" else "Caught · Your health reached zero. Inspect the recent events."
	instruction.visible = not terminal
	consequence.visible = not terminal
	confirmation_row.visible = not terminal
	confirm_button.visible = not terminal
	cancel_button.visible = not terminal
	restart_button.text = "Replay encounter" if terminal else "Restart"
	if terminal or resolving: confirm_button.disabled = true
	preview_details.text = P.preview_text(prediction)
	if not prediction.is_empty():
		var danger: bool = prediction.player.hp < state.player.hp or prediction.status == "lost"
		consequence.add_theme_color_override("font_color", (Color("ffc09a") if danger else Color("ade4d1")) if presentation_mode == "stage" else (P.DANGER if danger else P.BORROWED))
	else:
		var invalid := not command.is_empty()
		consequence.add_theme_color_override("font_color",
			(Color("ffc09a") if invalid else Color("e3c8af")) if presentation_mode == "stage" else (P.DANGER if invalid else P.SECONDARY))
	_refresh_intentions()
	_inspect_cell(selected if not selected.is_empty() else board.cursor)
	_update_board()
	if presentation_mode == "stage": _layout_stage()

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
	board.set_stage_mode(presentation_mode == "stage")
	board.set_presentation(presentation_mode != "plain", shadow.frame())
	board.theatre_mode = encounter_id == "two-pursuers" and presentation_mode == "stage"
	_present_theatre()

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
	if presentation_mode == "stage" and encounter_id == "two-pursuers":
		if mode == "capture":
			instruction.text = "Capture: choose a figure or foot marker. [ / ] cycles sources."
			if not state.stored.is_empty(): instruction.text += " Replaces held action."
		elif mode in ["move", "release"]:
			instruction.text += " Alt-click targets floor through figures."
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
	elif mode == "release": command = {"type": "release", "target": cell}
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
	var before: Dictionary = state.duplicate(true)
	if _puppet_rig and encounter_id == "two-pursuers": _puppet_rig.remember_held(before.stored)
	print("Borrowed Turns UI: submit turn=%d command=%s" % [state.turn, JSON.stringify(submitted)])
	if not model.act(submitted):
		push_error("Borrowed Turns UI: model rejected reassessed command.")
		return
	state = model.snapshot()
	shadow.observe(before, submitted, state, generation)
	print("Borrowed Turns UI: resolved turn=%d status=%s AP=%d MP=%d HP=%d" % [state.turn, state.status, state.action_points, state.movement_points, state.player.hp])
	changed = true
	_append_events(state.events)
	_clear_selection()
	resolving = true
	baseline_feedback_left = 0.16
	_refresh()
	board.pulse(state.events)
	board.show_transition(before)

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

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if restart_dialog.visible or help_dialog.visible or encounter_dialog.visible or _asset_dialog.visible: return
	if event.ctrl_pressed and event.keycode == KEY_R:
		_request_restart()
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
