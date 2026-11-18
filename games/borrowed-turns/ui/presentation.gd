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

static func enemy_name(enemy: Dictionary) -> String:
	if not str(enemy.get("name", "")).is_empty(): return str(enemy.name)
	return "Switcher" if enemy.kind == "swap" else "Pursuer " + str(enemy.id).to_upper()

static func geometry(ability: Dictionary) -> String:
	if ability.kind == "swap": return "One occupied target · exchange, then damage"
	if ability.kind == "burst": return "Area radius %d" % ability.radius
	var width: int = ability.get("width", 1)
	return "Line · Width %d" % width if width > 1 else "Line"

static func ability_text(ability: Dictionary) -> String:
	return "%s · %d damage\nRange %d · %s%s" % [str(ability.kind).capitalize(), ability.damage, ability.range, geometry(ability), " · Push" if ability.push else ""]

static func objective_text(state: Dictionary) -> String:
	if state.get("objective", "escape") == "defeat_all":
		return "%d HP · Foes left: %d\nDefeat all foes." % [state.player.hp, state.enemies.size()]
	if not state.has("exit"): return "%d HP" % state.player.hp
	return "%d HP · Exit %s\nReach %s%s" % [state.player.hp,
		"open" if state.turn >= state.exit.opens else "opens turn %d" % state.exit.opens,
		cell(state.exit.pos), "" if state.turn >= state.exit.opens else " when open"]

static func rejection_text(reason: String) -> String:
	return reason

static func event_text(event: Dictionary) -> String:
	var who := actor(str(event.get("actor", "")))
	var source := str(event.get("source", "")).to_upper()
	match event.get("type", ""):
		"move": return "%s moved to %s." % [who, cell(event.to)]
		"capture_armed": return "Capture armed. The next enemy hit is acquired after its normal effects and damage."
		"capture": return "Acquired %s from %s after taking the hit." % [event.kind, source]
		"shine": return "Shine · %s toward %s." % [str(event.kind).capitalize(), cell(event.target)]
		"ability_lost": return "Ability lost: source %s was defeated." % source
		"ray", "area": return "%s · %s footprint: %d cells." % [who, event.type, event.cells.size()]
		"mask":
			return "%s · Swap target %s%s." % [who, cell(event.target),
				" · no valid hit" if event.cells.is_empty() else " · only this tile"]
		"swap": return "%s at %s swaps with %s at %s; damage follows." % [who, cell(event.from), actor(event.other), cell(event.to)]
		"damage": return "%s took %d damage; %d HP left." % [who, event.amount, event.hp]
		"displace": return "%s displaced to %s." % [who, cell(event.to)]
		"death": return "%s fell." % who
		"turn": return "Turn %d · AP refreshed; fresh intentions." % event.number
		"win": return "Victory. All foes defeated." if event.get("objective", "escape") == "defeat_all" else "Escaped through the open exit."
		"loss": return "Caught. Your health reached zero."
	return str(event.get("type", ""))

static func preview_text(predicted: Dictionary) -> String:
	if predicted.is_empty(): return "Choose a legal command to inspect its exact ordered effects. Previewing never advances play."
	var lines: Array[String] = ["Command preview · exact order"]
	for event in predicted.events: lines.append(event_text(event))
	return "\n".join(lines)

static func stored_text(state: Dictionary) -> String:
	if state.stored.is_empty():
		return "Held: empty\nArm Capture for 1 AP, then take an enemy hit. Its effects and damage still happen."
	var stored: Dictionary = state.stored
	var ability: Dictionary = stored.ability
	return "Source %s · %s\nShine: 1 AP per use. Keep using it while its source lives.\nA new captured hit replaces it." % [
		str(stored.source).to_upper(), ability_text(ability)]

static func command_summary(current: Dictionary, predicted: Dictionary, action: Dictionary) -> String:
	var kind: String = action.type
	var cost: String = {"move": "Move · 1 AP", "capture": "Capture · 1 AP", "shine": "Shine · 1 AP", "end_turn": "End turn · free"}[kind]
	var end := "%d AP · %d HP · %s" % [predicted.action_points, predicted.player.hp, cell(predicted.player.pos)]
	if kind == "end_turn": cost += " · Leaving %d AP" % current.action_points
	var outcomes: Array[String] = []
	if predicted.status == "lost":
		outcomes.append("This command kills you. No ability is acquired.")
	elif predicted.status == "won":
		outcomes.append("Victory. All foes defeated." if predicted.get("objective", "escape") == "defeat_all" else "You escape.")
	else:
		for event in predicted.events:
			if event.type in ["capture_armed", "capture", "ability_lost"]: outcomes.append(event_text(event))
		if kind == "shine" and not predicted.stored.is_empty(): outcomes.append("Held ability retained.")
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
