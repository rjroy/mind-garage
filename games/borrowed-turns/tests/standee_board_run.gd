extends SceneTree
## Controlled standee geometry/picking, not artwork taste or a pixel-size budget.
## Before independent RED, establish neutral board methods documented in the slice
## brief. Missing interfaces exit 2; assertion failures exit 1. No production art,
## import cache, global RNG or live encounter tuning is used by these unit tests.

const BOARD := "res://ui/board.gd"
const IDS := ["A", "player", "B"]
var board_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		printerr("FAIL: ", label)

func near(a: Vector2, b: Vector2) -> bool:
	return a.is_finite() and a.distance_to(b) < 0.01

func _setup() -> bool:
	board_script = load(BOARD)
	if board_script == null or not board_script.can_instantiate():
		printerr("SETUP REQUIRED: loadable board script, not behavioral RED")
		return false
	var board = board_script.new()
	var required := {"configure_standees": 2, "standee_layout": 0, "actor_at": 1,
		"pick_cell": 1, "focus_actor": 1}
	for name in required:
		var found := false
		for method in board.get_method_list():
			if method.name == name and method.args.size() == required[name]: found = true
		if not found:
			printerr("SETUP REQUIRED: board.", name, "; see dual-layer playable slice brief")
			board.free()
			return false
	board.free()
	return true

func snapshot(dimensions: Vector2i = Vector2i(5, 5), isolated: bool = false) -> Dictionary:
	var skill := {"kind": "shove", "range": 3, "damage": 2, "radius": 0, "push": true}
	return {
		"width": dimensions.x, "height": dimensions.y, "walls": [],
		"player": {"pos": [0, 3] if isolated else [2, 2], "hp": 23},
		"enemies": [
			{"id": "A", "pos": [2, 2] if isolated else [2, 1], "hp": 11, "kind": "shove", "ability": skill.duplicate(true)},
			{"id": "B", "pos": [4, 3] if isolated else [2, 3], "hp": 17, "kind": "shove", "ability": skill.duplicate(true)},
		],
		"exit": {"pos": [dimensions.x - 1, 0], "opens": 9},
		"intentions": [], "stored": {}, "backlash_footprint": {},
	}

func textures() -> Dictionary:
	var result := {}
	for id in IDS:
		var image := Image.create(12, 20, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in range(2, 19):
			for x in range(3, 9):
				# Like accepted sources, the body is near-opaque, never exactly 1.
				image.set_pixel(x, y, Color(0.7, 0.5, 0.3, 0.99))
		image.set_pixel(6, 9, Color.TRANSPARENT) # Interior gap must click through.
		result[id] = ImageTexture.create_from_image(image)
	return result

func assembly() -> Dictionary:
	var result := {}
	for id in IDS:
		result[id] = {"canvas": Vector2(12, 20), "foot": Vector2(6, 19),
			"height_fraction": 0.40}
	return result

func make_board(dimensions: Vector2i = Vector2i(5, 5), isolated: bool = false):
	var board = board_script.new()
	# Deliberately outside SceneTree: no stage artwork or rendering dependency.
	board.size = Vector2(1280, 650)
	board.set_view(snapshot(dimensions, isolated), {}, [], [], "")
	board.set_stage_mode(true)
	board.set_presentation(true, {})
	return board

func entry(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if row.get("actor", "") == id: return row
	return {}

func valid_entry(row: Dictionary, label: String) -> bool:
	var valid: bool = row.get("actor") is String and row.get("cell") is Array \
		and row.get("rect") is Rect2 and row.get("foot") is Vector2 \
		and row.get("tab_rect") is Rect2 and row.get("opacity") is float \
		and row.get("texture") is Texture2D
	check(valid, label + ": actual draw descriptor has the contracted geometry and texture")
	return valid

func canvas_point(row: Dictionary, source_pixel: Vector2) -> Vector2:
	var rect: Rect2 = row.rect
	return rect.position + source_pixel / Vector2(row.texture.get_size()) * rect.size

func opaque_at(row: Dictionary, point: Vector2) -> bool:
	var rect: Rect2 = row.rect
	if not rect.has_point(point): return false
	var image: Image = row.texture.get_image()
	var uv := (point - rect.position) / rect.size
	var pixel := Vector2i(uv * Vector2(image.get_size()))
	return image.get_pixel(pixel.x, pixel.y).a >= 0.1

func test_configuration() -> void:
	var board = make_board()
	check(board.standee_layout().is_empty(), "unconfigured board does not invent standee artwork")
	check(not board.configure_standees({}, {}), "missing textures/anchors fail explicitly")
	var art := textures()
	var meta := assembly()
	check(board.configure_standees(art, meta), "test-owned near-opaque RGBA artwork configures")
	var rows: Array = board.standee_layout()
	check(rows.size() == 3, "one actual draw descriptor per living actor")
	var bad := assembly()
	bad.A.canvas = Vector2(99, 20)
	check(not board.configure_standees(art, bad), "native canvas/texture mismatch is rejected")
	check(board.standee_layout().is_empty(), "failed reconfiguration clears stale art rather than displaying wrong actors")
	board.free()

func test_geometry() -> void:
	for dimensions in [Vector2i(5, 5), Vector2i(8, 4)]:
		var board = make_board(dimensions)
		var art := textures()
		var meta := assembly()
		check(board.configure_standees(art, meta), "geometry fixture configures")
		for extent in [Vector2(1024, 510), Vector2(1600, 700)]:
			board.size = extent
			var rows: Array = board.standee_layout()
			check(rows.size() == 3, "resize/dimensions retain all three actual pieces")
			if rows.size() != 3: continue
			var ordered: Array = []
			var tabs: Array[Rect2] = []
			for row in rows:
				if not valid_entry(row, str(dimensions) + "/" + str(extent)): continue
				ordered.append(row.actor)
				var cell: Array = row.cell
				var center: Vector2 = board.cell_center(cell)
				var rect: Rect2 = row.rect
				var tab: Rect2 = row.tab_rect
				check(near(row.foot, center), row.actor + ": feet stay at the true projected cell center")
				check(near(canvas_point(row, meta[row.actor].foot), center), row.actor + ": native foot anchor is used by the full-canvas draw rectangle")
				check(is_equal_approx(rect.size.x / rect.size.y, 12.0 / 20.0), row.actor + ": artwork aspect ratio is not distorted")
				check(is_equal_approx(rect.size.y, board._stage_rect().size.y * meta[row.actor].height_fraction),
					row.actor + ": controlled assembly height scales with stage allocation, not old pawn size")
				check(row.texture == art[row.actor], row.actor + ": descriptor uses the injected texture, not a duplicate primitive")
				check(tab.has_area() and Rect2(Vector2.ZERO, board.size).encloses(tab), row.actor + ": source foot marker has usable board-local geometry")
				check(tab.grow(2).has_point(center), row.actor + ": foot marker is visibly attached to the owning cell")
				check(board.actor_at(tab.get_center()) == row.actor and board.pick_cell(tab.get_center()) == cell,
					row.actor + ": overlaid foot marker selects its true cell despite neighboring tall bodies")
				for other in tabs:
					check(not tab.intersects(other), "same-column actor markers do not obscure one another")
				tabs.append(tab)
			check(ordered == IDS, "same-column figures are drawn back-to-front, independent of source identity")
			check(board.state.player.pos == [2, 2] and board.state.enemies[0].pos == [2, 1]
				and board.state.enemies[1].pos == [2, 3], "readability never rearranges logical actors")
			if rows[0].get("cell") is Array and rows[0].cell.size() == 2:
				var original_cell: Array = rows[0].cell.duplicate()
				rows[0].cell[0] = 999
				check(entry(board.standee_layout(), "A").get("cell", []) == original_cell,
					"returned geometry cannot mutate actual actor ownership")
		board.free()

func test_alpha_and_floor_picking() -> void:
	var board = make_board(Vector2i(5, 5), true)
	check(board.configure_standees(textures(), assembly()), "isolated alpha fixture configures")
	var a := entry(board.standee_layout(), "A")
	if not valid_entry(a, "alpha fixture"):
		board.free()
		return
	var body := canvas_point(a, Vector2(5, 5))
	check(board.actor_at(body) == "A", "near-opaque body pixels select the figure, including above its own tile")
	check(board._from_pixel(body) != a.cell, "controlled body point genuinely differs from underlying floor ownership")
	check(board.pick_cell(body) == a.cell, "body hit uses the actor's true cell, not the floor behind its head")
	for pixel in [Vector2(1, 5), Vector2(6.5, 9.5)]:
		var gap := canvas_point(a, pixel)
		check(board.actor_at(gap).is_empty(), "transparent outer padding/interior gaps do not become opaque hit boxes")
		check(board.pick_cell(gap) == board._from_pixel(gap), "transparent artwork preserves shared inverse floor mapping")
	var empty: Vector2 = board.cell_center([1, 0])
	check(board.actor_at(empty).is_empty() and board.pick_cell(empty) == [1, 0],
		"unoccupied floor remains directly targetable through the shared projection")
	board.set_stage_mode(false)
	check(board.standee_layout().is_empty() and board.actor_at(body).is_empty(), "plain/paper have no invisible Stage actor hit regions")
	check(board.pick_cell(board.cell_center([2, 2])) == [2, 2], "non-Stage picking retains rectangular behavior")
	board.free()

func test_overlap_focus_and_lifetime() -> void:
	var board = make_board()
	check(board.configure_standees(textures(), assembly()), "overlap fixture configures")
	var rows: Array = board.standee_layout()
	var a := entry(rows, "A")
	var front := entry(rows, "B")
	if not valid_entry(a, "rear actor") or not valid_entry(front, "front actor"):
		board.free()
		return
	check(a.rect.intersects(front.rect), "same-column test actually stresses tall-piece occlusion")
	var overlap_found := false
	var intersection: Rect2 = a.rect.intersection(front.rect)
	for y in range(int(intersection.position.y), int(intersection.end.y), 2):
		for x in range(int(intersection.position.x), int(intersection.end.x), 2):
			var point := Vector2(x + 0.5, y + 0.5)
			if opaque_at(a, point) and opaque_at(front, point):
				check(board.actor_at(point) == "B", "opaque overlapping bodies pick the actual frontmost figure")
				overlap_found = true
				break
		if overlap_found: break
	check(overlap_found, "fixture contains actual overlapping opaque pixels, not only intersecting empty rectangles")
	var before: Dictionary = board.state.duplicate(true)
	board.focus_actor("A")
	rows = board.standee_layout()
	check(board.cursor == [2, 1], "keyboard/source focus reaches the rear actor's true cell")
	check(board.state == before, "focus does not move actors or alter gameplay")
	a = entry(rows, "A")
	front = entry(rows, "B")
	if valid_entry(a, "focused rear") and valid_entry(front, "focused front"):
		check(is_equal_approx(a.opacity, 1.0) and front.opacity > 0.0 and front.opacity < 1.0,
			"focusing a covered rear actor reveals it without removing the front actor")
		check(board.actor_at(a.tab_rect.get_center()) == "A", "rear foot marker remains directly selectable")
	board.focus_actor("")
	check(is_equal_approx(float(entry(board.standee_layout(), "B").get("opacity", 0.0)), 1.0), "clearing focus restores the front figure")
	var after := snapshot()
	after.enemies.remove_at(0)
	board.set_view(after, {}, [], [], "")
	check(entry(board.standee_layout(), "A").is_empty(), "removed actors cannot leave a stale drawn piece or hit region")
	board.focus_actor("A")
	check(board.state == after, "stale source focus cannot resurrect an actor or mutate the snapshot")
	board.free()

func _run() -> void:
	if not _setup():
		quit(2)
		return
	test_configuration()
	test_geometry()
	test_alpha_and_floor_picking()
	test_overlap_focus_and_lifetime()
	print("Standee board: %d checks, %d failures. Synthetic alpha/geometry, not visual acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
