extends "res://ui/smoke.gd"
## Replaces the retired appearance-picker matrix with the angled wavefront slice.
## Controlled assertions first; optional evidence uses actual encounter content.

const SliceFixture = preload("res://content/two_pursuers.gd")
const MotionOverlay = preload("res://ui/wavefront_overlay.gd")

func _comparison_setup() -> bool:
	if not _two_pursuers_setup(): return false
	if not game.board.has_method("announcement_regions"):
		printerr("SETUP REQUIRED: board.announcement_regions(); not behavioral RED")
		return false
	if not game.board.has_method("announcement_waves"):
		printerr("SETUP REQUIRED: board.announcement_waves(); not behavioral RED")
		return false
	return true

func _gameplay_facts() -> Dictionary:
	return {"model": game.model.snapshot(), "state": game.state.duplicate(true),
		"mode": game.mode, "selected": game.selected.duplicate(), "source": game.source,
		"command": game.command.duplicate(true), "prediction": game.prediction.duplicate(true),
		"candidates": game.candidates.duplicate(true), "history": game.history_lines.duplicate(),
		"confirmed": game.confirm_button.disabled, "summary": game.consequence.text}

func _polygon_near(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size(): return false
	for i in range(a.size()):
		if a[i].distance_to(b[i]) > 0.002: return false
	return true

func _check_default_slice() -> void:
	var origin: Vector2 = game.board.cell_center([1, 1])
	var across: Vector2 = game.board.cell_center([2, 1]) - origin
	var down: Vector2 = game.board.cell_center([1, 2]) - origin
	check(across.x > 0 and across.y > 0 and down.x < 0 and down.y > 0,
		"normal two-pursuer Stage entry has angled rows/staggered columns without selecting a look")
	var old_controls := game.find_child("BoardAppearance", true, false)
	check(old_controls == null or not old_controls.visible,
		"retired ribbon/stamp controls are not offered in the new slice")
	check(is_zero_approx(game.board.rotation), "ground yaw does not rotate the whole board Control or upright drawing")
	_check_warning_sources()
	_check_roster()

func _check_roster() -> void:
	var rows: Array = game.board.standee_layout()
	var expected := {"player": game.state.player.hp}
	for enemy in game.state.enemies: expected[enemy.id] = enemy.hp
	check(rows.size() == expected.size(), "always-visible roster has one current row per living identity")
	var names: Array = []
	var seen: Array[Rect2] = []
	var frame: Rect2 = game.board._stage_rect()
	var floor_seam := frame.position.y
	if game.board.stage_renderer:
		floor_seam += frame.size.y * game.board.stage_renderer._floor_top
	var controls: Array = [game.objective, game.phase, game.budgets, game.stored,
		game.instruction, game.consequence, game.confirm_button, game.cancel_button, game.restart_button]
	controls.append_array(game.action_buttons.values())
	for row in rows:
		check(row.get("name") is String and not str(row.get("name", "")).strip_edges().is_empty(),
			row.actor + ": real roster draw data carries the actor name")
		check(row.get("hp", -1) == expected.get(row.actor, -2), row.actor + ": real roster shows current model HP, not a stale or predicted value")
		if row.get("name", "") not in names: names.append(row.get("name", ""))
		var roster = row.get("roster_rect")
		check(roster is Rect2 and roster.has_area(), row.actor + ": actual roster has a visible/selectable rectangle")
		if not roster is Rect2 or not roster.has_area(): continue
		check(frame.encloses(roster) and game.board.get_rect().size.x >= roster.end.x,
			"roster stays inside the Stage allocation without resizing the playing plane")
		check(not roster.intersects(game.board._board_rect()), "roster is outside all grid bounds")
		check(roster.position.y >= floor_seam, "roster stays below the actual Director/floor seam")
		var global_roster := Rect2(roster.position + game.board.global_position, roster.size)
		check(game.get_viewport_rect().encloses(global_roster), "roster is always visible inside the actual viewport")
		for control in controls:
			if control.is_visible_in_tree():
				check(not global_roster.intersects(control.get_global_rect()), "roster never covers visible status or action controls")
		for other in seen: check(not roster.intersects(other), "roster identities have nonoverlapping selectable rows")
		seen.append(roster)
		check(game.board.actor_at(roster.get_center()) == row.actor, "actual roster target maps to the displayed source identity")
		check(game.board._from_pixel(roster.get_center()).is_empty(), "roster selection is not a disguised floor cell")
	check(names.size() == rows.size(), "roster names distinguish each living identity")

func _roster_click(id: String) -> bool:
	var row := _standee_entry(id)
	var roster = row.get("roster_rect")
	var usable: bool = roster is Rect2 and roster.has_area()
	check(usable, id + ": real roster hit target exists")
	if not usable: return false
	await _stage_gui_click(roster.get_center())
	return true

func _inspect_roster() -> void:
	game._cancel()
	var before: Dictionary = game.model.snapshot()
	var history_before: Array = game.history_lines.duplicate()
	var generation_before: int = game.generation
	var geometry := {}
	var rows: Array = game.board.standee_layout()
	for row in rows: geometry[row.actor] = [row.rect, row.foot, row.texture, row.roster_rect]
	for row in rows:
		if not (await _roster_click(row.actor)): continue
		check(game.selected == row.cell and game.source == ("" if row.actor == "player" else row.actor),
			"roster inspection reaches that actor's true cell/source")
		check(game.command.is_empty() and game.prediction.is_empty() and game.model.snapshot() == before
			and game.history_lines == history_before and game.generation == generation_before,
			"roster inspection never commits a command, resets performance or changes history")
		check(game.inspection.text.contains("%d HP" % row.hp), "ordinary inspection reports the same current HP as the roster")
		for current in game.board.standee_layout():
			check([current.rect, current.foot, current.texture, current.roster_rect] == geometry[current.actor],
				"using the roster does not resize/move accepted actors or shuffle roster rows")

func _check_plane_join() -> void:
	var projection = game.board._ensure_projection()
	var inverse: PackedFloat64Array = projection.inverse_coefficients()
	check(inverse.size() == 9, "actual ground projection exports a usable shader inverse")
	if inverse.size() != 9: return
	var renderer = game.board.stage_renderer
	check(renderer != null and renderer.floor_root != null, "actual Stage floor is attached")
	if renderer == null or renderer.floor_root == null: return
	check(is_zero_approx(renderer.floor_root.rotation) and is_zero_approx(renderer.backdrop.rotation)
		and is_zero_approx(renderer.foreground.rotation), "stage images/floor root are not rotated as a screenshot substitute")
	var pieces := 0
	for paper in renderer.floor_root.get_children():
		if not paper is Polygon2D: continue
		var material: ShaderMaterial = paper.material
		check(material != null, "floor polygons retain actual paper materials")
		if material == null: continue
		check(material.get_shader_parameter("inverse_x") == Vector3(inverse[0], inverse[1], inverse[2])
			and material.get_shader_parameter("inverse_y") == Vector3(inverse[3], inverse[4], inverse[5])
			and material.get_shader_parameter("inverse_w") == Vector3(inverse[6], inverse[7], inverse[8]),
			"rendered floor/apron shader consumes exactly the board inverse, not a second yaw")
		check(material.get_shader_parameter("board_size") == Vector2(game.state.width, game.state.height),
			"floor material keeps actual logical dimensions")
		if material.get_shader_parameter("apron"): continue
		pieces += 1
		var origin = material.get_shader_parameter("cell_origin")
		check(origin is Vector2, "paper cell exposes its actual logical origin")
		if origin is Vector2:
			check(_polygon_near(paper.polygon, game.board.cell_polygon([int(origin.x), int(origin.y)])),
				"floor cell polygon and board drawing use the same yawed projection")
	check(pieces == game.state.width * game.state.height, "shared plane draws every real cell exactly once")

func _check_warning_sources() -> void:
	var expected := {}
	for intent in game.state.intentions:
		if intent.source in ["A", "B"] and intent.kind == "shove": expected[intent.source] = intent.cells
	var observed := {}
	var regions: Array = game.board.announcement_regions()
	for row in regions:
		observed[row.get("source", "")] = row.get("cells", [])
		var contours: Array = row.get("contours", [])
		check(row.get("cells", []).is_empty() or not contours.is_empty(),
			"nonempty actual announcement has a broad logical region by default")
	check(observed == expected and regions.size() == expected.size(),
		"one exact current region per source; overlap/capture cannot merge or leave stale announcements")
	_check_wave_join()

func _check_wave_join() -> void:
	var rows: Array = game.board.announcement_waves()
	var regions: Array = game.board.announcement_regions()
	check(rows.size() == regions.size(), "real scene renders one moving-wave row per actual source occurrence")
	var frame: Dictionary = game.shadow.frame()
	var phase := fposmod(float(frame.get("loop_cycles", 0.0)) / 1.5, 1.0)
	for region in regions:
		var found := false
		for row in rows:
			if row.source != region.source: continue
			found = true
			var metadata: Dictionary = row.duplicate(true)
			metadata.erase("fills")
			metadata.erase("fronts")
			check(metadata == region, "actual wave row keeps source/origin/direction/turn/cells and logical contours")
			var geometry: Dictionary = MotionOverlay.wave_geometry(region, phase)
			check(row.get("fills", []) == region.contours and row.get("fills", []) == geometry.fills,
				"real floor wash covers each whole model-affected tile, without inset or invented source coverage")
			check(not row.get("fronts", []).is_empty() and row.get("fronts", []) == geometry.fronts,
				"real moving curves consume the slower phase derived from the shared rehearsal cycle count")
		check(found, region.source + ": real moving-wave row exists")

func _test_rehearsal_motion() -> void:
	await load_fixture(_controlled_fixture())
	var before := _gameplay_facts()
	var phase_before: float = game.shadow.frame().loop_phase
	var waves_before: Array = game.board.announcement_waves()
	# Let the normal scene process actual elapsed delta. No fabricated controller
	# ticks or fixed-frame recording timing; combat still awaits confirmation.
	await create_timer(0.16).timeout
	var phase_after: float = game.shadow.frame().loop_phase
	check(not is_equal_approx(phase_before, phase_after), "normal scene processing advances the existing rehearsal loop")
	check(_gameplay_facts() == before, "wave rehearsal never spends budgets, hurts actors, changes turns or alters selection")
	check(game.board.announcement_waves() != waves_before, "normal idle scene visibly changes the actual moving-front geometry")
	_check_warning_sources()
	for captured in ["A", "B"]:
		await load_fixture(_controlled_fixture())
		await _prepare_capture(captured)
		_check_warning_sources() # A preview must not stop its current waves.
		await commit()
		_check_warning_sources()
		var sources: Array = []
		for row in game.board.announcement_waves(): sources.append(row.source)
		check(sources == ["B" if captured == "A" else "A"],
			"confirmed capture stops only its current warning/waves, not the surviving source")
		var held_state := _gameplay_facts()
		var held_waves: Array = game.board.announcement_waves()
		await create_timer(0.16).timeout
		check(game.board.announcement_waves() != held_waves and _gameplay_facts() == held_state,
			"surviving source keeps rehearsing after either capture without advancing combat")

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

func _floor_click(cell: Array) -> void:
	var point: Vector2 = game.board.get_global_transform() * game.board.cell_center(cell)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.alt_pressed = true
		event.position = point
		game.get_viewport().push_input(event)
		await process_frame

func _prepare_capture(id: String) -> void:
	press(game.action_buttons.capture)
	var body := _standee_body_point(id)
	check(body.is_finite(), id + ": accepted actual body remains reachable on the angled board")
	if body.is_finite(): await _stage_gui_click(body)
	check(game.command == {"type": "capture", "source": id}, id + ": body click selects its true source")
	var row := _standee_entry(id)
	check(row.get("tab_rect") is Rect2, id + ": source foot tab remains available")
	if row.get("tab_rect") is Rect2: await _stage_gui_click(row.tab_rect.get_center())
	check(game.command == {"type": "capture", "source": id} and not game.confirm_button.disabled,
		id + ": projected foot tab prepares the same legal capture")
	if await _roster_click(id):
		check(game.command == {"type": "capture", "source": id} and not game.confirm_button.disabled,
			id + ": off-grid roster prepares the same capture as body and foot marker")

func _test_controlled_slice() -> void:
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		for captured in ["A", "B"]:
			await load_fixture(_controlled_fixture())
			_check_default_slice()
			_check_plane_join()
			var initial: Dictionary = game.state.duplicate(true)
			await _inspect_roster()
			for cell in [[0, 0], [4, 0], [4, 4], [0, 4]]:
				await _floor_click(cell)
				check(game.selected == cell and game.model.snapshot() == initial,
					"actual Alt-floor input reaches each rotated corner without advancing state")
			await _prepare_capture(captured)
			check(game.model.snapshot() == initial and preview_matches(), "capture selection is a nonmutating exact assessment")
			_check_warning_sources() # Preview must not prematurely remove either current threat.
			var before := _gameplay_facts()
			var sample: Dictionary = game.board.piece_appearance([1, 1])
			await _stage_resize(Vector2i(1600, 900) if extent.x == 1024 else Vector2i(1024, 720))
			check(_gameplay_facts() == before and game.board.piece_appearance([1, 1]) == sample,
				"resize with a prepared capture preserves command, prediction, storage, history and paper identity")
			_check_plane_join()
			_check_warning_sources()
			await _stage_resize(extent)
			await commit()
			check(game.state.stored.get("source", "") == captured and game.state.enemies.size() == 2,
				"actual capture owns the selected occurrence and leaves both standees alive")
			_check_warning_sources()
			_check_roster()
			press(game.action_buttons.release)
			await _floor_click([1, 2])
			check(game.command == {"type": "release", "target": [1, 2]} and not game.confirm_button.disabled,
				"Alt-floor release selects the exact yawed cell, not a body/head in front of it")
			check(not game.state.backlash_footprint.is_empty() and not game.board.effect_footprints().is_empty(),
				"held backlash and exact command effects stay available alongside the remaining enemy region")
			_check_warning_sources()
			_check_roster()
			before = _gameplay_facts()
			for view in ["plain", "paper", "stage"]:
				game.set_presentation_mode(view)
				await process_frame
				check(_gameplay_facts() == before, view + ": view changes preserve actual selected state/command/history")
				if view == "stage":
					_check_default_slice()
					_check_plane_join()
				else:
					check(game.board.announcement_regions().is_empty(), view + ": no invisible new Stage overlay remains")
					check(game.board.standee_layout().is_empty(), view + ": no invisible Stage roster remains")
			await commit()
			check(game.state.stored.is_empty(), "ordinary real release continues play beyond capture")
			_check_warning_sources()
			_check_roster()
			game._apply_restart()
			await process_frame
			check(game.state == initial and not game.resolving, "Restart restores the selected fixture, not an old visual generation")
			_check_default_slice()

func _test_roster_hp_sync() -> void:
	# Controlled damage and removal, not live encounter HP/tuning constants.
	await load_fixture(_controlled_fixture())
	press(game.action_buttons.capture)
	if not (await _roster_click("A")): return
	check(game.command == {"type": "capture", "source": "A"}, "roster can acquire a real current source")
	await commit()
	var before_hp: int = _standee_entry("B").hp
	press(game.action_buttons.release)
	await _floor_click([2, 3])
	check(not game.confirm_button.disabled, "controlled roster HP check prepares a real damaging release")
	var predicted_hp := -1
	for enemy in game.prediction.get("enemies", []):
		if enemy.id == "B": predicted_hp = enemy.hp
	check(predicted_hp >= 0 and predicted_hp < before_hp, "controlled release preview really damages the surviving pursuer")
	check(_standee_entry("B").hp == before_hp, "roster HP does not jump to the selected prediction before confirmation")
	_check_roster()
	await commit()
	check(_standee_entry("B").hp == predicted_hp, "confirmed damage refreshes the displayed pursuer HP")
	_check_roster()
	var player_before: int = game.state.player.hp
	select("end_turn")
	check(game.prediction.get("player", {}).get("hp", player_before) < player_before, "controlled surviving announcement really threatens player HP")
	check(_standee_entry("player").hp == player_before, "player roster HP remains current during End turn preview")
	await commit()
	check(_standee_entry("player").hp == game.state.player.hp and game.state.player.hp < player_before,
		"actual enemy damage refreshes player roster HP")
	_check_roster()
	var fragile := _controlled_fixture()
	fragile.enemies[1].hp = 1
	await load_fixture(fragile)
	var old_b := _standee_entry("B")
	press(game.action_buttons.capture)
	if not (await _roster_click("A")): return
	await commit()
	press(game.action_buttons.release)
	await _floor_click([2, 3])
	await commit()
	check(_standee_entry("B").is_empty(), "confirmed source death removes its roster and marker descriptors")
	if old_b.get("roster_rect") is Rect2 and old_b.roster_rect.has_area():
		check(game.board.actor_at(old_b.roster_rect.get_center()) != "B", "removed roster row cannot retain a stale actor hit")
	_check_roster()
	game._apply_restart()
	await process_frame
	_check_roster()
	check(not _standee_entry("B").is_empty(), "Restart restores the selected fixture's living roster")

func _capture_state(label: String) -> void:
	game._stage_sheet.hide()
	game.board.cursor = game.state.player.pos.duplicate()
	game.board.focus_actor("")
	game.board._hover_actor = ""
	game.board.hover_cell = []
	var processing: int = game.process_mode
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var before := _gameplay_facts()
	var frame: Dictionary = game.shadow.frame()
	await image("%d-wavefront-%s.png" % [capture_view.size.x, label])
	check(_gameplay_facts() == before and game.shadow.frame() == frame,
		"readback freezes only normal scene processing, never fabricates outcomes or Director imagery")
	game.process_mode = processing

func _capture_actual_encounter() -> void:
	game.fixture = SliceFixture.DATA.duplicate(true)
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		for state_name in ["initial", "A-held", "B-held"]:
			game._apply_restart()
			await process_frame
			if state_name != "initial":
				var id: String = state_name.left(1)
				await _prepare_capture(id)
				await commit()
				check(game.state.stored.get("source", "") == id, "actual matched held state owns " + id)
			_check_default_slice()
			await _capture_state(state_name)
			if state_name == "A-held":
				press(game.action_buttons.release)
				var target: Array = []
				for candidate in game.candidates:
					if candidate != game.state.player.pos:
						target = candidate
						break
				check(not target.is_empty(), "actual held action offers a legal preview")
				if not target.is_empty():
					await _floor_click(target)
					check(game.command == {"type": "release", "target": target}, "captured preview is the actual chosen floor command")
					await _capture_state("release-preview")

func _comparison_pack_ready() -> bool:
	var directory := "res://assets/puppets/two-pursuers"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--puppet-pack="): directory = arg.trim_prefix("--puppet-pack=")
	var assets = load("res://ui/two_pursuer_assets.gd")
	var pack: Dictionary = assets.puppets(directory)
	if pack.has("error"):
		printerr("SETUP REQUIRED: " + str(pack.error))
		return false
	return true

func _run() -> void:
	if not capture_dir.is_empty():
		var local_root := ProjectSettings.globalize_path("res://../../.lore/local").simplify_path() + "/"
		if not (capture_dir.simplify_path() + "/").begins_with(local_root):
			printerr("SETUP REQUIRED: use an absolute --capture-dir under repository .lore/local; evidence must survive reboot.")
			quit(2)
			return
	if not _comparison_pack_ready():
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
		var origin: Vector2 = game.board.cell_center([1, 1])
		check(is_equal_approx(game.board.cell_center([2, 1]).y, origin.y),
			"original escape Stage retains its unyawed baseline")
		await _choose_encounter_ui("two-pursuers")
		check(game.encounter_dialog.visible, "existing chooser requests the real two-pursuer encounter")
		if game.encounter_dialog.visible:
			game.encounter_dialog.confirmed.emit()
			game.encounter_dialog.hide()
		await process_frame
	check(game.encounter_id == "two-pursuers", "normal entry starts the new slice without an appearance choice")
	if game.encounter_id == "two-pursuers": await _test_controlled_slice()
	if game.encounter_id == "two-pursuers": await _test_roster_hp_sync()
	if game.encounter_id == "two-pursuers": await _test_rehearsal_motion()
	if failures == 0 and not capture_dir.is_empty(): await _capture_actual_encounter()
	print("Angled wavefront UI: %d checks, %d failures. Injected controls; no visual acceptance." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
