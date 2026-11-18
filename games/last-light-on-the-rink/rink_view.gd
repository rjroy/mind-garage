extends Node2D

const Ink = preload("res://art_ink.gd")
const IcePlane = preload("res://art_plane.gd")
const Neighborhood = preload("res://art_neighborhood.gd")
const IceSurface = preload("res://art_ice_surface.gd")
const Skater = preload("res://art_skater.gd")
const Program = preload("res://art_program.gd")
const AirShader = preload("res://art_air.gdshader")

const SKATE_ORIGIN := Vector2(360, 333)
const AMBER := Color("#ffca83")
const CHORUS := [Color("#f5d594"), Color("#ffc3ba")]
const ICE_DUST := Color("#e5fff4")

var _state: Dictionary = {}
var _ice: Node2D
var _program: Node2D
var _poses: Array[Dictionary] = []
var _cast: Array[Dictionary] = []
var _last_cue := 0.0
var _last_riding := 0.0
var _clock := 0.0
var _show := 0.0
var _curtain := 0.0
var _marked: Array = []
var _projected: Array[PackedVector2Array] = []
var _flakes := PackedVector4Array()
var _dust: Array[Dictionary] = []
var _dust_fraction := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 17014
	_build_sky()
	var horizon := Neighborhood.new()
	horizon.z_index = -4
	add_child(horizon)
	_ice = IceSurface.new()
	_ice.z_index = -2
	add_child(_ice)
	var near_bank := Neighborhood.new()
	near_bank.foreground = true
	near_bank.z_index = 2
	add_child(near_bank)
	_program = Program.new()
	_program.z_index = 4
	add_child(_program)
	for i in range(98):
		_flakes.append(Vector4(_rng.randf_range(0, 1170), _rng.randf_range(0, 760), _rng.randf_range(0.06, 1.0), _rng.randf_range(0.0, TAU)))


func _build_sky() -> void:
	var sky := ColorRect.new()
	var wash := ShaderMaterial.new()
	wash.shader = AirShader
	sky.material = wash
	sky.size = Vector2(1152, 720)
	sky.z_index = -5
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)


func present(s: Dictionary) -> void:
	var now := float(s.get("total_time", 0.0))
	var before := float(_state.get("total_time", 0.0))
	var reset: bool = now < before or (_state.get("phase", "opening") != "opening" and s.get("phase", "opening") == "opening")
	var paused := bool(s.get("paused", false))
	if reset:
		_poses.clear()
		_cast.clear()
		_dust.clear()
		_dust_fraction = 0.0
		_show = 0.0
		_curtain = 0.0
		_clock = 0.0
		_last_riding = 0.0
	elif not _state.is_empty() and not paused:
		if bool(s.get("riding", false)) and not bool(_state.get("riding", false)):
			_last_riding = 1.0
	if reset or paused or s.get("phase", "opening") not in ["opening", "rehearsal", "finale"]:
		_last_cue = 0.0
	elif not _state.is_empty() and int(s.get("cue_serial", 0)) > int(_state.get("cue_serial", 0)):
		_last_cue = 1.0
	_sync_cast(s, now - before)
	_state = s
	var grooves: Array = s.get("grooves", [])
	if grooves != _marked:
		_marked = grooves.duplicate()
		_projected.clear()
		for line in _marked:
			_projected.append(_project_line(line))


func cue_feedback_partner() -> int:
	var partner := int(_state.get("cued_partner", -1))
	return partner if _last_cue > 0.0 and partner >= 0 and partner < _cast.size() - 1 else -1


func _sync_cast(s: Dictionary, dt: float) -> void:
	var old := _cast
	var active: PackedVector2Array = s.get("active_line", PackedVector2Array())
	var velocity: Vector2 = s.get("vel", Vector2.ZERO)
	_cast = [{
		"kind": 0,
		"pos": s.get("pos", SKATE_ORIGIN),
		"heading": s.get("heading", -0.15),
		"glide": minf(velocity.length() / 250.0, 1.0),
		"carve": 1.0 if bool(s.get("carving", active.size() > 1)) else 0.0,
		"riding": bool(s.get("riding", false))
	}]
	var followers: Array = s.get("followers", [])
	for index in range(mini(followers.size(), 2)):
		var follower: Dictionary = followers[index]
		var p: Vector2 = follower.get("pos", Vector2.ZERO)
		var moving := 0.55
		var groove := int(follower.get("groove", -1))
		if index + 1 < old.size():
			var prior: Vector2 = old[index + 1].pos
			moving = minf(p.distance_to(prior) / (dt * 190.0), 1.0) if dt > 0.0001 else float(old[index + 1].glide)
		if follower.has("vel"):
			var follower_vel: Vector2 = follower.vel
			moving = minf(follower_vel.length() / 190.0, 1.0)
		_cast.append({
			"kind": index + 1,
			"pos": p,
			"heading": float(follower.get("heading", PI)),
			"glide": moving,
			"carve": 0.20 if groove >= 0 else 0.0,
			"riding": false,
			"groove": groove
		})


func _process(delta: float) -> void:
	var phase := String(_state.get("phase", "opening"))
	var bow_time := float(_state.get("bow_time", -1.0))
	if not bool(_state.get("paused", false)):
		var dt := minf(delta, 0.05)
		_clock += dt
		_last_cue = maxf(0.0, _last_cue - dt * 0.39)
		_last_riding = maxf(0.0, _last_riding - dt * 1.6)
		_show = move_toward(_show, 1.0 if phase in ["finale", "bow"] else 0.0, dt * 0.49)
		_curtain = smoothstep(1.65, 4.0, bow_time)
		_pose_cast(dt, bow_time)
		_blade_dust(dt)
		_ice.light(smoothstep(0.0, 1.0, _show), _curtain, _clock)
	_program.present(_state, _last_cue if cue_feedback_partner() >= 0 else 0.0)
	queue_redraw()


func _pose_cast(dt: float, bow_time: float) -> void:
	_poses.resize(_cast.size())
	var follow := 1.0 - exp(-23.0 * dt)
	for i in range(_cast.size()):
		var target := _cast[i]
		var pose := _poses[i]
		if pose.is_empty():
			pose = target.duplicate()
			pose["lean"] = 0.0
			pose["stride"] = i * 1.55
			pose["power"] = 0.0
			_poses[i] = pose
		var p: Vector2 = pose.pos
		var aim: Vector2 = target.pos
		pose.pos = p.lerp(aim, follow) if p.distance_to(aim) < 100.0 else aim
		var turn := angle_difference(float(pose.heading), float(target.heading))
		pose.heading = lerp_angle(float(pose.heading), float(target.heading), follow)
		pose.lean = lerpf(float(pose.lean), clampf(turn * 1.65, -1.0, 1.0), follow)
		pose.carve = lerpf(float(pose.carve), float(target.carve), follow * 0.55)
		pose.power = lerpf(float(pose.power), float(target.glide), follow * 0.46)
		pose.stride = fposmod(float(pose.stride) + dt * (0.65 + float(pose.power) * 7.0), TAU * 100.0)
		pose.riding = target.riding
		pose["groove"] = target.get("groove", -1)
		var ready_to_bow := maxf(0.0, bow_time - 1.35 - i * 0.10)
		pose["bow"] = smoothstep(0.04, 0.91, ready_to_bow) * (1.0 - smoothstep(1.26, 2.36, ready_to_bow))


func _blade_dust(dt: float) -> void:
	for index in range(_dust.size() - 1, -1, -1):
		var puff := _dust[index]
		puff.age += dt
		if float(puff.age) > float(puff.life):
			_dust.remove_at(index)
	if _poses.is_empty():
		return
	var pose := _poses[0]
	var amount := float(pose.carve) * float(pose.power)
	if amount < 0.03:
		return
	_dust_fraction += dt * (10.0 + amount * 60.0)
	var p: Vector2 = pose.pos
	var axis := IcePlane.direction(p, float(pose.heading))
	while _dust_fraction >= 1.0:
		_dust_fraction -= 1.0
		var drift := -axis.rotated(_rng.randf_range(-0.8, 0.8)) * _rng.randf_range(7, 44)
		_dust.append({
			"pos": IcePlane.project(p) - axis * _rng.randf_range(2.0, 9.0),
			"vel": drift,
			"age": 0.0,
			"life": _rng.randf_range(0.24, 0.67),
			"size": _rng.randf_range(0.55, 1.65)
		})


func _draw() -> void:
	var light := smoothstep(0, 1, _show)
	if light > 0:
		_draw_show(light)
	_draw_grooves(light)
	for puff in _dust:
		var t: float = float(puff.age) / float(puff.life)
		var p: Vector2 = puff.pos + puff.vel * float(puff.age) + Vector2(0, -5.0 * sin(t * PI))
		draw_circle(p, float(puff.size) * (1.0 - t * 0.30), Color(ICE_DUST, (1.0 - t) * 0.88), true, -1, true)
	_draw_cast(light)
	_draw_flakes()


func _draw_grooves(light: float) -> void:
	var binding: Dictionary = {}
	for i in range(1, _poses.size()):
		var groove := int(_poses[i].get("groove", -1))
		if groove >= 0:
			binding[groove] = CHORUS[i - 1]
	for i in range(_projected.size()):
		var path := _projected[i]
		var latest := i == _projected.size() - 1
		var tint: Color = binding.get(i, Color("#d2faf2"))
		if path.size() < 2:
			continue
		if i in binding:
			draw_polyline(path, Color(tint, 0.22 + light * 0.18), 8.0 + light * 2.0, true)
		elif latest:
			draw_polyline(path, Color("#a8e5ea", 0.26), 6.3, true)
		draw_polyline(_offset(path, Vector2(0.15, 1.45)), Color("#1e4867", 0.68 if latest else 0.44), 3.0 if latest else 2.1, true)
		draw_polyline(path, Color(tint, 0.94 if latest or i in binding else 0.57), 1.6 if latest or i in binding else 1.18, true)
		if latest:
			_cut_mouth(path, tint)
	var active: PackedVector2Array = _state.get("active_line", PackedVector2Array())
	if active.size() >= 2:
		var live := _project_line(active)
		if not _poses.is_empty():
			live.append(IcePlane.project(_poses[0].pos))
		draw_polyline(live, Color("#214b68", 0.37), 5.2, true)
		draw_polyline(live, Color("#9feef0", 0.43), 3.3, true)
		draw_polyline(live, Color("#f8ffec", 0.97), 1.8, true)


func _cut_mouth(path: PackedVector2Array, tint: Color) -> void:
	var p := path[0]
	var axis := (path[1] - p).normalized()
	var wing := axis.orthogonal()
	Ink.line(self, [p - axis * 4 + wing * 3.2, p, p - axis * 4 - wing * 3.2], Color("#275977", 0.45), 2.6)
	Ink.line(self, [p - axis * 4 + wing * 3.2 - Vector2(0, 0.6), p - Vector2(0, 0.6), p - axis * 4 - wing * 3.2 - Vector2(0, 0.6)], Color(tint, 0.86), 1.1)


func _draw_cast(light: float) -> void:
	var ordered := _poses.duplicate()
	if ordered.is_empty():
		ordered = [{"pos": SKATE_ORIGIN, "heading": -0.15}]
	ordered.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	var recipient := cue_feedback_partner()
	for pose in ordered:
		var p := IcePlane.project(pose.pos)
		var kind := int(pose.get("kind", 0))
		if kind == 0 and _last_riding > 0:
			_ripple(p, _last_riding, AMBER)
		elif recipient >= 0 and kind == recipient + 1:
			_ripple(p, _last_cue, CHORUS[recipient])
		Skater.draw(self, pose, light, _curtain)


func _ripple(p: Vector2, factor: float, tint: Color) -> void:
	var reach := 6.0 + (1.0 - factor) * 26.0
	var wave := PackedVector2Array()
	for i in range(29):
		wave.append(p + Vector2.from_angle(i * TAU / 28.0) * Vector2(reach, reach * 0.29))
	draw_polyline(wave, Color(tint, smoothstep(0.0, 0.8, factor) * 0.82), 1.2, true)


func _draw_show(light: float) -> void:
	# Tint the scene behind the performers. Real grooves stay the brightest lines on the ice.
	draw_rect(Rect2(0, 0, 1152, 720), Color("#171931", light * (0.28 - _curtain * 0.03)))
	var soft := Color("#ffd6a0", light * 0.17)
	var warm := Color("#ffe0ad", light * 0.78)
	var beam_mouths := [Vector2(218, 173), Vector2(969, 165)]
	for i in range(2):
		var beam: Vector2 = beam_mouths[i]
		var p := Vector2(576 + cos(_clock * 0.63 + float(i) * PI * 0.8) * (74.0 if i == 0 else 91.0), 470.0 + sin(_clock * 0.56 + float(i) * 1.8) * 34.0)
		var rink_center := IcePlane.project(Vector2(450, 250))
		p = p.lerp(rink_center, _curtain)
		_soft_beam(beam, p, soft)
		Ink.glow(self, p, Vector2(157, 50), Color(warm, light * (0.18 + _curtain * 0.10)))
		Ink.glow(self, beam, Vector2(44, 50), Color(warm, light * 0.61))
	_draw_audience(light)


func _soft_beam(origin: Vector2, p: Vector2, tint: Color) -> void:
	var side := Vector2(111, 8)
	var outer := Color(tint, 0)
	var far_core := Color(tint, tint.a * 0.32)
	for sign in [-1.0, 1.0]:
		var s := float(sign)
		draw_polygon(
			PackedVector2Array([origin, origin + Vector2(s * 3.7, 0), p + side * s, p + side * s * 0.36, p]),
			PackedColorArray([tint, outer, outer, far_core, far_core])
		)


func _draw_audience(light: float) -> void:
	for i in range(26):
		var x := 182.0 + i * 31.0 + sin(i * 8.141) * 8.2
		var y := 267.0 + cos(i * 7.64) * 3.4
		var bend := sin(float(i) * 4.57 + _clock * 1.8) * (0.7 + 1.9 * _curtain)
		var p := Vector2(x, y)
		var cap := Color("#71617b").lerp(Color("#ad7a76"), 0.5 + 0.5 * sin(i * 8.4))
		Ink.shape(self, [p + Vector2(-5, -1), p + Vector2(-4, -8), p + Vector2(bend, -11), p + Vector2(4, -8), p + Vector2(6, -1)], Color("#1d2b41", light * 0.98))
		draw_circle(p + Vector2(bend, -13.2), 2.95, Color(cap, light * 0.97), true, -1, true)
		if i % 4 == 1 and _curtain > 0.12:
			var hand := p + Vector2(bend * 2.1, -6 - absf(sin(_clock * 5.5 + i)) * 9)
			draw_line(p + Vector2(2, -6), hand, Color(cap, _curtain), 1.8, true)
		if i % 5 == 2:
			var lamp := p + Vector2(5.0 + bend, -6.2)
			Ink.glow(self, lamp, Vector2(14, 17), Color(AMBER, light * 0.61))
			draw_circle(lamp, 1.25, Color(AMBER, light), true, -1, true)


func _draw_flakes() -> void:
	for flake in _flakes:
		var x := fposmod(flake.x + _clock * (12.0 + 18.0 * flake.z) + 6.0 * sin(_clock * 0.65 + flake.w), 1170.0) - 9.0
		var y := fposmod(flake.y + _clock * lerpf(8.0, 35.0, flake.z), 760.0) - 16.0
		var a := lerpf(0.14, 0.63, flake.z)
		var p := Vector2(x, y)
		if flake.z > 0.86:
			draw_line(p - Vector2(1.6, 2.2), p, Color("#ebe5f3", a * 0.54), 1.15, true)
		draw_circle(p, lerpf(0.44, 1.55, flake.z), Color("#e9e9f0", a), true, -1, true)


func _project_line(line: PackedVector2Array) -> PackedVector2Array:
	var path := PackedVector2Array()
	for point in line:
		path.append(IcePlane.project(point))
	return path


func _offset(path: PackedVector2Array, amount: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in path:
		result.append(p + amount)
	return result
