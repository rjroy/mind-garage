extends SceneTree
## Controller behavior, using real model outcomes. No renderer or production content.

const Encounter = preload("res://model/encounter.gd")
const F = preload("res://tests/shadow_fixtures.gd")
const COMPONENT := "res://ui/shadow_presentation.gd"
var controller_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func _setup() -> bool:
	if not ResourceLoader.exists(COMPONENT):
		printerr("SETUP REQUIRED: ", COMPONENT, " is absent. Install the safe empty interface scaffold described in pilot-brief.md; this is not behavioral RED.")
		return false
	controller_script = load(COMPONENT)
	if controller_script == null or not controller_script.can_instantiate():
		printerr("SETUP REQUIRED: shadow presentation script must be loadable and instantiable; parse/import errors are not behavioral RED.")
		return false
	var probe = controller_script.new()
	if not probe is RefCounted:
		printerr("SETUP REQUIRED: controller must extend RefCounted.")
		return false
	var required := {"reset": 2, "observe": 4, "advance": 1, "frame": 0}
	for name in required:
		if not probe.has_method(name):
			printerr("SETUP REQUIRED: missing controller method ", name)
			return false
		for method in probe.get_method_list():
			if method.name == name and method.args.size() != required[name]:
				printerr("SETUP REQUIRED: wrong argument count for ", name)
				return false
	var initial = probe.frame()
	if not _shape(initial):
		printerr("SETUP REQUIRED: frame() must return the documented safe dictionary shape, even before reset.")
		return false
	return true

func _shape(value: Variant) -> bool:
	if not value is Dictionary: return false
	var fields_ok: bool = value.get("generation") is int and value.get("announcements") is Array and value.get("held") is Dictionary and value.get("cues") is Array and value.get("cue") is Dictionary and value.get("busy") is bool and (value.get("loop_phase") is float or value.get("loop_phase") is int)
	if not fields_ok: return false
	if value.loop_phase < 0.0 or value.loop_phase >= 1.0: return false
	if value.busy != (not value.cue.is_empty()): return false
	if value.busy:
		var progress = value.cue.get("progress")
		if not (progress is float or progress is int): return false
		if progress < 0.0 or progress > 1.0: return false
	return true

func view(p, label: String) -> Dictionary:
	var result = p.frame()
	check(_shape(result), label + ": safe frame schema")
	return result if _shape(result) else {}

func game(fixture: Dictionary):
	var g = Encounter.new()
	g.configure(fixture, "R2")
	return g

func controller(snapshot: Dictionary, generation: int = 1):
	var p = controller_script.new()
	p.reset(snapshot, generation)
	return p

func apply(g, p, action: Dictionary, generation: int = 1) -> Dictionary:
	var before: Dictionary = g.snapshot()
	var assessment: Dictionary = g.assess(action)
	check(assessment.get("legal", false), "controlled fixture command is legal: " + str(action))
	if not assessment.get("legal", false): return {}
	if not g.act(action):
		check(false, "model committed assessed fixture command")
		return {}
	var after: Dictionary = g.snapshot()
	var before_copy := before.duplicate(true)
	var action_copy := action.duplicate(true)
	var after_copy := after.duplicate(true)
	var accepted = p.observe(before, action, after, generation)
	check(accepted is bool and accepted, "observe accepts a confirmed transition in the current generation")
	check(before == before_copy and action == action_copy and after == after_copy, "observe does not mutate supplied snapshots or command")
	check(g.snapshot() == after_copy, "presentation does not change the real model")
	return after

func find_source(rows: Array, source: String) -> Dictionary:
	for row in rows:
		if not row is Dictionary:
			check(false, "announcement entries are dictionaries")
			continue
		if row.get("source", "") == source: return row
	return {}

func cue_types(frame: Dictionary) -> Array:
	var result := []
	for cue in frame.get("cues", []):
		if not cue is Dictionary:
			check(false, "cue entries are dictionaries")
			continue
		result.append(cue.get("type", ""))
	return result

func footprint(snapshot: Dictionary, actor: String) -> Array:
	for event in snapshot.get("events", []):
		if event.get("type", "") == "ray" and event.get("actor", "") == actor: return event.get("cells", [])
	return []

func drain(p, g, label: String) -> void:
	var model_before: Dictionary = g.snapshot()
	p.advance(60.0)
	var settled := view(p, label)
	check(not settled.get("busy", true) and settled.get("cue", {"missing": true}).is_empty(), label + ": finite cues finish despite persistent loops")
	check(g.snapshot() == model_before, label + ": advancing presentation cannot advance the game")

func test_reset_and_ownership() -> void:
	var fixture := F.single()
	fixture.enemies.append(F.foe("bolt", [5, 5], [0, -1], 8, F.ability("bolt")))
	var g = game(fixture)
	var snapshot: Dictionary = g.snapshot()
	var input_copy := snapshot.duplicate(true)
	var p = controller(snapshot)
	var frame := view(p, "reset")
	check(snapshot == input_copy, "reset does not mutate supplied state")
	check(frame.get("generation", -1) == 1 and not frame.get("busy", true) and frame.get("cues", [1]).is_empty(), "reset creates settled state without replaying events")
	var announcements: Array = frame.get("announcements", [])
	check(announcements.size() == 1 and not find_source(announcements, "shover").is_empty(), "one-shove pilot exposes shove announcements only")
	var announcement := find_source(announcements, "shover")
	check(announcement.get("kind", "") == "shove" and announcement.get("turn", -1) == snapshot.turn and announcement.get("cells", []) == snapshot.intentions[0].cells, "announcement identity and cells come from current intentions")
	var captured := apply(g, p, {"type": "capture", "source": "shover"})
	if captured.is_empty(): return
	frame = view(p, "captured")
	check(frame.get("announcements", [1]).is_empty(), "capture removes that occurrence's action shadow")
	check(frame.get("held", {}).get("source", "") == "shover" and frame.get("held", {}) == captured.stored, "held shove facts are a detached copy of authoritative storage")
	check(frame.get("busy", false) and cue_types(frame) == ["capture"], "capture has a finite transfer cue")
	var cue: Dictionary = frame.get("cue", {})
	check(cue.get("type", "") == "capture" and cue.get("from", []) == fixture.enemies[0].pos and cue.get("to", []) == captured.player.pos, "capture cue associates actual owner with the player anchor")
	drain(p, g, "capture completion")
	frame = view(p, "held idle")
	check(frame.get("held", {}).get("source", "") == "shover", "held motif persists after finite capture finishes")
	var second := apply(g, p, {"type": "end_turn"})
	if second.is_empty(): return
	drain(p, g, "fresh announcement completion")
	frame = view(p, "fresh announcement while held")
	announcement = find_source(frame.get("announcements", []), "shover")
	check(announcement.get("turn", -1) == 2 and frame.get("held", {}).get("captured_turn", -1) == 1, "fresh enemy occurrence coexists with the previous held shadow")
	check(not frame.get("busy", true) and not announcement.is_empty(), "persistent announcement does not hold completion busy")
	# Reset from a snapshot containing prior events restores facts without replay.
	p.reset(second, 2)
	frame = view(p, "restore settled snapshot")
	check(frame.get("cues", [1]).is_empty() and not frame.get("busy", true), "reset ignores historical snapshot events")
	check(frame.get("held", {}) == second.stored, "reset restores an already-held ability")

func test_release_and_expiry() -> void:
	var g = game(F.single())
	var p = controller(g.snapshot())
	if apply(g, p, {"type": "capture", "source": "shover"}).is_empty(): return
	drain(p, g, "before release")
	var released := apply(g, p, {"type": "release", "target": [3, 3]})
	if released.is_empty(): return
	var frame := view(p, "release")
	check(frame.get("held", {"missing": true}).is_empty() and cue_types(frame) == ["release"], "release consumes held motif and presents the same ability")
	var cue: Dictionary = frame.get("cue", {})
	check(cue.get("kind", "") == "shove" and cue.get("source", "") == "shover" and cue.get("from", []) == [2, 3] and cue.get("to", []) == [3, 3], "release retains ability/source and actual origin/target")
	check(cue.get("cells", []) == footprint(released, "player"), "release footprint is copied from actual resolution, not calculated by presentation")
	var at_start := view(p, "paused release")
	p.advance(0.0)
	check(p.frame() == at_start, "zero advancement supports a stable paused frame")
	drain(p, g, "release completion")
	g = game(F.single())
	p = controller(g.snapshot())
	if apply(g, p, {"type": "capture", "source": "shover"}).is_empty(): return
	drain(p, g, "before capture-turn end")
	if apply(g, p, {"type": "end_turn"}).is_empty(): return
	drain(p, g, "before deadline")
	var expired := apply(g, p, {"type": "end_turn"})
	if expired.is_empty(): return
	frame = view(p, "expiry")
	check(frame.get("held", {"missing": true}).is_empty() and cue_types(frame) == ["backlash", "resolve"], "deadline discharge precedes surviving enemy shove resolution")
	check(frame.get("cue", {}).get("cells", []) == footprint(expired, "player"), "backlash preserves complete model-authored self-centered footprint")
	check(frame.get("cue", {}).get("from", []) == [2, 3], "backlash anchors at the player's actual position")
	drain(p, g, "expiry completion")

func test_replacement_outcomes() -> void:
	for outcome in ["acquired", "source_dead", "out_of_reach", "lethal"]:
		var g = game(F.replacement(outcome))
		var p = controller(g.snapshot())
		if apply(g, p, {"type": "capture", "source": "old"}).is_empty(): continue
		drain(p, g, "before replacement " + outcome)
		var after := apply(g, p, {"type": "capture", "source": "new"})
		if after.is_empty(): continue
		var frame := view(p, "replacement " + outcome)
		var types := cue_types(frame)
		if outcome == "acquired":
			check(types == ["backlash", "capture"] and frame.get("held", {}).get("source", "") == "new", "successful replacement queues old discharge before new transfer")
			var cues: Array = frame.get("cues", [])
			if cues.size() == 2 and cues[0] is Dictionary and cues[1] is Dictionary:
				check(cues[0].get("source", "") == "old" and cues[1].get("source", "") == "new" and cues[0].get("event_index", -1) < cues[1].get("event_index", -1), "replacement cue sources and order match event ownership")
			else: check(false, "replacement exposes two inspectable ordered cues")
		else:
			check(types == ["backlash"] and frame.get("held", {"missing": true}).is_empty(), outcome + ": no transfer or acquisition after failed/lethal replacement")
			var model_outcome := false
			for event in after.events:
				if event.type == "capture_failed" and event.get("reason", "") == outcome: model_outcome = true
				if event.type == "loss" and outcome == "lethal": model_outcome = true
			check(model_outcome, "controlled fixture actually exercises " + outcome)
		check(frame.get("cue", {}).get("cells", []) == footprint(after, "player"), outcome + ": full backlash footprint remains visible, even on death")
		drain(p, g, "replacement completion " + outcome)

func test_source_death_and_stale_events() -> void:
	var g = game(F.source_death())
	var p = controller(g.snapshot())
	if apply(g, p, {"type": "capture", "source": "shover"}).is_empty(): return
	drain(p, g, "before source death")
	var after := apply(g, p, {"type": "end_turn"})
	if after.is_empty(): return
	var died := false
	for event in after.events:
		if event.type == "death" and event.get("actor", "") == "shover": died = true
	check(died, "controlled friendly-fire fixture kills the stored source")
	var frame := view(p, "stored source dead")
	check(frame.get("held", {}) == after.stored and frame.get("held", {}).get("source", "") == "shover", "source death does not remove a still-owned stored ability")
	check(frame.get("announcements", [1]).is_empty(), "dead source cannot reannounce; other ability kinds are outside this pilot")
	g = game(F.single())
	p = controller(g.snapshot(), 7)
	var before: Dictionary = g.snapshot()
	var command := {"type": "capture", "source": "shover"}
	if apply(g, p, command, 7).is_empty(): return
	var current: Dictionary = g.snapshot()
	var visual_before := view(p, "active transfer before rejected command")
	var invalid := {"type": "capture", "source": "absent"}
	check(not g.act(invalid) and g.snapshot() == current, "invalid model command leaves prior events unchanged")
	check(not p.observe(current, invalid, g.snapshot(), 7) and p.frame() == visual_before, "unchanged rejected transition does not replay stale events or disturb the active cue")
	var input_copy := current.duplicate(true)
	p.reset(current, 8)
	var reset_frame := view(p, "new generation")
	check(reset_frame.get("generation", -1) == 8 and not reset_frame.get("busy", true), "restart/reset cancels prior finite work")
	check(not p.observe(before, command, current, 7) and p.frame() == reset_frame, "late old-generation transition cannot resurrect a transfer")
	check(not p.observe(before, command, current, 9) and p.frame() == reset_frame, "uninitialized future generation is not implicitly accepted")
	p.reset(before, 7)
	check(p.frame() == reset_frame and current == input_copy, "stale reset cannot replace newer state or mutate inputs")
	p.advance(60.0)
	frame = view(p, "after stale cue drain")
	check(frame.get("held", {}) == current.stored and not frame.get("busy", true), "advancing after cancellation cannot restore old transient work")

func test_detachment_and_time() -> void:
	var g = game(F.single())
	var state: Dictionary = g.snapshot()
	var p = controller(state)
	var frame := view(p, "detachment input")
	var reference := frame.duplicate(true)
	var announcements: Array = frame.get("announcements", [])
	if not announcements.is_empty() and announcements[0] is Dictionary:
		announcements[0]["source"] = "caller-edit"
		var cells = announcements[0].get("cells", [])
		if cells is Array: cells.append([99, 99])
	else: check(false, "detachment test needs a real announcement")
	check(p.frame() == reference, "frame returns detached nested announcement data")
	var initial: Dictionary = p.frame()
	p.advance(-1.0)
	check(p.frame() == initial, "negative advancement is ignored")
	var twin = controller(state)
	p.advance(0.125)
	twin.advance(0.125)
	check(p.frame() == twin.frame(), "same input state and delta produce deterministic paused visual state")
	check(g.snapshot() == state, "advancement of persistent loops does not change model state")
	if apply(g, p, {"type": "capture", "source": "shover"}).is_empty(): return
	frame = view(p, "nested held and cue detachment")
	reference = frame.duplicate(true)
	var held: Dictionary = frame.get("held", {})
	var cue: Dictionary = frame.get("cue", {})
	if not held.is_empty(): held["source"] = "caller-edit"
	else: check(false, "detachment test needs authoritative held state")
	if not cue.is_empty(): cue["source"] = "caller-edit"
	else: check(false, "detachment test needs active transfer")
	var cues: Array = frame.get("cues", [])
	if not cues.is_empty() and cues[0] is Dictionary: cues[0]["source"] = "caller-edit"
	check(p.frame() == reference, "held, active cue and cue plan are detached from consumers")
	var unchanged: Dictionary = p.frame()
	p.advance(0.0)
	check(p.frame() == unchanged, "pause preserves active cue progress")
	# A consumer can edit its own input dictionaries after a call without changing
	# the controller or real model. This is distinct from output detachment above.
	var input: Dictionary = g.snapshot()
	var isolated = controller(input, 50)
	var protected: Dictionary = isolated.frame()
	input.enemies.clear()
	input.stored["source"] = "caller-edit"
	input.stored.ability["range"] = 99
	check(isolated.frame() == protected, "reset owns deep copies rather than retaining mutable input storage")
	var other = game(F.single())
	var before: Dictionary = other.snapshot()
	var action := {"type": "capture", "source": "shover"}
	if not other.act(action):
		check(false, "controlled input-detachment capture is legal")
		return
	var after: Dictionary = other.snapshot()
	var model_copy := after.duplicate(true)
	isolated.reset(before, 51)
	check(isolated.observe(before, action, after, 51), "input-detachment transition is accepted")
	protected = isolated.frame()
	before.enemies[0].pos[0] = 99
	after.stored.ability["range"] = 99
	after.events.clear()
	action["source"] = "caller-edit"
	check(isolated.frame() == protected and other.snapshot() == model_copy, "observe owns copies of historical anchors, events, held data and command")

func _run() -> void:
	if not _setup():
		quit(2)
		return
	test_reset_and_ownership()
	test_release_and_expiry()
	test_replacement_outcomes()
	test_source_death_and_stale_events()
	test_detachment_and_time()
	print("Shadow presentation behavior: %d checks, %d failures. Controller only; no visual or runtime-style acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
