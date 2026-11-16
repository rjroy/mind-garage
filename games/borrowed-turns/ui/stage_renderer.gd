extends RefCounted
## Approved source art and floor materials only. Board owns all tactical drawing.

const FloorShader = preload("res://ui/stage_floor.gdshader")
const SOURCE_SIZE := Vector2(1672, 941)
var backdrop: Sprite2D
var foreground: Sprite2D
var floor_root: Node2D
var floor_texture: Texture2D
var _rect := Rect2()
var _dimensions := Vector2i.ZERO
var _seed := -1
var _loaded := false
var _inverse := PackedFloat64Array()
var _apron_depth := 0.06

func attach(canvas: Control) -> void:
	print("Borrowed Turns stage: loading approved backdrop, floor and foreground sources")
	var rear := load("res://assets/stage/backdrop-paper.png") as Texture2D
	floor_texture = load("res://assets/stage/floor-paper.png") as Texture2D
	var front := load("res://assets/stage/foreground-paper.png") as Texture2D
	if rear == null or floor_texture == null or front == null:
		push_error("Borrowed Turns stage: source texture loading failed; no substitute artwork will be drawn.")
		return
	backdrop = Sprite2D.new()
	backdrop.name = "StageBackdrop"
	backdrop.texture = rear
	backdrop.centered = false
	backdrop.show_behind_parent = true
	canvas.add_child(backdrop)
	floor_root = Node2D.new()
	floor_root.name = "StageFloor"
	floor_root.show_behind_parent = true
	canvas.add_child(floor_root)
	foreground = Sprite2D.new()
	foreground.name = "StageForeground"
	foreground.texture = front
	foreground.centered = false
	canvas.add_child(foreground)
	_loaded = true
	print("Borrowed Turns stage: approved source textures loaded; original alpha preserved")

func set_visible(value: bool) -> void:
	if not _loaded: return
	backdrop.visible = value
	foreground.visible = value
	floor_root.visible = value

func _material(projection, dimensions: Vector2i, origin: Vector2, span: Vector2, piece: Dictionary, apron: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FloorShader
	var inverse: PackedFloat64Array = projection.inverse_coefficients()
	material.set_shader_parameter("inverse_x", Vector3(inverse[0], inverse[1], inverse[2]))
	material.set_shader_parameter("inverse_y", Vector3(inverse[3], inverse[4], inverse[5]))
	material.set_shader_parameter("inverse_w", Vector3(inverse[6], inverse[7], inverse[8]))
	material.set_shader_parameter("board_size", Vector2(dimensions))
	material.set_shader_parameter("cell_origin", origin)
	material.set_shader_parameter("cell_span", span)
	var crop: Rect2 = piece.uv_rect
	material.set_shader_parameter("source_crop", Vector4(crop.position.x, crop.position.y, crop.size.x, crop.size.y))
	material.set_shader_parameter("quarter_turn", piece.quarter_turn)
	material.set_shader_parameter("paper_tint", piece.tint)
	material.set_shader_parameter("apron", apron)
	return material

func _piece(polygon: PackedVector2Array, material: ShaderMaterial) -> void:
	var paper := Polygon2D.new()
	paper.polygon = polygon
	paper.texture = floor_texture
	paper.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	paper.material = material
	floor_root.add_child(paper)

func configure(rect: Rect2, dimensions: Vector2i, projection, sample_piece: Callable, visual_seed: int, apron_depth: float = 0.06) -> void:
	if not _loaded or projection.inverse_coefficients().is_empty(): return
	var inverse: PackedFloat64Array = projection.inverse_coefficients()
	if rect == _rect and dimensions == _dimensions and visual_seed == _seed and inverse == _inverse and apron_depth == _apron_depth: return
	_rect = rect
	_dimensions = dimensions
	_seed = visual_seed
	_inverse = inverse
	_apron_depth = apron_depth
	backdrop.position = rect.position
	foreground.position = rect.position
	backdrop.scale = rect.size / SOURCE_SIZE
	foreground.scale = backdrop.scale
	for child in floor_root.get_children():
		floor_root.remove_child(child)
		child.queue_free()
	# Extend the same plane behind the frame. This apron has no implied cells.
	var origin := Vector2(-dimensions.x * 0.45, -dimensions.y * apron_depth)
	var span := Vector2(dimensions.x * 1.9, dimensions.y * (1.49 + apron_depth))
	var apron := PackedVector2Array([projection.project(origin), projection.project(origin + Vector2(span.x, 0)),
		projection.project(origin + span), projection.project(origin + Vector2(0, span.y))])
	var clip := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var clipped := Geometry2D.intersect_polygons(apron, clip)
	var base := {"uv_rect": Rect2(Vector2.ZERO, Vector2.ONE), "quarter_turn": 0, "tint": Color(0.76, 0.76, 0.76, 1)}
	for polygon in clipped:
		_piece(polygon, _material(projection, dimensions, origin, span, base, true))
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			_piece(projection.cell_polygon([x, y]),
				_material(projection, dimensions, Vector2(x, y), Vector2.ONE, sample_piece.call([x, y]), false))
