extends RefCounted

## The ice fans out toward the near boards. The distortion keeps both axes
## monotonic and the whole sheet in frame, including when skating the edges.
static func project(point: Vector2) -> Vector2:
	var depth := point.y / 500.0
	return Vector2(
		576.0 + (point.x - 450.0) * lerpf(0.83, 1.13, depth) + lerpf(18.0, -18.0, depth),
		289.0 + 315.0 * depth + 20.0 * depth * depth
	)


static func direction(point: Vector2, heading: float) -> Vector2:
	return (project(point + Vector2.from_angle(heading) * 5.0) - project(point)).normalized()


static func outline() -> PackedVector2Array:
	# Fillets sit outside the playable rectangle; no legal blade position is hidden.
	var points := PackedVector2Array()
	var centers := [Vector2(1, 7), Vector2(899, 7), Vector2(899, 493), Vector2(1, 493)]
	for corner in range(4):
		for step in range(13):
			var angle := PI + float(corner) * PI * 0.5 + float(step) * PI / 24.0
			points.append(project(centers[corner] + Vector2(cos(angle) * 33.0, sin(angle) * 29.0)))
	return points
