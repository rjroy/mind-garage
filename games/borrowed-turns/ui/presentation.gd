extends RefCounted
## Display formatting only. Geometry, budgets and consequences belong to the model.

const INK := Color("202e2b")
const SECONDARY := Color("4a5d56")
const GROUND := Color("dce3da")
const FLOOR := Color("f2f4ec")
const GRID := Color("bac6b9")
const DANGER := Color("a83b2a")
const BORROWED := Color("00675f")
const EXIT := Color("7a5d00")
const WALL := Color("63756b")

static func cell(pos: Array) -> String:
	return "(%d, %d)" % [pos[0], pos[1]] if pos.size() == 2 else "none"

static func actor(id: String) -> String:
	return "You" if id == "player" else id.to_upper()

static func geometry(ability: Dictionary) -> String:
	return "Area radius %d" % ability.radius if ability.kind == "burst" else "Line"

static func ability_text(ability: Dictionary) -> String:
	return "%s · %d damage\nRange %d · %s%s" % [str(ability.kind).capitalize(), ability.damage, ability.range, geometry(ability), " · Push" if ability.push else ""]

static func event_text(event: Dictionary) -> String:
	var who := actor(str(event.get("actor", "")))
	var source := str(event.get("source", "")).to_upper()
	match event.get("type", ""):
		"move": return "%s moved to %s." % [who, cell(event.to)]
		"capture": return "Acquired %s from %s; this attack canceled." % [event.kind, source]
		"capture_failed":
			return "Capture failed: %s %s. Slot ends empty." % [source, "died" if event.reason == "source_dead" else "moved out of reach"]
		"release": return "Released %s toward %s." % ["pull" if event.get("invert", false) else str(event.kind), cell(event.target)]
		"backlash": return "Backlash · %s from %s discharges where you stand." % [str(event.kind).capitalize(), source]
		"ray", "area": return "%s · %s footprint: %d cells." % [who, event.type, event.cells.size()]
		"damage": return "%s took %d damage; %d HP left." % [who, event.amount, event.hp]
		"displace": return "%s displaced to %s." % [who, cell(event.to)]
		"death": return "%s fell." % who
		"turn": return "Turn %d · AP and MP refreshed; fresh intentions." % event.number
		"win": return "Escaped through the open exit."
		"loss": return "Caught. Your health reached zero."
	return str(event.get("type", ""))

static func preview_text(predicted: Dictionary) -> String:
	if predicted.is_empty(): return "Choose a legal command to inspect its exact ordered effects. Previewing never advances play."
	var lines: Array[String] = ["Command preview · exact order"]
	for event in predicted.events: lines.append(event_text(event))
	return "\n".join(lines)

static func deadline(state: Dictionary) -> String:
	if state.stored.is_empty(): return "Move and act in any order. End turn when ready."
	var due: int = state.stored.deadline_turn
	return "Release before ending turn %d%s" % [due, " · Backlash when you End turn" if state.turn >= due else ""]

static func stored_text(state: Dictionary) -> String:
	if state.stored.is_empty(): return "Empty\nCapture a nearby announced ability. Release can happen this turn."
	var stored: Dictionary = state.stored
	var ability: Dictionary = stored.ability
	var effect := "Area centered on you" if ability.kind == "burst" else "You + the stored source-direction line"
	return "%s · %d damage · Source %s\n%s\nBacklash here: %s; %d damage%s.\nRelease avoids you; backlash does not." % [
		str(ability.kind).capitalize(), ability.damage, str(stored.source).to_upper(), ability_text(ability).get_slice("\n", 1), effect, ability.damage,
		", pushes surviving enemies" if ability.push else "",
	]

static func command_summary(current: Dictionary, predicted: Dictionary, action: Dictionary) -> String:
	var kind: String = action.type
	var cost: String = {"move": "Move · 1 MP", "capture": "Capture · free", "release": "Release · 1 AP", "end_turn": "End turn"}[kind]
	var end := "%d AP · %d MP · %d HP · %s" % [predicted.action_points, predicted.movement_points, predicted.player.hp, cell(predicted.player.pos)]
	if kind == "end_turn": cost += " · Leaving %d AP / %d MP" % [current.action_points, current.movement_points]
	var outcomes: Array[String] = []
	if predicted.status == "lost":
		outcomes.append("This discharge kills you. No new ability is acquired." if kind == "capture" else "This command kills you.")
	elif predicted.status == "won": outcomes.append("You escape.")
	else:
		for event in predicted.events:
			if event.type == "capture_failed": outcomes.append(event_text(event))
		if kind == "capture" and not current.stored.is_empty() and not predicted.stored.is_empty():
			var hits: Array[String] = []
			for event in predicted.events:
				if event.type == "damage": hits.append("%s -%d HP" % [actor(event.actor), event.amount])
			outcomes.append("%s; acquired %s." % [", ".join(hits), predicted.stored.ability.kind])
		if kind == "end_turn" and not current.stored.is_empty() and current.turn >= current.stored.deadline_turn:
			outcomes.append("Held %s discharges before enemies." % current.stored.ability.kind)
	return "%s → %s\n%s" % [cost, end, " ".join(outcomes) if not outcomes.is_empty() else "Exact effects: Preview tab. The live board has not changed."]

static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	for type in ["Label", "Button", "CheckButton", "RichTextLabel"]: theme.set_color("font_color", type, INK)
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
	for color in ["font_selected_color", "font_unselected_color", "font_hovered_color", "font_focus_color"]: theme.set_color(color, "TabContainer", INK)
	return theme
