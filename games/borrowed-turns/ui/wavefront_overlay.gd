extends RefCounted
## Full affected-cell wash and source-driven curved fronts, below the actors.
## The scene supplies its existing rehearsal phase. No clock or victim inference.

const COOL := Color("b6dcff")
const WARM := Color("ff806a")

static func wave_geometry(region: Dictionary, phase: float) -> Dictionary:
	var contours: Array = region.get("contours", [])
	var result := {"fills": contours.duplicate(true), "fronts": []}
	var origin: Array = region.get("origin", [])
	var direction: Array = region.get("direction", [])
	if contours.is_empty() or origin.size() != 2 or direction.size() != 2 or not is_finite(phase):
		return result
	var forward := Vector2(direction[0], direction[1]).normalized()
	if forward == Vector2.ZERO: return result
	var side := Vector2(forward.y, -forward.x)
	var start := Vector2(origin[0] + 0.5, origin[1] + 0.5).dot(forward)
	var far := -INF
	var left := INF
	var right := -INF
	for contour in contours:
		for point in contour:
			far = maxf(far, point.dot(forward))
			left = minf(left, point.dot(side))
			right = maxf(right, point.dot(side))
	if far <= start or right <= left: return result
	for index in range(2):
		# Source lanes share time, but stagger emissions so opposing fronts do
		# not always meet/blend at the same position. Capture cannot rephase B.
		var progress := fposmod(phase + index * 0.5 + region.get("lane", 0) * 0.25, 1.0)
		var depth := lerpf(start, far, progress)
		var curve := PackedVector2Array()
		for sample in range(25):
			var across := float(sample) / 24.0
			var shoulder := 2.0 * across - 1.0
			# Apex leads in the actual attack direction. Both shoulders trail
			# towards the source; nothing points screen-right or at the player.
			curve.append(forward * (depth - 0.30 * shoulder * shoulder)
				+ side * lerpf(left, right, across))
		var parts: Array = []
		for contour in contours:
			parts.append_array(Geometry2D.intersect_polyline_with_polygon(curve, contour))
		result.fronts.append({"progress": progress, "curves": parts})
	return result

func _project(board, logical: PackedVector2Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	var projection = board._ensure_projection()
	for point in logical: points.append(projection.project(point))
	return points

func draw_regions(board, regions: Array) -> void:
	var ordered := regions.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary): return a.lane < b.lane)
	var scale := clampf(board._stage_rect().size.y / 514.0, 1.0, 1.5)
	# All full-cell washes first: one source's fill must not bury the other's
	# moving fronts. Overlapping cells still carry both source-colored effects.
	for row in ordered:
		var color := COOL if row.source == "A" else WARM
		for fill in row.fills:
			var polygon := _project(board, fill)
			board.draw_colored_polygon(polygon, Color(color, 0.30))
			var edge := polygon.duplicate()
			if not edge.is_empty(): edge.append(edge[0])
			board.draw_polyline(edge, Color(color, 0.70), 1.0, true)
	for row in ordered:
		var color := COOL if row.source == "A" else WARM
		for front in row.fronts:
			for curve in front.curves:
				if curve.size() < 2: continue
				var points := _project(board, curve)
				board.draw_polyline(points, Color(color, 0.20), 4.0 * scale, true)
				board.draw_polyline(points, Color(color, 0.98), 1.8 * scale, true)
