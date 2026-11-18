extends Node2D

const Ink = preload("res://art_ink.gd")
const SNOW := Color("#fff0d5")
const MUTED := Color("#c1d1df")
const AMBER := Color("#ffcd90")
const NIGHT := Color("#17263e")
# Let the full cast straighten up before offering another skate.
const GOOD_NIGHT_AT := 4.0

var _display := SystemFont.new()
var _body := SystemFont.new()
var _state: Dictionary = {}
var _last_cue := 0.0


func _ready() -> void:
	_display.font_names = PackedStringArray(["Noto Serif Display", "Baskerville", "Georgia", "DejaVu Serif", "serif"])
	_display.font_weight = 540
	_body.font_names = PackedStringArray(["Noto Sans", "Avenir Next", "Segoe UI", "DejaVu Sans", "sans-serif"])
	_body.font_weight = 520


func present(state: Dictionary, last_cue: float) -> void:
	_state = state
	_last_cue = last_cue
	queue_redraw()


func _draw() -> void:
	var phase := String(_state.get("phase", "opening"))
	var t := float(_state.get("phase_time", 0.0))
	var good_night := float(_state.get("bow_time", -1.0)) >= GOOD_NIGHT_AT
	var paused := bool(_state.get("paused", false))
	var grooves: Array = _state.get("grooves", [])
	var active: PackedVector2Array = _state.get("active_line", PackedVector2Array())
	var riding := bool(_state.get("riding", false))
	var muted := bool(_state.get("muted", false))
	_heading(phase, t, good_night)
	_footer(phase, t, grooves.size(), bool(_state.get("carving", active.size() > 1)), riding, muted, good_night)
	if paused:
		_pause(muted)


func _heading(phase: String, t: float, good_night: bool) -> void:
	var title := "Last Light on the Rink"
	var subtitle := "The ice is yours."
	var font_size := 55
	match phase:
		"opening":
			if t > 12.0:
				subtitle = ""
		"rehearsal":
			title = "Rehearsal"
			subtitle = "Two skaters join you on the ice." if t < 10.0 else ""
			font_size = 50
		"finale":
			title = "The Closing Show"
			subtitle = "One last skate before the lights go out." if t < 8.0 else ""
			font_size = 50
		"bow":
			title = "Good Night, Skaters" if good_night else "Take a Bow"
			subtitle = "Thanks for skating." if good_night else ""
			font_size = 52
	var base := Vector2(47, 82)
	_type(title, base, font_size, SNOW, _display, 2)
	if not subtitle.is_empty():
		_type(subtitle, base + Vector2(3, 30), 18, MUTED, _body, 1)
	_chapters(phase)


func _chapters(phase: String) -> void:
	var phases := ["opening", "rehearsal", "finale"]
	var labels := ["Open ice", "Rehearsal", "Finale"]
	var selected := phases.find(phase)
	if selected < 0:
		selected = 2
	var x := 833.0
	for i in range(phases.size()):
		var live := i == selected
		var color := AMBER if live else Color("#c2b6c9")
		var start := Vector2(x, 38)
		draw_line(start, start + Vector2(72, 0), Color(color, 0.95 if live else 0.45), 2.0 if live else 1.0, true)
		_type(labels[i], start + Vector2(0, 23), 15, SNOW if live else MUTED, _body, 1)
		x += 91.0


func _footer(phase: String, t: float, grooves: int, carving: bool, riding: bool, muted: bool, good_night: bool) -> void:
	var y := 688.0
	var x := 43.0
	if phase == "bow":
		if not good_night:
			return
		x = _control(x, y, "R", "Skate again", true)
		_control(x + 16, y, "Esc", "Pause")
		return
	x = _control(x, y, "WASD", " / ", false, 53.0, true)
	x = _arrows(x, y)
	_type("Skate", Vector2(x + 8, y + 19), 15, SNOW)
	x = _control(x + 60, y, "Space", "Hold to carve", carving, 56.0)
	if phase != "opening" or grooves > 0:
		x = _control(x + 11, y, "E", "Cue skater", _last_cue > 0.0)
	_control(849, y, "M", "Unmute" if muted else "Mute")
	_control(950, y, "Esc", "Pause")
	_control(1043, y, "R", "Restart")

	var tip := ""
	if riding:
		tip = "Riding a groove. Steer away to leave it."
	elif _last_cue > 0.0:
		tip = "Cue received. Watch the skater pick up your cut."
	elif phase == "opening":
		if t < 2.0:
			tip = "Push off and take a lap."
		elif grooves == 0:
			tip = "Hold Space through a turn, then let go to leave a groove."
		elif t < 26.0:
			tip = "Glide across a groove at a shallow angle to ride it."
	elif phase == "rehearsal":
		if t < 12.0 or grooves == 0:
			tip = "Cut a groove, then press E to cue a skater onto it." if grooves == 0 else "Press E to send a skater onto your latest groove."
	elif phase == "finale":
		if t >= 44.0:
			tip = "One last glide to centre ice."
		elif t < 8.0:
			tip = "Cue the others onto your cuts and skate with them."
	if not tip.is_empty():
		var width := _body.get_string_size(tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var p := Vector2(576 - width * 0.5, 654)
		draw_rect(Rect2(p - Vector2(12, 19), Vector2(width + 24, 28)), Color("#19283d", 0.94))
		draw_line(p + Vector2(-12, -19), p + Vector2(width + 12, -19), Color("#d1bcab", 0.29), 1.0, true)
		_type(tip, p, 16, AMBER if riding else SNOW)


func _pause(muted: bool) -> void:
	draw_rect(Rect2(0, 0, 1152, 720), Color("#0c172d", 0.65))
	draw_rect(Rect2(376, 246, 400, 213), Color("#192840"))
	draw_line(Vector2(376, 246), Vector2(776, 246), AMBER, 2.0, true)
	var title := "Paused"
	var width := _display.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	_type(title, Vector2(576 - width * 0.5, 325), 48, SNOW, _display)
	_control(435, 357, "Esc", "Resume", true)
	_control(588, 357, "M", "Unmute" if muted else "Mute")
	_control(435, 396, "R", "Restart")


func _control(x: float, y: float, key: String, label: String, lit: bool = false, cap: float = 0.0, plain: bool = false) -> float:
	var width := maxf(cap, _body.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16.0)
	_key_rect(Rect2(x, y, width, 25), lit)
	var key_width := _body.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_type(key, Vector2(x + (width - key_width) * 0.5, y + 17.1), 13, NIGHT if lit else SNOW)
	var label_width := _body.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	_type(label, Vector2(x + width + (5 if plain else 8), y + 18.4), 15, MUTED if plain else SNOW)
	return x + width + label_width + (10 if plain else 8)


func _arrows(x: float, y: float) -> float:
	_key_rect(Rect2(x, y, 53, 25), false)
	for i in range(4):
		var p := Vector2(x + 8.5 + i * 12.0, y + 12.5)
		var tip := Vector2.LEFT.rotated(i * PI * 0.5)
		var side := tip.orthogonal()
		Ink.line(self, [p - tip * 2.5 + side * 2.6, p + tip * 2, p - tip * 2.5 - side * 2.6], MUTED, 1.12)
	return x + 53


func _key_rect(rect: Rect2, lit: bool) -> void:
	draw_rect(rect, AMBER if lit else Color("#283c54"))
	draw_rect(rect, Color("#b4bac4", 0.49), false, 1.0)


func _type(text: String, at: Vector2, size: int, color: Color, face: Font = null, shadow: int = 0) -> void:
	var use_face: Font = face if face != null else _body
	if shadow > 0:
		draw_string_outline(use_face, at + Vector2(1, 1.7), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow, Color("#202340", 0.75))
	draw_string(use_face, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
