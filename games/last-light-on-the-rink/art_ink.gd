extends RefCounted

static func shape(node: Node2D, points: Array, color: Color) -> void:
	node.draw_colored_polygon(PackedVector2Array(points), color)


static func line(node: Node2D, points: Array, color: Color, width: float = 1.0) -> void:
	node.draw_polyline(PackedVector2Array(points), color, width, true)


static func ellipse(node: Node2D, center: Vector2, radius: Vector2, color: Color) -> void:
	var vertices := PackedVector2Array()
	for index in range(32):
		vertices.append(center + Vector2.from_angle(index * TAU / 32.0) * radius)
	node.draw_colored_polygon(vertices, color)


static func glow(node: Node2D, center: Vector2, radius: Vector2, color: Color) -> void:
	var rim := Color(color, 0.0)
	for index in range(24):
		var angle := index * TAU / 24.0
		var a := Vector2.from_angle(angle) * radius
		var b := Vector2.from_angle(angle + TAU / 24.0) * radius
		node.draw_polygon(
			PackedVector2Array([center, center + a * 0.45, center + a, center + b, center + b * 0.45]),
			PackedColorArray([color, Color(color, color.a * 0.26), rim, rim, Color(color, color.a * 0.26)])
		)


static func star(node: Node2D, point: Vector2, radius: float, color: Color) -> void:
	shape(node, [
		point + Vector2(0, -radius), point + Vector2(radius * 0.18, -radius * 0.16),
		point + Vector2(radius * 0.75, 0), point + Vector2(radius * 0.18, radius * 0.16),
		point + Vector2(0, radius), point + Vector2(-radius * 0.18, radius * 0.16),
		point + Vector2(-radius * 0.75, 0), point + Vector2(-radius * 0.18, -radius * 0.16)
	], color)
