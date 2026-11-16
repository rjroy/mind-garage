extends Node2D
## Disposable one-source study rig. Shared controller progress is the only clock.

const GLOW := """
shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(0.71, 0.90, 0.81, 1.0);
uniform float strength = 0.8;
void fragment() {
	float halo = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			halo += texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * 1.7).a;
		}
	}
	COLOR = vec4(tint.rgb, clamp(halo / 15.0, 0.0, 1.0) * strength);
}
"""
var _textures: Dictionary = {}
var _assembly: Dictionary = {}
var _hands: Dictionary = {}
var _body: Sprite2D
var _player: Sprite2D
var _generation := -1
var _lines: Array = []
var _labels: Array = []
var _glow_shader: Shader

func _clear_hands() -> void:
	for node in _hands.values():
		remove_child(node)
		node.queue_free()
	_hands.clear()
	_lines.clear()
	_labels.clear()

func configure_assets(textures: Dictionary, assembly: Dictionary) -> bool:
	_clear_hands()
	for sprite in [_body, _player]:
		if is_instance_valid(sprite):
			remove_child(sprite)
			sprite.queue_free()
	_body = null
	_player = null
	_textures = {}
	_assembly = {}
	for key in ["a_canvas", "p_canvas", "a_baseline", "a_hinge", "p_baseline", "p_handle", "held_hinge", "a_position", "p_position"]:
		if not assembly.get(key) is Vector2 or not assembly[key].is_finite(): return false
	for key in ["held_scale", "height_fraction"]:
		if not assembly.get(key) is float or not is_finite(assembly[key]) or assembly[key] <= 0: return false
	if assembly.a_canvas.x <= 0 or assembly.a_canvas.y <= 0 or assembly.p_canvas.x <= 0 or assembly.p_canvas.y <= 0: return false
	for key in ["a_body", "a_hands", "p_lantern"]:
		if not textures.get(key) is Texture2D: return false
		var canvas: Vector2 = assembly.p_canvas if key == "p_lantern" else assembly.a_canvas
		if textures[key].get_size() != canvas: return false
	_textures = textures.duplicate()
	_assembly = assembly.duplicate(true)
	_glow_shader = Shader.new()
	_glow_shader.code = GLOW
	_body = _sprite(_textures.a_body)
	_player = _sprite(_textures.p_lantern)
	add_child(_body)
	add_child(_player)
	_body.visible = false
	_generation = -1
	return true

func _sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

func _key(occurrence: Dictionary) -> String:
	return "%s/%d/%s" % [occurrence.source, occurrence.turn, occurrence.kind]

func _hand(occurrence: Dictionary) -> Node2D:
	var key := _key(occurrence)
	if not _hands.has(key):
		var node := Node2D.new()
		node.set_meta("occurrence", occurrence.duplicate(true))
		var halo := _sprite(_textures.a_hands)
		halo.name = "Glow"
		halo.position = -_assembly.a_hinge
		var material := ShaderMaterial.new()
		material.shader = _glow_shader
		halo.material = material
		node.add_child(halo)
		var art := _sprite(_textures.a_hands)
		art.name = "Art"
		art.position = -_assembly.a_hinge
		node.add_child(art)
		add_child(node)
		_hands[key] = node
	return _hands[key]

func _travel(source: Vector2, destination: Vector2, progress: float, scale_factor: float) -> Vector2:
	var travel := smoothstep(0.10, 0.88, progress)
	return source.lerp(destination, travel) - Vector2(0, sin(travel * PI) * scale_factor * 38.0)

func _pose(occurrence: Dictionary, role: String, hinge: Vector2, scale_factor: float, angle: float, phase: float) -> void:
	var node := _hand(occurrence)
	node.set_meta("role", role)
	node.transform = Transform2D(angle, Vector2.ONE * scale_factor, 0.0, hinge)
	var halo: Sprite2D = node.get_node("Glow")
	halo.visible = role != "rehearsal"
	halo.material.set_shader_parameter("strength", 0.68 + sin(phase * TAU) * 0.12)
	node.visible = true

func present(description: Dictionary, stage_rect: Rect2) -> void:
	if _assembly.is_empty(): return
	if description.is_empty():
		_clear_hands()
		_body.visible = false
		queue_redraw()
		return
	var generation: int = description.get("generation", -1)
	if generation < _generation: return
	if generation != _generation:
		_clear_hands()
		_generation = generation
	_lines.clear()
	_labels.clear()
	var scale_factor: float = stage_rect.size.y * _assembly.height_fraction / _assembly.a_canvas.y
	var a_foot: Vector2 = stage_rect.position + stage_rect.size * _assembly.a_position
	var p_foot: Vector2 = stage_rect.position + stage_rect.size * _assembly.p_position
	_body.position = a_foot - _assembly.a_baseline * scale_factor
	_body.scale = Vector2.ONE * scale_factor
	_player.position = p_foot - _assembly.p_baseline * scale_factor
	_player.scale = Vector2.ONE * scale_factor
	_labels.append({"at": _player.position + Vector2(65, 5) * scale_factor, "text": "You"})
	var phase: float = description.get("loop_phase", 0.0)
	var source: Vector2 = _body.position + _assembly.a_hinge * scale_factor
	var destination: Vector2 = _player.position + _assembly.held_hinge * scale_factor
	var handle: Vector2 = _player.position + _assembly.p_handle * scale_factor
	var source_occurrence: Dictionary = description.get("source_occurrence", {})
	var held: Dictionary = description.get("held_occurrence", {})
	var transfer: Dictionary = description.get("transfer", {})
	var wanted: Array[String] = []
	_body.visible = not source_occurrence.is_empty() or not transfer.is_empty()
	_body.modulate.a = 1.0
	if not source_occurrence.is_empty():
		var press := sin(phase * TAU)
		_pose(source_occurrence, "rehearsal", source + Vector2(press * 3, 0) * scale_factor,
			scale_factor, press * 0.025, phase)
		wanted.append(_key(source_occurrence))
		_labels.append({"at": _body.position + Vector2(134, 5) * scale_factor, "text": str(source_occurrence.source).to_upper()})
	if not transfer.is_empty():
		var progress: float = transfer.progress
		var key: Dictionary = transfer.occurrence
		var hinge := _travel(source, destination, progress, scale_factor)
		var travel := smoothstep(0.10, 0.88, progress)
		_pose(key, "transfer", hinge, scale_factor * lerpf(1.0, _assembly.held_scale, travel),
			-sin(progress * PI) * 0.12, phase)
		wanted.append(_key(key))
		_body.modulate.a = 1.0 - smoothstep(0.02, 0.48, progress)
		var trail := PackedVector2Array()
		for i in range(20):
			var prior := maxf(0, progress - float(i) * 0.018)
			var point := _travel(source, destination, prior, scale_factor)
			point.y += sin(float(i) * 0.7 + phase * TAU) * sin(float(i) / 19.0 * PI) * scale_factor * 4
			trail.append(point)
		_lines.append({"points": trail, "alpha": 0.60})
	if not held.is_empty():
		var twitch := sin(phase * TAU)
		var hinge := destination + Vector2(twitch * 2.0, sin(phase * TAU * 2.0) * 0.7) * scale_factor
		_pose(held, "held", hinge, scale_factor * _assembly.held_scale, twitch * 0.028, phase)
		wanted.append(_key(held))
		var tether := PackedVector2Array()
		for i in range(20):
			var t := float(i) / 19.0
			tether.append(handle.lerp(hinge, t) + Vector2(0, sin(t * TAU + phase * TAU) * sin(t * PI) * scale_factor * 4))
		_lines.append({"points": tether, "alpha": 0.42})
		_labels.append({"at": destination + Vector2(4, -42) * scale_factor,
			"text": "Held %s · turn %d" % [str(held.source).to_upper(), held.turn]})
	for key in _hands.keys():
		if key not in wanted:
			var node: Node2D = _hands[key]
			remove_child(node)
			node.queue_free()
			_hands.erase(key)
	queue_redraw()

func _draw() -> void:
	for line in _lines:
		draw_polyline(line.points, Color(0.71, 0.91, 0.81, line.alpha * 0.22), 7, true)
		draw_polyline(line.points, Color(0.71, 0.91, 0.81, line.alpha), 1.5, true)
	for label in _labels:
		draw_string(ThemeDB.fallback_font, label.at, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("25443b"))

func hand_instances() -> Array:
	var rows: Array = []
	for node in _hands.values():
		var art: Sprite2D = node.get_node("Art")
		rows.append({"occurrence": node.get_meta("occurrence").duplicate(true), "role": node.get_meta("role"),
			"transform": art.global_transform, "visible": art.is_visible_in_tree(), "instance_id": node.get_instance_id()})
	return rows
