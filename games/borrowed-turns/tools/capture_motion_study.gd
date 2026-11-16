extends SceneTree
## Disposable opt-in study. Normal game scripts, art and defaults are untouched.

const StudyProjection = preload("res://studies/capture_motion/projection.gd")
const Rig = preload("res://studies/capture_motion/rig.gd")
const SOURCE := "a"
const PACK := {
	"a_body": {"file": "a-body.png", "size": Vector2i(290, 145), "sha256": "183a86540b7611c47b8a8de3ba6da791e3c78e6025a9b38109c474defa1c0e3e"},
	"a_hands": {"file": "a-hands.png", "size": Vector2i(290, 145), "sha256": "3396932a1a8ae490b217100c79ce55a1490bde376c7896a62b6450f9f85b564f"},
	"p_lantern": {"file": "p-lantern.png", "size": Vector2i(145, 145), "sha256": "0675257136cff1f7375b8b621dffb64f4296940e29fe3b9ddf9c4e6a4cf0f588"},
}
const CODE := ["res://tools/capture_motion_study.gd", "res://studies/capture_motion/projection.gd",
	"res://studies/capture_motion/rig.gd", "res://ui/encounter_ui.gd", "res://ui/board.gd",
	"res://ui/shadow_presentation.gd", "res://ui/shadow_renderer.gd", "res://model/encounter.gd",
	"res://ui/stage_renderer.gd", "res://ui/stage_projection.gd", "res://ui/paper_cells.gd",
	"res://ui/stage_floor.gdshader", "res://assets/stage/backdrop-paper.png",
	"res://assets/stage/floor-paper.png", "res://assets/stage/foreground-paper.png"]

class FigureOnly:
	extends RefCounted
	var original: RefCounted
	func draw_figure(canvas: Control, at: Vector2, cell_size: float, player: bool) -> void:
		original.draw_figure(canvas, at, cell_size, player)
	func draw_shadows(_canvas: Control, _state: Dictionary, _frame: Dictionary, _center: Callable, _size: float, _source: String) -> void:
		pass # Only the expressive pass moves to the backdrop; factual board marks remain.

class StudyDriver:
	extends Node
	var update: Callable
	func _process(_delta: float) -> void:
		update.call()

var game: Control
var view: SubViewport
var rig: Node2D
var study_adapter: RefCounted
var projector = StudyProjection.new()
var assets_directory := ""
var record_directory := ""
var viewport_size := Vector2i(1280, 800)
var checks := 0
var failures := 0
var recording := false
var frame_count := 0
var record_finished := false
var last_description: Dictionary = {}
var code_before: Dictionary = {}
var manifest := {"study": "one-source capture motion", "manual_staging": true, "complete": false,
	"fps": 30, "frames": [], "commands": [], "input": "real scene controls; recorded mode uses injected GUI events, not OS input"}

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--study-assets="): assets_directory = argument.trim_prefix("--study-assets=")
		elif argument.begins_with("--record-dir="): record_directory = argument.trim_prefix("--record-dir=")
		elif argument.begins_with("--study-size="):
			var dimensions := argument.trim_prefix("--study-size=").split("x")
			if dimensions.size() != 2 or not dimensions[0].is_valid_int() or not dimensions[1].is_valid_int():
				printerr("Capture motion study: --study-size must be WIDTHxHEIGHT")
				quit(2)
				return
			viewport_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	if viewport_size.x < 1024 or viewport_size.y < 720:
		printerr("Capture motion study: minimum study size is 1024x720")
		quit(2)
		return
	call_deferred("_run")

func _check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures += 1
		push_error("Capture motion study: " + message)
	return value

func _assembly() -> Dictionary:
	return {"a_canvas": Vector2(290, 145), "p_canvas": Vector2(145, 145),
		"a_baseline": Vector2(105, 145), "a_hinge": Vector2(171, 96),
		"p_baseline": Vector2(56, 145), "p_handle": Vector2(105, 60),
		"held_hinge": Vector2(143, 74), "held_scale": 0.45,
		"a_position": Vector2(0.29, 0.45), "p_position": Vector2(0.54, 0.45), "height_fraction": 0.30}

func _fixture() -> Dictionary:
	return {"width": 7, "height": 7, "walls": [], "player": {"pos": [3, 3], "hp": 8},
		"exit": {"pos": [6, 6], "opens": 20}, "rules": {"actions": 2, "movement": 1, "capture_range": 1},
		"enemies": [{"id": SOURCE, "pos": [3, 2], "hp": 8, "kind": "shove", "dir": [0, 1],
			"ability": {"kind": "shove", "range": 3, "damage": 1, "radius": 0, "push": true}}]}

func _load_pack() -> Dictionary:
	print("Capture motion study: loading temporary cutout pack ", assets_directory)
	if not assets_directory.is_absolute_path() or not DirAccess.dir_exists_absolute(assets_directory):
		printerr("Capture motion study: supply --study-assets=<absolute local cutout directory>; no fallback art")
		return {}
	var textures := {}
	for key in PACK:
		var path := assets_directory.path_join(PACK[key].file)
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != PACK[key].sha256:
			printerr("Capture motion study: missing/mismatched approved temporary input: ", path)
			return {}
		var image := Image.new()
		var result := image.load(path)
		if result != OK or image.get_size() != PACK[key].size or image.detect_alpha() != Image.ALPHA_BLEND:
			printerr("Capture motion study: decode/dimensions/real-alpha check failed: ", path, " result=", result)
			return {}
		textures[key] = ImageTexture.create_from_image(image)
	print("Capture motion study: all three cutouts verified and loaded")
	return textures

func _code_hashes() -> Dictionary:
	var hashes := {}
	for path in CODE: hashes[path] = FileAccess.get_sha256(path)
	return hashes

func _present() -> void:
	var stage: bool = game.presentation_mode == "stage"
	game.board.shadow_renderer = study_adapter if stage else study_adapter.original
	rig.visible = stage
	if not stage:
		rig.present({}, Rect2())
		return
	last_description = projector.compose(game.state, game.shadow.frame(), game.generation, SOURCE)
	rig.present(last_description, game.board._stage_rect())

func _frames(count: int) -> void:
	for _index in range(count):
		if failures > 0: return
		await process_frame
		await RenderingServer.frame_post_draw
		if not recording: continue
		if not _check(absf(game.get_process_delta_time() - 1.0 / 30.0) < 0.00001, "whole-scene delta matches recorded 30 fps"): return
		var image := view.get_texture().get_image()
		if not _check(not image.is_empty() and image.get_size() == viewport_size, "actual framebuffer dimensions"): return
		var path := record_directory.path_join("frames/frame-%05d.png" % frame_count)
		if not _check(image.save_png(path) == OK, "save actual frame " + str(frame_count)): return
		manifest.frames.append({"file": "frames/frame-%05d.png" % frame_count, "generation": game.generation,
			"state": game.model.snapshot(), "controller": game.shadow.frame(),
			"scene_delta": game.get_process_delta_time(),
			"description": last_description.duplicate(true), "hands": rig.hand_instances(),
			"footprints": game.board.effect_footprints()})
		frame_count += 1

func _commit(action: String, target: Array = []) -> void:
	var before: Dictionary = game.model.snapshot()
	if not _check(not game.action_buttons[action].disabled, "enabled real operation " + action): return
	game.action_buttons[action].pressed.emit()
	if not target.is_empty():
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = game.board.cell_center(target)
		game.board.gui_input.emit(event)
	if not _check(not game.confirm_button.disabled and not game.prediction.is_empty(), "legal real confirmation"): return
	var prediction: Dictionary = game.prediction.duplicate(true)
	var command: Dictionary = game.command.duplicate(true)
	if not _check(game.model.snapshot() == before, "selection/assessment leaves model unchanged"): return
	game.confirm_button.pressed.emit()
	if not _check(game.model.snapshot() == prediction and game.state == prediction, "commit exactly equals assessment"): return
	manifest.commands.append({"command": command, "before": before, "prediction": prediction, "after": game.model.snapshot()})
	var remaining := 240
	while game.resolving and remaining > 0 and failures == 0:
		await _frames(1)
		remaining -= 1
	_check(not game.resolving, "shared finite feedback completes within bound")
	await _frames(2)

func _json_value(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x, value.y]
	if value is Transform2D: return [[value.x.x, value.x.y], [value.y.x, value.y.y], [value.origin.x, value.origin.y]]
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = _json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_json_value(item))
		return result
	return value

func _record() -> void:
	print("Capture motion study: recording actual rehearsal/capture/held/reannouncement")
	recording = true
	await _frames(60)
	await _commit("capture", [3, 2])
	_check(game.state.stored.get("source", "") == SOURCE, "actual capture acquired A")
	await _frames(75)
	await _commit("end_turn")
	await _frames(75)
	recording = false
	var hands: Array = rig.hand_instances()
	var roles: Array = []
	for hand in hands:
		if hand.visible: roles.append(hand.role)
	_check(hands.size() == 2 and "rehearsal" in roles and "held" in roles, "final fresh source and old held coexist")
	var observed: Array = []
	for frame in manifest.frames:
		for hand in frame.hands:
			if hand.visible and hand.role not in observed: observed.append(hand.role)
	_check("rehearsal" in observed and "transfer" in observed and "held" in observed, "record contains every actual hand role")
	_check(frame_count > 0 and FileAccess.file_exists(record_directory.path_join("frames/frame-%05d.png" % (frame_count - 1))),
		"terminal numbered frame exists")
	_check(view.get_texture().get_image().save_png(record_directory.path_join("final.png")) == OK, "saved terminal still")
	_check(_code_hashes() == code_before, "source/code/art hashes unchanged during recording")
	for key in PACK:
		_check(FileAccess.get_sha256(assets_directory.path_join(PACK[key].file)) == PACK[key].sha256, "temporary cutout unchanged: " + key)
	manifest["complete"] = failures == 0
	manifest["frame_count"] = frame_count
	manifest["checks"] = checks
	manifest["failures"] = failures
	manifest["final_state"] = game.model.snapshot()
	print("Capture motion study: writing record manifest")
	var file := FileAccess.open(record_directory.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		_check(false, "write manifest")
	else:
		file.store_string(JSON.stringify(_json_value(manifest), "\t"))
		file.close()
	print("Capture motion study: complete=%s frames=%d checks=%d failures=%d; actual scene, manual casting, no visual acceptance" %
		[str(failures == 0).to_lower(), frame_count, checks, failures])
	record_finished = true

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Capture motion study: use a graphical renderer for replay/recording, not the headless dummy renderer")
		quit(2)
		return
	if not record_directory.is_empty():
		# Godot consumes engine flags. Check their actual clock effect, not user args.
		await process_frame
		await process_frame
		if absf(root.get_process_delta_time() - 1.0 / 30.0) > 0.000001:
			printerr("Capture motion study: recording requires Godot --fixed-fps 30 before --; scene delta must be exactly 1/30")
			quit(2)
			return
	var textures := _load_pack()
	if textures.is_empty():
		quit(2)
		return
	if not record_directory.is_empty():
		print("Capture motion study: preparing fresh recording directory ", record_directory)
		if not record_directory.is_absolute_path() or DirAccess.dir_exists_absolute(record_directory) or FileAccess.file_exists(record_directory):
			printerr("Capture motion study: --record-dir must be a fresh absolute path")
			quit(2)
			return
		if DirAccess.make_dir_recursive_absolute(record_directory.path_join("frames")) != OK:
			printerr("Capture motion study: cannot create recording directory")
			quit(2)
			return
		Engine.max_fps = 30
		create_timer(45.0, true, false, true).timeout.connect(func():
			if not record_finished:
				printerr("Capture motion study: recording did not complete within 45 seconds")
				quit(1)
		)
		view = SubViewport.new()
		view.size = viewport_size
		view.gui_embed_subwindows = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
	else: root.size = viewport_size
	game = load("res://scenes/encounter.tscn").instantiate()
	if view: view.add_child(game)
	else: root.add_child(game)
	await _frames(2)
	game.set_presentation_mode("stage")
	game.fixture = _fixture()
	game._start_encounter()
	await _frames(2)
	study_adapter = FigureOnly.new()
	study_adapter.original = game.board.shadow_renderer
	game.board.shadow_renderer = study_adapter
	rig = Rig.new()
	if not rig.configure_assets(textures, _assembly()):
		printerr("Capture motion study: rig rejected verified inputs")
		rig.free()
		quit(2)
		return
	rig.show_behind_parent = true
	game.board.add_child(rig)
	game.board.move_child(rig, game.board.get_node("StageFloor").get_index())
	var driver := StudyDriver.new()
	driver.update = _present
	driver.process_priority = 10 # After the existing UI/controller's normal processing.
	game.board.add_child(driver)
	game.restart_button.tooltip_text = "Restart this controlled exchange; Capture A, then End turn to see its next announcement."
	_present()
	code_before = _code_hashes()
	manifest["code_hashes"] = code_before.duplicate()
	manifest["assets"] = PACK.duplicate(true)
	manifest["assembly"] = _assembly()
	manifest["fixture"] = _fixture()
	manifest["viewport"] = viewport_size
	manifest["godot"] = Engine.get_version_info().string
	if record_directory.is_empty():
		print("Capture motion study: ready; Capture A at (3,2), Confirm, then End turn/Confirm. Restart replays. Normal game unchanged.")
		return
	await _record()
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
