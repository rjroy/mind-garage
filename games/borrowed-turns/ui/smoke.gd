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
			F.enemy("source", [1, 4], skill),
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
			var data := F.encounter([F.enemy("a", [2, 1], F.ability("shove", 1, 3, 0, true), 12, [-1, 0])])
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
			check(preview_matches() and game.preview_details.is_visible_in_tree(), "ordered preview stays accessible and visible before commitment")
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
