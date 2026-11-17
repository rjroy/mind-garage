extends Node2D
## Bounded two-source performance. Positions are theatrical, never map bearings.
## All time and outcomes come from the shared controller and pure descriptor.

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
const BASELINES := {"A": Vector2(105, 145), "B": Vector2(180, 145)}
const HINGES := {"A": Vector2(171, 96), "B": Vector2(119, 87)}
const POSITIONS := {"A": Vector2(0.30, 0.45), "B": Vector2(0.80, 0.45)}
var _textures: Dictionary = {}
var _bodies: Dictionary = {}
var _hands: Dictionary = {}
var _player: Sprite2D
var _caption: Label
var _glow: Shader
var _generation := -1
var _prior_sources: Dictionary = {}
var _lines: Array = []
var _labels: Array = []

func _sprite(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return sprite

func configure_assets(textures: Dictionary) -> bool:
	for child in get_children(): child.free()
	_bodies.clear()
	_hands.clear()
	_textures.clear()
	for key in ["a_body", "a_hands", "b_body", "b_hands", "p_lantern"]:
		if not textures.get(key) is Texture2D: return false
		var canvas := Vector2(145, 145) if key == "p_lantern" else Vector2(290, 145)
		if textures[key].get_size() != canvas: return false
	_textures = textures.duplicate()
	_glow = Shader.new()
	_glow.code = GLOW
	for id in ["A", "B"]:
		_bodies[id] = _sprite(_textures[id.to_lower() + "_body"])
		add_child(_bodies[id])
	_player = _sprite(_textures.p_lantern)
	add_child(_player)
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.z_index = 1 # Text above the floor; puppet artwork remains behind it.
	_caption.add_theme_font_size_override("font_size", 13)
	_caption.add_theme_color_override("font_color", Color("ead4ab"))
	add_child(_caption)
	_generation = -1
	return true

func _clear_hands() -> void:
	for node in _hands.values(): node.free()
	_hands.clear()
	_lines.clear()
	_labels.clear()

func _key(occurrence: Dictionary) -> String:
	return "%s/%d/%s" % [occurrence.source, occurrence.turn, occurrence.kind]

func _hand(occurrence: Dictionary) -> Node2D:
	var key := _key(occurrence)
	if not _hands.has(key):
		var node := Node2D.new()
		var texture: Texture2D = _textures[str(occurrence.source).to_lower() + "_hands"]
		var halo := _sprite(texture)
		halo.name = "Glow"
		halo.position = -HINGES[occurrence.source]
		var material := ShaderMaterial.new()
		material.shader = _glow
		halo.material = material
		node.add_child(halo)
		var art := _sprite(texture)
		art.name = "Art"
		art.position = -HINGES[occurrence.source]
		node.add_child(art)
		add_child(node)
		_hands[key] = node
	return _hands[key]

func _pose(occurrence: Dictionary, role: String, position: Vector2, scale_factor: float,
	phase: float, mirror: float = 1.0, angle: float = 0.0) -> void:
	var node := _hand(occurrence)
	node.transform = Transform2D(angle, Vector2(mirror, 1) * scale_factor, 0.0, position)
	node.visible = true
	var halo: Sprite2D = node.get_node("Glow")
	halo.visible = role in ["transfer", "held", "shine"]
	halo.material.set_shader_parameter("tint", Color("b6e6ce"))
	halo.material.set_shader_parameter("strength", 0.72 + sin(phase * TAU) * 0.10)

func _travel(from: Vector2, to: Vector2, progress: float, scale_factor: float) -> Vector2:
	var t := smoothstep(0.08, 0.90, progress)
	return from.lerp(to, t) - Vector2(0, sin(t * PI) * 30 * scale_factor)

func _victims(cue: Dictionary) -> Array:
	var result: Array = []
	for event in cue.get("events", []):
		if event.type in ["damage", "displace", "death"] and event.get("actor", "") not in result:
			result.append(event.actor)
	return result

func present(description: Dictionary, rect: Rect2) -> void:
	if _textures.is_empty(): return
	if description.is_empty():
		_clear_hands()
		visible = false
		return
	visible = true
	var generation: int = description.generation
	if generation < _generation: return
	if generation != _generation:
		_clear_hands()
		_prior_sources.clear()
		_generation = generation
	_lines.clear()
	_labels.clear()
	var scale_factor := rect.size.y * 0.24 / 145.0
	var phase: float = description.loop_phase
	var sources: Dictionary = description.sources
	var cue: Dictionary = description.current_cue
	var transfer: Dictionary = description.transfer
	var held: Dictionary = description.held_occurrence
	var progress: float = cue.get("progress", 0.0)
	var p_origin := rect.position + rect.size * Vector2(0.57, 0.45) - Vector2(56, 145) * scale_factor
	var handle := p_origin + Vector2(105, 60) * scale_factor
	# Above/beside the lantern handle keeps held hands separate from B's inward
	# rehearsal. The luminous tether, not physical lamp decoration, owns the link.
	var destination := p_origin + Vector2(151, 25) * scale_factor
	_player.position = p_origin
	_player.scale = Vector2.ONE * scale_factor
	_player.modulate = Color.WHITE
	var victims := _victims(cue)
	if "player" in victims:
		# No player reaction merely because an enemy acts. Zero-damage recorded
		# damage/displacement still qualifies; no new outcome is computed here.
		_player.position.x += sin(progress * TAU) * sin(progress * PI) * 4 * scale_factor
		_player.modulate = Color(1, 0.78, 0.66) if progress > 0.35 and progress < 0.75 else Color.WHITE
	var wanted: Array[String] = []
	var any_threat := false
	for id in ["A", "B"]:
		var row: Dictionary = sources.get(id, {})
		var occurrence: Dictionary = row.get("occurrence", {})
		var body: Sprite2D = _bodies[id]
		body.position = rect.position + rect.size * POSITIONS[id] - BASELINES[id] * scale_factor
		body.scale = Vector2.ONE * scale_factor
		var capturing: bool = not transfer.is_empty() and transfer.occurrence.source == id
		var acting: bool = cue.get("type", "") == "resolve" and cue.get("source", "") == id
		var moving: bool = cue.get("type", "") == "move" and cue.get("actor", "") == id
		body.visible = not occurrence.is_empty() or capturing or acting or moving
		body.modulate = Color("f7d9a3") if row.get("inspected", false) else Color.WHITE
		var anchor: Vector2 = body.position + HINGES[id] * scale_factor
		var threatens: bool = row.get("threatens_player", false)
		any_threat = any_threat or threatens
		var local_phase := fposmod(phase + (0.36 if id == "B" else 0.0), 1.0)
		# During committed resolutions keep the next announcement quiet, rather
		# than showing next-turn attacks on top of this turn's actual outcome.
		if not occurrence.is_empty():
			var press := sin(local_phase * TAU) if threatens else 0.0
			var direction := 1.0 if id == "A" else -1.0
			_pose(occurrence, "rehearsal" if threatens else "watchful", anchor + Vector2(press * direction * 4, 0) * scale_factor,
				scale_factor, local_phase, 1.0, press * 0.023 if threatens else direction * 0.40)
			wanted.append(_key(occurrence))
		if body.visible:
			_labels.append({"at": body.position + Vector2(125, 4) * scale_factor,
				"text": ("◇ A" if id == "A" else "○ B") + (" · watching" if not threatens and not acting and not capturing and not moving else "")})
		if not description.busy and not occurrence.is_empty(): _prior_sources[id] = occurrence.duplicate(true)
	if not transfer.is_empty():
		var occurrence: Dictionary = transfer.occurrence
		var id: String = occurrence.source
		var origin: Vector2 = _bodies[id].position + HINGES[id] * scale_factor
		var t := smoothstep(0.08, 0.90, transfer.progress)
		# B's same physical cutout makes a continuous half-turn about its hinge,
		# so its palms end facing outward rather than threatening the player.
		var angle := -PI * t if id == "B" else -sin(t * PI) * 0.12
		_pose(occurrence, "transfer", _travel(origin, destination, transfer.progress, scale_factor),
			scale_factor * lerpf(1.0, 0.45, t), phase, 1.0, angle)
		wanted.append(_key(occurrence))
		var trail := PackedVector2Array()
		for i in range(18):
			trail.append(_travel(origin, destination, maxf(0, transfer.progress - i * 0.018), scale_factor))
		_lines.append({"points": trail, "color": Color("b6e6ce")})
	if not held.is_empty():
		_pose(held, "held", destination + Vector2(sin(phase * TAU) * 2, 0) * scale_factor,
			scale_factor * 0.45, phase, 1.0, (-PI if held.source == "B" else 0.0) + sin(phase * TAU) * 0.025)
		wanted.append(_key(held))
		_lines.append({"points": PackedVector2Array([handle, destination]), "color": Color("b6e6ce")})
		_labels.append({"at": destination + Vector2(-8, -39) * scale_factor,
			"text": "Held %s · T%d" % [held.source, held.turn]})
	if not cue.is_empty() and cue.type in ["shine", "resolve"]:
		var id: String = cue.source
		var relevant: bool = cue.type != "resolve" or "player" in victims
		var occurrence: Dictionary = held if cue.type == "shine" else _prior_sources.get(id, {})
		if relevant and not occurrence.is_empty() and occurrence.source == id:
			var position := destination
			var angle := -PI if id == "B" else 0.0
			var factor := scale_factor * 0.55
			if cue.type == "resolve":
				position = _bodies[id].position + HINGES[id] * scale_factor
				angle = 0.0
				factor = scale_factor
			var direction := -1.0 if cue.type == "resolve" and id == "B" else 1.0
			position.x += sin(progress * PI) * direction * 28 * scale_factor
			_pose(occurrence, cue.type, position, factor, phase, 1.0, angle)
			wanted.append(_key(occurrence))
		var target_names: Array[String] = []
		for victim in victims: target_names.append("you" if victim == "player" else str(victim))
		var caption: String = ("%s acts" % id) if cue.type == "resolve" else ("You Shine · " + id)
		if not target_names.is_empty(): caption += " → " + ", ".join(target_names)
		else: caption += " · no actor hit"
		_labels.append({"at": rect.position + rect.size * Vector2(0.22, 0.505), "text": caption, "floor": true})
	elif cue.get("type", "") == "move":
		_labels.append({"at": rect.position + rect.size * Vector2(0.22, 0.505),
			"text": "%s repositions" % cue.actor, "floor": true})
	else:
		_labels.append({"at": rect.position + rect.size * Vector2(0.22, 0.505),
			"text": "Rehearsal · if you End turn" if any_threat else "Watching · no current threat to you", "floor": true})
	for key in _hands.keys():
		if key not in wanted:
			_hands[key].free()
			_hands.erase(key)
	for label in _labels:
		if label.get("floor", false):
			_caption.text = label.text
			_caption.position = label.at - Vector2(0, 14)
	queue_redraw()

func _draw() -> void:
	for line in _lines:
		draw_polyline(line.points, Color(line.color, 0.18), 7, true)
		draw_polyline(line.points, Color(line.color, 0.68), 1.5, true)
	for label in _labels:
		if label.get("floor", false): continue
		draw_string(ThemeDB.fallback_font, label.at, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color("382433"))
