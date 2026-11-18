extends RefCounted

const Ink = preload("res://art_ink.gd")
const IcePlane = preload("res://art_plane.gd")
const INK := Color("#192b43")
const BLADE := Color("#f1f3db")
const COAT := [Color("#bc433a"), Color("#328a7d"), Color("#6a64a0")]
const LIGHT := [Color("#ff9b66"), Color("#8cddd1"), Color("#d1addf")]
const SCARF := [Color("#ffcc84"), Color("#ebd58d"), Color("#ffac9d")]
const SKIN := [Color("#f2b982"), Color("#c3836b"), Color("#e9aa82")]


static func draw(node: Node2D, pose: Dictionary, show: float, curtain: float) -> void:
	var model_point: Vector2 = pose.pos
	var heading: float = pose.heading
	var p := IcePlane.project(model_point)
	var tangent := IcePlane.direction(model_point, heading)
	var depth := clampf(model_point.y / 500.0, 0, 1)
	var size := lerpf(0.82, 1.19, depth)
	var power: float = pose.get("power", 0.0)
	var swing: float = pose.get("stride", 0.0)
	var carve: float = pose.get("carve", 0.0)
	var lean: float = pose.get("lean", 0.0)
	var kind: int = pose.get("kind", 0)
	var bow: float = pose.get("bow", 0.0)
	var riding: bool = pose.get("riding", false)
	var gold := SCARF[kind] as Color
	var shoulders := Vector2(
		tangent.x * (power * 4.2 + carve * 4.5 + bow * 11.0) + lean * 6.0 + 4.6 * bow,
		-31 + carve * 5.0 + bow * 8.5 + absf(sin(swing)) * power * 2.8
	)
	var hips := Vector2(tangent.x * power * 1.9, -17 + carve * 3.2 + bow * 1.6)
	var spread := 4.1 + carve * 1.8
	var push := sin(swing) * power * (7.0 if not riding else 3.4)
	var foot_a := Vector2(-spread, -1.4) + tangent * push
	var foot_b := Vector2(spread, -0.7) - tangent * push
	var open_arms := (0.92 * carve + 0.46 * power + show * 0.27) * (1.0 - bow)
	Ink.ellipse(node, p + Vector2(4, 3) * size, Vector2(22, 7) * size, Color(INK, 0.16))
	Ink.ellipse(node, p + Vector2(2, 1) * size, Vector2(12.5, 3.5) * size, Color(INK, 0.23))
	if kind > 0 and show > 0.02:
		Ink.glow(node, p, Vector2(39, 13) * size, Color(gold, 0.47 * show))
	if riding:
		Ink.glow(node, p, Vector2(26, 9) * size, Color("#ffd79a", 0.70))
	if depth < 0.93:
		node.draw_set_transform(p + Vector2(0, 2), 0, Vector2(size, -0.30 * size))
		var reflection := Color(COAT[kind], 0.19 + show * 0.15)
		Ink.line(node, [foot_a, hips, foot_b], Color(INK, reflection.a), 3.1)
		Ink.line(node, [hips, shoulders], reflection, 11.0)
		Ink.ellipse(node, shoulders - Vector2(0, 8), Vector2(5.1, 6.4), reflection)
		Ink.line(node, [hips, shoulders, shoulders + Vector2(-14 - tangent.x * 7.0, -2)], Color(gold, 0.19 + show * 0.12), 2.4)

	node.draw_set_transform(p, 0, Vector2.ONE * size)
	_body(node, shoulders, hips, foot_a, foot_b, tangent, power, open_arms, bow, swing, kind, curtain)
	node.draw_set_transform(Vector2.ZERO)


static func _body(node: Node2D, shoulders: Vector2, hips: Vector2, foot_a: Vector2, foot_b: Vector2, tangent: Vector2, power: float, open_arms: float, bow: float, swing: float, kind: int, curtain: float) -> void:
	var coat: Color = COAT[kind]
	var light: Color = LIGHT[kind]
	var gold: Color = SCARF[kind]
	var skin: Color = SKIN[kind]
	var warm := lerpf(0.0, 0.18, curtain)
	coat = coat.lerp(Color("#db6964"), warm)
	var side := clampf(tangent.x, -1, 1)
	var trailing := -tangent
	var scarf_start := shoulders + Vector2(-side * 2.5, -1.8)
	var scarf_elbow := scarf_start + Vector2(trailing.x * (10 + power * 9), 5.3 + trailing.y * power * 7.0)
	var scarf_tip := scarf_elbow + Vector2(trailing.x * (6 + power * 8) + sin(swing * 0.55) * 2.1, 5.5 + sin(swing * 0.81) * 3.2 * power)
	Ink.line(node, [scarf_start, scarf_elbow, scarf_tip], gold, 4.0)
	Ink.line(node, [scarf_start, scarf_elbow, scarf_tip], gold.lightened(0.28), 0.85)

	var back_hand := shoulders + Vector2(-8.0 - open_arms * 8.0 - side * power * 2.0 - bow * 6.0, 13.0 - open_arms * 11.0 - bow * 4.0)
	var front_hand := shoulders + Vector2(8.0 + open_arms * 11.0 + side * power * 2.5 + bow * 3.5, 12.0 - open_arms * 7.7 + bow * 4.0)
	var first_hip := hips + Vector2(-3.1, -1)
	var second_hip := hips + Vector2(3.1, -1)
	_leg(node, first_hip, foot_a, side, coat.darkened(0.39))
	_leg(node, second_hip, foot_b, side, INK.lightened(0.11))
	_arm(node, shoulders + Vector2(-5, 2), back_hand, coat.darkened(0.19), light, -1)
	_jacket(node, shoulders, hips, coat)
	Ink.line(node, [shoulders + Vector2(-5.5, 2.1), shoulders + Vector2(-5.8, 5.4), hips + Vector2(-5.4, 0.3)], Color(light, 0.79), 1.0)
	Ink.line(node, [shoulders + Vector2(2.3 + side * 3.0, 2.2), hips + Vector2(2.2 + side * 3.0, 3.2)], coat.darkened(0.36), 0.9)
	for mark_y in [6.9, 10.8]:
		var mark := shoulders + Vector2(2.9 + side * 3.0, minf(mark_y, hips.y - shoulders.y + 1.0))
		node.draw_circle(mark, 0.59, gold, true, -1, true)
	_arm(node, shoulders + Vector2(5, 1.8), front_hand, coat, light, 1)
	Ink.line(node, [shoulders + Vector2(-5.0, -1.4), shoulders + Vector2(0.7, 0.8), shoulders + Vector2(5.6, -1.5)], gold, 3.2)
	var head := shoulders + Vector2(side * (2.0 + bow * 3.0) + bow * 4.8, -8.2 + bow * 8.4)
	_head(node, head, tangent, skin, coat, light)


static func _jacket(node: Node2D, shoulders: Vector2, hips: Vector2, coat: Color) -> void:
	var axis := (hips - shoulders).normalized()
	var cross := Vector2(axis.y, -axis.x)
	var collar := shoulders - axis * 3.6
	var hem := hips + axis * 3.5
	Ink.shape(node, [
		collar - cross * 3.7, collar + cross * 3.7, shoulders + cross * 8.2, hem + cross * 7.0,
		hem + axis, hem - cross * 7.9, shoulders - cross * 7.1
	], INK)
	Ink.shape(node, [
		collar + axis - cross * 3.5, collar + axis + cross * 3.5, shoulders + cross * 7.1,
		hem + cross * 6.1 - axis * 0.8, hem, hem - cross * 6.6 - axis, shoulders - cross * 6.1
	], coat)


static func _arm(node: Node2D, root: Vector2, hand: Vector2, jacket: Color, trim: Color, side: float) -> void:
	var elbow := root.lerp(hand, 0.58) + Vector2(side * 1.9, 1.2)
	Ink.line(node, [root, elbow, hand], INK, 5.6)
	Ink.line(node, [root, elbow, hand], jacket, 4.15)
	node.draw_circle(elbow, 2.05, jacket, true, -1, true)
	node.draw_circle(hand, 2.5, INK, true, -1, true)
	node.draw_circle(hand - Vector2(0.35, 0.35), 1.62, trim, true, -1, true)


static func _leg(node: Node2D, hip: Vector2, foot: Vector2, side: float, pants: Color) -> void:
	var knee := hip.lerp(foot, 0.54) + Vector2(side * 3.7, -1.2)
	Ink.line(node, [hip, knee, foot + Vector2(0, -2.2)], INK, 5.8)
	Ink.line(node, [hip, knee, foot + Vector2(0, -2.2)], pants, 4.1)
	node.draw_circle(knee, 2.0, pants, true, -1, true)
	var toe := foot + Vector2(side * 4.0, -0.4)
	Ink.line(node, [foot + Vector2(-1.1, -3.4), foot + Vector2(0, -1.0), toe + Vector2(0, -1.1)], INK, 4.5)
	Ink.line(node, [foot + Vector2(-2.9, 1.15), toe + Vector2(0.7, 1.0)], BLADE, 1.3)


static func _head(node: Node2D, center: Vector2, direction: Vector2, skin: Color, coat: Color, trim: Color) -> void:
	var side := direction.x
	Ink.ellipse(node, center, Vector2(6.1, 6.8), INK)
	Ink.ellipse(node, center + Vector2(side * 1.65, 1.3), Vector2(4.1, 4.55), skin if direction.y > -0.53 else INK.lightened(0.14))
	if direction.y > -0.53:
		node.draw_circle(center + Vector2(side * 3.8 + 0.5, 1), 0.66, INK, true, -1, true)
		if absf(side) > 0.57:
			Ink.shape(node, [center + Vector2(side * 4.9, 1.7), center + Vector2(side * 6.1, 3), center + Vector2(side * 4.4, 3.8)], skin)
	Ink.shape(node, [
		center + Vector2(-5.9, -1.4), center + Vector2(-4.9, -5.0), center + Vector2(-2.8, -7.2), center + Vector2(1.8, -8.1),
		center + Vector2(4.7, -6.5), center + Vector2(5.9, -2.1), center + Vector2(3.5, -0.4), center + Vector2(-3.8, 0.4)
	], coat.darkened(0.07))
	Ink.line(node, [center + Vector2(-5.8, -1.3), center + Vector2(-0.9, -1.0), center + Vector2(6.0, -2.2)], trim, 2.1)
	node.draw_circle(center + Vector2(-0.6, -8.15), 2.05, trim.lightened(0.21), true, -1, true)
