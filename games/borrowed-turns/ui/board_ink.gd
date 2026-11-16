extends RefCounted
## Paper constructions in board space, plus cached screen-sized alpha contours.
## No rules, asset writes, clock, input regions or alternate projection.

const INK := Color("241623")
const PAPER_A := Color("f4d798")
const PAPER_B := Color("f2c6ad")
const CUT_EDGE := Color("a66c4b")
# An authored open palm, four distinct fingers, thumb and narrow cuff.
# Local -Y points in the direction of the shove.
const HAND := [
	Vector2(-0.24, 0.46), Vector2(-0.24, 0.22), Vector2(-0.30, 0.08),
	Vector2(-0.46, -0.04), Vector2(-0.49, -0.13), Vector2(-0.46, -0.20),
	Vector2(-0.39, -0.21), Vector2(-0.26, -0.10),
	Vector2(-0.26, -0.45), Vector2(-0.23, -0.52), Vector2(-0.18, -0.54),
	Vector2(-0.13, -0.50), Vector2(-0.11, -0.19),
	Vector2(-0.10, -0.61), Vector2(-0.06, -0.67), Vector2(0.00, -0.67),
	Vector2(0.04, -0.61), Vector2(0.05, -0.19),
	Vector2(0.09, -0.55), Vector2(0.13, -0.61), Vector2(0.19, -0.60),
	Vector2(0.23, -0.54), Vector2(0.21, -0.17),
	Vector2(0.27, -0.40), Vector2(0.31, -0.45), Vector2(0.36, -0.43),
	Vector2(0.39, -0.37), Vector2(0.35, 0.09), Vector2(0.26, 0.27),
	Vector2(0.25, 0.46),
]
var _contours: Dictionary = {}

func clear_contours() -> void:
	_contours.clear()

func draw_contour(board, row: Dictionary, original: Image, mode: String) -> void:
	var extent := Vector2i(ceili(row.rect.size.x), ceili(row.rect.size.y))
	if extent.x <= 0 or extent.y <= 0: return
	var cached: Dictionary = _contours.get(row.actor, {})
	if cached.get("extent") != extent or cached.get("original") != original:
		cached = _make_contours(original, extent, clampf(board._stage_rect().size.y / 514.0, 1.0, 1.6))
		_contours[row.actor] = cached
	board.draw_texture_rect(cached[mode], row.rect, false, Color(1, 1, 1, row.opacity))

func _make_contours(original: Image, extent: Vector2i, scale: float) -> Dictionary:
	var mask := original.duplicate() as Image
	mask.convert(Image.FORMAT_RGBA8)
	mask.resize(extent.x, extent.y, Image.INTERPOLATE_LANCZOS)
	var bytes := mask.get_data()
	var black := Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	var rim := Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	black.fill(Color.TRANSPARENT)
	rim.fill(Color.TRANSPARENT)
	var radius := 1.05 * scale
	var outside := radius + 0.95
	var samples: Array = []
	var limit := ceili(outside + 0.65)
	for dy in range(-limit, limit + 1):
		for dx in range(-limit, limit + 1):
			var distance := Vector2(dx, dy).length()
			if distance > outside + 0.65: continue
			samples.append([dx, dy, clampf(radius + 0.65 - distance, 0, 1),
				clampf(outside + 0.65 - distance, 0, 1)])
	# Only the alpha outside the existing image is added. A faded front piece
	# stays faded; overlapping shifted copies must not make its body opaque.
	for y in range(extent.y):
		for x in range(extent.x):
			var center := float(bytes[(y * extent.x + x) * 4 + 3]) / 255.0
			if center >= 0.999: continue
			var inner := 0.0
			var outer := 0.0
			for sample in samples:
				var sx: int = x + sample[0]
				var sy: int = y + sample[1]
				if sx < 0 or sy < 0 or sx >= extent.x or sy >= extent.y: continue
				var alpha := float(bytes[(sy * extent.x + sx) * 4 + 3]) / 255.0
				inner = maxf(inner, alpha * sample[2])
				outer = maxf(outer, alpha * sample[3])
			inner = maxf(0, inner - center)
			outer = maxf(0, outer - center)
			if outer <= 0: continue
			black.set_pixel(x, y, Color(Color("150f17"), inner))
			var color := Color("efcf90").lerp(Color("150f17"), inner / outer)
			rim.set_pixel(x, y, Color(color, outer))
	return {"original": original, "extent": extent,
		"black": ImageTexture.create_from_image(black), "rim": ImageTexture.create_from_image(rim)}

func _project(board, point: Vector2) -> Vector2:
	return board._ensure_projection().project(point)

func _lane_center(cell: Array, lane: int, direction: Vector2) -> Vector2:
	var offset := 0.14 if lane == 0 else 0.86
	return Vector2(cell[0] + (0.5 if direction.x != 0 else offset),
		cell[1] + (offset if direction.x != 0 else 0.5))

func _polygon(board, points: Array) -> PackedVector2Array:
	var projected := PackedVector2Array()
	for point in points: projected.append(_project(board, point))
	return projected

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty(): result.append(result[0])
	return result

func _stroke(board, points: Array, color: Color, width: float = 1.0) -> void:
	board.draw_polyline(_polygon(board, points), color, width, true)

func _hand(board, center: Vector2, forward: Vector2, width: float, height: float, paper: Color, stamp: bool) -> void:
	var right := Vector2(forward.y, -forward.x)
	var shape: Array = []
	for point in HAND: shape.append(center + right * point.x * width - forward * point.y * height)
	var polygon := _polygon(board, shape)
	if stamp: board.draw_polyline(_closed(polygon), INK, 2.6, true)
	board.draw_colored_polygon(polygon, paper)
	board.draw_polyline(_closed(polygon), Color(paper, 0.75) if stamp else Color("503028"), 0.65, true)
	var crease := INK if stamp else CUT_EDGE
	_stroke(board, [center + right * -0.11 * width - forward * 0.13 * height,
		center + right * -0.06 * width + forward * 0.06 * height,
		center + right * 0.13 * width + forward * 0.12 * height], crease, 0.75)
	_stroke(board, [center + right * -0.20 * width - forward * 0.30 * height,
		center + right * 0.22 * width - forward * 0.30 * height], crease, 0.8)

func _badge(board, at: Vector2, id: String, emphasized: bool) -> void:
	var center := _project(board, at)
	var scale := clampf(board._stage_rect().size.y / 514.0, 1, 1.35)
	var radius := 6.5 * scale
	var paper := Color("ffecc4") if emphasized else PAPER_A if id == "A" else PAPER_B
	if id == "A":
		var diamond := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0),
			center + Vector2(0, radius), center + Vector2(-radius, 0)])
		board.draw_colored_polygon(diamond, paper)
		board.draw_polyline(_closed(diamond), INK, 1.0, true)
	else:
		board.draw_circle(center, radius, paper, true, -1, true)
		board.draw_arc(center, radius, 0, TAU, 24, INK, 1.0, true)
	var font_size := roundi(9 * scale)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(id, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	board.draw_string(font, center + Vector2(-text_size.x / 2, font_size * 0.34),
		id, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)

func _ribbon_cell(board, center: Vector2, forward: Vector2, paper: Color) -> void:
	var right := Vector2(forward.y, -forward.x)
	var points: Array = []
	# Slightly irregular cut edges, stable in board space rather than animated.
	for side in [-1.0, 1.0]:
		var steps: Array = [-0.49, -0.21, 0.08, 0.30, 0.49]
		if side > 0: steps.reverse()
		for i in range(steps.size()):
			var edge: float = 0.102 + (0.006 if i % 2 == 0 else -0.003)
			points.append(center + forward * steps[i] + right * side * edge)
	var polygon := _polygon(board, points)
	board.draw_colored_polygon(polygon, paper)
	board.draw_polyline(_closed(polygon), INK, 1.5, true)
	for side in [-1.0, 1.0]:
		_stroke(board, [center - forward * 0.45 + right * side * 0.082,
			center + forward * 0.45 + right * side * 0.082], Color("b17a50"), 0.7)
	# The dark cut/fold at each cell boundary exposes the exact segmentation.
	_stroke(board, [center + forward * 0.46 - right * 0.09,
		center + forward * 0.46 + right * 0.09], CUT_EDGE, 1)
	for i in range(3):
		var start := center + forward * (-0.30 + i * 0.24) + right * 0.065
		_stroke(board, [start, start + forward * 0.08 - right * 0.014], Color("fff0cb", 0.65), 0.6)
	_hand(board, center - forward * 0.02, forward, 0.22, 0.50, INK, false)
	var head := _polygon(board, [center + forward * 0.43,
		center + forward * 0.34 + right * 0.045, center + forward * 0.34 - right * 0.045])
	board.draw_colored_polygon(head, INK)

func draw_announcements(board, marks: Array, language: String) -> void:
	for mark in marks:
		if mark.cells.is_empty(): continue
		var forward := Vector2(mark.direction[0], mark.direction[1]).normalized()
		if forward == Vector2.ZERO: continue
		var paper := PAPER_A if mark.source == "A" else PAPER_B
		var emphasized: bool = mark.source == board.source
		if language == "ribbons":
			var first := _lane_center(mark.cells[0], mark.lane, forward) - forward * 0.49
			var anchor: Vector2 = board.cell_center(mark.origin) + Vector2(-31 if mark.lane == 0 else 31, 8)
			var start := _project(board, first)
			board.draw_line(anchor, start, INK, 4.0, true)
			board.draw_line(anchor, start, paper, 2.0, true)
		for cell in mark.cells:
			var center := _lane_center(cell, mark.lane, forward)
			if language == "ribbons": _ribbon_cell(board, center, forward, paper)
			else:
				_hand(board, center, forward, 0.26, 0.60, paper, true)
				# A small impression line beyond the fingers reinforces direction
				# without connecting neighboring cells into a path.
				var right := Vector2(forward.y, -forward.x)
				_stroke(board, [center + forward * 0.46 - right * 0.06,
					center + forward * 0.49, center + forward * 0.46 + right * 0.06], paper, 1.4)
			_badge(board, center - forward * 0.32, mark.source, emphasized)
