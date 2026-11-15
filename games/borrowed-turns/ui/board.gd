extends Control
## Draws model-owned footprints. Only screen/cell conversion lives here.

signal cell_selected(cell: Array)
signal cell_inspected(cell: Array)
signal cancel_requested

const P = preload("res://ui/presentation.gd")
const ShadowRenderer = preload("res://ui/shadow_renderer.gd")
var shadow_renderer = ShadowRenderer.new()
var paper_mode := false
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

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(294, 294)
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_exited.connect(func(): hover_cell = []; queue_redraw())
	gui_input.connect(_on_gui_input)

func set_view(snapshot: Dictionary, predicted: Dictionary, legal_cells: Array, target: Array, selected_source: String) -> void:
	state = snapshot
	preview = predicted
	candidates = legal_cells
	selected = target
	source = selected_source
	queue_redraw()

func set_presentation(paper: bool, frame: Dictionary) -> void:
	paper_mode = paper
	shadow_frame = frame
	queue_redraw()

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
	queue_redraw()

func _process(_delta: float) -> void:
	if accent > 0.0:
		queue_redraw()

func _cell_size() -> float:
	if state.is_empty(): return 1.0
	return floor(minf(64.0, minf((size.x - 52) / state.width, (size.y - 42) / state.height)))

func _board_rect() -> Rect2:
	var extent := Vector2(float(state.get("width", 7)), float(state.get("height", 7))) * _cell_size()
	return Rect2((size - extent) / 2.0 + Vector2(10, 6), extent)

func cell_center(cell: Array) -> Vector2:
	return _board_rect().position + (Vector2(cell[0], cell[1]) + Vector2(0.5, 0.5)) * _cell_size()

func _cell_rect(cell: Array) -> Rect2:
	return Rect2(cell_center(cell) - Vector2.ONE * _cell_size() / 2, Vector2.ONE * _cell_size())

func _from_pixel(pixel: Vector2) -> Array:
	if state.is_empty() or not _board_rect().has_point(pixel): return []
	var position_in_grid := (pixel - _board_rect().position) / _cell_size()
	return [int(position_in_grid.x), int(position_in_grid.y)]

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _from_pixel(event.position)
		if cell != hover_cell:
			hover_cell = cell
			if not cell.is_empty(): cell_inspected.emit(cell)
			queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_requested.emit()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _from_pixel(event.position)
			if not cell.is_empty():
				cursor = cell.duplicate()
				grab_focus()
				cell_selected.emit(cell)
				queue_redraw()
			accept_event()
	if event is InputEventKey and event.pressed and not event.echo and not state.is_empty():
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
			cursor = [clampi(cursor[0] + step.x, 0, state.width - 1), clampi(cursor[1] + step.y, 0, state.height - 1)]
			cell_inspected.emit(cursor)
			queue_redraw()
			accept_event()

func _text(at: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
	var color := P.BORROWED if footprint.actor == "player" and footprint.stage == "release" else P.DANGER
	for cell in footprint.cells:
		draw_rect(_cell_rect(cell).grow(-7), color, false, 2)
		if active_shadow and footprint.stage == "backlash":
			draw_rect(_cell_rect(cell).grow(-10), color, false, 1)
	if footprint.type == "ray" and footprint.actor == "player" and footprint.stage == "release" and not footprint.cells.is_empty():
		_arrow(cell_center(state.player.pos), cell_center(footprint.cells.back()), P.BORROWED, false)

func _draw() -> void:
	if state.is_empty(): return
	var cell_size := _cell_size()
	var rect := _board_rect()
	draw_rect(rect, P.FLOOR)
	if paper_mode:
		shadow_renderer.draw_shadows(self, state, shadow_frame, cell_center, cell_size, source)
	for x in range(state.width + 1):
		var start := rect.position + Vector2(x * cell_size, 0)
		draw_line(start, start + Vector2(0, rect.size.y), P.GRID, 1)
		if x < state.width: _text(start + Vector2(cell_size / 2 - 4, -10), str(x), P.SECONDARY)
	for y in range(state.height + 1):
		var start := rect.position + Vector2(0, y * cell_size)
		draw_line(start, start + Vector2(rect.size.x, 0), P.GRID, 1)
		if y < state.height: _text(start + Vector2(-22, cell_size / 2 + 5), str(y), P.SECONDARY)
	for wall in state.walls: draw_rect(_cell_rect(wall).grow(-3), P.WALL)
	var exit_rect := _cell_rect(state.exit.pos).grow(-5)
	draw_rect(exit_rect, P.EXIT, false, 2)
	draw_rect(exit_rect.grow(-4), P.EXIT, false, 1)
	_text(exit_rect.position + Vector2(3, exit_rect.size.y - 6), "EXIT", P.EXIT, 12)
	var threat_counts := {}
	for intent in state.get("intentions", []):
		for cell in intent.cells:
			var key := str(cell)
			threat_counts[key] = threat_counts.get(key, 0) + 1
			var tile := _cell_rect(cell).grow(-3)
			draw_rect(tile, Color(P.DANGER, 0.08))
			draw_line(tile.position + Vector2(2, 10), tile.position + Vector2(10, 2), P.DANGER, 1)
			if intent.source == source: draw_rect(tile, P.DANGER, false, 2)
			if threat_counts[key] > 1: _text(tile.position + Vector2(tile.size.x - 14, 14), str(threat_counts[key]), P.DANGER)
		if intent.kind != "burst" and not intent.cells.is_empty():
			for enemy in state.enemies:
				if enemy.id == intent.source:
					_arrow(cell_center(enemy.pos), cell_center(intent.cells.back()), P.DANGER, true)
	var backlash: Dictionary = state.get("backlash_footprint", {})
	if not backlash.is_empty():
		for cell in backlash.cells:
			draw_rect(_cell_rect(cell).grow(-2), P.DANGER, false, 2)
			draw_rect(_cell_rect(cell).grow(-5), P.DANGER, false, 1)
	for cell in candidates:
		var tile := _cell_rect(cell).grow(-5)
		draw_rect(tile, P.BORROWED, false, 1.5)
		draw_circle(tile.position + Vector2(5, 5), 2, P.BORROWED)
	var stored: Dictionary = state.get("stored", {})
	var effects: Array = preview.get("events", []) if not preview.is_empty() else last_events
	var footprints := effect_footprints()
	var shadow_effects := _uses_shadow_effects()
	if shadow_effects:
		for footprint in footprints: _draw_effect_footprint(footprint, true)
	var footprint_index := 0
	var effect_positions := {"player": state.player.pos}
	var death_cells: Array = []
	for enemy in state.enemies: effect_positions[enemy.id] = enemy.pos
	for event in effects:
		if not shadow_effects and event.type in ["ray", "area"]:
			var footprint: Dictionary = footprints[footprint_index]
			footprint_index += 1
			_draw_effect_footprint(footprint)
		if event.type == "move" or event.type == "displace":
			_arrow(cell_center(event.from), cell_center(event.to), P.BORROWED, false)
			effect_positions[event.actor] = event.to
		if event.type == "death" and effect_positions.has(event.actor): death_cells.append(effect_positions[event.actor])
	for enemy in state.enemies:
		var pawn := Rect2(cell_center(enemy.pos) - Vector2.ONE * cell_size * 0.23, Vector2.ONE * cell_size * 0.46)
		if paper_mode and enemy.kind == "shove":
			shadow_renderer.draw_figure(self, cell_center(enemy.pos), cell_size, false)
			_text(cell_center(enemy.pos) + Vector2(-4, 4), str(enemy.id).left(1).to_upper(), P.INK, 12)
		else:
			draw_rect(pawn, P.INK)
			_text(pawn.position + Vector2(5, pawn.size.y - 5), str(enemy.id).to_upper(), P.FLOOR, 16)
		var hp_at := cell_center(enemy.pos) + Vector2(-cell_size * 0.23, -cell_size * (0.42 if paper_mode and enemy.kind == "shove" else 0.23) - 4)
		if paper_mode:
			var text_width := ThemeDB.fallback_font.get_string_size("%d HP" % enemy.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_rect(Rect2(hp_at - Vector2(1, 12), Vector2(text_width + 2, 14)), P.FLOOR)
		_text(hp_at, "%d HP" % enemy.hp, P.INK, 12)
		if enemy.id == source or (not stored.is_empty() and enemy.id == stored.source):
			draw_rect(pawn.grow(5), P.BORROWED, false, 2)
	var player := cell_center(state.player.pos)
	if paper_mode:
		shadow_renderer.draw_figure(self, player, cell_size, true)
		_text(player + Vector2(-4, 4), "Y", P.INK, 12)
	else:
		draw_circle(player, cell_size * 0.20, P.INK)
		_text(player + Vector2(-5, 5), "Y", P.FLOOR, 14)
	var diamond := player + Vector2(cell_size * 0.30, -cell_size * 0.20)
	draw_polyline(PackedVector2Array([diamond + Vector2(0, -5), diamond + Vector2(5, 0), diamond + Vector2(0, 5), diamond + Vector2(-5, 0), diamond + Vector2(0, -5)]), P.BORROWED, 2, true)
	if not preview.is_empty():
		var ghost := cell_center(preview.player.pos)
		draw_arc(ghost, cell_size * 0.29, 0, TAU, 32, P.BORROWED, 2, true)
		for enemy in preview.enemies:
			for current in state.enemies:
				if current.id == enemy.id and current.pos != enemy.pos:
					draw_rect(_cell_rect(enemy.pos).grow(-cell_size * 0.23), P.BORROWED, false, 2)
		for cell in death_cells:
			var center := cell_center(cell)
			draw_line(center - Vector2(12, 12), center + Vector2(12, 12), P.DANGER, 3)
			draw_line(center - Vector2(12, -12), center + Vector2(12, -12), P.DANGER, 3)
	for cell in [hover_cell, selected]:
		if not cell.is_empty(): draw_rect(_cell_rect(cell).grow(-2), P.BORROWED, false, 2)
	if has_focus():
		draw_rect(_cell_rect(cursor).grow(-1), P.INK, false, 3)
		draw_rect(rect.grow(7), P.INK, false, 2)
