extends RefCounted
## Pure display formatting. Legality, affected geometry and outcomes belong to the model.

const INK := Color("202e2b")
const SECONDARY := Color("4a5d56")
const GROUND := Color("dce3da")
const FLOOR := Color("f2f4ec")
const GRID := Color("bac6b9")
const DANGER := Color("a83b2a")
const BORROWED := Color("00675f")
const EXIT := Color("7a5d00")
const WALL := Color("63756b")

const NAMES := {
	"V1": "Action cost", "V2": "Adjacent capture", "V3": "Two-action expiry",
	"V4": "Source linked", "V5": "Delayed backlash", "V6": "Fixed target",
}
const RULES := {
	"V1": "Capture uses your action. One stored plan; no expiry. Discard uses an action.",
	"V2": "Capture beside the source, with an optional one-cell approach. Both happen in one action.",
	"V3": "Release by the second action after capture, or the stored plan expires harmlessly.",
	"V4": "The stored plan is lost if its source dies before release. Keep the source in view.",
	"V5": "Capture is free once per turn. Release by the second action after capture, or take 1 damage. Discard also deals 1 damage.",
	"V6": "Choose the release cell when you capture. It stays fixed, even after you move.",
}

static func cell(pos: Array) -> String:
	if pos.size() != 2:
		return "none"
	return "(%d, %d)" % [pos[0], pos[1]]

static func actor(id: String) -> String:
	return "You" if id == "player" else id.to_upper()

static func event_text(event: Dictionary) -> String:
	var who := actor(str(event.get("actor", "")))
	var source := str(event.get("source", "")).to_upper()
	match event.get("type", ""):
		"move": return "%s moved to %s." % [who, cell(event.to)]
		"capture": return "%s's %s captured; this attack canceled." % [source, event.kind]
		"release":
			var effect := "pull" if event.get("invert", false) else str(event.kind)
			return "Released %s toward %s." % [effect, cell(event.target)]
		"discard": return "Discarded %s's stored plan." % source
		"ray": return "%s resolved %s across %d cells." % [who, event.kind, event.cells.size()]
		"damage": return "%s took %d damage; %d HP left." % [who, event.amount, event.hp]
		"displace": return "%s displaced to %s." % [who, cell(event.to)]
		"death": return "%s fell." % who
		"slot_lost":
			return "Stored plan lost: source %s died." % source if event.reason == "source_dead" else "Stored plan expired."
		"backlash": return "%s backlash: %d direct damage; no displacement." % [event.kind.capitalize(), event.amount]
		"turn": return "Turn %d · Fresh enemy intentions." % event.number
		"win": return "Escaped through the open exit."
		"loss": return "Caught. Your health reached zero."
	return str(event.get("type", ""))

static func stored_text(state: Dictionary) -> String:
	var stored: Dictionary = state.get("stored", {})
	if stored.is_empty():
		return "Empty\nCapture an announced plan to hold it here."
	var lines: Array[String] = ["%s · Source %s" % [str(stored.kind).capitalize(), str(stored.source).to_upper()]]
	lines.append("Bolt: 1 damage." if stored.kind == "bolt" else "Shove: 1 damage, then push one cell.")
	match state.variant:
		"V3":
			var count := maxi(0, 2 - int(stored.actions_elapsed))
			lines.append("%d %s left before expiry." % [count, "action" if count == 1 else "actions"])
		"V5":
			var count := maxi(0, 2 - int(stored.actions_elapsed))
			lines.append("%d %s left before 1 damage backlash.\nDiscard: 1 damage now." % [count, "action" if count == 1 else "actions"])
		"V4": lines.append("Linked to source %s's survival." % str(stored.source).to_upper())
		"V6": lines.append("Fixed release cell: %s." % cell(stored.target))
		_: lines.append("No expiry. Discard uses your action.")
	if stored.captured_turn == state.turn:
		lines.append("Release available on a later turn, not this turn.")
	return "\n".join(lines)

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	for type in ["Label", "Button", "CheckButton", "RichTextLabel"]:
		theme.set_color("font_color", type, INK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = FLOOR
		box.set_content_margin_all(9)
		box.border_color = GRID
		box.set_border_width_all(1)
		if state == "hover": box.bg_color = Color("cbd7cc")
		if state == "pressed": box.bg_color = INK
		if state == "disabled": box.bg_color = GROUND
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = INK
			box.set_border_width_all(3)
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", FLOOR)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", SECONDARY)
	theme.set_constant("separation", "VBoxContainer", 8)
	theme.set_constant("separation", "HBoxContainer", 10)
	var surface := StyleBoxFlat.new()
	surface.bg_color = FLOOR
	surface.set_content_margin_all(8)
	theme.set_stylebox("panel", "TabContainer", surface)
	theme.set_stylebox("panel", "AcceptDialog", surface)
	for tab_state in ["tab_selected", "tab_unselected", "tab_hovered", "tab_focus"]:
		var tab := StyleBoxFlat.new()
		tab.bg_color = FLOOR if tab_state == "tab_selected" else GROUND
		tab.set_content_margin_all(8)
		if tab_state == "tab_focus":
			tab.bg_color = Color.TRANSPARENT
			tab.border_color = INK
			tab.set_border_width_all(2)
		theme.set_stylebox(tab_state, "TabContainer", tab)
	for color in ["font_selected_color", "font_unselected_color", "font_hovered_color", "font_focus_color"]:
		theme.set_color(color, "TabContainer", INK)
	return theme
