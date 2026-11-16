extends "res://ui/smoke.gd"
## Reuses real scene smoke helpers. Behavioral checks use controlled tuning;
## optional matched evidence uses the actual encounter, never a mocked board.

const SliceFixture = preload("res://content/two_pursuers.gd")

func _comparison_setup() -> bool:
	if not _two_pursuers_setup(): return false
	for method in ["set_board_comparison", "board_comparison", "announcement_marks"]:
		if not game.board.has_method(method):
			printerr("SETUP REQUIRED: board.", method, "; not behavioral RED")
			return false
	if not game.has_method("set_board_comparison"):
		printerr("SETUP REQUIRED: encounter UI set_board_comparison; not behavioral RED")
		return false
	var properties: Array[String] = []
	for property in game.get_property_list(): properties.append(property.name)
	for name in ["telegraph_picker", "contour_picker"]:
		if name not in properties or not game.get(name) is OptionButton:
			printerr("SETUP REQUIRED: populated real ", name, "; not behavioral RED")
			return false
	var expected := {
		"telegraph_picker": ["current", "ribbons", "stamps"],
		"contour_picker": ["current", "black", "rim"],
	}
	for name in expected:
		var picker: OptionButton = game.get(name)
		var values: Array = []
		for index in range(picker.item_count): values.append(picker.get_item_metadata(index))
		if values != expected[name]:
			printerr("SETUP REQUIRED: ", name, " metadata ", expected[name], "; not behavioral RED")
			return false
	return true

func _pick_option(picker: OptionButton, value: String) -> void:
	for index in range(picker.item_count):
		if picker.get_item_metadata(index) == value:
			picker.select(index)
			picker.item_selected.emit(index)
			return
	check(false, "comparison control exposes " + value)

func _pick_look(telegraph: String, contour: String) -> bool:
	_pick_option(game.telegraph_picker, telegraph)
	_pick_option(game.contour_picker, contour)
	var applied: bool = game.board.board_comparison() == {"telegraph": telegraph, "contour": contour}
	check(applied, "real picker signals apply " + telegraph + "/" + contour + " to the board")
	return applied

func _gameplay_facts() -> Dictionary:
	return {"model": game.model.snapshot(), "state": game.state.duplicate(true),
		"mode": game.mode, "selected": game.selected.duplicate(), "source": game.source,
		"command": game.command.duplicate(true), "prediction": game.prediction.duplicate(true),
		"candidates": game.candidates.duplicate(true), "history": game.history_lines.duplicate(),
		"confirmed": game.confirm_button.disabled, "summary": game.consequence.text}

func _presentation_facts() -> Dictionary:
	return {"generation": game.generation, "frame": game.shadow.frame(),
		"resolving": game.resolving, "cursor": game.board.cursor.duplicate(),
		"focus": game.get_viewport().gui_get_focus_owner(),
		"sheet": game._stage_sheet.visible, "tab": game.event_tabs.current_tab,
		"geometry": game.board.standee_layout(),
		"effects": game.board.effect_footprints(), "backlash": game.state.backlash_footprint.duplicate(true)}

func _open_appearance() -> void:
	if not game._stage_sheet.visible: press(game._stage_plans)
	game.event_tabs.current_tab = game.event_tabs.get_tab_idx_from_control(game.details_scroll)
	await process_frame
	await process_frame
	for picker in [game.telegraph_picker, game.contour_picker]:
		check(picker.is_visible_in_tree() and not picker.disabled, "comparison picker is usable in Details/Plans")
		game.details_scroll.ensure_control_visible(picker)
		await process_frame
		await process_frame
		check(game.details_scroll.get_global_rect().encloses(picker.get_global_rect())
			and game.get_viewport_rect().encloses(picker.get_global_rect()),
			"comparison picker can be scrolled fully into the real viewport")

func _check_warning_sources() -> void:
	var expected := {}
	for intent in game.state.intentions:
		if intent.source in ["A", "B"] and intent.kind == "shove":
			expected[intent.source] = intent.cells
	var observed := {}
	var rows: Array = game.board.announcement_marks()
	for row in rows: observed[row.get("source", "")] = row.get("cells", [])
	check(observed == expected and rows.size() == expected.size(),
		"actual board descriptors follow every current source footprint without stale or merged warnings")

func _controlled_fixture() -> Dictionary:
	var data := F.encounter([
		F.enemy("A", [2, 1], F.ability("shove", 2, 3, 0, true), 19, [0, 1]),
		F.enemy("B", [2, 3], F.ability("shove", 2, 3, 0, true), 17, [0, -1]),
	], 3, 31)
	data.width = 5
	data.height = 5
	data.player.pos = [2, 2]
	data.exit = {"pos": [4, 4], "opens": 12}
	return data

func _test_controlled_comparison() -> void:
	check(game.board.board_comparison() == {"telegraph": "current", "contour": "current"},
		"appearance defaults preserve the current baseline")
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		for captured in ["A", "B"]:
			await load_fixture(_controlled_fixture())
			# Appearance switching during capture prediction must not cancel a
			# still-live warning or manufacture a held action/transfer.
			select("capture", [2, 1] if captured == "A" else [2, 3])
			check(not game.confirm_button.disabled, "controlled source has a real legal capture preview")
			await _open_appearance()
			for telegraph in ["current", "ribbons", "stamps"]:
				for contour in ["current", "black", "rim"]:
					var before := _gameplay_facts()
					var presentation := _presentation_facts()
					_pick_look(telegraph, contour)
					check(_gameplay_facts() == before, "picker changes preserve selection, assessment, budgets and history")
					check(_presentation_facts() == presentation,
						"picker changes do not restart Director/controller, move/resize actors or close Details")
					_check_warning_sources()
			var before := _gameplay_facts()
			check(game.set_board_comparison("ribbons", "black"), "direct UI seam accepts a valid pair")
			check(game.board.board_comparison() == {"telegraph": "ribbons", "contour": "black"}
				and game.telegraph_picker.get_selected_metadata() == "ribbons"
				and game.contour_picker.get_selected_metadata() == "black",
				"programmatic changes synchronize both visible controls with the sole board preference")
			check(not game.set_board_comparison("stamps", "unknown")
				and game.board.board_comparison() == {"telegraph": "ribbons", "contour": "black"}
				and game.telegraph_picker.get_selected_metadata() == "ribbons"
				and game.contour_picker.get_selected_metadata() == "black",
				"invalid pair does not partially change board or controls")
			check(_gameplay_facts() == before, "direct option application never reassesses or commits")
			game._stage_sheet.hide()
			var expected: Dictionary = game.prediction.duplicate(true)
			press(game.confirm_button)
			check(game.resolving, "actual capture starts shared finite feedback")
			before = _gameplay_facts()
			var in_flight := _presentation_facts()
			_pick_look("stamps", "rim")
			check(_gameplay_facts() == before and _presentation_facts() == in_flight,
				"appearance during capture does not cancel, reset or replay the actual transfer")
			await settle()
			check(game.state == expected and game.model.snapshot() == expected,
				"appearance during capture preserves exact confirmed prediction")
			check(game.state.stored.get("source", "") == captured, "real capture keeps the chosen held source")
			_check_warning_sources()
			# Release prediction coexists with current intentions and the held
			# backlash footprint, rather than becoming another enemy warning.
			select("release", [1, 2])
			check(not game.confirm_button.disabled and not game.state.backlash_footprint.is_empty(),
				"controlled held state has a legal release preview and current backlash risk")
			before = _gameplay_facts()
			for telegraph in ["ribbons", "stamps"]:
				var presentation := _presentation_facts()
				_pick_look(telegraph, "rim")
				check(_gameplay_facts() == before and _presentation_facts() == presentation,
					"new warnings preserve exact release preview, held risk and settled ownership")
				_check_warning_sources()
			for view in ["plain", "paper", "stage"]:
				game.set_presentation_mode(view)
				await process_frame
				check(_gameplay_facts() == before, view + ": comparison preference never resets gameplay")
				check(game.board.board_comparison() == {"telegraph": "stamps", "contour": "rim"},
					view + ": chosen board appearance survives view changes")
				if view != "stage":
					check(not game.telegraph_picker.is_visible_in_tree() and not game.contour_picker.is_visible_in_tree(),
						"two-pursuer appearance controls do not leak into baseline views")
			game._apply_restart()
			await process_frame
			check(game.board.board_comparison() == {"telegraph": "stamps", "contour": "rim"}
				and game.telegraph_picker.get_selected_metadata() == "stamps"
				and game.contour_picker.get_selected_metadata() == "rim",
				"Restart preserves appearance preferences while resetting the real encounter")

func _capture_batch(label: String, outlines: bool = false) -> void:
	game._stage_sheet.hide()
	game.board.cursor = game.state.player.pos.duplicate()
	game.board.focus_actor("")
	game.board._hover_actor = ""
	game.board.hover_cell = []
	var processing: int = game.process_mode
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var before := _gameplay_facts()
	var frame: Dictionary = game.shadow.frame()
	var looks: Array = [["ribbons", "rim"], ["stamps", "rim"]]
	if outlines: looks = [["current", "current"], ["current", "black"], ["current", "rim"]]
	for look in looks:
		if _pick_look(look[0], look[1]):
			await image("%d-%s-%s-%s.png" % [capture_view.size.x, label, look[0], look[1]])
		check(_gameplay_facts() == before and game.shadow.frame() == frame,
			"matched readback changes only board appearance, with the actual Director pose frozen")
	game.process_mode = processing

func _capture_actual_encounter() -> void:
	# This is the integration/evidence boundary: no constant HP, range, palette,
	# contour width or actor-size expectations are imported into unit tests.
	game.fixture = SliceFixture.DATA.duplicate(true)
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		for state_name in ["initial", "A-held", "B-held"]:
			game._apply_restart()
			await process_frame
			if state_name != "initial":
				var id: String = state_name.left(1)
				var position: Array = []
				for enemy in game.state.enemies:
					if enemy.id == id: position = enemy.pos
				check(not position.is_empty(), "actual compared capture source exists: " + id)
				if position.is_empty(): continue
				await capture(position)
				check(game.state.stored.get("source", "") == id, "actual matched held state owns " + id)
			_check_warning_sources()
			if state_name == "initial": await _capture_batch("outline-initial", true)
			await _capture_batch(state_name)
			if state_name == "A-held":
				# An actual legal command, not a drawn imaginary consequence.
				select("release")
				var target: Array = []
				for candidate in game.candidates:
					if candidate != game.state.player.pos:
						target = candidate
						break
				check(not target.is_empty(), "actual held state offers a release-preview target")
				if not target.is_empty():
					click(target)
					await _capture_batch("release-preview")

func _run() -> void:
	if not _two_pursuers_pack_ready():
		quit(2)
		return
	game = load("res://scenes/encounter.tscn").instantiate()
	if capture_dir.is_empty(): root.add_child(game)
	else:
		DirAccess.make_dir_recursive_absolute(capture_dir)
		capture_view = SubViewport.new()
		capture_view.size = Vector2i(1024, 720)
		capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_view.gui_embed_subwindows = true
		root.add_child(capture_view)
		capture_view.add_child(game)
	await process_frame
	await process_frame
	if not _comparison_setup():
		game.queue_free()
		await process_frame
		quit(2)
		return
	game.set_presentation_mode("stage")
	if game.encounter_id != "two-pursuers":
		await _choose_encounter_ui("two-pursuers")
		check(game.encounter_dialog.visible, "existing chooser requests the real two-pursuer encounter")
		if game.encounter_dialog.visible:
			game.encounter_dialog.confirmed.emit()
			game.encounter_dialog.hide()
		await process_frame
	check(game.encounter_id == "two-pursuers", "comparison uses the normal playable two-pursuer scene")
	if game.encounter_id == "two-pursuers": await _test_controlled_comparison()
	# Do not produce mislabeled candidate evidence after behavioral failures.
	if failures == 0 and not capture_dir.is_empty(): await _capture_actual_encounter()
	print("Board comparison UI: %d checks, %d failures. Injected controls; no visual acceptance." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
