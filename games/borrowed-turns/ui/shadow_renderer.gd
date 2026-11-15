extends RefCounted
## Runtime paper shapes. Takes screen anchors and model-owned facts, not gameplay rules.

const P = preload("res://ui/presentation.gd")
const PAPER := Color("efe8d5")
const EDGE := Color("b7a889")
const SHADOW := Color("26302f")

func _polygon(canvas: Control, points: Array, origin: Vector2, scale: float, angle: float, color: Color, edge: Color = Color.TRANSPARENT) -> void:
	var transformed := PackedVector2Array()
	for point in points: transformed.append(origin + Vector2(point[0], point[1]).rotated(angle) * scale)
	canvas.draw_colored_polygon(transformed, color)
	if edge.a > 0.0:
		var closed := transformed.duplicate()
		closed.append(transformed[0])
		canvas.draw_polyline(closed, edge, 1.2, true)

func _palm(canvas: Control, origin: Vector2, scale: float, angle: float, alpha: float, binding: Color = Color.TRANSPARENT) -> void:
	# Bent forearm, thumb notch and three blunt fingers keep the pushing hand
	# identifiable without a sprite, particle trail or physically cast shadow.
	_polygon(canvas, [
		[0.0, 0.08], [0.24, 0.04], [0.42, -0.02], [0.52, 0.02],
		[0.57, -0.03], [0.48, -0.18], [0.53, -0.23], [0.65, -0.14],
		[0.65, -0.34], [0.72, -0.36], [0.76, -0.14],
		[0.79, -0.40], [0.86, -0.40], [0.87, -0.13],
		[0.92, -0.33], [0.99, -0.31], [0.97, 0.08],
		[0.88, 0.22], [0.73, 0.26], [0.54, 0.23], [0.40, 0.15],
		[0.25, 0.19], [0.0, 0.24],
	], origin, scale, angle, Color(SHADOW, alpha), Color(binding, binding.a * alpha))
	if binding.a > 0.0:
		var a := origin + Vector2(0.22, 0.05).rotated(angle) * scale
		var b := origin + Vector2(0.25, 0.18).rotated(angle) * scale
		canvas.draw_line(a, b, Color(binding, alpha), 1.2, true)

func draw_figure(canvas: Control, at: Vector2, cell_size: float, player: bool) -> void:
	var s := cell_size
	var body := [[-0.15, -0.19], [0.12, -0.19], [0.18, 0.20], [0.06, 0.28], [-0.20, 0.19]] if player else [[-0.28, -0.17], [0.22, -0.17], [0.29, 0.22], [-0.24, 0.22]]
	_polygon(canvas, body, at, s, 0, PAPER, P.INK)
	_polygon(canvas, [[0.10, -0.15], [0.15, -0.12], [0.18, 0.20], [0.08, 0.25]], at, s, 0, EDGE)
	_polygon(canvas, [[-0.15, 0.18], [-0.02, 0.20], [-0.06, 0.40], [-0.23, 0.40]], at, s, 0, P.INK)
	_polygon(canvas, [[0.04, 0.20], [0.16, 0.18], [0.24, 0.39], [0.07, 0.39]], at, s, 0, P.INK)
	_polygon(canvas, [[-0.11, -0.37], [0.08, -0.38], [0.14, -0.28], [0.06, -0.17], [-0.10, -0.19], [-0.15, -0.28]], at, s, 0, PAPER, P.INK)
	canvas.draw_line(at + Vector2(-0.08, -0.10) * s, at + Vector2(0.10, 0.12) * s, EDGE, 1, true)

func _direction(state: Dictionary, source: String) -> Vector2:
	for enemy in state.enemies:
		if enemy.id == source: return Vector2(enemy.dir[0], enemy.dir[1])
	var held: Dictionary = state.get("stored", {})
	if not held.is_empty() and held.source == source: return Vector2(held.dir[0], held.dir[1])
	return Vector2.RIGHT

func _pending(frame: Dictionary, type: String, source: String = "") -> bool:
	var cue: Dictionary = frame.get("cue", {})
	if cue.is_empty(): return false
	for plan in frame.cues:
		if plan.event_index >= cue.event_index and plan.type == type and (source.is_empty() or plan.source == source): return true
	return false

func _backlash_kills_player(state: Dictionary, cue: Dictionary) -> bool:
	var events: Array = state.get("events", [])
	var start: int = cue.get("event_index", -1)
	if start < 0 or start >= events.size() or events[start].type != "backlash": return false
	var footprint_seen := false
	for i in range(start + 1, events.size()):
		var event: Dictionary = events[i]
		if event.type in ["release", "backlash", "capture", "capture_failed", "turn"]: break
		if event.type in ["ray", "area"]:
			if footprint_seen or event.actor != "player": break
			footprint_seen = true
		if footprint_seen and (event.type == "loss" or (event.type == "death" and event.actor == "player")): return true
	return false

func gesture_endpoint(state: Dictionary, cue: Dictionary) -> Array:
	if cue.is_empty(): return []
	var endpoint: Array = cue.from
	if not cue.to.is_empty(): endpoint = cue.to
	elif not cue.cells.is_empty(): endpoint = cue.cells.back()
	# Only this ability's ordered resolution can make its gesture a lethal self-hit.
	if cue.type == "backlash" and _backlash_kills_player(state, cue): endpoint = cue.from
	return endpoint.duplicate()

func draw_shadows(canvas: Control, state: Dictionary, frame: Dictionary, center: Callable, size: float, selected_source: String) -> void:
	if frame.is_empty(): return
	var loop: float = frame.loop_phase
	for intent in frame.announcements:
		if _pending(frame, "resolve", intent.source): continue
		for enemy in state.enemies:
			if enemy.id != intent.source: continue
			var direction := _direction(state, intent.source)
			var amount := 0.90 + sin(loop * TAU) * 0.07
			_palm(canvas, center.call(enemy.pos) + direction * size * 0.12, size * amount, direction.angle(), 0.90 if intent.source == selected_source else 0.68)
	if not frame.held.is_empty() and not _pending(frame, "capture"):
		var player: Vector2 = center.call(state.player.pos)
		var plate := Rect2(player + Vector2(0.18, -0.65) * size, Vector2(0.55, 0.38) * size)
		canvas.draw_rect(plate, PAPER)
		canvas.draw_rect(plate, P.BORROWED, false, 1.4)
		_palm(canvas, player + Vector2(0.22, -0.40) * size, size * 0.47, -0.08 + sin(loop * TAU) * 0.04, 0.96, P.BORROWED)
	var cue: Dictionary = frame.get("cue", {})
	if cue.is_empty() or cue.kind != "shove" or cue.from.is_empty(): return
	var origin: Vector2 = center.call(cue.from)
	var progress: float = cue.progress
	if cue.type == "capture":
		var destination: Vector2 = center.call(cue.to) + Vector2(0.25, -0.22) * size
		var eased := progress * progress * (3.0 - 2.0 * progress)
		var anchor := origin.lerp(destination, eased) - Vector2(0, sin(progress * PI) * size * 0.42)
		var direction := _direction(state, cue.source)
		_palm(canvas, anchor - direction * size * 0.20, size * lerpf(0.83, 0.38, eased), direction.angle() + sin(progress * PI) * 0.35, 0.95, P.BORROWED)
	else:
		var endpoint: Vector2 = center.call(gesture_endpoint(state, cue))
		var direction := (endpoint - origin).normalized()
		if direction == Vector2.ZERO: direction = _direction(state, cue.source)
		var push := clampf((progress - 0.20) / 0.55, 0.0, 1.0)
		push = 1.0 - pow(1.0 - push, 3.0)
		var tip := origin.lerp(endpoint, push)
		var ink := P.DANGER if cue.type == "backlash" else (P.BORROWED if cue.type == "release" else P.INK)
		_palm(canvas, tip - direction * size * 0.72, size * 0.76, direction.angle(), 0.96 - maxf(0, progress - 0.80) * 3.0, ink)
		if cue.type == "backlash":
			var hit := Rect2(origin - Vector2.ONE * size * 0.29, Vector2.ONE * size * 0.58).grow(sin(progress * PI) * size * 0.10)
			canvas.draw_rect(hit, P.DANGER, false, 2.0)
