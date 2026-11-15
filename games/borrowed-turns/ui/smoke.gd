extends SceneTree
## Real scene controls with controlled inputs. Not physical OS input or model unit tests.

const F = preload("res://ui/smoke_fixtures.gd")
const P = preload("res://ui/presentation.gd")
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
	await create_timer(0.21).timeout
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
