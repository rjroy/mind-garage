extends "res://ui/smoke.gd"
## Actual Stage joins: projection, roster, warnings and borrowed attack geometry.

const MotionOverlay = preload("res://ui/wavefront_overlay.gd")
const GroundProjection = preload("res://ui/stage_projection.gd")

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
		"one exact current region per source; arming/holding cannot merge or cancel announcements")
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

func _controlled_fixture() -> Dictionary:
	return F.two_pursuers()

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

func same_cells(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for cell in expected:
		if cell not in actual: return false
	return true

func describes_wide(text: String) -> bool:
	var words := text.to_lower()
	return words.contains("width 3") or words.contains("3-wide") or words.contains("three-wide")

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

func _test_rehearsal_motion() -> void:
	await load_fixture(_controlled_fixture())
	if not await _prepare_arm(): return
	var initial: Array = game.board.announcement_waves().duplicate(true)
	await commit()
	check(game.state.capture_armed and game.state.stored.is_empty(), "arming alone acquires no source")
	_check_warning_sources()
	var before := _gameplay_facts()
	var phase: float = game.shadow.frame().loop_phase
	var time_limit := Time.get_ticks_msec() + 2000
	while is_equal_approx(game.shadow.frame().loop_phase, phase) and Time.get_ticks_msec() < time_limit:
		await process_frame
	var moving: Array = game.board.announcement_waves()
	check(initial.size() == 2 and moving.size() == 2, "both sources remain dangerous and animated after arming")
	for i in range(mini(initial.size(), moving.size())):
		check(initial[i].source == moving[i].source and initial[i].cells == moving[i].cells
			and initial[i].fronts != moving[i].fronts, "both independent warnings move without canceling either attack")
	check(_gameplay_facts() == before, "rehearsal motion never spends AP, moves an actor or advances combat")

func _test_controlled_slice() -> void:
	for extent in [Vector2i(1024, 720), Vector2i(1600, 900)]:
		await _stage_resize(extent)
		await load_fixture(F.two_pursuers(true))
		_check_default_slice()
		_check_plane_join()
		await _inspect_roster()
		var initial: Dictionary = game.state.duplicate(true)
		for cell in [[0, 0], [4, 0], [4, 4], [0, 4]]:
			await _floor_click(cell)
			check(game.selected == cell and game.model.snapshot() == initial, "actual Alt-floor input reaches every rotated corner without advancing state")
		if not await _prepare_arm(): continue
		var before := _gameplay_facts()
		var piece: Dictionary = game.board.piece_appearance([1, 1])
		await _stage_resize(Vector2i(1600, 900) if extent.x == 1024 else Vector2i(1024, 720))
		check(_gameplay_facts() == before and game.board.piece_appearance([1, 1]) == piece,
			"resize preserves targetless arm command, exact prediction, budgets, history and paper identity")
		_check_plane_join()
		_check_warning_sources()
		await _stage_resize(extent)
		await commit()
		check(game.state.capture_armed and game.state.stored.is_empty() and game.state.intentions == initial.intentions,
			"confirmed arm leaves both overlapping attacks intact without source-click selection")
		_check_warning_sources()
		select("end_turn")
		await commit()
		check(game.state.stored.get("source", "") == "A" and game.state.player.hp < initial.player.hp
			and game.state.enemies.size() == 2, "full real attacks acquire the first source without canceling damage or removing either actor")
		_check_warning_sources()
		_check_roster()
		var held: Dictionary = game.state.stored.duplicate(true)
		if not await _prepare_shine([2, 0]): continue
		check(not game.board.effect_footprints().is_empty(), "real Shine preview displays exact effects under the actors")
		_check_warning_sources()
		_check_roster()
		await commit()
		check(game.state.stored == held, "nonlethal Shine keeps the same borrowed occurrence")
		_check_warning_sources()
		_check_roster()
		game._apply_restart()
		await process_frame
		check(game.state == initial and not game.resolving, "Restart restores this fixture, not an old visual generation")
		_check_default_slice()

func _roster_damage_fixture(fragile: bool = false) -> Dictionary:
	var data := F.armed_fight(false)
	data.enemies[1] = F.enemy("B", [5, 3], F.ability("shove", 1, 3), 1 if fragile else 9, [-1, 0])
	return data

func _test_roster_hp_sync() -> void:
	for fragile in [false, true]:
		await load_fixture(_roster_damage_fixture(fragile))
		_check_roster()
		await _inspect_roster()
		if not await _prepare_arm(): continue
		await commit()
		var hp: int = _standee_entry("player").hp
		select("end_turn")
		check(game.prediction.player.hp == hp - 2 and _standee_entry("player").hp == hp,
			"normal enemy hit preview never jumps the roster to predicted HP")
		await commit()
		check(_standee_entry("player").hp == game.state.player.hp and game.state.player.hp == hp - 2,
			"full real enemy damage refreshes player roster HP before borrowing")
		_check_roster()
		var old_b := _standee_entry("B")
		if not await _prepare_shine([5, 3]): continue
		var predicted_hp := 0
		for enemy in game.prediction.enemies:
			if enemy.id == "B": predicted_hp = enemy.hp
		check(predicted_hp < old_b.hp and _standee_entry("B").hp == old_b.hp,
			"actual damaging Shine previews B's HP without changing the confirmed roster")
		_check_roster()
		await commit()
		if fragile:
			check(_standee_entry("B").is_empty()
				and game.board.actor_at(old_b.roster_rect.get_center()) != "B", "actual death removes B's roster, foot marker and stale hit target")
		else:
			check(_standee_entry("B").hp == predicted_hp, "confirmed Shine synchronizes the displayed pursuer HP")
		_check_roster()
		game._apply_restart()
		await process_frame
		check(not _standee_entry("B").is_empty(), "Restart restores living roster identities")
		_check_roster()

func _test_wide_borrowed_geometry() -> void:
	var data := F.wide_capture()
	data.enemies[0].pos = [0, 2] # Inside Shine's left lane, outside its narrow center.
	await load_fixture(data)
	var incoming := [[2, 3], [3, 3], [4, 3], [2, 2], [3, 2], [4, 2]]
	var expected := [[0, 2], [1, 2], [2, 2], [0, 1], [1, 1], [2, 1]]
	var b_plan: Dictionary = {}
	for intent in game.state.intentions:
		if intent.source == "B": b_plan = intent
	check(same_cells(b_plan.get("cells", []), incoming) and game.state.player.pos == [2, 3],
		"actual wide B warning includes the side-only player cell and every forward lane")
	var named := false
	for row in game.intention_list.get_children():
		if row is Button and row.text.begins_with("B ·"): named = describes_wide(row.text)
	check(named, "actual B ability details disclose width three before acquisition")
	_check_default_slice()
	for cell in incoming:
		check(game.board._from_pixel(game.board.cell_center(cell)) == cell, "all wide side-lane cells share projection and picking inverse")
	if not await _prepare_arm(): return
	await commit()
	select("end_turn")
	await commit()
	check(game.state.player.pos == [1, 3] and game.state.player.hp == 27
		and game.state.stored.get("source", "") == "B" and game.state.stored.ability.get("width", 1) == 3,
		"real side-lane hit deals full damage and radial horizontal-tie push before acquiring wide B")
	check(describes_wide(game.stored.text + " " + game.stage_held_details.text), "held HUD and Details name the real three-wide borrowed ability")
	var held: Dictionary = game.state.stored.duplicate(true)
	var hp: int = _standee_entry("A").hp
	if not await _prepare_shine([1, 1]): return
	var cells: Array = []
	var side_hit := false
	for event in game.prediction.events:
		if event.type == "ray" and event.actor == "player": cells = event.cells
		if event.type == "damage" and event.actor == "A": side_hit = true
	check(same_cells(cells, expected) and side_hit, "borrowed wide Shine uses all six actual model cells and hits the off-center foe")
	var shown: Array = []
	for row in game.board.effect_footprints():
		if row.actor == "player" and row.stage == "shine": shown = row.cells
	check(same_cells(shown, expected) and _standee_entry("A").hp == hp,
		"real preview drawing retains all wide cells while roster HP stays confirmed")
	await commit()
	check(game.state.action_points == 2 and game.state.stored == held and _standee_entry("A").hp < hp,
		"one-AP wide Shine synchronizes HP without consuming the ability")
	_check_warning_sources()
	select("end_turn")
	await commit()
	var desc: Dictionary = game._two_source_presentation.compose(game.state, game.shadow.frame(), game.generation, ["A", "B"], "")
	check(desc.get("held_occurrence", {}).get("turn", -1) == held.captured_turn
		and desc.get("sources", {}).get("B", {}).get("occurrence", {}).get("turn", -1) == game.state.turn,
		"retained wide power stays distinct from its source's fresh aimed announcement")
	check(game.state.stored == held, "fresh source aim does not rewrite the held ability or expire it")
	_check_warning_sources()

func _foreground_alpha(image: Image, stage: Rect2, point: Vector2) -> float:
	var uv := (point - stage.position) / stage.size
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: return 1.0
	var pixel := Vector2i(uv * Vector2(image.get_size()))
	return image.get_pixel(pixel.x, pixel.y).a

func _capacity_measure(projection, dimensions: Vector2i, stage: Rect2, foreground: Image) -> Dictionary:
	var bounds := Rect2(projection.project(Vector2.ZERO), Vector2.ZERO)
	var min_altitude := INF
	var min_step := INF
	var min_cell_height := INF
	var min_cell_width := INF
	var touched := 0
	var max_cover := 0.0
	var blocked_patch_cells := 0
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var polygon: PackedVector2Array = projection.cell_polygon([x, y])
			var box := Rect2(polygon[0], Vector2.ZERO)
			for i in range(polygon.size()):
				bounds = bounds.expand(polygon[i])
				box = box.expand(polygon[i])
				var edge: Vector2 = polygon[(i + 1) % 4] - polygon[i]
				for opposite in [2, 3]:
					min_altitude = minf(min_altitude, absf((polygon[(i + opposite) % 4] - polygon[i]).cross(edge)) / edge.length())
			min_cell_height = minf(min_cell_height, box.size.y)
			min_cell_width = minf(min_cell_width, box.size.x)
			var center: Vector2 = projection.project(Vector2(x + 0.5, y + 0.5))
			for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
				if x + direction.x < dimensions.x and y + direction.y < dimensions.y:
					var neighbor: Vector2 = projection.project(Vector2(x + direction.x + 0.5, y + direction.y + 0.5))
					min_step = minf(min_step, center.distance_to(neighbor))
			var covered := 0
			for v in [0.1, 0.3, 0.5, 0.7, 0.9]:
				for u in [0.1, 0.3, 0.5, 0.7, 0.9]:
					if _foreground_alpha(foreground, stage, projection.project(Vector2(x + u, y + v))) > 0.1:
						covered += 1
			if covered > 0: touched += 1
			max_cover = maxf(max_cover, covered / 25.0)
			var blocked := false
			for offset in [Vector2(0.5, 0.5), Vector2(0.35, 0.5), Vector2(0.65, 0.5), Vector2(0.5, 0.35), Vector2(0.5, 0.65)]:
				if _foreground_alpha(foreground, stage, projection.project(Vector2(x, y) + offset)) > 0.1:
					blocked = true
			if blocked: blocked_patch_cells += 1
	return {"bounds": bounds, "minimum_cell_altitude": min_altitude,
		"minimum_cell_box": Vector2(min_cell_width, min_cell_height), "minimum_neighbor_step": min_step,
		"foreground_touched_cells_sampled": touched, "maximum_sampled_cover": max_cover,
		"blocked_center_patch_cells": blocked_patch_cells}

func _test_capacity_boundaries() -> void:
	# This is a bounded live-renderer capacity fixture, not permanent encounter
	# tuning. Numerical 7/8 comparisons below configure only the existing pure
	# projection helper; they do not add playable modes or change any game rule.
	for viewport in [Vector2i(1024, 720), Vector2i(1280, 800)]:
		await _stage_resize(viewport)
		var data := F.two_pursuers()
		data.width = 7
		data.height = 7
		data.objective = "defeat_all"
		data.erase("exit")
		data.player.pos = [0, 3]
		data.enemies[0].pos = [6, 0]
		data.enemies[1].pos = [6, 6]
		data.enemies[1].ability.width = 3
		await load_fixture(data)
		var before := _gameplay_facts()
		var stage: Rect2 = game.board._stage_rect()
		var foreground: Image = game.board.stage_renderer.foreground.texture.get_image()
		if foreground.is_compressed(): check(foreground.decompress() == OK, "foreground alpha is available for exact geometry inspection")
		var current := _capacity_measure(game.board._ensure_projection(), Vector2i(7, 7), stage, foreground)
		check(current.blocked_center_patch_cells == 0,
			"every playable cell retains a clear central patch in the original foreground art; no invisible trap cells")
		var widths := {}
		for row in game.board.standee_layout():
			var meta: Dictionary = game.board._standee_assembly[row.actor]
			var accepted_size: Vector2 = meta.canvas * stage.size.y * meta.height_fraction / meta.canvas.y
			check(row.rect.size.distance_to(accepted_size) < 0.01,
				"capacity uses accepted actor scale metadata, never uniform standee shrinking")
			var image: Image = game.board._standee_images[row.actor]
			widths[row.actor] = image.get_used_rect().size.x * row.rect.size.x / image.get_width()
			check(row.foot.distance_to(game.board.cell_center(row.cell)) < 0.01
				and row.foot.y > stage.position.y + stage.size.y * game.board.stage_renderer._floor_top,
				"extreme-start actor feet stay on the shared floor below the Director seam")
			check(_foreground_alpha(foreground, stage, row.foot) <= 0.1,
				"actual extreme actor foot/source anchor is not hidden by the foreground")
		for y in range(7):
			for x in range(7):
				var center: Vector2 = game.board.cell_center([x, y])
				check(stage.has_point(center) and game.board._input_cell(center, true) == [x, y],
					"every capacity cell center remains on-stage and selectable through art without changing actor-priority picking")
				for offset in [Vector2(0.35, 0.5), Vector2(0.65, 0.5), Vector2(0.5, 0.35), Vector2(0.5, 0.65)]:
					var patch: Vector2 = game.board._ensure_projection().project(Vector2(x, y) + offset)
					check(game.board._from_pixel(patch) == [x, y],
						"central visible patch has usable interior ownership, not only one lucky center pixel")
		print("CAPACITY current ", {"viewport": viewport, "dimensions": Vector2i(7, 7), "stage": stage,
			"geometry": current, "accepted_actor_alpha_widths": widths})
		# Report, do not style-assert, the density tradeoff. Source alpha and real
		# projected distances inform the candidate choice; these are not claims
		# that a particular pixel size or sampled cover percentage looks good.
		for count in [7, 8]:
			var projection := GroundProjection.new()
			var reclaimed := Rect2(stage.position + stage.size * Vector2(0.08, 0.445), stage.size * Vector2(0.74, 0.51))
			check(projection.configure_ground(count, count, reclaimed, 30.0), "existing shared homography supports a candidate capacity probe")
			print("CAPACITY reclaimed-floor proposal ", {"viewport": viewport, "dimensions": Vector2i(count, count),
				"geometry": _capacity_measure(projection, Vector2i(count, count), stage, foreground)})
		check(_gameplay_facts() == before, "capacity probes never move actors, spend AP or fabricate telegraphs")
		_check_plane_join()
		_check_warning_sources()
		_check_roster()
		_stage_controls_fit("capacity " + str(viewport))
		var snapshot: Dictionary = game.model.snapshot()
		for cell in [[0, 0], [6, 0], [6, 6], [0, 6], [3, 0], [6, 3], [3, 6], [0, 3]]:
			await _floor_click(cell)
			check(game.selected == cell and game.model.snapshot() == snapshot,
				"real GUI reaches every outer corner/edge destination without an invisible or inaccessible edge cell")
		var selected := _gameplay_facts()
		await _stage_resize(Vector2i(1280, 800) if viewport.x == 1024 else Vector2i(1024, 720))
		check(_gameplay_facts() == selected, "capacity resize preserves selection, history, budget and exact model state")
		_check_plane_join()
		_check_warning_sources()
		_check_roster()

func _run() -> void:
	if not _comparison_pack_ready():
		quit(2)
		return
	game = load("res://scenes/encounter.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if not _comparison_setup():
		game.queue_free()
		await process_frame
		quit(2)
		return
	check(game.encounter_id == "two-pursuers", "normal entry opens the accepted Stage slice without an appearance matrix")
	await _test_controlled_slice()
	await _test_roster_hp_sync()
	await _test_rehearsal_motion()
	await _test_wide_borrowed_geometry()
	await _test_capacity_boundaries()
	print("Stage board integration: %d checks, %d failures. Injected GUI, not visual acceptance." % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
