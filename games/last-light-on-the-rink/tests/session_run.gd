extends SceneTree

# Run the real configured scene, for example:
# godot --headless --path games/last-light-on-the-rink --fixed-fps 60 --script res://tests/session_run.gd
#
# No game clock or production state is injected. All interaction goes through
# the same keyboard events as a player, and phase waits have bounded timeouts.

const TICKS_PER_SECOND := 60
const PHASE_TIMEOUT_TICKS := 120 * TICKS_PER_SECOND

var scene: Node
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_path := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if not _check(scene_path == "res://rink.tscn", "configured main scene is rink.tscn"):
		_finish()
		return
	var packed := load(scene_path) as PackedScene
	if not _check(packed != null, "configured scene loads"):
		_finish()
		return
	scene = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	if not _check(scene.has_method("current_state"), "scene exposes current_state"):
		_finish()
		return

	var initial := _state()
	_check(initial.get("phase") == "opening", "starts in opening")
	var start_pos: Vector2 = initial.get("pos", Vector2.ZERO)
	_key(KEY_D, true)
	await _ticks(120)
	_key(KEY_D, false)
	_check(_position().distance_to(start_pos) > 1.0, "skates immediately during opening")

	await _test_pause_and_mute()
	await _restart()
	_check(_position().is_equal_approx(start_pos), "first performance starts at reset position")
	var first := await _performance(false)
	if first.is_empty():
		_finish()
		return
	await _restart()
	_check(_position().is_equal_approx(start_pos), "second performance starts at same reset position")
	var second := await _performance(true)
	if not second.is_empty():
		_check(
			_trajectories_differ(first, second),
			"different performances produce different partner finale trajectories"
		)
	_finish()


func _test_pause_and_mute() -> void:
	var before := _state()
	_pulse(KEY_ESCAPE)
	await _ticks(2)
	var paused := _state()
	_check(bool(paused.get("paused", false)), "Escape pauses")
	var frozen_time := float(paused.get("total_time", -1.0))
	await _ticks(60)
	_check(
		is_equal_approx(float(_state().get("total_time", -2.0)), frozen_time),
		"paused simulation clock remains stopped"
	)
	_pulse(KEY_ESCAPE)
	await _ticks(2)
	_check(not bool(_state().get("paused", true)), "Escape resumes")
	_pulse(KEY_M)
	await _ticks(2)
	_check(
		bool(_state().get("muted", false)) != bool(before.get("muted", false)),
		"M toggles mute"
	)
	_pulse(KEY_M)
	await _ticks(2)
	_check(_state().get("muted") == before.get("muted"), "M restores mute")


func _performance(alternate: bool) -> Array:
	var label := "second" if alternate else "first"
	if not await _wait_for_phase("rehearsal"):
		return []

	# Two separate gestures: one mostly horizontal, the other bent vertically.
	# Reverse both for the second performance instead of relying on tuning values.
	var first_key := KEY_A if alternate else KEY_D
	var second_key := KEY_W if alternate else KEY_S
	var third_key := KEY_D if alternate else KEY_A
	await _draw_line([first_key], 4)
	var first_grooves: Array = _state().get("grooves", []).duplicate(true)
	_check(first_grooves.size() >= 1, label + ": first gesture creates a track")
	if first_grooves.size() >= 1:
		_check(_path_length(first_grooves[-1]) > 10.0, label + ": first track contains actual travel")
	var serial := int(_state().get("cue_serial", 0))
	_pulse(KEY_E)
	await _ticks(3)
	_check(int(_state().get("cue_serial", 0)) == serial + 1, label + ": first E cue registers once")
	var first_followers: Array = _state().get("followers", [])
	_check(
		first_followers.size() >= 1 and int(first_followers[0].get("groove", -1)) == first_grooves.size() - 1
		and not first_grooves.is_empty(),
		label + ": first cue assigns first authored track"
	)

	await _draw_line([second_key, third_key], 3)
	var grooves: Array = _state().get("grooves", []).duplicate(true)
	_check(grooves.size() >= 2, label + ": second gesture creates another track")
	if grooves.size() >= 2:
		_check(_path_length(grooves[-1]) > 10.0, label + ": second track contains actual travel")
		_check(grooves[0] != grooves[1], label + ": authored tracks differ")
	serial = int(_state().get("cue_serial", 0))
	_pulse(KEY_E)
	await _ticks(3)
	_check(int(_state().get("cue_serial", 0)) == serial + 1, label + ": second E cue registers once")

	var followers: Array = _state().get("followers", [])
	if _check(followers.size() >= 2, label + ": both partners present"):
		_check(
			int(followers[0].get("groove", -1)) >= 0 and int(followers[1].get("groove", -1)) >= 0,
			label + ": both partners have assigned tracks"
		)
		_check(
			followers[0].get("groove", null) != followers[1].get("groove", null),
			label + ": partners have their own cued tracks"
		)
		_check(
			int(followers[0].get("groove", -1)) == 0 and int(followers[1].get("groove", -1)) == 1,
			label + ": each partner retains the intended authored track"
		)
		var traces := [[], []]
		var near_runs := [0, 0]
		var tracing := [false, false]
		var stayed_near := [true, true]
		var traced_distance := [0.0, 0.0]
		var previous := [Vector2.ZERO, Vector2.ZERO]
		for sample in range(40):
			await _ticks(30)
			followers = _state().get("followers", [])
			if followers.size() < 2:
				_check(false, label + ": partners remain present")
				break
			for index in range(2):
				var pos: Vector2 = followers[index].get("pos", Vector2.ZERO)
				traces[index].append(pos)
				var groove_index := int(followers[index].get("groove", -1))
				if groove_index < 0 or groove_index >= grooves.size():
					stayed_near[index] = false
					continue
				var near := _distance_to_path(pos, grooves[groove_index]) <= 20.0
				if tracing[index]:
					stayed_near[index] = stayed_near[index] and near
					traced_distance[index] += pos.distance_to(previous[index])
				else:
					near_runs[index] = near_runs[index] + 1 if near else 0
					tracing[index] = near_runs[index] >= 3
				previous[index] = pos
		for index in range(2):
			_check(
				tracing[index] and stayed_near[index] and traced_distance[index] > 10.0,
				label + ": partner %d approaches and travels along assigned track" % (index + 1)
			)
		_check(_trajectories_differ(traces[0], traces[1]), label + ": partners trace different shapes")

	if not await _wait_for_phase("finale"):
		return []
	var finale_trace: Array = []
	var partners_present := true
	while _state().get("phase") == "finale" and finale_trace.size() < 120:
		var state := _state()
		var sample: Array = []
		for follower in state.get("followers", []):
			sample.append(follower.get("pos", Vector2.ZERO))
		partners_present = partners_present and sample.size() >= 2
		finale_trace.append(sample)
		await _ticks(60)
	_check(partners_present, label + ": finale retains both partners")
	if not _check(_state().get("phase") == "bow", label + ": finale reaches bow"):
		return []
	_check(finale_trace.size() >= 2, label + ": finale has a measurable trajectory")
	return finale_trace


func _draw_line(keys: Array, seconds_per_key: int) -> void:
	_key(KEY_SPACE, true)
	for key in keys:
		_key(key, true)
		await _ticks(seconds_per_key * TICKS_PER_SECOND)
		_key(key, false)
	_key(KEY_SPACE, false)
	await _ticks(3)


func _restart() -> void:
	_pulse(KEY_R)
	await _ticks(2)
	var state := _state()
	_check(state.get("phase") == "opening", "R restarts at opening")
	_check(int(state.get("cue_serial", -1)) == 0, "restart clears cues")
	_check(state.get("grooves", []).is_empty(), "restart clears authored tracks")
	_check(state.get("active_line", []).is_empty(), "restart clears active track")
	_check(not bool(state.get("paused", true)), "restart is not paused")


func _wait_for_phase(target: String) -> bool:
	for tick in range(PHASE_TIMEOUT_TICKS):
		if _state().get("phase") == target:
			return true
		await physics_frame
	_check(false, "timed out waiting for " + target + "; last state: " + str(_state()))
	return false


func _ticks(count: int) -> void:
	for tick in range(count):
		await physics_frame


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _pulse(code: Key) -> void:
	_key(code, true)
	_key(code, false)


func _state() -> Dictionary:
	return scene.current_state()


func _position() -> Vector2:
	return _state().get("pos", Vector2.ZERO)


func _path_length(path: PackedVector2Array) -> float:
	var length := 0.0
	for i in range(1, path.size()):
		length += path[i - 1].distance_to(path[i])
	return length


func _distance_to_path(pos: Vector2, path: PackedVector2Array) -> float:
	var distance := INF
	for i in range(1, path.size()):
		var closest := Geometry2D.get_closest_point_to_segment(pos, path[i - 1], path[i])
		distance = minf(distance, pos.distance_to(closest))
	return distance


func _trajectories_differ(a: Array, b: Array) -> bool:
	if a.size() < 2 or b.size() < 2:
		return false
	# Compare displacement, not spawn offsets. Samples may contain one position
	# or multiple skaters' positions for the finale.
	var count := mini(a.size(), b.size())
	for i in range(1, count):
		var aa: Array = a[i] if a[i] is Array else [a[i]]
		var bb: Array = b[i] if b[i] is Array else [b[i]]
		var a0: Array = a[0] if a[0] is Array else [a[0]]
		var b0: Array = b[0] if b[0] is Array else [b[0]]
		for j in range(mini(mini(aa.size(), bb.size()), mini(a0.size(), b0.size()))):
			if aa[j] is Vector2 and bb[j] is Vector2 and a0[j] is Vector2 and b0[j] is Vector2:
				if (aa[j] - a0[j]).distance_to(bb[j] - b0[j]) > 1.0:
					return true
	return false


func _check(condition: bool, description: String) -> bool:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)
	return condition


func _finish() -> void:
	print("SESSION TEST: ", checks - failures.size(), "/", checks, " checks passed")
	if not failures.is_empty():
		print("Failures: ", failures)
	quit(0 if failures.is_empty() else 1)
