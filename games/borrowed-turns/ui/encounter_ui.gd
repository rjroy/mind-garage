extends Control
## Native interaction coordinator; the model supplies all rules and predictions.

const Encounter = preload("res://model/encounter.gd")
const Board = preload("res://ui/board.gd")
const P = preload("res://ui/presentation.gd")
const EncounterContent = preload("res://content/encounters.gd")
const Shadow = preload("res://ui/shadow_presentation.gd")
const SliceAssets = preload("res://ui/two_pursuer_assets.gd")
const TwoSourcePresentation = preload("res://ui/two_pursuer_presentation.gd")
const TwoSourceRig = preload("res://ui/two_pursuer_rig.gd")
var model = Encounter.new()
var encounters: Dictionary = EncounterContent.registry()
var shadow = Shadow.new()
var encounter_id := "switcher"
var encounter_picker: OptionButton
var encounter_dialog: ConfirmationDialog
var _pending_encounter := ""
var _puppet_pack := ""
var _slice_art: Dictionary = {}
var _puppet_art: Dictionary = {}
var _puppet_rig: Node2D
var _two_source_presentation = TwoSourcePresentation.new()
var _stage_sources: Array = []
var baseline_feedback_left := 0.0
var _displayed_held: Dictionary = {}
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
var details_scroll: ScrollContainer
var stage_held_details: Label
var _stage_root: Control
var _stage_sheet: PanelContainer
var _stage_sheet_margin: MarginContainer
var _stage_title: Label
var _stage_plans: Button
var _stage_controls: Button

func _ready() -> void:
	theme = P.make_theme()
	_puppet_pack = "res://assets/puppets/two-pursuers"
	for argument in OS.get_cmdline_user_args():
		if argument == "--invert" or argument.begins_with("--invert="):
			push_error("Borrowed Turns: --invert is no longer supported.")
			get_tree().quit(2)
			return
		elif argument.begins_with("--variant="):
			push_warning("Borrowed Turns: legacy variant selection is unsupported. Running the revised baseline.")
		elif argument == "--presentation" or argument.begins_with("--presentation="):
			push_error("Borrowed Turns: --presentation is no longer supported.")
			get_tree().quit(2)
			return
		elif argument.begins_with("--encounter="):
			encounter_id = argument.trim_prefix("--encounter=")
			if not encounters.has(encounter_id):
				push_error("Borrowed Turns: unknown encounter " + encounter_id)
				get_tree().quit(2)
				return
		elif argument.begins_with("--puppet-pack="):
			_puppet_pack = argument.trim_prefix("--puppet-pack=")
	if not _load_stage_art():
		get_tree().quit(2)
		return
	fixture = _encounter_data(encounter_id).duplicate(true)
	_build_interface()
	_start_encounter()

func _process(delta: float) -> void:
	if state.is_empty(): return
	shadow.advance(delta)
	var frame: Dictionary = shadow.frame()
	board.set_presentation(frame)
	if frame.held != _displayed_held: _refresh_storage(frame.held)
	_present_stage()
	if resolving:
		baseline_feedback_left = maxf(0, baseline_feedback_left - delta)
		if baseline_feedback_left <= 0 and not shadow.frame().busy:
			resolving = false
			_refresh()
			board.grab_focus()

func _load_stage_art() -> bool:
	var standees: Dictionary = SliceAssets.standees()
	if standees.has("error"):
		push_error("Borrowed Turns: " + standees.error)
		return false
	var puppets: Dictionary = SliceAssets.puppets(_puppet_pack)
	if puppets.has("error"):
		push_error("Borrowed Turns: " + puppets.error)
		return false
	_slice_art = standees
	_puppet_art = puppets.textures
	return true

func _sync_encounter_picker() -> void:
	for i in range(encounter_picker.item_count):
		if encounter_picker.get_item_metadata(i) == encounter_id: encounter_picker.select(i)

func _encounter_data(id: String) -> Dictionary:
	return encounters.get(id, {}).get("data", {})

func request_encounter(id: String) -> void:
	if not encounters.has(id) or id == encounter_id:
		_sync_encounter_picker()
		return
	_pending_encounter = id
	print("Borrowed Turns UI: encounter change requested current=%s candidate=%s" % [encounter_id, id])
	encounter_dialog.dialog_text = "Start %s?\nThis replaces the current run, including held actions, budgets and history." % encounters[id].name
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
	print("Borrowed Turns UI: replacing encounter %s -> %s" % [encounter_id, id])
	encounter_id = id
	fixture = _encounter_data(id).duplicate(true)
	_pending_encounter = ""
	_sync_encounter_picker()
	_start_encounter()

func _configure_stage() -> bool:
	if not board.configure_standees(_slice_art.textures, _slice_art.assembly):
		push_error("Borrowed Turns: approved standee assembly failed; no substitute will be used.")
		return false
	if _puppet_rig == null:
		_puppet_rig = TwoSourceRig.new()
		_puppet_rig.name = "TwoSourcePerformance"
		_puppet_rig.show_behind_parent = true
		board.add_child(_puppet_rig)
		if not _puppet_rig.configure_assets(_puppet_art):
			push_error("Borrowed Turns: temporary puppet assembly failed.")
			return false
	_puppet_rig.bind_composition(state.enemies)
	_present_stage()
	return true

func _present_stage() -> void:
	if _puppet_rig == null: return
	if board.stage_renderer:
		# Explicit source-layer order: backdrop / performers / floor / board /
		# foreground. All three approved stage source textures stay unchanged.
		board.move_child(board.stage_renderer.backdrop, 0)
		board.move_child(_puppet_rig, 1)
	var description: Dictionary = _two_source_presentation.compose(state, shadow.frame(), generation, _stage_sources, source)
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
	for id in encounters:
		encounter_picker.add_item(encounters[id].name)
		encounter_picker.set_item_metadata(encounter_picker.item_count - 1, id)
	encounter_picker.item_selected.connect(func(index: int): request_encounter(encounter_picker.get_item_metadata(index)))
	_sync_encounter_picker()
	encounter_dialog = ConfirmationDialog.new()
	encounter_dialog.title = "Start a different encounter?"
	encounter_dialog.confirmed.connect(_confirm_encounter_request)
	encounter_dialog.canceled.connect(_cancel_encounter_request)
	encounter_dialog.get_cancel_button().pressed.connect(_cancel_encounter_request)
	add_child(encounter_dialog)
	_build_stage_shell()
	_stage_root.add_child(encounter_picker)
	objective = _label(_stage_root, "", 13, true)
	phase = _label(_stage_root, "", 13)
	restart_button = _button(_stage_root, "Restart", func(): _request_restart())
	budgets = _label(_stage_root, "", 13, true)
	board = Board.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.cell_selected.connect(_select_cell)
	board.cell_inspected.connect(_inspect_cell)
	board.cancel_requested.connect(_cancel)
	_stage_root.add_child(board)
	inspection = _label(_stage_root, "", 13, true)
	result = _label(_stage_root, "", 13, true)
	result.visible = false
	for entry in [["move", "Move · M"], ["capture", "Capture · C"], ["shine", "Shine · S"], ["end_turn", "End turn · E"]]:
		var button := _button(_stage_root, entry[1], _choose_action.bind(entry[0]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		action_buttons[entry[0]] = button
	instruction = _label(_stage_root, "", 13, true)
	consequence = _label(_stage_root, "", 13, true)
	confirm_button = _button(_stage_root, "Confirm", _confirm)
	cancel_button = _button(_stage_root, "Cancel", _cancel)
	rail = _box(_stage_sheet_margin)
	event_tabs = TabContainer.new()
	event_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(event_tabs)
	details_scroll = ScrollContainer.new()
	details_scroll.name = "Plans"
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_stretch_ratio = 2.5
	event_tabs.add_child(details_scroll)
	var details := _box(details_scroll)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(details, "Stored ability", 18)
	stored = _label(_stage_root, "", 13, true)
	stored.add_theme_color_override("font_color", P.BORROWED)
	availability = _label(details, "", 14, true)
	stage_held_details = _label(details, "", 14, true)
	_label(details, "Enemy intentions · in order", 18)
	intention_list = VBoxContainer.new()
	details.add_child(intention_list)
	var recent := VBoxContainer.new()
	recent.name = "Recent events"
	event_tabs.add_child(recent)
	history = RichTextLabel.new()
	history.selection_enabled = true
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
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.title = "Replace this encounter?"
	restart_dialog.ok_button_text = "Start again"
	restart_dialog.cancel_button_text = "Keep playing"
	restart_dialog.confirmed.connect(_apply_restart)
	add_child(restart_dialog)
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Controls and borrowed abilities"
	help_dialog.dialog_text = "Each turn starts with 3 AP. Each one-cell cardinal move, Capture and Shine costs 1 AP. End turn is free and always explicit; running out of AP never ends your turn automatically.\n\nCapture arms you without choosing a source or target. The next enemy attack that hits you keeps all its normal effects and damage, then you acquire its ability if you and its source survive. Misses leave Capture armed. You cannot arm it twice.\nYour current ability stays until a new hit replaces it. Shine uses it for 1 AP without forgetting it. Keep it as long as its source lives; defeating that source removes the ability after the full attack resolves.\n\nChoose an operation, inspect its exact preview, then Confirm. Move and Shine require a target. Cancel only backs out of an unconfirmed command; it does not undo arming.\nM: Move, C: Capture, S: Shine, E: prepare End turn.\nTab / Shift+Tab: controls. Arrows on board: inspect.\nEnter selects a cell; a separate Enter confirms. Esc / right click: cancel preview.\nCtrl+R: restart. Nothing advances during inspection or preview.\n\nEnemy plans resolve only when you End turn. Capture does not cancel their attacks. Teal outlines show legal choices. Preview lists ordered effects; Recent events contains only confirmed commands."
	help_dialog.dialog_text += "\n\nStage: click figure or foot marker; [ / ] cycles figures.\nAlt-click targets floor through figures. Details opens exact effects.\nTheatre positions identify actors, not compass directions; rehearsal does not advance time."
	help_dialog.dialog_text += "\n\nFights end when all foes are defeated. In Two pursuers, A chases with a narrow shove; B seeks usable maximum attack range with a three-wide shove. Width is across the attack, not extra forward range. Shine keeps the borrowed attack's width.\nEnd turn resolves old attacks, then opponents' one-step movement, then new aim."
	help_dialog.dialog_text += "\nTwo pursuers: cool A/diamond and warm B/circle wavefronts show current threats."
	help_dialog.dialog_text += "\n\nSwitcher (A, provisional artwork): one marked target tile, not a line attack. Its hollow source pad is the other exchange endpoint, not a damage tile. The target cell stays locked when you move away; anyone left there can be hit. It exchanges positions first, then damages the target. Shine uses the same swap on an occupied enemy tile. A miss still spends the attack, not your armed Capture.\nChoose Switcher + B to combine that exchange with B's unchanged wide shove."
	help_dialog.dialog_text += "\n\nPull deals damage along a cardinal line, then pulls each surviving target one legal step toward the attacker. Shine pulls toward you. Burst marks an area at the end of its line."
	add_child(help_dialog)
	# Keep tab order: events, preview, plans.
	event_tabs.move_child(details_scroll, 2)
	for control in [encounter_picker, restart_button, confirm_button, cancel_button] + action_buttons.values():
		control.custom_minimum_size = Vector2.ZERO
		if control is Button: control.add_theme_font_size_override("font_size", 13)
	board.custom_minimum_size = Vector2.ZERO
	_stage_root.visible = true
	resized.connect(_resize_rail)
	_resize_rail()

func _resize_rail() -> void:
	_layout_stage()

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

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _layout_stage() -> void:
	if _stage_root == null: return
	var width := maxf(1, size.x - 16)
	var x := 8.0
	_place(_stage_title, Rect2(x, 8, 145, 32))
	_place(phase, Rect2(x + 153, 8, 80, 34))
	_place(encounter_picker, Rect2(size.x - 628, 8, 164, 32))
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
	_stage_sources.clear()
	for enemy in state.enemies:
		if _stage_sources.size() < 2: _stage_sources.append(enemy.id)
	board.bind_composition(state.enemies)
	shadow.reset(state, generation)
	baseline_feedback_left = 0.0
	changed = false
	resolving = false
	board.clear_pulse()
	if not _configure_stage():
		get_tree().quit(2)
		return
	board.cursor = state.player.pos.duplicate()
	history_lines = ["Turn 1 · %s\nDefeat all foes. Capture arms for 1 AP; taking the next hit acquires its ability. End turn when ready." %
		encounters[encounter_id].name]
	history.text = "\n".join(history_lines)
	new_events.visible = false
	_clear_selection()
	_refresh()
	print("Borrowed Turns UI: start baseline=R2 encounter=%s presentation=stage" % encounter_id)

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
	instruction.text = "Move, Capture or Shine: 1 AP. End turn: free."
	consequence.text = "Move and act in any order. Enemies act only when you End turn."
	consequence.add_theme_color_override("font_color", P.SECONDARY)
	confirm_button.disabled = true
	confirm_button.text = "Confirm"
	event_tabs.current_tab = 0
	if _stage_sheet: _stage_sheet.visible = false

func _refresh() -> void:
	objective.text = P.objective_text(state)
	var terminal: bool = state.status != "playing"
	phase.text = "Turn %d\n%s" % [state.turn, "Victory" if state.status == "won" else ("Caught" if terminal else ("Resolving" if resolving else "Your turn"))]
	budgets.text = "AP %d / %d · End turn: free\n%s" % [state.action_points, state.rules.actions,
		"Capture armed · next hit still hurts" if state.capture_armed else "Capture: 1 AP · arms your next hit"]
	_refresh_storage(shadow.frame().held)
	var info: Array[String] = ["Move: 1 AP per tile · Capture: 1 AP to arm · Shine: 1 AP per use"]
	if state.action_points == 0: info.append("No AP: End turn when ready. An already armed Capture stays armed.")
	availability.text = "\n".join(info)
	if not terminal and mode == "inspect" and state.action_points == 0:
		consequence.text = "No AP left. End turn when ready; armed Capture still works."
	for action in action_buttons:
		action_buttons[action].set_pressed_no_signal(mode == action)
		action_buttons[action].disabled = terminal or resolving
	action_buttons.move.disabled = terminal or resolving or state.action_points == 0
	action_buttons.capture.disabled = terminal or resolving or state.action_points == 0 or state.capture_armed
	action_buttons.shine.disabled = terminal or resolving or state.action_points == 0 or state.stored.is_empty()
	cancel_button.disabled = mode == "inspect" or resolving
	result.visible = terminal
	result.text = "Victory · All foes defeated." if state.status == "won" else "Caught · Your health reached zero. Inspect the recent events."
	instruction.visible = not terminal
	consequence.visible = not terminal
	confirm_button.visible = not terminal
	cancel_button.visible = not terminal
	restart_button.text = "Replay encounter" if terminal else "Restart"
	if terminal or resolving: confirm_button.disabled = true
	preview_details.text = P.preview_text(prediction)
	if not prediction.is_empty():
		var danger: bool = prediction.player.hp < state.player.hp or prediction.status == "lost"
		consequence.add_theme_color_override("font_color", Color("ffc09a") if danger else Color("ade4d1"))
	else:
		var invalid := not command.is_empty()
		consequence.add_theme_color_override("font_color",
			Color("ffc09a") if invalid else Color("e3c8af"))
	_refresh_intentions()
	_inspect_cell(selected if not selected.is_empty() else board.cursor)
	_update_board()
	_layout_stage()

func _refresh_storage(held: Dictionary) -> void:
	# Presentation owns this boundary's storage, not the already-final snapshot.
	_displayed_held = held
	var displayed := state.duplicate()
	displayed.stored = held
	stage_held_details.text = P.stored_text(displayed)
	stored.add_theme_color_override("font_color", Color("ade4d1"))
	if held.is_empty():
		stored.text = "Held: empty\nTake a hit with Capture armed."
	else:
		var width: int = held.ability.get("width", 1)
		stored.text = "Held %s · %s · %d damage / range %d%s\nShine: 1 AP · kept while source lives%s" % [
			str(held.source).to_upper(), str(held.ability.kind).capitalize(), held.ability.damage,
			held.ability.range, " / width %d" % width if width > 1 else "", " · pull" if held.ability.kind == "pull" else (" · push" if held.ability.push else "")]

func _visible_intentions() -> Array:
	return [] if shadow.frame().get("announcements_deferred", false) else state.intentions

func _refresh_intentions() -> void:
	for child in intention_list.get_children():
		intention_list.remove_child(child)
		child.queue_free()
	for intent in _visible_intentions():
		for enemy in state.enemies:
			if enemy.id != intent.source: continue
			var description := "%s · %s · %s" % [str(enemy.id).to_upper(), P.enemy_name(enemy), P.ability_text(enemy.ability)]
			if intent.kind == "swap": description += "\nLocked tile %s · source %s" % [P.cell(intent.target), P.cell(intent.from)]
			var row := _button(intention_list, description, _select_cell.bind(enemy.pos))
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.disabled = resolving
	if shadow.frame().get("announcements_deferred", false):
		_label(intention_list, "Resolving attacks and movement.")
	elif state.intentions.is_empty(): _label(intention_list, "No active enemy plans.")

func _inspect_cell(cell: Array) -> void:
	var occupants: Array[String] = []
	if state.player.pos == cell: occupants.append("You · %d HP" % state.player.hp)
	for enemy in state.enemies:
		if enemy.pos == cell: occupants.append("%s · %s · %d HP" % [str(enemy.id).to_upper(), P.enemy_name(enemy), enemy.hp])
	var threats: Array[String] = []
	for intent in _visible_intentions():
		if cell in intent.cells: threats.append(str(intent.source).to_upper())
	var threat_text := "Threats: " + ", ".join(threats) if not threats.is_empty() else "No announced threat"
	if shadow.frame().get("announcements_deferred", false): threat_text = "Resolving attacks and movement."
	inspection.text = "%s · %s · %s" % [P.cell(cell), ", ".join(occupants) if not occupants.is_empty() else "Empty", threat_text]

func _update_board() -> void:
	board.set_view(state, prediction, candidates, selected, source)
	board.set_presentation(shadow.frame())
	_present_stage()

func _choose_action(action: String) -> void:
	if resolving or state.status != "playing": return
	_clear_selection()
	mode = action
	match mode:
		"move": instruction.text = "Move: choose one adjacent legal cell. Uses 1 AP per tile."
		"capture":
			instruction.text = "Capture: arm for 1 AP. The next hit still deals damage, then you acquire it."
			command = {"type": "capture"}
			_assess_command()
		"shine": instruction.text = "Shine: choose a target in the held ability's range. Uses 1 AP; keeps the ability."
		"end_turn":
			instruction.text = "End turn: free. Inspect attacks and movement before confirming."
			command = {"type": "end_turn"}
			_assess_command()
	if mode in ["move", "shine"]:
		instruction.text += " Alt-click targets floor through figures."
	_rebuild_candidates()
	_refresh()
	if command.is_empty(): board.grab_focus()

func _rebuild_candidates() -> void:
	candidates = []
	if mode in ["move", "shine"]:
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
	elif mode == "shine": command = {"type": "shine", "target": cell}
	else: return
	_assess_command()
	_refresh()

func _assess_command(focus_confirmation: bool = true) -> void:
	var assessment: Dictionary = model.assess(command)
	prediction = assessment.preview
	confirm_button.disabled = not assessment.legal
	confirm_button.text = "Confirm %s" % ("end turn" if command.type == "end_turn" else str(command.type))
	consequence.text = P.command_summary(state, prediction, command) if assessment.legal else P.rejection_text(assessment.reason)
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
	print("Borrowed Turns UI: submit turn=%d command=%s" % [state.turn, JSON.stringify(submitted)])
	if not model.act(submitted):
		push_error("Borrowed Turns UI: model rejected reassessed command.")
		return
	state = model.snapshot()
	shadow.observe(before, submitted, state, generation)
	print("Borrowed Turns UI: resolved turn=%d status=%s AP=%d HP=%d" % [state.turn, state.status, state.action_points, state.player.hp])
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
	if restart_dialog.visible or help_dialog.visible or encounter_dialog.visible: return
	if event.ctrl_pressed and event.keycode == KEY_R:
		_request_restart()
		get_viewport().set_input_as_handled()
		return
	var action := ""
	match event.keycode:
		KEY_M: action = "move"
		KEY_C: action = "capture"
		KEY_S: action = "shine"
		KEY_E: action = "end_turn"
		KEY_ESCAPE:
			_cancel()
			get_viewport().set_input_as_handled()
	if not action.is_empty() and not action_buttons[action].disabled:
		_choose_action(action)
		get_viewport().set_input_as_handled()
