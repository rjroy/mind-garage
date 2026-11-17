extends SceneTree
## FY3-C01/C02/C03: real-model outcomes at the actual renderer/board decision boundary.
##
## SETUP PREREQUISITE, separately authorized; do not count missing methods as RED:
## 1. ui/shadow_renderer.gd: extract existing endpoint choice into
##    gesture_endpoint(state: Dictionary, cue: Dictionary) -> Array. Empty cue
##    returns []; otherwise choose cue.to, else cells.back(), else cue.from;
##    preserve the current final-status-lost backlash collapse for assertion RED.
##    draw_shadows MUST obtain its endpoint by centering this returned cell.
## 2. ui/board.gd: extract the currently DRAWN ray/area footprint rows into
##    effect_footprints() -> Array, each detached row exactly
##    {type: 'ray'|'area', actor: String, stage: 'release'|'backlash'|'enemy',
##     cells: Array}. Preserve existing preview.events-or-last_events selection.
##    Player stage follows preceding release/backlash marker; other actors use
##    'enemy'. _draw MUST consume these rows for tactical effect-cell outlines
##    and the existing player release arrow, not retain a second footprint loop.
##    Preserve existing colors/line styling, movement arrows/death markers and
##    pulse timing. Do NOT add active-cue selection or local loss attribution yet.
## These are small shared drawing decisions, not test-only hooks or new rules.
## Run this suite only AFTER that behavior-preserving extraction. Exit 2 is setup,
## exit 1 is assertion failure, exit 0 passes. Original controller tests stay intact.

const Encounter = preload("res://model/encounter.gd")
const Shadow = preload("res://ui/shadow_presentation.gd")
const F = preload("res://tests/shadow_rendering_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const RENDERER := "res://ui/shadow_renderer.gd"
const BOARD := "res://ui/board.gd"
var renderer_script: Script
var board_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func _method(probe: Object, name: String, arity: int) -> bool:
	for method in probe.get_method_list():
		if method.name == name: return method.args.size() == arity
	return false

func _setup() -> bool:
	renderer_script = load(RENDERER)
	board_script = load(BOARD)
	if renderer_script == null or board_script == null or not renderer_script.can_instantiate() or not board_script.can_instantiate():
		printerr("SETUP REQUIRED: renderer and board must load cleanly; parse/import errors are not behavioral RED.")
		return false
	var renderer = renderer_script.new()
	var board = board_script.new()
	var ready: bool = _method(renderer, "gesture_endpoint", 2) and _method(board, "effect_footprints", 0)
	if not ready:
		printerr("SETUP REQUIRED: behavior-preserving gesture_endpoint(state, cue) and effect_footprints() extraction; see runner header. Missing seam is not assertion RED.")
	else:
		var endpoint = renderer.call("gesture_endpoint", {}, {})
		var rows = board.call("effect_footprints")
		ready = endpoint is Array and endpoint.is_empty() and rows is Array and rows.is_empty()
		if not ready: printerr("SETUP REQUIRED: empty endpoint/board inputs must return safe empty arrays.")
	board.free()
	return ready

func game(fixture: Dictionary):
	var g = Encounter.new()
	var isolated := fixture.duplicate(true)
	isolated.objective = "escape"
	g.configure(isolated, "R2")
	return g

func commit(g, p, command: Dictionary) -> Dictionary:
	var before: Dictionary = g.snapshot()
	var assessment: Dictionary = g.assess(command)
	check(assessment.get("legal", false), "controlled real-model command is legal: " + str(command))
	if not assessment.get("legal", false): return {}
	check(g.act(command), "real model commits assessed command")
	var after: Dictionary = g.snapshot()
	check(p.observe(before, command, after, 1), "controller accepts committed transition")
	return after

func deadline(later_lethal: bool = false) -> Dictionary:
	# Acquire from the safe flank before stepping into the later bolt line.
	# The deadline/backlash/friendly-fire sequence itself is unchanged.
	var fixture := F.deadline(later_lethal)
	fixture.player.pos = [1, 3]
	fixture.enemies[0].pos = [1, 4]
	# Re-aiming this bystander must not push the player out of the killer's
	# later line. It remains the real backlash victim, not a second attacker.
	fixture.enemies[1].kind = "bolt"
	fixture.enemies[1].ability = {"kind": "bolt", "damage": 0, "range": 3, "radius": 0, "push": false}
	var g = game(fixture)
	var p = Shadow.new()
	p.reset(g.snapshot(), 1)
	if commit(g, p, {"type": "capture", "source": "held"}).is_empty(): return {}
	p.advance(60.0)
	if commit(g, p, {"type": "move", "to": [2, 3]}).is_empty(): return {}
	p.advance(60.0)
	if commit(g, p, {"type": "end_turn"}).is_empty(): return {}
	p.advance(60.0)
	var after := commit(g, p, {"type": "end_turn"})
	if after.is_empty(): return {}
	check(after.stored.is_empty() and after.backlash_footprint.is_empty(), "deadline consumed storage and settled backlash footprint")
	return {"game": g, "presentation": p, "after": after}

func event_index(events: Array, type: String, actor: String = "") -> int:
	for i in range(events.size()):
		if events[i].get("type", "") == type and (actor.is_empty() or events[i].get("actor", "") == actor): return i
	return -1

func test_local_backlash_lethality() -> void:
	var scenario := deadline(true)
	if scenario.is_empty(): return
	var after: Dictionary = scenario.after
	var frame: Dictionary = scenario.presentation.frame()
	var cue: Dictionary = frame.get("cue", {})
	var events: Array = after.events
	var backlash_marker := event_index(events, "backlash")
	var backlash_ray := event_index(events, "ray", "player")
	var victim_damage := event_index(events, "damage", "victim")
	var victim_push := event_index(events, "displace", "victim")
	var later_ray := event_index(events, "ray", "killer")
	var player_death := event_index(events, "death", "player")
	check(after.status == "lost", "C01 fixture ends lost from a later attack")
	check(backlash_marker >= 0 and backlash_ray > backlash_marker and victim_damage > backlash_ray and victim_push > victim_damage and later_ray > victim_push and player_death > later_ray,
		"C01 actual backlash damages/displaces victim BEFORE later enemy ray kills player")
	check(cue.get("type", "") == "backlash" and cue.get("cells", []).size() > 1, "C01 active cue is the full nonlethal backlash")
	if cue.get("type", "") != "backlash" or cue.get("cells", []).is_empty(): return
	var renderer = renderer_script.new()
	var state_before := after.duplicate(true)
	var cue_before := cue.duplicate(true)
	var endpoint = renderer.call("gesture_endpoint", after, cue)
	check(endpoint == cue.cells.back() and endpoint != cue.from,
		"FY3-C01: later enemy loss must NOT collapse an earlier survivable backlash gesture")
	check(after == state_before and cue == cue_before, "endpoint choice does not mutate authoritative state or cue")
	check(scenario.game.snapshot() == after, "render decision cannot mutate the real model")

	# Preserve the intentional collapse when THIS backlash actually kills self.
	var g = game(F.self_lethal())
	var p = Shadow.new()
	p.reset(g.snapshot(), 1)
	if commit(g, p, {"type": "capture", "source": "old"}).is_empty(): return
	p.advance(60.0)
	var lethal := commit(g, p, {"type": "capture", "source": "new"})
	if lethal.is_empty(): return
	var lethal_cue: Dictionary = p.frame().get("cue", {})
	check(lethal.status == "lost" and event_index(lethal.events, "death", "player") >= 0 and event_index(lethal.events, "ray", "new") == -1,
		"C01 control fixture actually dies within old backlash, before another enemy resolution")
	check(event_index(lethal.events, "damage", "new") == -1, "lethal self-hit stops downstream victim damage")
	if lethal_cue.is_empty():
		check(false, "lethal backlash provides a cue")
		return
	check(renderer.call("gesture_endpoint", lethal, lethal_cue) == lethal_cue.get("from", []),
		"FY3-C01 control: actually lethal self-hit still collapses at player")

func cue_footprints(cue: Dictionary) -> Array:
	if cue.is_empty() or cue.get("type", "") == "capture": return []
	return [{"type": "ray", "actor": "player" if cue.type in ["release", "backlash"] else cue.source,
		"stage": "enemy" if cue.type == "resolve" else cue.type, "cells": cue.cells.duplicate(true)}]

func expected_from_events(events: Array) -> Array:
	# Ordered event projection, never footprint geometry or damage simulation.
	var result: Array = []
	var stage := "enemy"
	for event in events:
		if event.type in ["release", "backlash"]: stage = event.type
		if event.type in ["ray", "area"]:
			result.append({"type": event.type, "actor": event.actor,
				"stage": stage if event.actor == "player" else "enemy", "cells": event.cells.duplicate(true)})
	return result

func drawn(board, label: String) -> Array:
	var rows = board.call("effect_footprints")
	check(rows is Array, label + ": drawing consumer returns rows")
	if not rows is Array: return []
	for row in rows:
		if not row is Dictionary:
			check(false, label + ": footprint row is a dictionary")
			continue
		check(row.get("cells") is Array and row.get("type", "") in ["ray", "area"] and row.get("stage", "") in ["release", "backlash", "enemy"] and row.get("actor") is String,
			label + ": drawing row identifies cells, type, actor and stage")
	return rows

func next_cue(p, previous: Dictionary) -> Dictionary:
	# Bounded clock stepping seeks an actual cue boundary, not a style duration.
	for _step in range(14400):
		p.advance(1.0 / 240.0)
		var current: Dictionary = p.frame().get("cue", {})
		if current.is_empty() or current.get("event_index", -1) != previous.get("event_index", -1): return current
	check(false, "finite presentation reaches its next cue within a generous 60-second bound")
	return {}

func test_active_cue_footprints() -> void:
	var scenario := deadline()
	if scenario.is_empty(): return
	var after: Dictionary = scenario.after
	var p = scenario.presentation
	var frame: Dictionary = p.frame()
	var first: Dictionary = frame.get("cue", {})
	var aggregate := expected_from_events(after.events)
	check(after.status == "playing" and aggregate.size() > 1, "C02 fixture has surviving backlash and later independent ray resolutions")
	check(first.get("type", "") == "backlash", "C02 starts on backlash, not a later queued resolve")
	if first.get("type", "") != "backlash": return
	var player_ray := event_index(after.events, "ray", "player")
	check(player_ray >= 0 and first.cells == after.events[player_ray].cells, "C02 cue cells are the actual model backlash ray")
	var board = board_script.new()
	board.set_view(after, {}, [], [], "")
	board.set_presentation(true, frame)
	board.last_events = after.events.duplicate(true)
	board.accent = 1.0
	check(drawn(board, "live legacy pulse") == cue_footprints(first),
		"FY3-C02: active backlash draws ONLY its own tactical cells, not queued aggregate rays")
	# Explicit expired-pulse input exercises the real consumer after all legacy
	# pulse state is gone, without fixing either animation's current duration.
	board.clear_pulse()
	check(board.last_events.is_empty() and board.accent == 0.0 and p.frame().busy,
		"C02 legacy pulse is expired while finite shadow feedback remains active")
	check(drawn(board, "expired legacy pulse") == cue_footprints(first),
		"FY3-C02: consuming storage / expiring old pulse does not erase active backlash tiles")
	# Check throughout this cue, including its final portion, without pinning
	# total duration. Other tactical intentions are a separate board layer.
	var saw_late_backlash := false
	for _step in range(14400):
		var active_frame: Dictionary = p.frame()
		var active: Dictionary = active_frame.get("cue", {})
		if active.is_empty() or active.get("event_index", -1) != first.event_index: break
		if active.get("progress", 0.0) >= 0.75 and not saw_late_backlash:
			saw_late_backlash = true
			board.set_presentation(true, active_frame)
			check(drawn(board, "late backlash") == cue_footprints(active), "FY3-C02: backlash tiles persist through the final portion of the active cue")
		p.advance(1.0 / 240.0)
	check(saw_late_backlash, "C02 sampled late active backlash before its boundary")
	var later: Dictionary = p.frame().get("cue", {})
	check(later.get("type", "") == "resolve", "C02 reaches the queued enemy resolution after backlash")
	var resolved := 0
	while not later.is_empty() and resolved < 20:
		board.set_presentation(true, p.frame())
		if later.get("type", "") == "resolve":
			var index: int = later.get("event_index", -1)
			check(index >= 0 and index < after.events.size() and after.events[index].get("actor", "") == later.get("source", "") and after.events[index].get("cells", []) == later.get("cells", []),
				"C02 later resolve identifies its real ordered enemy ray")
			check(drawn(board, "later enemy resolve") == cue_footprints(later),
				"FY3-C02: later resolve replaces backlash tiles with ONLY its own actor/stage/cells")
			resolved += 1
		later = next_cue(p, later)
	check(resolved > 0 and not p.frame().busy, "C02 exercised later resolutions and finite completion")
	board.set_presentation(true, p.frame())
	check(drawn(board, "settled paper").is_empty(), "finished cue leaves no stale tactical effect tiles")
	check(scenario.game.snapshot() == after, "footprint rendering and clock advancement leave the real model unchanged")

	# Plain feedback and unconfirmed exact previews retain their existing complete
	# event projection. The fix must not globally filter all UI to one cue.
	board.set_presentation(false, frame)
	board.last_events = after.events.duplicate(true)
	check(drawn(board, "plain legacy feedback") == aggregate, "plain legacy footprint behavior is preserved")
	board.set_presentation(true, frame)
	board.set_view(after, after, [], [], "")
	board.clear_pulse()
	check(drawn(board, "exact preview") == aggregate, "unconfirmed preview retains all exact ordered event footprints")
	board.free()

func collect_mixed_feedback(g, p, after: Dictionary, label: String, expect_capture: bool = false) -> void:
	# Consume the same deterministic time/frame and drawing boundary as C02.
	# Do not prescribe an added cue kind, private queue or visual-duration value.
	# Every committed ray/area must get a readable ordered stage even when only
	# shove has an animated hand. An aggregate of queued later effects is not one.
	var expected := expected_from_events(after.events)
	var observed: Array = []
	var board = board_script.new()
	board.set_view(after, {}, [], [], "")
	board.last_events = after.events.duplicate(true)
	board.accent = 1.0
	var previous: Array = []
	var capture_seen := false
	var detached_checked := false
	var finished := false
	for step in range(14400):
		var frame: Dictionary = p.frame()
		board.set_presentation(true, frame)
		var rows = board.call("effect_footprints")
		if not rows is Array:
			check(false, label + ": actual footprint consumer returns an array")
			break
		if step == 0 or rows != previous:
			rows = drawn(board, label + " stage transition")
			check(rows.size() <= 1, "FY3-C03: " + label + " never shows queued aggregate footprints early")
			if not rows.is_empty():
				var next: int = observed.size()
				check(next < expected.size() and rows.size() == 1 and rows[0] == expected[next],
					"FY3-C03: " + label + " next drawn actor/type/stage/cells follow real event order")
				for row in rows:
					if row is Dictionary: observed.append(row.duplicate(true))
					else: check(false, label + ": observed stage is a dictionary")
				if not detached_checked and rows[0] is Dictionary and rows[0].get("cells") is Array:
					detached_checked = true
					var intact: Array = rows.duplicate(true)
					rows[0].cells.append([99, 99])
					check(board.call("effect_footprints") == intact, label + ": consumed footprint cells are detached")
					rows = intact
		previous = rows.duplicate(true)
		var cue: Dictionary = frame.get("cue", {})
		if expect_capture and not capture_seen and cue.get("type", "") == "capture":
			capture_seen = true
			check(observed == expected and rows.is_empty(),
				"FY3-C03: bolt backlash feedback finishes BEFORE shove capture transfer, not hidden underneath it")
		if step == 0:
			# The complete ordered transition must remain available after the
			# legacy pulse expires; no production pulse-duration assumption.
			board.clear_pulse()
		if not frame.get("busy", false):
			finished = true
			break
		p.advance(1.0 / 240.0)
	check(finished, label + ": ordered mixed feedback completes within a generous 60-second bound")
	check(observed == expected, "FY3-C03: " + label + " displays EVERY committed ray/area once in order, including non-shove effects")
	if expect_capture: check(capture_seen, "C03 replacement eventually presents the actual shove acquisition")
	board.set_presentation(true, p.frame())
	check(drawn(board, label + " settled").is_empty(), label + ": no stale committed footprints after finite completion")
	check(g.snapshot() == after, label + ": presentation time/render queries do not change model outcomes")
	board.free()

func test_bolt_backlash_before_shove_capture() -> void:
	var g = game(F.bolt_to_shove())
	var p = Shadow.new()
	p.reset(g.snapshot(), 1)
	if commit(g, p, {"type": "capture", "source": "bolt"}).is_empty(): return
	p.advance(60.0)
	var after := commit(g, p, {"type": "capture", "source": "shove"})
	if after.is_empty(): return
	var backlash := event_index(after.events, "backlash")
	var ray := event_index(after.events, "ray", "player")
	var acquisition := event_index(after.events, "capture")
	check(after.status == "playing" and after.stored.get("source", "") == "shove",
		"C03 controlled replacement survives and acquires shove")
	check(backlash >= 0 and ray > backlash and acquisition > ray and after.events[backlash].get("kind", "") == "bolt" and after.events[ray].get("kind", "") == "bolt",
		"C03 actual model emits bolt backlash/ray BEFORE shove acquisition")
	check(event_index(after.events, "damage", "player") > ray and event_index(after.events, "damage", "shove") > ray,
		"C03 bolt backlash genuinely affects player and new source, not just an empty marker")
	collect_mixed_feedback(g, p, after, "bolt backlash then shove capture", true)

func test_mixed_enemy_resolution() -> void:
	for order in [["bolt", "shove", "burst"], ["burst", "shove", "bolt"]]:
		var g = game(F.mixed_resolution(order))
		var p = Shadow.new()
		p.reset(g.snapshot(), 1)
		var after := commit(g, p, {"type": "end_turn"})
		if after.is_empty(): continue
		var expected := expected_from_events(after.events)
		var actors: Array = []
		var cells: Array = []
		var has_area := false
		for row in expected:
			actors.append(row.actor)
			if not cells.has(row.cells): cells.append(row.cells)
			if row.actor == "burst" and row.type == "area": has_area = true
		check(after.status == "playing" and actors == order and cells.size() == 3 and has_area,
			"C03 actual mixed fixture has distinct ray/area geometry in requested source order: " + str(order))
		collect_mixed_feedback(g, p, after, "mixed enemy order " + str(order))

func actor_grid(board, id: String) -> Vector2:
	for row in board._visual_actors():
		if row.actor == id: return row.grid - Vector2(0.5, 0.5)
	return Vector2(INF, INF)

func test_moves_do_not_leak_into_ability_motion() -> void:
	var transition := MovementFixture.movement_transition()
	var p = Shadow.new()
	p.reset(transition.before, 51)
	check(p.observe(transition.before, {"type": "end_turn"}, transition.after, 51),
		"board timeline receives test-owned old attacks, displacement and voluntary moves")
	var board = board_script.new()
	board.size = Vector2(1024, 650)
	board.theatre_mode = true
	board.set_stage_mode(true)
	board.set_view(transition.after, {}, [], [], "")
	board.show_transition(transition.before)
	var seen: Array = []
	var sliding: Array = []
	for _step in range(14400):
		var frame: Dictionary = p.frame()
		board.set_presentation(true, frame)
		if not frame.busy: break
		var cue: Dictionary = frame.cue
		var index: int = cue.get("event_index", -1)
		if index not in seen:
			seen.append(index)
			check(board.announcement_marks().is_empty() and board.announcement_waves().is_empty(),
				"board does not draw future next-turn warnings during old effects or slides")
		var a := actor_grid(board, "A")
		var b := actor_grid(board, "B")
		if index in [0, 3]:
			check(a == Vector2(3, 1) and is_equal_approx(b.x, 3.0),
				"future voluntary moves cannot run inside preceding ability feedback")
		if cue.get("type", "") == "move":
			check(drawn(board, "active slide").is_empty(), "a voluntary slide does not invent a ray/area hit footprint")
			var progress: float = cue.get("progress", 0.0)
			if progress > 0.25 and progress < 0.75:
				var id: String = cue.get("actor", "")
				if id not in sliding:
					sliding.append(id)
					if id == "A":
						check(a.x > 2.0 and a.x < 3.0 and is_equal_approx(a.y, 1.0)
							and b == Vector2(3, 3), "A slides on its own event; B waits after its ability displacement")
					elif id == "B":
						check(a == Vector2(2, 1) and b.x > 2.0 and b.x < 3.0
							and is_equal_approx(b.y, 3.0), "B slides only after A has reached its committed destination")
		p.advance(1.0 / 120.0)
	check(seen == [0, 3, 5, 6] and sliding == ["A", "B"], "actual board interpolation exercises both distinct finite slides")
	board.set_presentation(true, p.frame())
	check(actor_grid(board, "A") == Vector2(2, 1) and actor_grid(board, "B") == Vector2(2, 3),
		"settled figures end at exact authoritative cells without changing the model")
	check(board.announcement_marks().size() == 1, "settled board exposes the fresh shove announcement, not old resolved cells")
	board.free()

func _run() -> void:
	if not _setup():
		quit(2)
		return
	test_local_backlash_lethality()
	test_active_cue_footprints()
	test_bolt_backlash_before_shove_capture()
	test_mixed_enemy_resolution()
	test_moves_do_not_leak_into_ability_motion()
	print("Shadow rendering regressions: %d checks, %d failures. Drawing decisions only; no visual-appeal or physical-input acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
