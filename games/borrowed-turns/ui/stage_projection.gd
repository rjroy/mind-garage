extends RefCounted
## One plane homography shared by drawing, material sampling and hit conversion.

var columns := 0
var rows := 0
var _forward := PackedFloat64Array()
var _inverse := PackedFloat64Array()

func configure(new_columns: int, new_rows: int, quad: PackedVector2Array) -> bool:
	columns = 0
	rows = 0
	_forward.clear()
	_inverse.clear()
	if new_columns <= 0 or new_rows <= 0 or quad.size() != 4: return false
	var orientation := 0.0
	for i in range(4):
		if not quad[i].is_finite(): return false
		var cross := (quad[(i + 1) % 4] - quad[i]).cross(quad[(i + 2) % 4] - quad[(i + 1) % 4])
		if absf(cross) < 0.000001: return false
		if i == 0: orientation = signf(cross)
		elif signf(cross) != orientation: return false
	var p := quad[0]
	var q := quad[1]
	var r := quad[2]
	var s := quad[3]
	var delta := p - q + r - s
	var g := 0.0
	var h := 0.0
	if delta.length_squared() > 0.000000000001:
		var one := q - r
		var two := s - r
		var denominator := one.cross(two)
		if absf(denominator) < 0.000001: return false
		g = delta.cross(two) / denominator
		h = one.cross(delta) / denominator
	var a := q.x - p.x + g * q.x
	var b := s.x - p.x + h * s.x
	var c := float(p.x)
	var d := q.y - p.y + g * q.y
	var e := s.y - p.y + h * s.y
	var f := float(p.y)
	var determinant := a * (e - f * h) - b * (d - f * g) + c * (d * h - e * g)
	if not is_finite(determinant) or absf(determinant) < 0.000000001: return false
	_forward = PackedFloat64Array([a, b, c, d, e, f, g, h, 1.0])
	_inverse = PackedFloat64Array([e - f * h, c * h - b, b * f - c * e,
		f * g - d, a - c * g, c * d - a * f,
		d * h - e * g, b * g - a * h, a * e - b * d])
	for i in range(9):
		_inverse[i] /= determinant
		if not is_finite(_inverse[i]):
			_forward.clear()
			_inverse.clear()
			return false
	columns = new_columns
	rows = new_rows
	return true

func _apply(matrix: PackedFloat64Array, point: Vector2) -> Vector2:
	if matrix.is_empty(): return Vector2.ZERO
	var divisor := matrix[6] * point.x + matrix[7] * point.y + matrix[8]
	if absf(divisor) < 0.000000000001: return Vector2.ZERO
	return Vector2((matrix[0] * point.x + matrix[1] * point.y + matrix[2]) / divisor,
		(matrix[3] * point.x + matrix[4] * point.y + matrix[5]) / divisor)

func project(grid: Vector2) -> Vector2:
	if columns == 0 or rows == 0: return Vector2.ZERO
	return _apply(_forward, grid / Vector2(columns, rows))

func unproject(pixel: Vector2) -> Vector2:
	return _apply(_inverse, pixel) * Vector2(columns, rows)

func cell_at(pixel: Vector2) -> Array:
	if columns == 0 or rows == 0 or not pixel.is_finite(): return []
	var logical := unproject(pixel)
	# Remove round-off at exact seams, without swallowing a meaningful outside gap.
	if absf(logical.x - roundf(logical.x)) < 0.000001: logical.x = roundf(logical.x)
	if absf(logical.y - roundf(logical.y)) < 0.000001: logical.y = roundf(logical.y)
	if not logical.is_finite() or logical.x < 0 or logical.y < 0 or logical.x >= columns or logical.y >= rows: return []
	return [int(floorf(logical.x)), int(floorf(logical.y))]

func cell_polygon(cell: Array) -> PackedVector2Array:
	if columns == 0 or rows == 0 or cell.size() != 2: return PackedVector2Array()
	var x := int(cell[0])
	var y := int(cell[1])
	if x < 0 or y < 0 or x >= columns or y >= rows: return PackedVector2Array()
	return PackedVector2Array([project(Vector2(x, y)), project(Vector2(x + 1, y)),
		project(Vector2(x + 1, y + 1)), project(Vector2(x, y + 1))])

func inverse_coefficients() -> PackedFloat64Array:
	# The actual floor shader consumes the same inverse, not a second derivation.
	return _inverse.duplicate()
