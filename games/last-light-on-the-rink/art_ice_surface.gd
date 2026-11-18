extends Node2D

const IcePlane = preload("res://art_plane.gd")
const Ink = preload("res://art_ink.gd")
const SurfaceShader = preload("res://art_ice.gdshader")

var _appearance := ShaderMaterial.new()


func _ready() -> void:
	var plate := Polygon2D.new()
	plate.polygon = IcePlane.outline()
	_appearance.shader = SurfaceShader
	plate.material = _appearance
	plate.z_index = -1
	add_child(plate)


func light(show_lights: float, curtain: float, clock: float) -> void:
	_appearance.set_shader_parameter("show_lights", show_lights)
	_appearance.set_shader_parameter("curtain", curtain)
	_appearance.set_shader_parameter("time", clock)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88659
	for i in range(310):
		var x := rng.randf_range(2, 898)
		var y := rng.randf_range(0, 500)
		var p := Vector2(x, y)
		var length := rng.randf_range(7, 41)
		var axis := Vector2.from_angle(rng.randf_range(-0.96, 0.96))
		var ink := Color("#daeade", rng.randf_range(0.055, 0.17)) if i % 5 != 0 else Color("#3e6287", 0.16)
		var end := (p + axis * length).clamp(Vector2(-18, -7), Vector2(918, 507))
		Ink.line(self, [IcePlane.project(p), IcePlane.project(p.lerp(end, 0.5) + Vector2(0, 1.3)), IcePlane.project(end)], ink, 0.8)
	_paint_crest()
	_frost_edge()


func _paint_crest() -> void:
	var center := Vector2(450, 250)
	var line := Color("#e3e9e0", 0.26)
	var deep := Color("#366a88", 0.25)
	for radius in [39.0, 49.0, 67.0]:
		var ring := PackedVector2Array()
		for index in range(81):
			ring.append(IcePlane.project(center + Vector2.from_angle(index * TAU / 80.0) * radius))
		draw_polyline(ring, line if radius < 60.0 else deep, 1, true)
	for axis in range(8):
		var a := Vector2.from_angle(axis * TAU / 8.0)
		var tangent := Vector2(-a.y, a.x)
		var reach := 35.0 if axis % 2 == 0 else 22.0
		var foot := center + a * 5.0
		var joint := center + a * (reach * 0.56)
		var tip := center + a * reach
		Ink.shape(self, [IcePlane.project(foot), IcePlane.project(joint + tangent * 4.0), IcePlane.project(tip), IcePlane.project(joint - tangent * 4.0)], line)
		if axis % 2 == 0:
			var p := IcePlane.project(center + a * 58)
			Ink.star(self, p, 2.6, line)


func _frost_edge() -> void:
	var edge := IcePlane.outline()
	var ridge := PackedVector2Array()
	var inward := PackedVector2Array()
	var center := IcePlane.project(Vector2(450, 250))
	for point in edge:
		ridge.append(point.lerp(center, 0.015))
		inward.append(point.lerp(center, 0.032))
	ridge.append(ridge[0])
	inward.append(inward[0])
	draw_polyline(ridge, Color("#e0e7e5", 0.43), 2.65, true)
	draw_polyline(inward, Color("#cadfe5", 0.28), 1, true)
