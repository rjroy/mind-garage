extends SceneTree
## Real scene controls with controlled inputs. Not physical OS input or model unit tests.

const F = preload("res://ui/smoke_fixtures.gd")
const P = preload("res://ui/presentation.gd")
const Production = preload("res://content/escape.gd")
var game: Control
var checks := 0
var failures := 0
var capture_dir := ""
var capture_view: SubViewport

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
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

func capture(pos: Array) -> void:
	select("capture", pos)
	await commit()

func image(name: String) -> void:
	if capture_dir.is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := capture_view.get_texture().get_image()
	check(picture.get_size() == capture_view.size, "actual capture dimensions")
	check(picture.save_png(capture_dir.path_join(name)) == OK, "saved " + name)

func preview_matches() -> bool:
	return game.preview_details.text == P.preview_text(game.prediction)

func _test_interleave() -> void:
	await load_fixture(F.encounter([F.enemy("a", [4, 3], F.ability("bolt", 1, 4))]))
	await move([2, 3])
	await move([3, 3])
	await capture([4, 3])
	check(game.state.turn == 1 and game.state.action_points == 2 and game.state.movement_points == 2, "free capture after two moves keeps independent budgets")
	await move([3, 2])
	select("release", [4, 2])
	check(not game.prediction.is_empty(), "same-turn release is legal")
	await image("r2-interleave-release.png")
	await commit()
	await move([3, 1])
	check(game.state.action_points == 1 and game.state.movement_points == 0 and game.state.turn == 1, "human 2AP4MP example leaves 1AP0MP without ending turn")
	check(game.state.player.hp == 20, "no premature enemy resolution between commands")
	select("end_turn")
	check(preview_matches(), "End turn ordered preview is current")
	var before: Dictionary = game.state.duplicate(true)
	press(game.cancel_button)
	check(game.model.snapshot() == before, "End turn cancellation changes nothing")
	select("end_turn")
	await commit()
	check(game.state.turn == 2 and game.state.action_points == 2 and game.state.movement_points == 4, "explicit End turn refreshes model budgets")

func _test_replacements() -> void:
	var enemies := [
		F.enemy("a", [1, 2], F.ability("bolt")),
		F.enemy("b", [2, 3], F.ability("shove", 1, 2, 0, true)),
		F.enemy("c", [1, 4], F.ability("burst", 2, 4, 1)),
		F.enemy("d", [0, 3], F.ability("bolt")),
	]
	var fixture := F.encounter(enemies, 0)
	fixture.rules.actions = 0
	await load_fixture(fixture)
	await capture([1, 2])
	await capture([2, 3])
	await capture([1, 4])
	check(game.state.turn == 1 and game.state.action_points == 0 and game.state.movement_points == 0, "more than two free captures work at zero AP and MP")
	check(not game.action_buttons.capture.disabled and not game.action_buttons.end_turn.disabled, "capture and End turn remain available at zero budgets")
	select("capture", [0, 3])
	check(game.prediction.stored.source == "d" and game.prediction.player.hp < game.state.player.hp, "area replacement previews self damage and acquisition")
	var enemy_damage := false
	for event in game.prediction.events:
		if event.type == "damage" and event.actor != "player": enemy_damage = true
	check(enemy_damage and preview_matches(), "area replacement previews real enemy damage and synchronized text")
	await image("r2-area-replacement.png")
	await commit()
	check(game.history_lines.size() > 6, "free commands append committed history within one turn")
	# Killing the chosen source is a legal successful discharge, not a rejected command.
	await load_fixture(F.encounter([
		F.enemy("burst", [1, 4], F.ability("burst", 3, 3, 1)),
		F.enemy("fragile", [2, 3], F.ability("bolt"), 2),
	]))
	await capture([1, 4])
	select("capture", [2, 3])
	check(not game.confirm_button.disabled and game.prediction.stored.is_empty(), "source-death replacement is legal and predicts empty storage")
	check(game.preview_details.text.contains("Capture failed") and game.consequence.text.contains("empty"), "capture_failed is visible before confirmation")
	await image("r2-capture-failed.png")
	await commit()
	# A push can invalidate the selected new source without undoing the discharge.
	await load_fixture(F.encounter([
		F.enemy("burst", [1, 4], F.ability("burst", 1, 3, 1, true)),
		F.enemy("moved", [2, 3], F.ability("bolt")),
	]))
	await capture([1, 4])
	select("capture", [2, 3])
	check(game.preview_details.text.contains("out of reach") and game.prediction.stored.is_empty(), "post-backlash source displacement previews capture failure")
	await commit()
	# Legal lethal replacement remains confirmable and never claims acquisition.
	await load_fixture(F.encounter([
		F.enemy("burst", [1, 4], F.ability("burst", 4, 3, 1)),
		F.enemy("new", [2, 3], F.ability("bolt")),
	], 1, 3))
	await capture([1, 4])
	select("capture", [2, 3])
	check(game.prediction.status == "lost" and not game.confirm_button.disabled and game.prediction.stored.is_empty(), "legal lethal preview stays enabled with no acquisition")
	check(game.consequence.text.contains("kills you"), "lethal replacement warning is visible")
	if capture_view: capture_view.size = Vector2i(1024, 720)
	await image("r2-1024-lethal-preview.png")
	await commit()
	check(game.result.visible and game.action_buttons.capture.disabled, "failure keeps final board/history but freezes gameplay")
	await image("r2-1024-failure.png")
	press(game.restart_button)
	check(game.state.turn == 1 and game.state.stored.is_empty() and not game.restart_dialog.visible, "terminal replay resets without a replacement dialog")
	if capture_view: capture_view.size = Vector2i(1280, 800)

func _test_deadline() -> void:
	await load_fixture(F.encounter([F.enemy("a", [1, 4], F.ability("burst", 2, 4, 1))]))
	await capture([1, 4])
	check(game.state.stored.deadline_turn == 2 and game.budgets.text.contains("ending turn 2"), "exact deadline visible outside scrolling rail")
	select("end_turn")
	await commit()
	check(not game.state.stored.is_empty() and game.state.turn == 2, "capture-turn End turn preserves storage")
	check(game.budgets.text.contains("Backlash"), "deadline-turn warning is visible")
	var footprint: Dictionary = game.state.backlash_footprint.duplicate(true)
	await move([2, 3])
	check(game.state.stored.deadline_turn == 2 and game.state.backlash_footprint != footprint, "movement updates backlash center without changing deadline")
	select("end_turn")
	check(game.preview_details.text.contains("Backlash") and game.prediction.stored.is_empty(), "deadline End turn previews discharge and empty slot")
	await image("r2-deadline-end-turn.png")
	if capture_view:
		capture_view.size = Vector2i(1024, 720)
		await image("r2-1024-deadline.png")
		capture_view.size = Vector2i(1280, 800)
	await commit()
	check(game.state.turn == 3, "deadline End turn advances only after confirmation")

func _test_ability_ranges() -> void:
	for skill in [F.ability("bolt", 1, 4), F.ability("shove", 1, 2, 0, true), F.ability("burst", 2, 2, 1)]:
		await load_fixture(F.encounter([
			F.enemy("source", [1, 4], skill, 12, [1, 0]),
			F.enemy("victim", [3, 2], F.ability("bolt")),
		]))
		await capture([1, 4])
		select("release", [1 + skill.range, 3])
		check(not game.prediction.is_empty() and preview_matches(), "inherited %s range is selectable on capture turn" % skill.kind)
		var before: Dictionary = game.model.snapshot()
		click([2 + skill.range, 3])
		check(game.prediction.is_empty() and game.confirm_button.disabled and game.model.snapshot() == before, "outside inherited range rejects without stale preview or mutation")
		click([1 + skill.range, 3])
		if skill.kind == "burst":
			var areas := 0
			for event in game.prediction.events:
				if event.type == "area": areas += 1
			check(areas == 1, "burst release exposes area geometry rather than a ray")
			await image("r2-area-release.png")
		await commit()

func _test_normal_shove() -> void:
	await load_fixture(F.encounter([F.enemy("shover", [2, 3], F.ability("shove", 1, 4, 0, true))]))
	var forbidden_toggles: Array[String] = []
	for node in game.find_children("*", "CheckButton", true, false):
		if "invert" in node.text.to_lower() or "pull" in node.text.to_lower():
			forbidden_toggles.append(node.text)
	check(forbidden_toggles.is_empty(), "no Invert or pull controls exist")
	check(not game.model.snapshot().has("invert_enabled"), "active encounter snapshot has no invert configuration")
	await capture([2, 3])
	var before: Dictionary = game.model.snapshot()
	select("release", [2, 3])
	check(not game.command.has("invert"), "normal release command has no invert field")
	check(game.model.snapshot() == before, "release selection and assessment do not mutate")
	check(not game.prediction.is_empty() and game.prediction == game.model.assess(game.command).get("preview", {}) and preview_matches(), "normal release ordered text matches model prediction")
	check(game.board.preview == game.prediction and game.board.selected == [2, 3], "normal release board and target match prediction")
	var displacement := []
	for event in game.prediction.get("events", []):
		if event.get("type") == "displace" and event.get("actor") == "shover": displacement = event.get("to", [])
	check(displacement == [3, 3], "normal shove preview pushes source away")
	await image("r2-normal-shove.png")
	await commit()
	var pushed := false
	for enemy in game.state.enemies:
		if enemy.id == "shover" and enemy.pos == [3, 3]: pushed = true
	check(pushed, "confirmed normal shove pushes source away")
	press(game.restart_button)
	check(game.restart_dialog.visible, "unfinished changed run protects restart")
	game.restart_dialog.get_cancel_button().pressed.emit()
	game.restart_dialog.hide()
	check(game.changed, "canceling restart preserves the encounter")
	press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	check(game.state.turn == 1 and game.state.stored.is_empty() and game.history_lines.size() == 1, "restart isolates storage, budgets and history")

func _test_shadow_integration() -> void:
	var reference: Array = []
	var reference_history: Array[String] = []
	for view in ["plain", "paper", "stage"]:
		game.set_presentation_mode(view)
		check(game.presentation_mode == view, "explicit presentation selection accepts " + view)
		await load_fixture(F.shadow_single())
		var observed: Array = []
		for step in [["capture", [2, 3]], ["end_turn", []], ["release", [2, 3]]]:
			select(step[0], step[1])
			observed.append(game.prediction.duplicate(true))
			observed.append(game.board.effect_footprints().duplicate(true))
			await commit()
			observed.append(game.state.duplicate(true))
			if step[0] == "end_turn":
				var frame: Dictionary = game.shadow.frame()
				check(not frame.held.is_empty() and frame.announcements.size() == 1, view + ": fresh source announcement coexists with old held shadow")
		if view == "plain":
			reference = observed
			reference_history = game.history_lines.duplicate()
		else:
			check(observed == reference and game.history_lines == reference_history, view + ": actual controls yield baseline-identical assessments, model state, events and history")
	game.set_presentation_mode("paper")
	await load_fixture(F.shadow_single())
	var before: Dictionary = game.model.snapshot()
	select("capture", [4, 4])
	check(game.shadow.frame().cues.is_empty() and game.model.snapshot() == before, "invalid source selection creates no committed transfer")
	select("capture", [2, 3])
	press(game.cancel_button)
	check(game.shadow.frame().cues.is_empty() and game.model.snapshot() == before, "canceling capture preview creates no transfer")
	select("capture", [2, 3])
	press(game.confirm_button)
	check(game.resolving and game.shadow.frame().busy, "paper capture starts finite feedback")
	var once: Dictionary = game.model.snapshot()
	var lines: int = game.history_lines.size()
	game._confirm()
	check(game.model.snapshot() == once and game.history_lines.size() == lines, "repeated confirmation during feedback cannot commit twice")
	game.paper_switch.set_pressed(false)
	check(game.presentation_mode == "plain" and not game.resolving and not game.shadow.frame().busy, "view switch cancels transfer without retaining busy work")
	check(game.model.snapshot() == once and game.history_lines.size() == lines, "view change preserves progress, budgets and history")
	game.paper_switch.set_pressed(true)
	check(game.shadow.frame().held == once.stored and game.shadow.frame().cues.is_empty(), "returning to paper restores settled ownership without replay")
	select("release", [2, 3])
	var selected_command: Dictionary = game.command.duplicate(true)
	var selected_prediction: Dictionary = game.prediction.duplicate(true)
	game.paper_switch.set_pressed(false)
	game.paper_switch.set_pressed(true)
	check(game.command == selected_command and game.prediction == selected_prediction and preview_matches(), "view switches preserve targeting and synchronized prediction")
	press(game.cancel_button)
	await load_fixture(F.shadow_single())
	select("capture", [2, 3])
	press(game.confirm_button)
	var old_generation: int = game.generation
	press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	await settle()
	check(game.generation > old_generation and game.state.stored.is_empty() and game.shadow.frame().held.is_empty() and not game.shadow.frame().busy, "restart during transfer isolates generation and cancels acquisition visuals")
	for outcome in ["acquired", "source_dead", "out_of_reach", "lethal"]:
		await load_fixture(F.shadow_replacement(outcome))
		await capture([1, 4])
		select("capture", [0, 3] if outcome == "acquired" else [2, 3])
		await commit()
		var types: Array = []
		for cue in game.shadow.frame().cues: types.append(cue.type)
		check(types == (["backlash", "capture"] if outcome == "acquired" else ["backlash"]), outcome + ": actual UI transfer plan follows the real replacement result")
		check(game.shadow.frame().held == game.state.stored, outcome + ": held rendering matches actual acquisition or loss")
	await load_fixture(F.encounter([
		F.enemy("a", [2, 3], F.ability("shove", 1, 3, 0, true), 1, [1, 0]),
		F.enemy("b", [2, 5], F.ability("bolt", 1, 3), 8, [0, -1]),
	]))
	await capture([2, 3])
	select("end_turn")
	await commit()
	check(not game.shadow.frame().held.is_empty() and game.shadow.frame().announcements.is_empty(), "source death removes fresh source shadow but not its still-held capture")
	if capture_view:
		capture_view.size = Vector2i(1024, 720)
		await process_frame
		check(game.board._cell_size() >= 36 and game.confirm_button.get_global_rect().end.y <= 720, "minimum viewport preserves tactical cell size and confirmation bounds")
		await image("fy3-1024-held-source-dead.png")
		capture_view.size = Vector2i(1280, 800)

func _stage_setup() -> bool:
	for method in ["set_stage_mode", "cell_polygon", "piece_appearance", "figure_layout"]:
		if not game.board.has_method(method):
			printerr("SETUP REQUIRED: loadable shared stage board seams before RED; missing " + method + ". See tests/stage_projection_run.gd and stage integration brief.")
			return false
	return true

func _stage_resize(viewport_size: Vector2i) -> void:
	if capture_view: capture_view.size = viewport_size
	else: root.size = viewport_size
	await process_frame
	await process_frame

func _stage_gui_click(local_point: Vector2) -> void:
	# Through the actual viewport GUI path, so decorative layers cannot silently
	# eat clicks. This is still injected input, not physical OS input evidence.
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.board.get_global_transform() * local_point
	game.get_viewport().push_input(event)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
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

func _test_stage_return_panels() -> void:
	# STAGE-C01: leaving a TabContainer must restore the rail's actual controls,
	# not retain the inactive Plans tab's hidden flag. Active Plans is a distinct
	# control case. Held storage plus a fresh announcement exercises both panels.
	await _stage_resize(Vector2i(1024, 720))
	game.set_presentation_mode("paper")
	await load_fixture(F.shadow_single())
	await capture([2, 3])
	select("end_turn")
	await commit()
	check(not game.state.stored.is_empty() and game.state.intentions.size() == 1,
		"STAGE-C01 fixture has held details and a fresh enemy intention")
	for baseline in ["plain", "paper"]:
		for panel in ["preview", "events", "plans"]:
			game.set_presentation_mode("stage")
			press(game._stage_plans)
			var tab: Control = game.preview_details if panel == "preview" else (game.history.get_parent() if panel == "events" else game.details_scroll)
			var tab_index: int = game.event_tabs.get_tab_idx_from_control(tab)
			check(tab_index >= 0, "STAGE-C01 requested stage tab exists: " + panel)
			if tab_index < 0: continue
			game.event_tabs.current_tab = tab_index
			await process_frame
			await process_frame
			check(game.details_scroll.is_visible_in_tree() == (panel == "plans"),
				"STAGE-C01 tab visibility precondition: " + panel)
			var before: Dictionary = game.model.snapshot()
			var history_before: Array[String] = game.history_lines.duplicate()
			game.set_presentation_mode(baseline)
			await process_frame
			await process_frame
			var label: String = "STAGE-C01 stage/" + panel + " -> " + baseline
			var viewport_bounds: Rect2 = game.get_viewport_rect()
			var rail_bounds: Rect2 = game.rail.get_global_rect()
			var details_bounds: Rect2 = game.details_scroll.get_global_rect()
			check(game.details_scroll.get_parent() == game.rail and game.details_scroll.is_visible_in_tree(),
				label + ": details return as a visible rail panel, not a hidden tab")
			check(details_bounds.size.x > 0 and details_bounds.size.y > 0 and rail_bounds.encloses(details_bounds) and viewport_bounds.encloses(details_bounds),
				label + ": restored details have nonzero in-viewport rail allocation")
			check(game.stored.is_visible_in_tree() and game.stored.text == P.stored_text(before),
				label + ": complete held-ability details are visible, not the compact stage summary")
			check(game.intention_list.is_visible_in_tree(), label + ": enemy intention controls return visibly")
			game.details_scroll.ensure_control_visible(game.stored)
			await process_frame
			await process_frame
			var stored_bounds: Rect2 = game.stored.get_global_rect()
			var line_height: float = game.stored.get_theme_font("font").get_height(game.stored.get_theme_font_size("font_size"))
			check(stored_bounds.size.x > 0 and details_bounds.intersection(stored_bounds).size.y >= line_height,
				label + ": stored text occupies readable space inside the scroll viewport")
			var plan_button: Button
			for child in game.intention_list.get_children():
				if child is Button:
					plan_button = child
					break
			check(plan_button != null, label + ": fresh model intention has a real source control")
			if plan_button == null: continue
			game.details_scroll.ensure_control_visible(plan_button)
			await process_frame
			await process_frame
			var button_bounds := plan_button.get_global_rect()
			check(plan_button.is_visible_in_tree() and details_bounds.encloses(button_bounds) and viewport_bounds.encloses(button_bounds)
				and button_bounds.size.y >= plan_button.get_combined_minimum_size().y,
				label + ": intention row can be scrolled fully into usable viewport space")
			press(plan_button)
			check(game.source == "a" and game.selected == [2, 3],
				label + ": restored intention control selects its actual source")
			check(game.model.snapshot() == before and game.history_lines == history_before,
				label + ": restoring and using panels does not advance gameplay or rewrite history")

func _test_stage_integration() -> void:
	game.set_presentation_mode("stage")
	check(game.presentation_mode == "stage", "optional stage presentation is selectable")
	if game.presentation_mode != "stage": return
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
				await _stage_gui_click(center)
				check(game.selected == cell and game.model.snapshot() == before, "actual viewport targeting reaches every corner without spending a turn")
			var selected_before: Array = game.selected.duplicate()
			await _stage_gui_click(Vector2(1, 1))
			check(game.selected == selected_before and game.model.snapshot() == before, "decorative stage background does not select a board cell")
			press(game.action_buttons.capture)
			await _stage_gui_click(game.board.cell_center([2, 1]))
			check(game.command == {"type": "capture", "source": "a"} and not game.confirm_button.disabled, "stage click selects the real capture source")
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
			var committed: Dictionary = game.model.snapshot()
			var committed_history: Array[String] = game.history_lines.duplicate()
			game.set_presentation_mode("plain")
			check(not game.resolving and not game.shadow.frame().busy, "leaving stage during feedback cancels stale visual work")
			check(game.model.snapshot() == committed and game.history_lines == committed_history, "leaving stage preserves committed outcomes and history")
			game.set_presentation_mode("stage")
			check(game.shadow.frame().held == committed.stored and game.shadow.frame().cues.is_empty(), "returning to stage restores ownership without replay")
			select("end_turn")
			press(game.confirm_button)
			check(game.resolving and game.board.piece_appearance([1, 1]) == paper_piece, "new-turn feedback preserves the same visual paper seed")
			var old_generation: int = game.generation
			game._apply_restart()
			await settle()
			check(game.generation > old_generation and game.state == before and game.shadow.frame().held.is_empty() and not game.shadow.frame().busy, "stage restart during feedback removes old held state and stale work")
			check(game.board.piece_appearance([1, 1]) == paper_piece, "restart does not reshuffle the same visual field")
			await _stage_resize(viewport_size)
	# Actual unchanged encounter and separately labeled controlled shove captures.
	# Production data is used only at this integration boundary, never as unit
	# expectations. Do not invent readability from pixel positions.
	for viewport_size in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(viewport_size)
		await load_fixture(Production.DATA)
		_stage_controls_fit("actual encounter " + str(viewport_size))
		await image("stage-%d-encounter.png" % viewport_size.x)
		await load_fixture(F.shadow_single())
		select("capture", [2, 3])
		await image("stage-%d-shove-preview.png" % viewport_size.x)
		await commit()
		await image("stage-%d-shove-held.png" % viewport_size.x)
	await _test_stage_return_panels()
	game.set_presentation_mode("paper")
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
	check(game.encounter_id == "two-pursuers" and game.presentation_mode == "stage",
		"actual command-line encounter and presentation select the normal playable scene")
	check(game.state.get("objective", "") == "defeat_all", "normal fight objective is explicitly defeat all opponents")
	var player: Array = game.state.player.pos
	check(player == [0, int(game.state.height / 2.0)], "actual fight starts at the left edge midpoint")
	var corners: Array = []
	var patterns: Array = []
	for enemy in game.state.enemies:
		corners.append(enemy.pos)
		patterns.append(enemy.get("movement_pattern", ""))
	check(corners.size() == 2 and [game.state.width - 1, 0] in corners
		and [game.state.width - 1, game.state.height - 1] in corners,
		"actual opponents start at the opposite edge's two corners")
	check("chase_player" in patterns and "keep_max_range" in patterns,
		"default fight exposes both requested active opponent roles")
	var picker: OptionButton = game.encounter_picker
	check(picker.get_selected_metadata() == "two-pursuers", "visible chooser reflects the command-line encounter")
	check(not game.objective.text.to_lower().contains("exit"), "default visible objective is combat, not bypassing enemies")
	check(game.board.standee_layout().size() == 3, "command-line entry loads all three approved standee actors")

func _test_two_pursuers_integration() -> void:
	check(game.encounter_id == "two-pursuers" and game.presentation_mode == "stage",
		"normal entry opens the active fight and accepted Stage without buried choices")
	if game.encounter_id == "two-pursuers":
		_test_two_pursuers_startup()
		await _choose_encounter_ui("escape")
		if game.encounter_dialog.visible:
			game.encounter_dialog.confirmed.emit()
			game.encounter_dialog.hide()
		await process_frame
	check(game.encounter_id == "escape" and game.fixture == Production.DATA,
		"explicit escape comparison retains its authored source fixture")
	game.set_presentation_mode("stage")
	await _stage_resize(Vector2i(1024, 720))
	var original: Dictionary = game.model.snapshot()
	await _choose_encounter_ui("two-pursuers")
	check(game.encounter_dialog.visible and game.model.snapshot() == original,
		"choosing another encounter requests a new run without changing the current model")
	if game.encounter_dialog.visible:
		game.encounter_dialog.get_cancel_button().pressed.emit()
		game.encounter_dialog.hide()
	check(game.encounter_id == "escape" and game.model.snapshot() == original,
		"canceling encounter replacement preserves the current run")
	await _choose_encounter_ui("two-pursuers")
	if game.encounter_dialog.visible:
		game.encounter_dialog.confirmed.emit()
		game.encounter_dialog.hide()
	await process_frame
	check(game.encounter_id == "two-pursuers", "confirmed chooser starts the real playable two-pursuer encounter")
	_check_default_puppet_pack()
	if game.encounter_id != "two-pursuers": return
	_test_two_pursuers_startup()
	# Capture/body/roster geometry below uses a test-owned safe flank, not
	# mutable production start positions or an illegal crossfire acquisition.
	await load_fixture(F.two_pursuers())
	var initial: Dictionary = game.state.duplicate(true)
	check(initial.width == 5 and initial.height == 5 and initial.player.pos == [1, 2],
		"controlled depth fixture starts capture from a safe flank")
	var cells := {}
	for enemy in initial.enemies: cells[enemy.id] = enemy.pos
	check(cells == {"A": [2, 1], "B": [2, 3]}, "both pursuers remain in the deliberately overlapping depth column")
	var threats: Array = []
	for intent in initial.intentions:
		if [2, 2] in intent.cells: threats.append(intent.source)
	check(threats.size() == 2 and "A" in threats and "B" in threats,
		"controlled footprints overlap independently away from the safe player cell")
	var source_paths := {"player": "player.png", "A": "enemy-a.png", "B": "enemy-b.png"}
	for viewport_size in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(viewport_size)
		game._apply_restart()
		await process_frame
		_stage_controls_fit("two-pursuers " + str(viewport_size))
		check(game.encounter_picker.is_visible_in_tree()
			and game.get_viewport_rect().encloses(game.encounter_picker.get_global_rect()),
			"encounter choice stays accessible in the real Stage layout")
		var rows: Array = game.board.standee_layout()
		check(rows.size() == 3, "real board uses three authored standee draw instances")
		for id in ["player", "A", "B"]:
			var row := _standee_entry(id)
			var texture = row.get("texture")
			check(texture is Texture2D, id + ": approved candidate artwork is loaded by the actual board")
			if not texture is Texture2D: continue
			check(texture.resource_path == "res://assets/standees/two-pursuers/" + source_paths[id],
				id + ": source texture is the approved unchanged standee, not a primitive fallback")
			check(row.get("foot") is Vector2 and row.get("cell") is Array
				and row.foot.distance_to(game.board.cell_center(row.cell)) < 0.01,
				id + ": actual figure is attached to the projected owning cell")
		await image("dual-layer-%d-initial.png" % viewport_size.x)
		# Both choices matter: the B handoff is not assumed from the older A-only
		# motion pilot. Orientation/taste are judged in actual render evidence.
		for id in ["A", "B"]:
			press(game.action_buttons.capture)
			var point := _standee_body_point(id)
			check(point.is_finite(), id + ": some actual visible body can be picked above its owning floor cell")
			if not point.is_finite(): continue
			await _stage_gui_click(point)
			check(game.command == {"type": "capture", "source": id} and not game.confirm_button.disabled,
				id + ": actual viewport body click prepares the correct source capture")
			check(game.state == initial, "body selection and preview do not advance the encounter")
			check(not game._stage_sheet.visible, "selection leaves the puppet performance unobscured")
			check(not game.consequence.text.is_empty() and game.consequence.is_visible_in_tree()
				and game.confirm_button.is_visible_in_tree() and game.cancel_button.is_visible_in_tree(),
				"cost/consequence and confirmation stay present without the opaque Details sheet")
			press(game._stage_plans)
			await process_frame
			check(game._stage_sheet.visible and game.preview_details.is_visible_in_tree() and preview_matches(),
				"explicit Details reveals the exact selected ordered preview")
			var floor_bounds: Rect2 = game.board._board_rect()
			floor_bounds.position += game.board.global_position
			check(not game._stage_sheet.get_global_rect().intersects(floor_bounds),
				"explicit Details never covers the playable floor")
			press(game._stage_plans)
			await image("dual-layer-%d-%s-preview.png" % [viewport_size.x, id.to_lower()])
			await commit()
			check(game.state.stored.get("source", "") == id and game.state.enemies.size() == 2,
				id + ": capture stores that occurrence and leaves both standees alive")
			var other: String = "B" if id == "A" else "A"
			check(game.state.intentions.size() == 1 and game.state.intentions[0].source == other,
				id + ": capture removes only that source announcement; the other remains authoritative")
			await image("dual-layer-%d-%s-held.png" % [viewport_size.x, id.to_lower()])
			var committed: Dictionary = game.state.duplicate(true)
			var lines: Array[String] = game.history_lines.duplicate()
			select("end_turn")
			var prepared: Dictionary = game.prediction.duplicate(true)
			var submitted: Dictionary = game.command.duplicate(true)
			for view in ["plain", "paper", "stage"]:
				game.set_presentation_mode(view)
				await process_frame
				check(game.encounter_id == "two-pursuers" and game.state == committed
					and game.history_lines == lines and game.command == submitted and game.prediction == prepared,
					view + ": view changes preserve selected encounter, command, prediction and progress")
			await commit()
			check(game.state.turn > committed.turn and not game.state.stored.is_empty(),
				"real End turn continues the encounter while retaining the old held occurrence")
			select("release")
			var target: Array = []
			for candidate in game.candidates:
				if candidate != game.state.player.pos:
					target = candidate
					break
			check(not target.is_empty(), "continuing encounter offers a real legal release target")
			if not target.is_empty():
				click(target)
				await commit()
				check(game.state.stored.is_empty(), "actual release clears storage and returns to continued play")
			game._apply_restart()
			await process_frame
			check(game.encounter_id == "two-pursuers" and game.state == initial
				and game.shadow.frame().held.is_empty() and not game.resolving,
				"Restart restores this selected encounter and clears stale held/performance work")
	# A selected rear source can be reached without clicking an obscured body.
	var ordered: Array = game.board.standee_layout()
	var target_index := -1
	for i in range(ordered.size()):
		if ordered[i].actor == "A": target_index = i
	check(target_index >= 0, "controlled keyboard fixture contains A")
	if target_index >= 0: game.board.cursor = ordered[posmod(target_index - 1, ordered.size())].cell.duplicate()
	var cycle := InputEventKey.new()
	cycle.keycode = KEY_BRACKETRIGHT
	cycle.pressed = true
	game.board.gui_input.emit(cycle)
	check(game.board.cursor == _standee_entry("A").get("cell", []), "real bracket-key source cycling reaches A without a body click")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	press(game.action_buttons.capture)
	game.board.gui_input.emit(enter)
	check(game.command == {"type": "capture", "source": "A"} and game.state == initial,
		"keyboard rear-source focus prepares capture without committing it")
	press(game.cancel_button)
	var winning := F.encounter([
		F.enemy("A", [2, 1], F.ability("shove", 2, 2, 0, true), 9, [0, 1]),
		F.enemy("B", [2, 3], F.ability("shove", 2, 2, 0, true), 9, [0, -1]),
	], 2, 13)
	winning.width = 5
	winning.height = 5
	winning.player.pos = [2, 2]
	winning.exit = {"pos": [3, 2], "opens": 1}
	await load_fixture(winning)
	await move([3, 2])
	check(game.state.status == "won" and game.result.is_visible_in_tree()
		and game.action_buttons.capture.disabled, "selected Stage encounter supports a real terminal result, not a capture-only script")
	press(game.restart_button)
	check(game.encounter_id == "two-pursuers" and game.state.status == "playing"
		and game.state.stored.is_empty(), "terminal replay retains the selected encounter identity")
	var before_switch: Dictionary = game.state.duplicate(true)
	await _choose_encounter_ui("escape")
	check(game.encounter_dialog.visible and game.state == before_switch, "returning to the original encounter is also an explicit new run")
	if game.encounter_dialog.visible:
		game.encounter_dialog.confirmed.emit()
		game.encounter_dialog.hide()
	await process_frame
	check(game.encounter_id == "escape" and game.fixture == Production.DATA,
		"original content remains available unchanged through the real chooser")
	game.set_presentation_mode("paper")

func _test_active_opponents() -> void:
	check(game.encounter_id == "two-pursuers" and game.presentation_mode == "stage",
		"normal entry is the active Stage fight, not the retained escape comparison")
	if game.encounter_id != "two-pursuers":
		await _choose_encounter_ui("two-pursuers")
		if game.encounter_dialog.visible:
			game.encounter_dialog.confirmed.emit()
			game.encounter_dialog.hide()
		await process_frame
	game.set_presentation_mode("stage")
	_test_two_pursuers_startup()
	# Formatter inputs are explicit authored facts. Missing exit is not the
	# rule selector, and an irreversible failed replacement is not rejection.
	var victory := P.event_text({"type": "win", "objective": "defeat_all"}).to_lower()
	check(not victory.contains("escape") and (victory.contains("victory") or victory.contains("defeat")),
		"defeat-all win event history reports combat victory, never escape")
	check(P.event_text({"type": "win", "objective": "escape"}).to_lower().contains("escape"),
		"retained explicit escape history keeps its meaning")
	var failed := P.event_text({"type": "capture_failed", "source": "A", "reason": "threatened"}).to_lower()
	check((failed.contains("threat") or failed.contains("attack")) and not failed.contains("out of reach"),
		"post-backlash threatened acquisition failure is not mislabeled as range failure")
	var blocked := F.encounter([
		F.enemy("A", [2, 3], F.ability("shove", 1, 2, 0, true), 12, [1, 0]),
		F.enemy("B", [1, 5], F.ability("bolt", 1, 4), 13, [0, -1]),
	], 3, 39, 2)
	blocked.objective = "defeat_all"
	await load_fixture(blocked)
	var before: Dictionary = game.model.snapshot()
	var history_before: Array = game.history_lines.duplicate()
	select("capture", [2, 3])
	check(game.confirm_button.disabled and game.prediction.is_empty() and game.candidates.is_empty(),
		"any other source's current threat blocks capture, not only the selected source's footprint")
	var reason: String = game.consequence.text.to_lower()
	check((reason.contains("threat") or reason.contains("attack") or reason.contains("announced"))
		and game.consequence.is_visible_in_tree(), "capture restriction is explained in persistent visible consequence text")
	game._confirm()
	check(game.model.snapshot() == before and game.history_lines == history_before,
		"blocked capture confirmation is atomic: no backlash, acquisition, history or budget mutation")
	await settle()

	var fight := F.active_fight()
	await load_fixture(fight)
	var objective_text: String = game.objective.text.to_lower()
	var objective_ready: bool = not objective_text.contains("exit") \
		and (objective_text.contains("defeat") or objective_text.contains("foe") or objective_text.contains("opponent"))
	check(objective_ready, "active fight persistently explains its defeat-all objective, not exit timing")
	check(not game.state.has("exit") and game.board.state.get("objective", "") == "defeat_all",
		"real fight can load/refresh/draw without a fake exit field")
	var initial: Dictionary = game.model.snapshot()
	var initial_history: Array = game.history_lines.duplicate()
	select("end_turn")
	var assessed: Dictionary = game.model.assess({"type": "end_turn"})
	check(game.prediction == assessed.get("preview", {}) and preview_matches(),
		"UI preview is exactly the model's old-resolution-plus-movement prediction, not another planner")
	check(game.model.snapshot() == initial and game.history_lines == initial_history,
		"previewing aimed attacks and movement never advances the fight")
	var movement: Array = []
	for event in game.prediction.get("events", []):
		if event.type == "move" and event.actor != "player":
			movement.append(event)
			check(game.preview_details.text.contains(P.event_text(event)), "exact ordered preview includes the actual moving actor and destination")
	check(not movement.is_empty(), "controlled mobile fight has real previewed enemy movement")
	var expected: Dictionary = game.prediction.duplicate(true)
	press(game.confirm_button)
	check(game.resolving and game.model.snapshot() == expected, "confirmation commits once, then finite feedback owns input lock")
	var committed_history: Array = game.history_lines.duplicate()
	var saw_slide := false
	var announced_early := false
	var deadline := Time.get_ticks_msec() + 10000
	while game.resolving and Time.get_ticks_msec() < deadline:
		var frame: Dictionary = game.shadow.frame()
		if frame.busy:
			announced_early = announced_early or not frame.announcements.is_empty() \
				or not game.board.announcement_waves().is_empty()
		if frame.cue.get("type", "") == "move":
			saw_slide = true
			var index: int = frame.cue.get("event_index", -1)
			check(index >= 0 and index < expected.events.size() and expected.events[index].type == "move",
				"finite slide references the actual committed move event")
			game._confirm()
			game._select_cell([0, 0])
			check(game.model.snapshot() == expected and game.history_lines == committed_history,
				"input stays locked during slides and cannot replay or partially commit a command")
		await process_frame
	check(not game.resolving and saw_slide and not announced_early,
		"old effects and separate slides finish before fresh next-turn warnings/rehearsal begin")
	check(game.state == expected and game.model.snapshot() == expected, "movement completion settles to the exact model snapshot")
	for enemy in expected.enemies:
		var row := _standee_entry(enemy.id)
		check(row.get("cell", []) == enemy.pos and row.get("foot", Vector2(INF, INF)).distance_to(game.board.cell_center(enemy.pos)) < 0.01,
			"settled accepted standee is anchored at its authoritative moved cell")
	# Cancellation uses the same generation/reset path, not a movement clock.
	select("end_turn")
	press(game.confirm_button)
	var after: Dictionary = game.model.snapshot()
	var generation: int = game.generation
	game.set_presentation_mode("plain")
	check(game.generation > generation and not game.resolving and not game.shadow.frame().busy
		and game.model.snapshot() == after, "view change cancels finite slides while keeping committed movement")
	game.set_presentation_mode("stage")
	select("end_turn")
	press(game.confirm_button)
	generation = game.generation
	game._apply_restart()
	await process_frame
	check(game.generation > generation and game.model.snapshot() == initial and not game.shadow.frame().busy
		and game.history_lines.size() == 1, "restart cancels old-generation slides and restores the selected fight")

	var winning := F.encounter([
		F.enemy("A", [1, 4], F.ability("shove", 3, 3), 2, [1, 0]),
		F.enemy("B", [2, 3], F.ability("shove", 1, 2), 2, [1, 0]),
	], 3, 39)
	winning.objective = "defeat_all"
	winning.erase("exit")
	await load_fixture(winning)
	await capture([1, 4])
	select("release", [2, 3])
	await commit()
	check(game.state.status == "playing" and game.state.enemies.size() == 1,
		"defeating only one opponent does not complete the fight")
	select("end_turn")
	await commit()
	var threatened_state: Dictionary = game.model.snapshot()
	var threatened_history: Array = game.history_lines.duplicate()
	select("capture", [1, 4])
	check(game.confirm_button.disabled and game.prediction.is_empty()
		and game.model.snapshot() == threatened_state and game.history_lines == threatened_history,
		"fresh upward attack blocks reacquisition before repositioning, without changing state/history")
	press(game.cancel_button)
	var flank_path := [[2, 3], [2, 4]]
	var usable_path: bool = game.state.movement_points >= flank_path.size()
	for cell in flank_path:
		usable_path = usable_path and cell[0] >= 0 and cell[0] < game.state.width \
			and cell[1] >= 0 and cell[1] < game.state.height and cell not in game.state.walls
		for enemy in game.state.enemies:
			if enemy.pos == cell: usable_path = false
	check(usable_path, "controlled victory fixture has enough MP and two free in-bounds flank cells")
	if not usable_path: return
	for cell in flank_path: await move(cell)
	var safe_flank := true
	for intent in game.state.intentions:
		if game.state.player.pos in intent.cells: safe_flank = false
	check(safe_flank and game.state.player.pos == [2, 4] and game.state.intentions == threatened_state.intentions
		and game.model.assess({"type": "capture", "source": "A"}).get("legal", false),
		"real movement reaches a safe adjacent flank while the old attack aim remains locked")
	await capture([1, 4])
	select("release", [1, 4])
	check(game.prediction.get("status", "") == "won" and not game.consequence.text.to_lower().contains("escape"),
		"last-foe defeat previews victory using the explicit combat objective")
	await commit()
	check(game.state.status == "won" and game.result.is_visible_in_tree()
		and not game.result.text.to_lower().contains("escape") and game.action_buttons.capture.disabled,
		"terminal fight retains board/history with combat victory, not an exit result")
	check(not game.history.text.to_lower().contains("escaped"), "committed fight history never invents an escape")
	press(game.restart_button)
	check(game.state.status == "playing" and game.state.enemies.size() == 2 and not game.restart_dialog.visible,
		"terminal replay restarts the fight without progression, unlocks or an unnecessary confirmation")

func _run() -> void:
	game = load("res://scenes/encounter.tscn").instantiate()
	if capture_dir.is_empty(): root.add_child(game)
	else:
		DirAccess.make_dir_recursive_absolute(capture_dir)
		capture_view = SubViewport.new()
		capture_view.size = Vector2i(1280, 800)
		capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_view.gui_embed_subwindows = true
		root.add_child(capture_view)
		capture_view.add_child(game)
	await process_frame
	await process_frame
	check(game.state.variant == "R2" and game.state.status == "playing", "one R2 baseline opens immediately")
	check(game.action_buttons.keys() == ["move", "capture", "release", "end_turn"], "only the four revised operations exist")
	if OS.get_cmdline_user_args().has("--focus=active-opponents"):
		await _test_active_opponents()
		print("Active opponents UI: %d checks, %d failures. Controlled joins, not enjoyment or visual acceptance." % [checks, failures])
		game.queue_free()
		await process_frame
		quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--focus=no-invert"):
		await _test_normal_shove()
		print("R2 UI smoke: %d checks, %d failures. Injected GUI events, not physical OS input." % [checks, failures])
		game.queue_free()
		await process_frame
		quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--focus=shadow"):
		await _test_shadow_integration()
		print("R2 UI smoke: %d checks, %d failures. Injected GUI events, not physical OS input." % [checks, failures])
		game.queue_free()
		await process_frame
		quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--focus=two-pursuers") \
		or OS.get_cmdline_user_args().has("--focus=two-pursuers-cli"):
		if not _two_pursuers_setup():
			game.queue_free()
			await process_frame
			quit(2)
			return
		if OS.get_cmdline_user_args().has("--focus=two-pursuers-cli"):
			_test_two_pursuers_startup()
		else:
			await _test_two_pursuers_integration()
		print("Two-pursuers UI smoke: %d checks, %d failures. Injected viewport input, not human playability approval." % [checks, failures])
		game.queue_free()
		await process_frame
		quit(1 if failures else 0)
		return
	if not _stage_setup():
		game.queue_free()
		await process_frame
		quit(2)
		return
	if OS.get_cmdline_user_args().has("--focus=stage"):
		await _test_stage_integration()
		print("R2 UI smoke: %d checks, %d failures. Injected GUI events, not physical OS input." % [checks, failures])
		game.queue_free()
		await process_frame
		quit(1 if failures else 0)
		return
	if capture_view:
		for size in [Vector2i(1280, 800), Vector2i(1024, 720), Vector2i(1600, 900)]:
			capture_view.size = size
			await image("r2-%d-start.png" % size.x)
		capture_view.size = Vector2i(1280, 800)
	await _test_interleave()
	await _test_replacements()
	await _test_deadline()
	await _test_ability_ranges()
	await _test_normal_shove()
	await _test_shadow_integration()
	await _test_stage_integration()
	# Board Enter selects without committing; the next explicit confirmation acts.
	await load_fixture(F.encounter([]))
	var before_keyboard: Dictionary = game.model.snapshot()
	var end_key := InputEventKey.new()
	end_key.keycode = KEY_E
	end_key.pressed = true
	game.get_viewport().push_input(end_key)
	await process_frame
	check(game.command.get("type", "") == "end_turn" and game.model.snapshot() == before_keyboard, "injected E prepares End turn without committing")
	var escape_key := InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	game.get_viewport().push_input(escape_key)
	await process_frame
	check(game.command.is_empty() and game.model.snapshot() == before_keyboard, "injected Esc cancels End turn without advancing")
	press(game.action_buttons.move)
	game.board.cursor = [2, 3]
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	game.board.gui_input.emit(key)
	check(game.state.movement_points == 4 and game.confirm_button.has_focus(), "board Enter only selects and focuses confirmation")
	await commit()
	var winning := F.encounter([])
	winning.exit = {"pos": [2, 3], "opens": 1}
	await load_fixture(winning)
	await move([2, 3])
	check(game.state.status == "won" and game.result.visible, "escape remains the objective and preserves terminal board")
	await image("r2-escaped.png")
	print("R2 UI smoke: %d checks, %d failures. Injected GUI events, not physical OS input." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
