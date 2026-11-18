extends RefCounted

const CATCH_WIDTH := 4.5
const CATCH_ALIGNMENT := 0.90
const APPROACH_EPSILON_SQUARED := 0.001
const PROJECTION_EPSILON := 0.001
const MIN_RIDE_DISTANCE := 17.0

var length := 0.0
var _points: PackedVector2Array
var _distances := PackedFloat32Array()
var _bounds: Rect2


func _init(points: PackedVector2Array) -> void:
	_points = points
	_distances.resize(points.size())
	_bounds = Rect2(points[0], Vector2.ZERO)
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
		_distances[i] = length
		_bounds = _bounds.expand(points[i])
	_bounds = _bounds.grow(CATCH_WIDTH)


func points() -> PackedVector2Array:
	return _points.duplicate()


func point_at(distance: float) -> Vector2:
	var segment := _segment_at(distance)
	var fraction := inverse_lerp(_distances[segment], _distances[segment + 1], distance)
	return _points[segment].lerp(_points[segment + 1], clampf(fraction, 0.0, 1.0))


func tangent_at(distance: float, direction: float) -> Vector2:
	var start := point_at(maxf(0.0, distance - 2.5))
	var end := point_at(minf(length, distance + 2.5))
	if start.distance_squared_to(end) < 0.001:
		var segment := _segment_at(distance)
		return _points[segment].direction_to(_points[segment + 1]) * direction
	return start.direction_to(end) * direction


# A candidate stores arc distance, direction along the stroke (+1/-1), and cost.
func catch_near(before: Vector2, after: Vector2, heading: Vector2, best_cost: float) -> Vector3:
	var best := Vector3(0.0, 0.0, best_cost)
	if not _bounds.has_point(after):
		return best
	for i in range(_points.size() - 1):
		var a := _points[i]
		var b := _points[i + 1]
		if after.x < minf(a.x, b.x) - CATCH_WIDTH or after.x > maxf(a.x, b.x) + CATCH_WIDTH:
			continue
		if after.y < minf(a.y, b.y) - CATCH_WIDTH or after.y > maxf(a.y, b.y) + CATCH_WIDTH:
			continue
		var edge := b - a
		var edge_length := edge.length()
		if edge_length <= PROJECTION_EPSILON:
			continue
		var tangent := edge / edge_length
		var alignment := tangent.dot(heading)
		if absf(alignment) < CATCH_ALIGNMENT:
			continue
		var offset := after - a
		var projection := tangent.dot(offset)
		var along := clampf(projection, 0.0, edge_length)
		var distance := _distances[i] + along
		var ride_left := length - distance if alignment > 0.0 else distance
		if ride_left < MIN_RIDE_DISTANCE:
			continue
		var closest := a + tangent * along
		var gap := after.distance_squared_to(closest)
		var cost := gap + 12.0 * (1.0 - absf(alignment))
		if gap > CATCH_WIDTH * CATCH_WIDTH or cost >= best.z:
			continue
		# Sliding toward a sample endpoint or another branch is not a
		# lateral approach to this segment.
		var previous_side := tangent.cross(before - a)
		var current_side := tangent.cross(offset)
		var projects_onto_segment := (
			projection >= -PROJECTION_EPSILON and projection <= edge_length + PROJECTION_EPSILON
		)
		var approaching := (
			previous_side * previous_side > current_side * current_side + APPROACH_EPSILON_SQUARED
		)
		# A true crossing can end past an endpoint or farther from the line.
		if not (projects_onto_segment and approaching):
			if Geometry2D.segment_intersects_segment(before, after, a, b) == null:
				continue
		best = Vector3(distance, signf(alignment), cost)
	return best


func _segment_at(distance: float) -> int:
	var low := 0
	var high := _distances.size() - 1
	while high - low > 1:
		var mid := (low + high) >> 1
		if _distances[mid] <= distance:
			low = mid
		else:
			high = mid
	return low
