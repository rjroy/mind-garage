extends Node2D

const Ink = preload("res://art_ink.gd")
const IcePlane = preload("res://art_plane.gd")
const SNOW := Color("#949bb3")
const GREY_LAVENDER := Color("#525d79")
const ROOF := Color("#29334d")
const DEEP := Color("#172338")
const PINE := Color("#22344a")
const LAMP := Color("#ffe0a3")
const BOARD := Color("#38485d")

var foreground := false
var _rng := RandomNumberGenerator.new()


func _draw() -> void:
	_rng.seed = 62782 if foreground else 4792
	if foreground:
		_near_bank()
	else:
		_stars()
		_distant_ridge()
		_houses()
		_street_and_rink()


func _stars() -> void:
	for i in range(78):
		var p := Vector2(_rng.randf_range(11, 1142), _rng.randf_range(11, 201))
		var a := _rng.randf_range(0.22, 0.76) * lerpf(1.0, 0.21, p.y / 205.0)
		draw_circle(p, _rng.randf_range(0.45, 1.3), Color(LAMP, a), true, -1, true)
		if i in [12, 25, 52]:
			Ink.star(self, p, 3.1, Color("#f4d5cc"))


func _distant_ridge() -> void:
	var first := [Vector2(0, 302), Vector2(0, 213)]
	var second := [Vector2(0, 302), Vector2(0, 233)]
	for x in range(0, 1171, 18):
		var dx := float(x)
		var h := sin(dx / 93.0) * 17.0 + cos(dx / 42.0) * 4.0 + _rng.randf_range(-4, 4)
		first.append(Vector2(dx, 209.0 - h))
		second.append(Vector2(dx, 229.0 - sin(dx / 130.0 + 1.2) * 25.0 - h * 0.32))
	first.append(Vector2(1170, 302))
	second.append(Vector2(1170, 302))
	Ink.shape(self, first, Color("#625973"))
	Ink.shape(self, second, Color("#494761"))
	for x in range(6, 1152, 11):
		var y := 215.0 + sin(x * 0.022) * 8.0
		_fir(Vector2(x, y + _rng.randf_range(0, 15)), _rng.randf_range(10, 42), Color("#494861"), Color("#655c73"))


func _houses() -> void:
	_house(Vector2(50, 226), 104, 79, Color("#53485f"), Color("#39344c"), false, 1)
	_house(Vector2(161, 225), 112, 68, Color("#5d485d"), Color("#43384f"), true, 0)
	_house(Vector2(282, 232), 132, 58, Color("#604c59"), Color("#42394e"), false, 1)
	_house(Vector2(423, 234), 117, 73, Color("#51485e"), Color("#393850"), true, 0)
	_house(Vector2(541, 233), 90, 59, Color("#625265"), Color("#473953"), false, 2)
	_house(Vector2(648, 237), 118, 53, Color("#6a4c5c"), Color("#4d374b"), false, 0)
	_house(Vector2(772, 239), 108, 64, Color("#655169"), Color("#473a54"), true, 0)
	_house(Vector2(885, 237), 92, 50, Color("#785763"), Color("#553e53"), false, 2)
	_house(Vector2(979, 237), 124, 72, Color("#71505f"), Color("#513e55"), true, 0)
	_house(Vector2(1108, 241), 102, 80, Color("#4c495f"), Color("#3e3650"), false, 1)
	for spec in [[11, 232, 72], [39, 234, 59], [168, 237, 49], [392, 235, 52], [520, 238, 57], [646, 239, 37], [778, 244, 55], [892, 244, 63], [1105, 242, 58], [1134, 245, 90]]:
		_fir(Vector2(spec[0], spec[1]), spec[2], PINE.lerp(ROOF, 0.5), GREY_LAVENDER)
	for spec in [[115, 232, 71, -0.08], [326, 237, 91, 0.25], [606, 241, 66, -0.17], [1029, 240, 84, 0.11]]:
		_branch(Vector2(spec[0], spec[1]), spec[2], spec[3] - PI * 0.5, 4, Color("#292e43"))


func _house(base: Vector2, width: float, height: float, front: Color, side: Color, gable: bool, variant: int) -> void:
	var x := base.x
	var y := base.y
	var front_width := width * 0.77
	var eaves := y - height * 0.65
	var top := y - height - (11.0 if gable else 0.0)
	var angle := width * 0.20
	var main := [Vector2(x, y), Vector2(x + front_width, y + 3), Vector2(x + front_width, eaves), Vector2(x, eaves)]
	draw_rect(Rect2(x + front_width * 0.69, top - 6, 7, 21), side)
	draw_rect(Rect2(x + front_width * 0.69 - 1, top - 7, 9, 3), Color("#796782"))
	Ink.shape(self, main, front)
	Ink.shape(self, [main[1], Vector2(x + width, y - 8), Vector2(x + width, eaves - 12), main[2]], side)
	if gable:
		var peak := Vector2(x + front_width * 0.52, top)
		Ink.shape(self, [main[2], main[3], peak], front.lightened(0.044))
		Ink.shape(self, [peak, peak + Vector2(angle, -9), Vector2(x + width + 4, eaves - 11), main[2] + Vector2(5, 0)], ROOF)
		Ink.line(self, [Vector2(x - 6, eaves + 1), peak, peak + Vector2(angle, -9)], SNOW, 3.4)
		Ink.line(self, [peak, Vector2(x + front_width + 5, eaves + 1)], SNOW.darkened(0.15), 3.2)
		_window(peak + Vector2(-5, 16), Vector2(10, 12), variant != 1, true)
	else:
		var ridge := Vector2(x + width * 0.23, top)
		var ridge_end := Vector2(x + width * 0.83, top - 5)
		var lower_left := Vector2(x - 7, eaves + 2)
		var lower_right := Vector2(x + front_width + 5, eaves + 2)
		Ink.shape(self, [lower_left, ridge, ridge_end, lower_right], ROOF.lightened(0.08))
		Ink.shape(self, [lower_right, ridge_end, Vector2(x + width + 4, eaves - 10)], ROOF)
		Ink.shape(self, [lower_left, ridge, ridge_end, ridge_end + Vector2(-5, 7), lower_right + Vector2(-2, -2), lower_left + Vector2(3, -1)], SNOW.darkened(0.12))
		Ink.line(self, [lower_left, lower_right], DEEP, 2.0)
	for row in range(4):
		var board_y := eaves + 10.0 + 9.0 * row
		if board_y < y - 3:
			draw_line(Vector2(x + 1, board_y), Vector2(x + front_width - 1, board_y + 1), Color(side, 0.48), 0.75, true)
	for i in range(3):
		var p := Vector2(x + front_width * (0.18 + i * 0.31) - 5, eaves + 10)
		_window(p, Vector2(12, 16), i != variant or gable, false)
	_window(Vector2(x + width * 0.84, eaves + 6), Vector2(9, 13), variant != 1, false)
	var door := Vector2(x + front_width * 0.55, y - 15)
	draw_rect(Rect2(door, Vector2(12, 17)), DEEP)
	draw_rect(Rect2(door + Vector2(2, 2), Vector2(8, 7)), Color("#c59375"))
	draw_line(Vector2(x + 1, y - 1), Vector2(x + front_width, y + 2), front.lightened(0.17), 1.5, true)


func _window(p: Vector2, size: Vector2, lit: bool, round_top: bool) -> void:
	var center := p + size * 0.5
	var glass := LAMP.lerp(Color("#f3a96a"), _rng.randf_range(0.08, 0.65)) if lit else Color("#303a56")
	if lit:
		Ink.glow(self, center, size * 1.65, Color("#ffb574", 0.30))
	draw_rect(Rect2(p - Vector2(1, 1), size + Vector2(2, 3)), Color("#312a43"))
	draw_rect(Rect2(p, size), glass)
	if round_top:
		draw_circle(p + Vector2(size.x * 0.5, 1), size.x * 0.5, glass, true, -1, true)
	draw_line(p + Vector2(size.x * 0.5, 0), p + Vector2(size.x * 0.5, size.y), Color("#71546a"), 0.9, true)
	draw_line(p + Vector2(0, size.y * 0.46), p + Vector2(size.x, size.y * 0.46), Color("#71546a"), 0.8, true)
	draw_line(p + Vector2(-2, size.y + 1), p + size + Vector2(2, 1), Color("#b4a1ae"), 1.3, true)


func _fir(p: Vector2, height: float, body: Color, rim: Color) -> void:
	Ink.line(self, [p, p + Vector2(2, -height * 0.92)], body.darkened(0.20), maxf(1.0, height * 0.041))
	for level in range(5, -1, -1):
		var y := height * (0.115 + level * 0.132)
		var wide := (level + 1.7) * height * 0.047
		var shift := sin(level * 1.19 + p.x) * height * 0.032
		var high := p + Vector2(shift + 1, -height + y * 0.80)
		var left := p + Vector2(-wide + shift, -height + y + height * 0.19)
		var right := p + Vector2(wide + shift, left.y - p.y - height * 0.04)
		Ink.shape(self, [high, left, left.lerp(right, 0.29) + Vector2(0, -height * 0.037), left.lerp(right, 0.56) + Vector2(0, height * 0.027), right], body)
		Ink.line(self, [left.lerp(high, 0.55), left.lerp(high, 0.26) + Vector2(2, 1), left.lerp(right, 0.39) + Vector2(0, -5)], Color(rim, 0.78), maxf(0.7, height * 0.017))


func _branch(p: Vector2, length: float, a: float, steps: int, color: Color) -> void:
	var tip := p + Vector2.from_angle(a) * length
	if steps == 0:
		draw_line(p, tip, color, 0.9, true)
		return
	var elbow := p.lerp(tip, 0.49) + Vector2(_rng.randf_range(-0.12, 0.12) * length, 0)
	Ink.line(self, [p, elbow, tip], color, float(steps) * 1.33)
	_branch(elbow, length * _rng.randf_range(0.42, 0.59), a - _rng.randf_range(0.31, 0.71), steps - 1, color)
	_branch(tip, length * _rng.randf_range(0.33, 0.52), a + _rng.randf_range(0.22, 0.54), steps - 1, color)
	_branch(p.lerp(tip, 0.72), length * _rng.randf_range(0.25, 0.43), a + _rng.randf_range(0.55, 0.83), steps - 1, color)


func _street_and_rink() -> void:
	Ink.shape(self, [Vector2(0, 235), Vector2(310, 226), Vector2(694, 237), Vector2(1152, 241), Vector2(1152, 720), Vector2(0, 720)], Color("#4a5671"))
	Ink.shape(self, [Vector2(0, 267), Vector2(301, 236), Vector2(626, 242), Vector2(1152, 250), Vector2(1152, 291), Vector2(697, 264), Vector2(258, 257), Vector2(0, 296)], Color("#303c54"))
	Ink.line(self, [Vector2(0, 264), Vector2(303, 235), Vector2(1152, 248)], Color("#888497"), 2.2)
	Ink.line(self, [Vector2(0, 295), Vector2(255, 259), Vector2(690, 266), Vector2(1152, 291)], Color("#71778b"), 3.0)
	for index in range(92):
		var p := Vector2(_rng.randf_range(-20, 1160), _rng.randf_range(252, 700))
		var tint := Color("#a4aaba", _rng.randf_range(0.10, 0.37))
		var size := _rng.randf_range(4, 55)
		Ink.line(self, [p, p + Vector2(size * 0.66, -1.7), p + Vector2(size, -0.5)], tint, _rng.randf_range(0.7, 3.8))
	_bench(Vector2(116, 354), 0.95, 0.34)
	_bench(Vector2(1016, 359), 0.96, -0.25)
	_bench(Vector2(292, 259), 0.72, 0.04)
	_bench(Vector2(827, 260), 0.72, -0.03)
	for spec in [[37, 394, 71], [64, 471, 93], [28, 615, 134], [1142, 448, 93], [1119, 565, 113]]:
		_fir(Vector2(spec[0], spec[1]), spec[2], Color("#263d52"), GREY_LAVENDER)

	var rim := IcePlane.outline()
	var shell := PackedVector2Array()
	for point in rim:
		shell.append(Vector2(575, 422) + (point - Vector2(575, 422)) * Vector2(1.023, 1.040) + Vector2(0, -2))
	draw_colored_polygon(shell, Color("#a3a6b3"))
	var back := PackedVector2Array()
	for i in range(27):
		back.append(rim[i])
	_back_rail(back)

	for i in range(4):
		var p := Vector2(219 + i * 250, 276 + i * 0.6)
		_lantern(p, 104 + float(i % 2) * 10.0, 1.0)
	_string_lights(Vector2(104, 185), Vector2(1065, 166), 27, 48)
	_lantern(Vector2(90, 340), 157, 1.23)
	_lantern(Vector2(1069, 337), 173, 1.35)


func _bench(p: Vector2, size: float, lean: float) -> void:
	var along := Vector2(1.0, lean) * size
	var up := Vector2(0.03, -1.0) * size
	var end := p + along * 59.0
	draw_line(p, p + up * 25, DEEP, size * 3, true)
	draw_line(end, end + up * 25, DEEP, size * 3, true)
	for i in range(3):
		var a := p + up * (25.0 - i * 5.1)
		draw_line(a, a + along * 59.0, Color("#755468").lerp(ROOF, i * 0.18), size * 4.2, true)
	draw_line(p + up * 10.5, end + up * 10.5, board_snow(), size * 2.4, true)


func board_snow() -> Color:
	return Color("#b2b6c3")


func _lantern(p: Vector2, height: float, scale_factor: float) -> void:
	var top := p + Vector2(0, -height)
	Ink.ellipse(self, p + Vector2(3, 3), Vector2(12, 3.8) * scale_factor, Color("#222c42", 0.56))
	Ink.line(self, [p, top + Vector2(0, 11)], DEEP, 4.7 * scale_factor)
	Ink.line(self, [p + Vector2(-1, 0), top + Vector2(-1, 11)], Color("#7c7390"), 0.8)
	Ink.line(self, [p + Vector2(-5, 0), p + Vector2(5, 0)], DEEP, 3.5)
	Ink.glow(self, top, Vector2(49, 57) * scale_factor, Color("#ffc277", 0.50))
	Ink.glow(self, top, Vector2(21, 25) * scale_factor, Color("#ffcf82", 0.64))
	var a := top + Vector2(-5, -9) * scale_factor
	var b := top + Vector2(5, -9) * scale_factor
	var c := top + Vector2(3.5, 7) * scale_factor
	var d := top + Vector2(-3.5, 7) * scale_factor
	Ink.shape(self, [a, b, c, d], LAMP)
	Ink.line(self, [a, b, c, d, a, top + Vector2(0, -14) * scale_factor, b], DEEP, 1.5 * scale_factor)
	draw_line(top + Vector2(0, -8), top + Vector2(0, 6), Color("#d2a275"), 1, true)


func _string_lights(start: Vector2, end: Vector2, count: int, dip: float) -> void:
	var points := PackedVector2Array()
	for i in range(81):
		var t := i / 80.0
		points.append(start.lerp(end, t) + Vector2(0, sin(t * PI) * dip))
	draw_polyline(points, Color("#222539"), 1.35, true)
	for i in range(1, count):
		var t := i / float(count)
		var p := start.lerp(end, t) + Vector2(0, sin(t * PI) * dip + 3.7)
		draw_line(p - Vector2(0, 3.5), p, DEEP, 1.0, true)
		Ink.glow(self, p, Vector2(15, 17), Color("#ffbf71", 0.57))
		draw_circle(p, 2.0, LAMP if i % 3 != 0 else Color("#ffad8a"), true, -1, true)


func _back_rail(points: PackedVector2Array) -> void:
	var deck := PackedVector2Array()
	var top := PackedVector2Array()
	for point in points:
		top.append(point - Vector2(0, 18))
	for point in top:
		deck.append(point)
	for i in range(points.size() - 1, -1, -1):
		deck.append(points[i])
	draw_colored_polygon(deck, BOARD)
	draw_polyline(top, SNOW, 2.5, true)
	for i in range(16):
		var p := IcePlane.project(Vector2(24 + i * 56, -20))
		draw_line(p - Vector2(0, 18), p, Color("#9a9aac"), 2.1, true)


func _near_bank() -> void:
	var rim := IcePlane.outline()
	var top := rim.slice(26)
	for index in range(top.size() - 1):
		var a := top[index]
		var b := top[index + 1]
		if absf(a.x - b.x) > 0.1:
			Ink.shape(self, [a, b, b + Vector2(0, 14), a + Vector2(0, 14)], Color("#27394d"))
	draw_polyline(top, Color("#c5c4cf"), 3.1, true)
	var edge := PackedVector2Array()
	for point in top:
		edge.append(point + Vector2(0, 12))
	draw_polyline(edge, Color("#57647c"), 1.8, true)
	for i in range(19):
		var p := IcePlane.project(Vector2(22 + i * 48, 521))
		draw_line(p + Vector2(0, 2), p + Vector2(0, 14), Color("#647089"), 1.5, true)
	Ink.shape(self, [Vector2(0, 662), Vector2(141, 677), Vector2(361, 675), Vector2(553, 668), Vector2(812, 680), Vector2(1024, 668), Vector2(1152, 646), Vector2(1152, 720), Vector2(0, 720)], Color("#1c2d43"))
	Ink.line(self, [Vector2(0, 663), Vector2(141, 679), Vector2(361, 677), Vector2(553, 670), Vector2(812, 682), Vector2(1024, 670), Vector2(1152, 648)], Color("#45566f"), 2.3)
	_fir(Vector2(18, 724), 175, Color("#182c40"), Color("#54617a"))
	_fir(Vector2(1137, 733), 162, Color("#17293e"), Color("#536079"))
	_branch(Vector2(-21, 504), 78.0, -1.17, 4, Color("#19283b"))
	_branch(Vector2(1171, 516), 104.0, -1.98, 5, Color("#19283b"))
