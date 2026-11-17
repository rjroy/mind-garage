extends SceneTree
## Controlled stage geometry/material tests. No production art or encounter tuning.
## SETUP BEFORE INDEPENDENT RED (missing imports/methods are NOT behavioral RED):
## - ui/stage_projection.gd, RefCounted:
##   configure(columns: int, rows: int, quad: PackedVector2Array) -> bool
##   project(grid: Vector2) -> Vector2; unproject(pixel: Vector2) -> Vector2
##   cell_at(pixel: Vector2) -> Array
##   cell_polygon(cell: Array) -> PackedVector2Array
##   Quad order TL, TR, BR, BL. Grid coordinates are continuous logical corners.
## - ui/paper_cells.gd, RefCounted: sample(cell: Array, visual_seed: int) -> Dictionary
##   Detached {uv_rect: Rect2 in normalized texture coordinates,
##             quarter_turn: int, tint: Color}. No global RNG or gameplay data.
## - board.gd: cell_polygon(Array), piece_appearance(Array),
##   figure_layout(Array) -> {origin: Vector2, foot: Vector2, size: float}.
##   Extract existing rectangular geometry and figure origin/size without changing
##   baseline behavior. Draw paths MUST consume these shared seams, not test copies.
##   Stage flag may initially be inert; neutral loadable helpers are sufficient.
##   No substantive stage implementation belongs in this setup.
## Exit 2 is setup, 1 is assertion RED, 0 passes. Syntax-only author validation.

const Encounter = preload("res://model/encounter.gd")
const F = preload("res://ui/smoke_fixtures.gd")
const PROJECTION := "res://ui/stage_projection.gd"
const MATERIAL := "res://ui/paper_cells.gd"
const BOARD := "res://ui/board.gd"
var projection_script: Script
var material_script: Script
var board_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func near(actual: Vector2, expected: Vector2) -> bool:
	return actual.is_finite() and actual.distance_to(expected) < 0.002

func _method(object: Object, name: String, arity: int) -> bool:
	for method in object.get_method_list():
		if method.name == name: return method.args.size() == arity
	return false

func _setup() -> bool:
	for path in [PROJECTION, MATERIAL, BOARD]:
		if not ResourceLoader.exists(path):
			printerr("SETUP REQUIRED: loadable stage interfaces; missing ", path)
			return false
	projection_script = load(PROJECTION)
	material_script = load(MATERIAL)
	board_script = load(BOARD)
	for script in [projection_script, material_script, board_script]:
		if script == null or not script.can_instantiate():
			printerr("SETUP REQUIRED: stage interfaces must parse and instantiate cleanly.")
			return false
	var projection = projection_script.new()
	var material = material_script.new()
	var board = board_script.new()
	var ready: bool = _method(projection, "configure", 3) and _method(projection, "project", 1) \
		and _method(projection, "configure_ground", 4) \
		and _method(projection, "unproject", 1) and _method(projection, "cell_at", 1) \
		and _method(projection, "cell_polygon", 1) and _method(material, "sample", 2) \
		and _method(board, "cell_polygon", 1) \
		and _method(board, "piece_appearance", 1) and _method(board, "figure_layout", 1)
	if ready:
		ready = projection.call("project", Vector2.ZERO) is Vector2 \
			and projection.call("unproject", Vector2.ZERO) is Vector2 \
			and projection.call("cell_at", Vector2.ZERO) is Array \
			and projection.call("cell_polygon", [0, 0]) is PackedVector2Array \
			and material.call("sample", [0, 0], 17) is Dictionary
	board.free()
	if not ready: printerr("SETUP REQUIRED: see exact typed interfaces and extraction in runner header.")
	return ready

func rectangle() -> PackedVector2Array:
	return PackedVector2Array([Vector2(60, 40), Vector2(460, 40), Vector2(460, 280), Vector2(60, 280)])

func trapezoid() -> PackedVector2Array:
	return PackedVector2Array([Vector2(100, 100), Vector2(300, 100), Vector2(400, 300), Vector2(0, 300)])

func configured(columns: int, rows: int, quad: PackedVector2Array):
	var projection = projection_script.new()
	check(projection.call("configure", columns, rows, quad) == true, "valid controlled projection configures")
	return projection

func test_known_projection() -> void:
	var fresh = projection_script.new()
	check(fresh.call("cell_at", Vector2.ZERO).is_empty() and fresh.call("cell_polygon", [0, 0]).is_empty(),
		"unconfigured helper has no hittable/drawable board")
	var p = configured(4, 2, rectangle())
	check(near(p.call("project", Vector2(2, 1)), Vector2(260, 160)), "rectangular forward map has known center")
	check(near(p.call("unproject", Vector2(160, 100)), Vector2(1, 0.5)), "rectangular inverse has known fractional coordinates")
	p = configured(4, 2, trapezoid())
	# Independent analytic homography: x=(100+200u-100v)/(1-v/2),
	# y=(100+50v)/(1-v/2). This rejects bilinear quad interpolation.
	check(near(p.call("project", Vector2(2, 1)), Vector2(200, 500.0 / 3.0)), "perspective midpoint follows a projective map, not bilinear lerp")
	check(near(p.call("unproject", Vector2(200, 200)), Vector2(2, 4.0 / 3.0)), "perspective inverse matches independent expected logical point")
	var expected := trapezoid()
	for index in range(4):
		var logical: Vector2 = [Vector2(0, 0), Vector2(4, 0), Vector2(4, 2), Vector2(0, 2)][index]
		check(near(p.call("project", logical), expected[index]), "known corner %d maps exactly" % index)

func test_boundaries_and_cells() -> void:
	var p = configured(4, 2, rectangle())
	for pair in [
		[Vector2(60, 40), [0, 0]], [Vector2(459.99, 279.99), [3, 1]],
		[Vector2(160, 100), [1, 0]], [Vector2(159.99, 100), [0, 0]],
		[Vector2(200, 160), [1, 1]], [Vector2(200, 159.99), [1, 0]],
		[Vector2(460, 100), []], [Vector2(200, 280), []],
		[Vector2(59.99, 100), []], [Vector2(200, 39.99), []],
		[Vector2(460, 280), []],
	]:
		check(p.call("cell_at", pair[0]) == pair[1], "half-open logical tile ownership: " + str(pair[0]))
	p = configured(4, 2, trapezoid())
	for point in [Vector2(10, 110), Vector2(390, 110), Vector2(200, 99), Vector2(200, 301)]:
		check(p.call("cell_at", point).is_empty(), "outside sloped polygon rejected, not merely bounding box: " + str(point))
	for invalid_cell in [[-1, 0], [4, 0], [0, 2]]:
		check(p.call("cell_polygon", invalid_cell).is_empty(), "out-of-board cell has no drawing polygon")
	var left: PackedVector2Array = p.call("cell_polygon", [1, 0])
	var right: PackedVector2Array = p.call("cell_polygon", [2, 0])
	check(left.size() == 4 and right.size() == 4, "cell polygons contain four logical corners")
	if left.size() == 4 and right.size() == 4:
		check(near(left[1], right[0]) and near(left[2], right[3]), "adjacent paper geometry shares a seam before visual inset")
		left[0] = Vector2(-999, -999)
		check(p.call("cell_polygon", [1, 0])[0] != left[0], "returned polygon cannot mutate projection state")

func test_dimensions_and_reconfiguration() -> void:
	for dimensions in [Vector2i(1, 1), Vector2i(3, 8), Vector2i(11, 4)]:
		for viewport_scale in [Vector2(0.7, 1.3), Vector2(2.1, 0.6)]:
			var quad := trapezoid()
			for i in range(quad.size()): quad[i] = quad[i] * viewport_scale + Vector2(23, 19)
			var p = configured(dimensions.x, dimensions.y, quad)
			for y in range(dimensions.y):
				for x in range(dimensions.x):
					var logical := Vector2(x + 0.5, y + 0.5)
					var pixel: Vector2 = p.call("project", logical)
					check(near(p.call("unproject", pixel), logical), "round trip across runtime dimensions/aspect")
					check(p.call("cell_at", pixel) == [x, y], "every cell center remains selectable")
			check(p.call("configure", 2, 3, rectangle()) == true, "same helper reconfigures on board/viewport change")
			check(near(p.call("project", Vector2(1, 1.5)), Vector2(260, 160)), "reconfiguration replaces old dimensions and mapping")

func test_invalid_configuration() -> void:
	for invalid in [
		[0, 3, rectangle()], [3, -1, rectangle()],
		[3, 3, PackedVector2Array([Vector2.ZERO, Vector2.ONE, Vector2(2, 2)])],
		[3, 3, PackedVector2Array([Vector2.ZERO, Vector2(10, 10), Vector2(10, 0), Vector2(0, 10)])],
		[3, 3, PackedVector2Array([Vector2.ZERO, Vector2(10, 0), Vector2(2, 2), Vector2(0, 10)])],
		[3, 3, PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)])],
	]:
		var p = configured(2, 3, rectangle())
		check(p.call("configure", invalid[0], invalid[1], invalid[2]) == false, "invalid/degenerate mapping rejected")
		check(p.call("cell_at", Vector2(260, 160)).is_empty() and p.call("cell_polygon", [0, 0]).is_empty(),
			"each invalid reconfiguration clears a previously valid hittable/drawable mapping")

func test_ground_projection() -> void:
	# Bounds, angle and dimensions belong to these tests, not live scene tuning.
	for yaw in [27.0, -34.0]:
		for dimensions in [Vector2i(5, 5), Vector2i(9, 4)]:
			for bounds in [Rect2(37, 51, 800, 300), Rect2(91, 120, 470, 210)]:
				var p = projection_script.new()
				var applied: bool = p.configure_ground(dimensions.x, dimensions.y, bounds, yaw)
				check(applied, "controlled yawed ground plane configures")
				if not applied: continue
				var corners := [Vector2.ZERO, Vector2(dimensions.x, 0),
					Vector2(dimensions), Vector2(0, dimensions.y)]
				for corner in corners:
					check(bounds.grow(0.01).has_point(p.project(corner)), "uniformly fitted ground corners stay inside supplied bounds")
				var center := Vector2(dimensions) / 2.0
				var across: Vector2 = p.project(center + Vector2.RIGHT * 0.4) - p.project(center)
				var down: Vector2 = p.project(center + Vector2.DOWN * 0.4) - p.project(center)
				check(across.x > 0 and signf(across.y) == signf(yaw),
					"positive ground yaw brings increasing X toward the viewer")
				check(down.y > 0 and signf(down.x) == -signf(yaw),
					"ground yaw staggers the columns rather than rotating upright images")
				var left_span: float = p.project(Vector2(1, center.y)).distance_to(p.project(Vector2(0, center.y)))
				var right_span: float = p.project(Vector2(dimensions.x, center.y)).distance_to(p.project(Vector2(dimensions.x - 1, center.y)))
				check((right_span - left_span) * signf(yaw) > 0,
					"yaw changes perspective depth along X, not just a 2D rotation of the old board")
				var inverse: PackedFloat64Array = p.inverse_coefficients()
				check(inverse.size() == 9, "yawed ground exports the same homography inverse used by floor material")
				for y in range(dimensions.y):
					for x in range(dimensions.x):
						var point := Vector2(x + 0.37, y + 0.63)
						var pixel: Vector2 = p.project(point)
						check(near(p.unproject(pixel), point) and p.cell_at(pixel) == [x, y],
							"yawed fractional points round-trip to exact floor ownership")
						if inverse.size() == 9:
							var divisor := inverse[6] * pixel.x + inverse[7] * pixel.y + inverse[8]
							var logical := Vector2(
								(inverse[0] * pixel.x + inverse[1] * pixel.y + inverse[2]) / divisor,
								(inverse[3] * pixel.x + inverse[4] * pixel.y + inverse[5]) / divisor) * Vector2(dimensions)
							check(near(logical, point), "actual shader inverse equation agrees with yawed floor picking")
				for point in [Vector2(-0.01, 1), Vector2(dimensions.x, 1), Vector2(1, dimensions.y)]:
					check(p.cell_at(p.project(point)).is_empty(), "yawed plane retains half-open outer ownership")
				var one: PackedVector2Array = p.cell_polygon([1, 1])
				var two: PackedVector2Array = p.cell_polygon([2, 1])
				check(one.size() == 4 and two.size() == 4, "yawed cells expose real projected corners")
				if one.size() == 4 and two.size() == 4:
					check(near(one[1], two[0]) and near(one[2], two[3]), "yaw does not open logical seams between cells")
	for invalid in [
		[0, 4, Rect2(0, 0, 600, 240), 27.0],
		[4, 4, Rect2(0, 0, 0, 240), 27.0],
		[4, 4, Rect2(0, 0, 600, -1), 27.0],
		[4, 4, Rect2(Vector2(INF, 0), Vector2(600, 240)), 27.0],
		[4, 4, Rect2(0, 0, 600, 240), NAN],
	]:
		var p = configured(4, 4, rectangle())
		check(not p.configure_ground(invalid[0], invalid[1], invalid[2], invalid[3]), "invalid ground configuration rejects")
		check(p.inverse_coefficients().is_empty() and p.cell_polygon([0, 0]).is_empty()
			and p.cell_at(Vector2(100, 100)).is_empty(), "failed ground reconfiguration clears a formerly valid map")

func valid_piece(value: Dictionary) -> bool:
	if not value.get("uv_rect") is Rect2 or not value.get("tint") is Color or not value.get("quarter_turn") is int: return false
	var uv: Rect2 = value.uv_rect
	var tint: Color = value.tint
	return uv.position.is_finite() and uv.size.is_finite() and uv.size.x > 0 and uv.size.y > 0 \
		and uv.position.x >= 0 and uv.position.y >= 0 and uv.end.x <= 1.00001 and uv.end.y <= 1.00001 \
		and value.quarter_turn >= 0 and value.quarter_turn < 4 \
		and is_finite(tint.r) and is_finite(tint.g) and is_finite(tint.b) and is_equal_approx(tint.a, 1.0)

func test_stable_material() -> void:
	var material = material_script.new()
	var baseline: Array = []
	var different_seed: Array = []
	var distinct: Array = []
	for y in range(3):
		for x in range(4):
			var piece: Dictionary = material.call("sample", [x, y], 731)
			check(valid_piece(piece), "paper sample is a bounded crop, quarter-turn and opaque finite tint")
			baseline.append(piece.duplicate(true))
			if not distinct.has(piece): distinct.append(piece.duplicate(true))
			different_seed.append(material.call("sample", [x, y], 732))
	check(distinct.size() > 1, "neighboring pieces do not all reuse an identical appearance")
	check(different_seed != baseline, "visual seed controls the stable paper field")
	var reversed: Array = []
	for y in range(2, -1, -1):
		for x in range(3, -1, -1):
			reversed.push_front(material.call("sample", [x, y], 731))
	check(reversed == baseline, "paper appearance is independent of traversal order and prior calls")
	var changed: Dictionary = material.call("sample", [1, 1], 731)
	changed["tint"] = Color.MAGENTA
	check(material.call("sample", [1, 1], 731) == baseline[5], "returned descriptor is detached")
	seed(9173)
	var expected_random := randi()
	seed(9173)
	material.call("sample", [3, 2], 731)
	check(randi() == expected_random, "visual sampling does not consume global gameplay RNG")

func board_fixture(columns: int, rows: int) -> Dictionary:
	var data := F.encounter([])
	data.width = columns
	data.height = rows
	data.player.pos = [1, 1]
	data.exit.pos = [columns - 1, rows - 1]
	return data

func test_board_consumer() -> void:
	var model = Encounter.new()
	var board = board_script.new()
	for dimensions in [Vector2i(4, 3), Vector2i(9, 5)]:
		model.configure(board_fixture(dimensions.x, dimensions.y), "R2")
		var snapshot: Dictionary = model.snapshot()
		var intact := snapshot.duplicate(true)
		board.set_view(snapshot, {}, [], [], "")
		board.set_presentation({})
		board.size = Vector2(960, 620)
		for cell in [[0, 0], [1, 1], [dimensions.x - 1, dimensions.y - 1]]:
			var polygon: PackedVector2Array = board.call("cell_polygon", cell)
			var center: Vector2 = board.cell_center(cell)
			check(polygon.size() == 4 and Geometry2D.is_point_in_polygon(center, polygon), "actual board places logical centers inside shared drawing polygons")
			check(board._from_pixel(center) == cell, "actual board hit conversion selects the displayed logical tile")
			var layout: Dictionary = board.call("figure_layout", cell)
			check(layout.get("origin") is Vector2 and layout.get("foot") is Vector2 and layout.get("size") is float,
				"actual figure placement provides upright origin, foot and scale")
			if layout.get("origin") is Vector2 and layout.get("foot") is Vector2 and layout.get("size") is float:
				check(near(layout.foot, center) and layout["size"] > 0 and layout.origin.y < layout.foot.y and is_equal_approx(layout.origin.x, layout.foot.x),
					"stage figure feet anchor to the logical tile without tilting the standee")
		var back: PackedVector2Array = board.call("cell_polygon", [0, 0])
		var front: PackedVector2Array = board.call("cell_polygon", [0, dimensions.y - 1])
		if back.size() == 4 and front.size() == 4:
			check(back[0].distance_to(back[1]) < front[3].distance_to(front[2]), "stage far tiles are narrower than near tiles")
		var top_right: PackedVector2Array = board.call("cell_polygon", [dimensions.x - 1, 0])
		var bottom_right: PackedVector2Array = board.call("cell_polygon", [dimensions.x - 1, dimensions.y - 1])
		if back.size() == 4 and front.size() == 4 and top_right.size() == 4 and bottom_right.size() == 4:
			var reference = configured(dimensions.x, dimensions.y, PackedVector2Array([back[0], top_right[1], bottom_right[2], front[3]]))
			check(near(board.cell_center([1, 1]), reference.call("project", Vector2(1.5, 1.5))), "actual actor anchor uses the same projective mapping as floor corners")
		var far_figure: Dictionary = board.call("figure_layout", [0, 0])
		var near_figure: Dictionary = board.call("figure_layout", [0, dimensions.y - 1])
		check(far_figure.get("size", 0.0) > 0 and far_figure.get("size", 0.0) < near_figure.get("size", 0.0),
			"upright figures scale with stage depth")
		var old_piece: Dictionary = board.call("piece_appearance", [1, 1])
		var old_center: Vector2 = board.cell_center([1, 1])
		board.size = Vector2(650, 470)
		check(not near(board.cell_center([1, 1]), old_center), "actual board recomputes placement after resizing")
		check(board._from_pixel(board.cell_center([1, 1])) == [1, 1], "resized drawing and hit mapping stay aligned")
		check(board.call("piece_appearance", [1, 1]) == old_piece, "resizing does not reshuffle paper")
		check(snapshot == intact and model.snapshot() == intact, "projection and material leave model-owned input immutable")
		board.size = Vector2(960, 620)
	board.free()

func _run() -> void:
	if not _setup():
		quit(2)
		return
	test_known_projection()
	test_boundaries_and_cells()
	test_dimensions_and_reconfiguration()
	test_invalid_configuration()
	test_ground_projection()
	test_stable_material()
	test_board_consumer()
	print("Stage projection: %d checks, %d failures. Controlled geometry/material and board boundaries; not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
