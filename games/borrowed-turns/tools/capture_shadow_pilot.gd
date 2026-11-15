extends SceneTree
## Real scene evidence through injected native controls. PNG sequences are motion
## evidence, not shipping art. No direct model mutations or alternate game actions.

const F = preload("res://ui/smoke_fixtures.gd")
var game: Control
var view: SubViewport
var output := "/tmp/opencode/borrowed-turns-fy3-evidence"
var clip := ""
var frame_index := 0
var failures := 0
var fixture_origin := "production"
var manifest := {"baseline": "ba3ab7a", "input": "injected real scene controls, not physical OS input", "fps": 30, "stills": [], "clips": []}

func _initialize() -> void:
	Engine.max_fps = 30
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="): output = arg.trim_prefix("--out-dir=")
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Shadow pilot capture: " + message)

func _press(button: Button) -> void:
	_check(not button.disabled, "enabled control: " + button.text)
	if not button.disabled: button.pressed.emit()

func _select(action: String, cell: Array = []) -> void:
	_press(game.action_buttons[action])
	if cell.is_empty(): return
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.board.cell_center(cell)
	game.board.gui_input.emit(event)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
		await RenderingServer.frame_post_draw
		if not clip.is_empty():
			var path := output.path_join(clip).path_join("frame-%04d.png" % frame_index)
			_check(view.get_texture().get_image().save_png(path) == OK, "save motion frame")
			frame_index += 1

func _settle() -> void:
	var limit := 240
	while game.resolving and limit > 0:
		await _frames(1)
		limit -= 1
	_check(not game.resolving, "finite scene feedback completed")
	await _frames(2)

func _commit() -> void:
	var expected: Dictionary = game.prediction.duplicate(true)
	_press(game.confirm_button)
	await _settle()
	_check(game.model.snapshot() == expected, "captured feedback equals assessed model outcome")

func _still(name: String) -> void:
	await _frames(2)
	var image := view.get_texture().get_image()
	_check(image.get_size() == view.size, "actual still dimensions")
	_check(image.save_png(output.path_join(name)) == OK, "save " + name)
	manifest.stills.append({"file": name, "viewport": [view.size.x, view.size.y], "fixture_origin": fixture_origin,
		"presentation": game.presentation_mode, "fixture": game.fixture.duplicate(true), "state": game.model.snapshot(), "shadow_frame": game.shadow.frame(),
		"effect_footprints": game.board.effect_footprints(), "legacy_pulse_active": not game.board.last_events.is_empty()})

func _fixture(data: Dictionary) -> void:
	fixture_origin = "controlled UI fixture"
	game.fixture = data.duplicate(true)
	game._start_encounter()
	await _frames(2)

func _paper(enabled: bool) -> void:
	if game.paper_switch.button_pressed != enabled: game.paper_switch.set_pressed(enabled)
	await _frames(2)

func _begin_clip(name: String) -> void:
	clip = name
	frame_index = 0
	DirAccess.make_dir_recursive_absolute(output.path_join(clip))

func _end_clip() -> void:
	manifest.clips.append({"frames_directory": clip, "frame_count": frame_index, "viewport": [view.size.x, view.size.y],
		"fixture_origin": fixture_origin, "fixture": game.fixture.duplicate(true), "final_state": game.model.snapshot()})
	clip = ""

func _paused(name: String, advance: float) -> void:
	# Sample normal scene time: controller, feedback budget and bound board tween
	# all advance together. Freeze the whole scene only for image readback.
	var elapsed := 0.0
	while elapsed < advance:
		await _frames(1)
		elapsed += game.get_process_delta_time()
	var previous_process_mode := game.process_mode
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await _still(name)
	game.process_mode = previous_process_mode

func _normal_motion() -> void:
	await _fixture(F.shadow_single())
	_begin_clip("normal-frames")
	await _frames(12)
	_select("capture", [2, 3])
	await _frames(12)
	await _commit()
	await _frames(18)
	_select("end_turn")
	await _frames(8)
	await _commit()
	await _frames(18)
	_select("release", [2, 3])
	await _frames(10)
	await _commit()
	await _frames(16)
	_end_clip()

func _backlash_motion() -> void:
	await _fixture(F.shadow_replacement("out_of_reach"))
	_begin_clip("backlash-frames")
	await _frames(10)
	_select("capture", [1, 4])
	await _frames(8)
	await _commit()
	_select("end_turn")
	await _commit()
	await _frames(18)
	_select("capture", [2, 3])
	await _frames(15)
	await _commit()
	await _frames(18)
	_end_clip()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	view = SubViewport.new()
	view.size = Vector2i(1280, 800)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.gui_embed_subwindows = true
	root.add_child(view)
	game = load("res://scenes/encounter.tscn").instantiate()
	view.add_child(game)
	await _frames(3)
	for size in [Vector2i(1280, 800), Vector2i(1024, 720)]:
		view.size = size
		await _paper(false)
		await _still("production-plain-%d.png" % size.x)
		await _paper(true)
		await _still("production-paper-%d.png" % size.x)
	view.size = Vector2i(1280, 800)
	await _normal_motion()
	await _backlash_motion()
	await _fixture(F.shadow_single())
	_select("capture", [2, 3])
	_press(game.confirm_button)
	await _paused("controlled-capture-transfer.png", 0.28)
	await _settle()
	await _still("controlled-held.png")
	_select("end_turn")
	await _commit()
	await _still("controlled-held-and-reannounced.png")
	_select("release", [2, 3])
	await _still("controlled-release-preview.png")
	_press(game.confirm_button)
	await _paused("controlled-release-action.png", 0.25)
	await _settle()
	await _fixture(F.shadow_replacement("out_of_reach"))
	_select("capture", [1, 4])
	await _commit()
	_select("capture", [2, 3])
	await _still("controlled-failed-replacement-preview.png")
	_press(game.confirm_button)
	await _paused("controlled-backlash-action.png", 0.25)
	await _settle()
	await _still("controlled-failed-replacement-result.png")
	await _fixture(F.shadow_replacement("lethal"))
	_select("capture", [1, 4])
	await _commit()
	view.size = Vector2i(1024, 720)
	_select("capture", [2, 3])
	await _still("controlled-lethal-preview-1024.png")
	_press(game.confirm_button)
	await _paused("controlled-lethal-discharge-1024.png", 0.25)
	await _settle()
	view.size = Vector2i(1280, 800)
	await _fixture(F.encounter([
		F.enemy("a", [3, 1], F.ability("shove", 1, 3, 0, true), 8, [0, 1]),
		F.enemy("b", [3, 5], F.ability("shove", 1, 3, 0, true), 8, [0, -1]),
		F.enemy("c", [2, 3], F.ability("shove", 1, 3, 0, true), 8, [0, -1]),
	]))
	_select("capture", [2, 3])
	await _commit()
	_select("end_turn")
	await _commit()
	await _still("controlled-overlap-held-and-reannounced.png")
	view.size = Vector2i(1024, 720)
	await _still("controlled-overlap-1024.png")
	await _fixture(F.shadow_single())
	_select("capture", [2, 3])
	_press(game.confirm_button)
	_press(game.restart_button)
	game.restart_dialog.confirmed.emit()
	game.restart_dialog.hide()
	await _settle()
	await _still("controlled-restart-recovery-1024.png")
	manifest["failures"] = failures
	manifest["godot"] = Engine.get_version_info().string
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(manifest, "\t"))
	else: _check(false, "write evidence manifest")
	print("Shadow pilot capture: %d stills, %d motion sequences, %d failures. SubViewports and injected controls only." % [manifest.stills.size(), manifest.clips.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
