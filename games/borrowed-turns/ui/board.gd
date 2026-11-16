extends Control
## Draws model-owned footprints. Only screen/cell conversion lives here.

signal cell_selected(cell: Array)
signal cell_inspected(cell: Array)
signal cancel_requested

const P = preload("res://ui/presentation.gd")
const ShadowRenderer = preload("res://ui/shadow_renderer.gd")
const PaperCells = preload("res://ui/paper_cells.gd")
const StageProjection = preload("res://ui/stage_projection.gd")
const StageRenderer = preload("res://ui/stage_renderer.gd")
const BoardInk = preload("res://ui/board_ink.gd")
var shadow_renderer = ShadowRenderer.new()
var paper_cells = PaperCells.new()
var stage_projection = StageProjection.new()
var stage_renderer: RefCounted
var visual_seed := 731
var _projection_size := Vector2(-1, -1)
var _projection_dimensions := Vector2i.ZERO
var paper_mode := false
var stage_mode := false
var shadow_frame: Dictionary = {}
var state: Dictionary = {}
var preview: Dictionary = {}
var candidates: Array = []
var selected: Array = []
var source := ""
var cursor := [1, 3]
var hover_cell: Array = []
var last_events: Array = []
var accent := 0.0
var pulse_tween: Tween
var theatre_mode := false
var _standee_textures: Dictionary = {}
var _standee_images: Dictionary = {}
var _standee_assembly: Dictionary = {}
var _focused_actor := ""
var _hover_actor := ""
var _motion_before: Dictionary = {}
var _telegraph := "current"
var _contour := "current"
var board_ink = BoardInk.new()

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(294, 294)
	resized.connect(_on_resized)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_exited.connect(func(): hover_cell = []; _hover_actor = ""; queue_redraw())
	gui_input.connect(_on_gui_input)
	_sync_stage()

func _on_resized() -> void:
	_sync_stage()
	queue_redraw()

func set_view(snapshot: Dictionary, predicted: Dictionary, legal_cells: Array, target: Array, selected_source: String) -> void:
	state = snapshot
	preview = predicted
	candidates = legal_cells
	selected = target
	source = selected_source
	_sync_stage()
	queue_redraw()

func set_presentation(paper: bool, frame: Dictionary) -> void:
	paper_mode = paper
	shadow_frame = frame
	if not frame.get("busy", false) and accent <= 0.0: _motion_before.clear()
	queue_redraw()

func set_stage_mode(enabled: bool) -> void:
	if stage_mode == enabled: return
	stage_mode = enabled
	clip_contents = enabled
	_sync_stage()
	queue_redraw()

func set_board_comparison(telegraph: String, contour: String) -> bool:
	if telegraph not in ["current", "ribbons", "stamps"] or contour not in ["current", "black", "rim"]:
		return false
	_telegraph = telegraph
	_contour = contour
	queue_redraw()
	return true

func board_comparison() -> Dictionary:
	return {"telegraph": _telegraph, "contour": _contour}

func announcement_marks() -> Array:
	if not stage_mode or not theatre_mode or state.is_empty(): return []
	var marks: Array = []
	for intent in state.get("intentions", []):
		if intent.source not in ["A", "B"] or intent.kind != "shove": continue
		for enemy in state.get("enemies", []):
			if enemy.id != intent.source or enemy.get("hp", 0) <= 0: continue
			marks.append({"source": intent.source, "turn": state.turn, "kind": intent.kind,
				"origin": enemy.pos.duplicate(), "direction": enemy.dir.duplicate(),
				"cells": intent.cells.duplicate(true), "lane": 0 if intent.source == "A" else 1})
			break
	return marks

func _uses_board_ink() -> bool:
	return stage_mode and theatre_mode and not _standee_textures.is_empty() and _telegraph != "current"

func configure_standees(textures: Dictionary, assembly: Dictionary) -> bool:
	board_ink.clear_contours()
	_standee_textures.clear()
	_standee_images.clear()
	_standee_assembly.clear()
	_focused_actor = ""
	_hover_actor = ""
	_projection_size = Vector2(-1, -1)
	for id in ["player", "A", "B"]:
		var meta: Dictionary = assembly.get(id, {})
		var texture = textures.get(id)
		if not texture is Texture2D or not meta.get("canvas") is Vector2 or not meta.get("foot") is Vector2 \
			or not meta.get("height_fraction") is float:
			_sync_stage()
			return false
		var canvas: Vector2 = meta.canvas
		var foot: Vector2 = meta.foot
		if not canvas.is_finite() or canvas.x <= 0 or canvas.y <= 0 or texture.get_size() != canvas \
			or not foot.is_finite() or foot.x < 0 or foot.y < 0 or foot.x > canvas.x or foot.y > canvas.y \
			or not is_finite(meta.height_fraction) or meta.height_fraction <= 0:
			_sync_stage()
			return false
	var images := {}
	for id in ["player", "A", "B"]:
		var image: Image = textures[id].get_image()
		if image == null or image.is_empty(): return false
		if image.is_compressed() and image.decompress() != OK: return false
		images[id] = image
	_standee_textures = textures.duplicate()
	_standee_images = images
	_standee_assembly = assembly.duplicate(true)
	_sync_stage()
	queue_redraw()
	return true

func show_transition(before: Dictionary) -> void:
	_motion_before = before.duplicate(true) if theatre_mode else {}

func _visual_actors() -> Array:
	var actors: Dictionary = {}
	if state.is_empty(): return []
	actors.player = {"actor": "player", "cell": state.player.pos.duplicate(), "hp": state.player.hp}
	for enemy in state.enemies:
		actors[enemy.id] = {"actor": enemy.id, "cell": enemy.pos.duplicate(), "hp": enemy.hp}
	for row in actors.values(): row["grid"] = Vector2(row.cell[0] + 0.5, row.cell[1] + 0.5)
	if not _motion_before.is_empty():
		var cue: Dictionary = shadow_frame.get("cue", {})
		var events: Array = state.get("events", [])
		var positions := {"player": _motion_before.player.pos}
		var old: Dictionary = {"player": _motion_before.player}
		for enemy in _motion_before.enemies:
			positions[enemy.id] = enemy.pos
			old[enemy.id] = enemy
		var end := events.size()
		var start: int = cue.get("event_index", -1)
		for planned in shadow_frame.get("cues", []):
			if planned.event_index > start: end = mini(end, planned.event_index)
		var progress: float = cue.get("progress", clampf((1.0 - accent) / 0.88, 0.0, 1.0))
		var alive := positions.keys()
		for i in range(events.size()):
			if not cue.is_empty() and i >= end: break
			var event: Dictionary = events[i]
			var amount := smoothstep(0.18, 0.80, progress) if i >= start else 1.0
			if event.type in ["move", "displace"]:
				var from := Vector2(event.from[0], event.from[1])
				var to := Vector2(event.to[0], event.to[1])
				positions[event.actor] = from.lerp(to, amount)
			if event.type == "death" and amount >= 1.0: alive.erase(event.actor)
		for id in old:
			if id not in alive:
				actors.erase(id)
				continue
			if not actors.has(id):
				actors[id] = {"actor": id, "cell": old[id].pos.duplicate(), "hp": old[id].hp}
			var pos = positions[id]
			actors[id]["grid"] = Vector2(pos[0] + 0.5, pos[1] + 0.5)
	return actors.values()

func standee_layout() -> Array:
	if not stage_mode or _standee_textures.is_empty() or state.is_empty(): return []
	var rows: Array = []
	var projection = _ensure_projection()
	for actor in _visual_actors():
		var id: String = actor.actor
		if not _standee_textures.has(id): continue
		var meta: Dictionary = _standee_assembly[id]
		var factor: float = _stage_rect().size.y * meta.height_fraction / meta.canvas.y
		var foot: Vector2 = projection.project(actor.grid)
		var rect := Rect2(foot - meta.foot * factor, meta.canvas * factor)
		rows.append({"actor": id, "cell": actor.cell.duplicate(), "rect": rect, "foot": foot,
			"tab_rect": Rect2(foot + Vector2(-31, -2), Vector2(62, 21)), "opacity": 1.0,
			"texture": _standee_textures[id], "hp": actor.hp})
	rows.sort_custom(func(a: Dictionary, b: Dictionary): return a.foot.y < b.foot.y)
	var focus: String = _hover_actor if not _hover_actor.is_empty() else _focused_actor
	var focus_index := -1
	for i in range(rows.size()):
		if rows[i].actor == focus: focus_index = i
	if focus_index >= 0:
		for i in range(focus_index + 1, rows.size()):
			if rows[i].rect.intersects(rows[focus_index].rect): rows[i].opacity = 0.32
	return rows

func actor_at(local_pixel: Vector2) -> String:
	var rows := standee_layout()
	for row in rows:
		if row.tab_rect.has_point(local_pixel): return row.actor
	rows.reverse()
	for row in rows:
		var rect: Rect2 = row.rect
		if not rect.has_point(local_pixel): continue
		var image: Image = _standee_images[row.actor]
		var uv := (local_pixel - rect.position) / rect.size
		var pixel := Vector2i(uv * Vector2(image.get_size()))
		if image.get_pixel(pixel.x, pixel.y).a >= 0.1: return row.actor
	return ""

func pick_cell(local_pixel: Vector2) -> Array:
	var id := actor_at(local_pixel)
	if not id.is_empty():
		for row in standee_layout():
			if row.actor == id: return row.cell.duplicate()
	return _from_pixel(local_pixel)

func _input_cell(local_pixel: Vector2, floor_only: bool = false) -> Array:
	var floor_cell := _from_pixel(local_pixel)
	if floor_only: return floor_cell
	var picked := pick_cell(local_pixel)
	# Tall art must not make a legal floor destination inaccessible behind an
	# actor that is not itself a legal target for the current operation.
	if not candidates.is_empty() and picked not in candidates and floor_cell in candidates:
		return floor_cell
	return picked

func focus_actor(actor: String) -> void:
	if actor.is_empty():
		_focused_actor = ""
		queue_redraw()
		return
	for row in standee_layout():
		if row.actor == actor:
			_focused_actor = actor
			cursor = row.cell.duplicate()
			cell_inspected.emit(cursor)
			queue_redraw()
			return

func _stage_rect() -> Rect2:
	var extent := Vector2(1672, 941)
	var scale_factor := maxf(0.0, minf(size.x / extent.x, size.y / extent.y))
	extent *= scale_factor
	return Rect2((size - extent) / 2.0, extent)

func _ensure_projection():
	var dimensions := Vector2i(state.get("width", 0), state.get("height", 0))
	if _projection_size != size or _projection_dimensions != dimensions:
		_projection_size = size
		_projection_dimensions = dimensions
		var rect := _stage_rect()
		var quad := PackedVector2Array()
		var points := [Vector2(0.25, 0.46), Vector2(0.75, 0.46), Vector2(0.77, 0.885), Vector2(0.20, 0.885)]
		if not _standee_textures.is_empty():
			points = [Vector2(0.23, 0.54), Vector2(0.77, 0.54), Vector2(0.79, 0.90), Vector2(0.20, 0.90)]
		for point in points:
			quad.append(rect.position + point * rect.size)
		stage_projection.configure(dimensions.x, dimensions.y, quad)
	return stage_projection

func _sync_stage() -> void:
	if not is_inside_tree(): return
	if not stage_mode:
		if stage_renderer: stage_renderer.set_visible(false)
		return
	if state.is_empty(): return
	if stage_renderer == null:
		stage_renderer = StageRenderer.new()
		stage_renderer.attach(self)
	var projection = _ensure_projection()
	stage_renderer.configure(_stage_rect(), Vector2i(state.width, state.height), projection, piece_appearance, visual_seed,
		0.33 if not _standee_textures.is_empty() else 0.06)
	stage_renderer.set_visible(true)

func pulse(events: Array) -> void:
	clear_pulse()
	last_events = events
	accent = 1.0
	pulse_tween = create_tween()
	pulse_tween.tween_property(self, "accent", 0.0, 0.18)
	pulse_tween.finished.connect(func(): last_events = []; queue_redraw())

func clear_pulse() -> void:
	if pulse_tween and pulse_tween.is_valid(): pulse_tween.kill()
	last_events = []
	accent = 0.0
	_motion_before.clear()
	queue_redraw()

func _process(_delta: float) -> void:
	if accent > 0.0:
		queue_redraw()

func _cell_size() -> float:
	if state.is_empty(): return 1.0
	if stage_mode: return float(figure_layout(state.player.pos)["size"])
	return floor(minf(64.0, minf((size.x - 52) / state.width, (size.y - 42) / state.height)))

func _board_rect() -> Rect2:
	if stage_mode:
		var projection = _ensure_projection()
		var rect := Rect2(projection.project(Vector2.ZERO), Vector2.ZERO)
		for corner in [Vector2(state.get("width", 0), 0), Vector2(state.get("width", 0), state.get("height", 0)), Vector2(0, state.get("height", 0))]:
			rect = rect.expand(projection.project(corner))
		return rect
	var extent := Vector2(float(state.get("width", 7)), float(state.get("height", 7))) * _cell_size()
	return Rect2((size - extent) / 2.0 + Vector2(10, 6), extent)

func cell_center(cell: Array) -> Vector2:
	if stage_mode: return _ensure_projection().project(Vector2(cell[0] + 0.5, cell[1] + 0.5))
	return _board_rect().position + (Vector2(cell[0], cell[1]) + Vector2(0.5, 0.5)) * _cell_size()

func cell_polygon(cell: Array) -> PackedVector2Array:
	if state.is_empty() or cell.size() != 2: return PackedVector2Array()
	if stage_mode: return _ensure_projection().cell_polygon(cell)
	var rect := Rect2(cell_center(cell) - Vector2.ONE * _cell_size() / 2, Vector2.ONE * _cell_size())
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)])

func _cell_rect(cell: Array) -> Rect2:
	var polygon := cell_polygon(cell)
	if polygon.is_empty(): return Rect2()
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon: rect = rect.expand(point)
	return rect

func piece_appearance(cell: Array) -> Dictionary:
	return paper_cells.sample(cell, visual_seed)

func figure_layout(cell: Array) -> Dictionary:
	if state.is_empty() or cell.size() != 2:
		return {"origin": Vector2.ZERO, "foot": Vector2.ZERO, "size": 0.0}
	var origin := cell_center(cell)
	if stage_mode:
		var polygon := cell_polygon(cell)
		if polygon.size() != 4: return {"origin": origin, "foot": origin, "size": 0.0}
		var extent := (polygon[0].distance_to(polygon[1]) + polygon[3].distance_to(polygon[2])) * 0.26
		return {"origin": origin - Vector2(0, extent * 0.40), "foot": origin, "size": extent}
	var figure_size := _cell_size()
	return {"origin": origin, "foot": origin + Vector2(0, 0.40 * figure_size), "size": figure_size}

func _from_pixel(pixel: Vector2) -> Array:
	if stage_mode: return _ensure_projection().cell_at(pixel)
	if state.is_empty() or not _board_rect().has_point(pixel): return []
	var position_in_grid := (pixel - _board_rect().position) / _cell_size()
	return [int(position_in_grid.x), int(position_in_grid.y)]

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var actor := actor_at(event.position)
		if actor != _hover_actor:
			_hover_actor = actor
			queue_redraw()
		var cell := _input_cell(event.position, event.alt_pressed)
		if cell != hover_cell:
			hover_cell = cell
			if not cell.is_empty(): cell_inspected.emit(cell)
			queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_requested.emit()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _input_cell(event.position, event.alt_pressed)
			if not cell.is_empty():
				cursor = cell.duplicate()
				grab_focus()
				cell_selected.emit(cell)
				queue_redraw()
			accept_event()
	if event is InputEventKey and event.pressed and not event.echo and not state.is_empty():
		if event.keycode in [KEY_BRACKETLEFT, KEY_BRACKETRIGHT] and not standee_layout().is_empty():
			var rows := standee_layout()
			var index := -1
			for i in range(rows.size()):
				if rows[i].cell == cursor: index = i
			index = posmod(index + (1 if event.keycode == KEY_BRACKETRIGHT else -1), rows.size())
			focus_actor(rows[index].actor)
			accept_event()
			return
		var step := Vector2i.ZERO
		match event.keycode:
			KEY_LEFT: step.x = -1
			KEY_RIGHT: step.x = 1
			KEY_UP: step.y = -1
			KEY_DOWN: step.y = 1
			KEY_ENTER, KEY_KP_ENTER:
				cell_selected.emit(cursor.duplicate())
				accept_event()
		if step != Vector2i.ZERO:
			_focused_actor = ""
			cursor = [clampi(cursor[0] + step.x, 0, state.width - 1), clampi(cursor[1] + step.y, 0, state.height - 1)]
			cell_inspected.emit(cursor)
			queue_redraw()
			accept_event()

func _text(at: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _danger() -> Color:
	return Color("ffac89") if stage_mode else P.DANGER

func _borrowed() -> Color:
	return Color("9de8d5") if stage_mode else P.BORROWED

func _tile(cell: Array, inset: float, color: Color, filled: bool = false, width: float = 1.0) -> void:
	if not stage_mode:
		if filled: draw_rect(_cell_rect(cell).grow(-inset), color)
		else: draw_rect(_cell_rect(cell).grow(-inset), color, false, width)
		return
	var polygon := cell_polygon(cell)
	if polygon.is_empty(): return
	var center := cell_center(cell)
	for i in range(polygon.size()): polygon[i] = polygon[i].move_toward(center, inset)
	if filled: draw_colored_polygon(polygon, color)
	else:
		polygon.append(polygon[0])
		draw_polyline(polygon, color, width, true)

func _arrow(from: Vector2, to: Vector2, color: Color, dashed: bool) -> void:
	if from.is_equal_approx(to): return
	if dashed: draw_dashed_line(from, to, color, 2.0, 6.0)
	else: draw_line(from, to, color, 3.0, true)
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([to, to - direction * 9 + side * 5, to - direction * 9 - side * 5]), color)

func _uses_shadow_effects() -> bool:
	return paper_mode and preview.is_empty() and not shadow_frame.get("cues", []).is_empty()

func effect_footprints() -> Array:
	if _uses_shadow_effects():
		var cue: Dictionary = shadow_frame.get("cue", {})
		if cue.is_empty() or cue.type == "capture": return []
		return [{"type": cue.footprint_type, "actor": cue.source if cue.type == "resolve" else "player",
			"stage": "enemy" if cue.type == "resolve" else cue.type, "cells": cue.cells.duplicate(true)}]
	var effects: Array = preview.get("events", []) if not preview.is_empty() else last_events
	var footprints: Array = []
	var stage := "enemy"
	for event in effects:
		if event.type in ["release", "backlash"]: stage = event.type
		if event.type in ["ray", "area"]:
			footprints.append({"type": event.type, "actor": event.actor,
				"stage": stage if event.actor == "player" else "enemy", "cells": event.cells.duplicate(true)})
	return footprints

func _draw_effect_footprint(footprint: Dictionary, active_shadow: bool = false) -> void:
	var color := _borrowed() if footprint.actor == "player" and footprint.stage == "release" else _danger()
	for cell in footprint.cells:
		_tile(cell, 7, color, false, 2)
		if active_shadow and footprint.stage == "backlash":
			_tile(cell, 10, color, false, 1)
	if footprint.type == "ray" and footprint.actor == "player" and footprint.stage == "release" and not footprint.cells.is_empty():
		_arrow(cell_center(state.player.pos), cell_center(footprint.cells.back()), _borrowed(), false)

func _draw_backlash_and_choices() -> void:
	var backlash: Dictionary = state.get("backlash_footprint", {})
	if not backlash.is_empty():
		for cell in backlash.cells:
			_tile(cell, 2, _danger(), false, 2)
			_tile(cell, 5, _danger(), false, 1)
	for cell in candidates:
		var tile := _cell_rect(cell).grow(-5)
		_tile(cell, 5, _borrowed(), false, 1.5)
		draw_circle(cell_center(cell) + Vector2(-5, 0) if stage_mode else tile.position + Vector2(5, 5), 2, _borrowed())

func _draw_enemy(enemy: Dictionary, stored: Dictionary) -> void:
	var placement := figure_layout(enemy.pos)
	var origin: Vector2 = placement.origin
	var figure_size: float = placement["size"]
	var pawn := Rect2(origin - Vector2.ONE * figure_size * 0.23, Vector2.ONE * figure_size * 0.46)
	if stage_mode:
		pawn.position = placement.foot - Vector2(figure_size * 0.23, figure_size * 0.46)
	if paper_mode and enemy.kind == "shove":
		shadow_renderer.draw_figure(self, origin, figure_size, false)
		_text(origin + Vector2(-4, 4), str(enemy.id).left(1).to_upper(), P.INK, 12)
	else:
		draw_rect(pawn, Color("efe8d5") if stage_mode else P.INK)
		_text(pawn.position + Vector2(5, pawn.size.y - 5), str(enemy.id).to_upper(), P.INK if stage_mode else P.FLOOR, 14 if stage_mode else 16)
	var hp_at := origin + Vector2(-figure_size * 0.23, -figure_size * (0.42 if paper_mode and enemy.kind == "shove" else 0.23) - 4)
	# Side labels avoid piling an HP tag on the standee in the preceding row.
	if stage_mode: hp_at = placement.foot + Vector2(figure_size * 0.33, -figure_size * 0.16)
	if paper_mode:
		var text_width := ThemeDB.fallback_font.get_string_size("%d HP" % enemy.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2(hp_at - Vector2(1, 12), Vector2(text_width + 2, 14)), P.FLOOR)
	_text(hp_at, "%d HP" % enemy.hp, P.INK, 12)
	if enemy.id == source or (not stored.is_empty() and enemy.id == stored.source):
		draw_rect(pawn.grow(5), _borrowed(), false, 2)

func _draw_player() -> void:
	var placement := figure_layout(state.player.pos)
	var player: Vector2 = placement.origin
	var player_size: float = placement["size"]
	if paper_mode:
		shadow_renderer.draw_figure(self, player, player_size, true)
		_text(player + Vector2(-4, 4), "Y", P.INK, 12)
	else:
		draw_circle(player, player_size * 0.20, P.INK)
		_text(player + Vector2(-5, 5), "Y", P.FLOOR, 14)
	var diamond := player + Vector2(player_size * 0.30, -player_size * 0.20)
	draw_polyline(PackedVector2Array([diamond + Vector2(0, -5), diamond + Vector2(5, 0), diamond + Vector2(0, 5), diamond + Vector2(-5, 0), diamond + Vector2(0, -5)]), _borrowed(), 2, true)

func _draw_standees() -> void:
	var rows := standee_layout()
	for row in rows:
		if theatre_mode and _contour != "current":
			board_ink.draw_contour(self, row, _standee_images[row.actor], _contour)
		var emphasized: bool = row.actor in [source, _focused_actor, _hover_actor]
		if emphasized:
			for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				draw_texture_rect(row.texture, Rect2(row.rect.position + offset, row.rect.size), false, Color(0.66, 0.94, 0.83, row.opacity))
		draw_texture_rect(row.texture, row.rect, false, Color(1, 1, 1, row.opacity))
	if _uses_board_ink():
		board_ink.draw_announcements(self, announcement_marks(), _telegraph)
		# Command consequences stay above the new paper marks, but below source
		# tabs. This is the same exact footprint/event path as the baseline.
		_draw_backlash_and_choices()
		for footprint in effect_footprints(): _draw_effect_footprint(footprint, _uses_shadow_effects())
		var effects: Array = preview.get("events", []) if not preview.is_empty() else last_events
		for event in effects:
			if event.type in ["move", "displace"]:
				_arrow(cell_center(event.from), cell_center(event.to), _borrowed(), false)
	# Source markers are deliberately above every tall body, not depth-occluded.
	for row in rows:
		var tab: Rect2 = row.tab_rect
		draw_style_box(_tab_style(row.actor == source), tab)
		var mark := tab.position + Vector2(9, 10)
		if row.actor == "A":
			draw_polyline(PackedVector2Array([mark + Vector2(0, -4), mark + Vector2(4, 0), mark + Vector2(0, 4), mark + Vector2(-4, 0), mark + Vector2(0, -4)]), P.INK, 1.3, true)
		elif row.actor == "B": draw_arc(mark, 4, 0, TAU, 16, P.INK, 1.3, true)
		_text(tab.position + Vector2(17 if row.actor != "player" else 5, 15),
			"%s %dHP" % ["P" if row.actor == "player" else row.actor, row.hp], P.INK, 12)

func _tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("b6ebd5") if active else Color("f2ddba")
	style.border_color = Color("714852")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func _draw() -> void:
	if state.is_empty(): return
	var cell_size := _cell_size()
	var rect := _board_rect()
	if not stage_mode: draw_rect(rect, P.FLOOR)
	if paper_mode and not theatre_mode:
		shadow_renderer.draw_shadows(self, state, shadow_frame, cell_center, cell_size, source)
	for x in range(state.width + 1):
		var start := rect.position + Vector2(x * cell_size, 0)
		if stage_mode:
			start = _ensure_projection().project(Vector2(x, 0))
			draw_line(start, _ensure_projection().project(Vector2(x, state.height)), Color("bb887b", 0.55), 1)
			if x < state.width: _text(_ensure_projection().project(Vector2(x + 0.5, 0)) + Vector2(-3, -8), str(x), Color("f0d2a0"), 12)
		else:
			draw_line(start, start + Vector2(0, rect.size.y), P.GRID, 1)
			if x < state.width: _text(start + Vector2(cell_size / 2 - 4, -10), str(x), P.SECONDARY)
	for y in range(state.height + 1):
		var start := rect.position + Vector2(0, y * cell_size)
		if stage_mode:
			start = _ensure_projection().project(Vector2(0, y))
			draw_line(start, _ensure_projection().project(Vector2(state.width, y)), Color("bb887b", 0.55), 1)
			if y < state.height: _text(_ensure_projection().project(Vector2(0, y + 0.5)) + Vector2(-20, 4), str(y), Color("f0d2a0"), 12)
		else:
			draw_line(start, start + Vector2(rect.size.x, 0), P.GRID, 1)
			if y < state.height: _text(start + Vector2(-22, cell_size / 2 + 5), str(y), P.SECONDARY)
	for wall in state.walls: _tile(wall, 3, Color("837077") if stage_mode else P.WALL, true)
	var exit_rect := _cell_rect(state.exit.pos).grow(-5)
	var exit_color := Color("ffe1a0") if stage_mode else P.EXIT
	_tile(state.exit.pos, 5, exit_color, false, 2)
	_tile(state.exit.pos, 9, exit_color, false, 1)
	_text(cell_center(state.exit.pos) + Vector2(-14, 4) if stage_mode else exit_rect.position + Vector2(3, exit_rect.size.y - 6), "EXIT", exit_color, 12)
	var threat_counts := {}
	var ink_sources: Array = []
	if _uses_board_ink():
		for mark in announcement_marks(): ink_sources.append(mark.source)
	for intent in state.get("intentions", []):
		if intent.source in ink_sources and intent.kind == "shove": continue
		for cell in intent.cells:
			var key := str(cell)
			threat_counts[key] = threat_counts.get(key, 0) + 1
			var tile := _cell_rect(cell).grow(-3)
			_tile(cell, 3, Color(_danger(), 0.16 if stage_mode else 0.08), true)
			var hatch := cell_center(cell) + Vector2(-6, -2) if stage_mode else tile.position + Vector2(2, 10)
			if _standee_textures.is_empty() or not stage_mode:
				draw_line(hatch, hatch + Vector2(8, -8), _danger(), 1)
			if intent.source == source: _tile(cell, 3, _danger(), false, 2)
			if threat_counts[key] > 1 and (_standee_textures.is_empty() or not stage_mode):
				_text(tile.position + Vector2(tile.size.x - 14, 14), str(threat_counts[key]), _danger())
		if intent.kind != "burst" and not intent.cells.is_empty() and (_standee_textures.is_empty() or not stage_mode):
			for enemy in state.enemies:
				if enemy.id == intent.source:
					_arrow(cell_center(enemy.pos), cell_center(intent.cells.back()), _danger(), true)
	if not _uses_board_ink(): _draw_backlash_and_choices()
	var stored: Dictionary = state.get("stored", {})
	var effects: Array = preview.get("events", []) if not preview.is_empty() else last_events
	var footprints := effect_footprints()
	var shadow_effects := _uses_shadow_effects()
	if shadow_effects and not _uses_board_ink():
		for footprint in footprints: _draw_effect_footprint(footprint, true)
	var footprint_index := 0
	var effect_positions := {"player": state.player.pos}
	var death_cells: Array = []
	for enemy in state.enemies: effect_positions[enemy.id] = enemy.pos
	for event in effects:
		if not shadow_effects and event.type in ["ray", "area"]:
			var footprint: Dictionary = footprints[footprint_index]
			footprint_index += 1
			if not _uses_board_ink(): _draw_effect_footprint(footprint)
		if event.type == "move" or event.type == "displace":
			if not _uses_board_ink(): _arrow(cell_center(event.from), cell_center(event.to), _borrowed(), false)
			effect_positions[event.actor] = event.to
		if event.type == "death" and effect_positions.has(event.actor): death_cells.append(effect_positions[event.actor])
	var enemies: Array = state.enemies.duplicate()
	if stage_mode: enemies.sort_custom(func(a: Dictionary, b: Dictionary): return cell_center(a.pos).y < cell_center(b.pos).y)
	var player_drawn := false
	if not standee_layout().is_empty():
		_draw_standees()
		# Source-marked warning tabs sit beside, rather than underneath, the tall
		# silhouettes. Every model-authored cell/source remains represented.
		var labels_per_cell := {}
		for intent in state.intentions:
			if intent.source in ink_sources and intent.kind == "shove": continue
			for cell in intent.cells:
				var key := str(cell)
				var index: int = labels_per_cell.get(key, 0)
				labels_per_cell[key] = index + 1
				var tile := _cell_rect(cell)
				var point := tile.position + Vector2(4 + index * 14, 15)
				_text(point, str(intent.source), _danger(), 12)
	else:
		for enemy in enemies:
			if stage_mode and not player_drawn and cell_center(state.player.pos).y <= cell_center(enemy.pos).y:
				_draw_player()
				player_drawn = true
			_draw_enemy(enemy, stored)
		if not player_drawn: _draw_player()
	if not preview.is_empty():
		var ghost := cell_center(preview.player.pos)
		draw_arc(ghost, cell_size * 0.29, 0, TAU, 32, _borrowed(), 2, true)
		for enemy in preview.enemies:
			for current in state.enemies:
				if current.id == enemy.id and current.pos != enemy.pos:
					_tile(enemy.pos, cell_size * 0.23, _borrowed(), false, 2)
		for cell in death_cells:
			var center := cell_center(cell)
			draw_line(center - Vector2(12, 12), center + Vector2(12, 12), _danger(), 3)
			draw_line(center - Vector2(12, -12), center + Vector2(12, -12), _danger(), 3)
	for cell in [hover_cell, selected]:
		if not cell.is_empty(): _tile(cell, 2, _borrowed(), false, 2)
	if has_focus():
		_tile(cursor, 1, Color("ffe5b7") if stage_mode else P.INK, false, 3)
		if not stage_mode: draw_rect(rect.grow(7), P.INK, false, 2)
