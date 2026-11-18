extends SceneTree
## Finite event-owned presentation. Controlled facts, no combat planner or live tuning.

const F = preload("res://tests/shadow_fixtures.gd")
const MovementFixture = preload("res://ui/smoke_fixtures.gd")
const Controller = preload("res://ui/shadow_presentation.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func controller(snapshot: Dictionary, generation: int = 1):
	var p = Controller.new()
	p.reset(snapshot, generation)
	return p

func view(p, label: String) -> Dictionary:
	var frame: Dictionary = p.frame()
	check(frame.get("generation") is int and frame.get("announcements") is Array
		and frame.get("held") is Dictionary and frame.get("cues") is Array
		and frame.get("cue") is Dictionary and frame.get("busy") is bool,
		label + ": safe detached frame schema")
	check(frame.get("loop_phase", -1.0) >= 0.0 and frame.get("loop_phase", 1.0) < 1.0,
		label + ": shared loop phase is normalized")
	check(frame.get("busy", false) == not frame.get("cue", {}).is_empty(), label + ": only finite work is busy")
	if frame.get("busy", false):
		check(frame.cue.get("progress", -1.0) >= 0.0 and frame.cue.get("progress", 2.0) <= 1.0,
			label + ": finite cue progress is bounded")
	return frame

func observe(p, transition: Dictionary, generation: int = 1) -> void:
	var saved := transition.duplicate(true)
	check(p.observe(transition.before, transition.command, transition.after, generation), "current-generation transition accepted")
	check(transition == saved, "observe never mutates snapshots, command or nested events")

func cue_types(frame: Dictionary) -> Array:
	var result: Array = []
	for cue in frame.get("cues", []): result.append(cue.get("type", ""))
	return result

func seek(p, type: String) -> Dictionary:
	for _step in range(14400):
		var frame: Dictionary = p.frame()
		if frame.get("cue", {}).get("type", "") == type: return frame
		if not frame.get("busy", false): break
		p.advance(1.0 / 240.0)
	check(false, "finite sequence reaches " + type)
	return {}

func test_arm_is_not_acquisition() -> void:
	var before := F.state()
	var after := before.duplicate(true)
	after.capture_armed = true
	after.action_points = 2
	after.events = [{"type": "capture_armed"}]
	var p = controller(before)
	observe(p, {"before": before, "after": after, "command": {"type": "capture"}})
	var frame := view(p, "armed")
	check(frame.get("held", {}).is_empty() and frame.get("cues", []).is_empty(),
		"arming alone never creates acquisition/transfer or cancels enemy attacks")
	check(frame.get("announcements", []).size() == 1
		and frame.announcements[0].cells == before.intentions[0].cells,
		"armed attacker still announces its exact damaging shove")
	# Misses and later turns can remain armed; reset must not fabricate history.
	after.turn = 4
	p.reset(after, 2)
	check(not p.frame().busy and p.frame().held.is_empty(), "restored persistent arming is not replayed as a transfer")

func test_damage_then_acquisition_before_next_attack() -> void:
	for replacement in [false, true]:
		var transition := F.armed_hit(replacement)
		var p = controller(transition.before)
		observe(p, transition)
		var frame := view(p, "hit feedback")
		check(cue_types(frame) == ["resolve", "capture", "resolve"],
			"complete normal first strike precedes transfer, then independent second attack")
		var cues: Array = frame.get("cues", [])
		if cues.size() != 3: continue
		check(cues[0].event_index == 0 and cues[1].event_index == 3 and cues[2].event_index == 4,
			"finite stages own actual ordered model event indices, not invented resolution")
		check(cues[0].cells == transition.after.events[0].cells and cues[2].cells == transition.after.events[4].cells,
			"both enemy attacks retain their full model-authored footprints")
		check(cues[1].get("source", "") == "A" and cues[1].get("from", []) == [2, 1]
			and cues[1].get("to", []) == [2, 4],
			"transfer anchors at attacker and player AFTER normal attack displacement")
		var expected_old: Dictionary = transition.before.stored if replacement else {}
		check(frame.get("held", {}) == expected_old,
			"future acquisition cannot replace the old visible motif before damaging attack finishes")
		frame = seek(p, "capture")
		if frame.is_empty(): continue
		check(frame.get("held", {}).is_empty(), "active handoff does not duplicate the incoming held motif")
		frame = seek(p, "resolve")
		check(frame.get("cue", {}).get("source", "") == "B" and frame.get("held", {}) == transition.after.stored,
			"new motif is held after transfer while the second attack still proceeds")
		p.advance(60.0)
		frame = view(p, "settled acquisition")
		check(not frame.busy and frame.held == transition.after.stored and not frame.announcements.is_empty(),
			"settlement retains the acquired ability AND fresh living source announcement")

func test_reusable_shine_and_source_loss() -> void:
	for kind in ["shove", "bolt", "burst"]:
		var transition := F.shine_transition(kind)
		var p = controller(transition.before)
		observe(p, transition)
		var frame := view(p, kind + " shine")
		check(cue_types(frame) == ["shine"] and frame.get("held", {}) == transition.before.stored,
			kind + ": Shine is a player ability stage without consuming the held ability")
		var cue: Dictionary = frame.get("cue", {})
		check(cue.get("type", "") == "shine" and cue.get("source", "") == "A"
			and cue.get("from", []) == transition.before.player.pos and cue.get("to", []) == transition.command.target
			and cue.get("cells", []) == transition.after.events[1].cells
			and cue.get("footprint_type", "") == transition.after.events[1].type,
			kind + ": Shine uses actual source, selected endpoint, ray/area and full geometry")
		p.advance(60.0)
		check(not p.frame().busy and p.frame().held == transition.before.stored, "Shine completion keeps reusable storage")
		# Repeating the same action is another finite occurrence, not consumed data.
		var again := transition.duplicate(true)
		again.before = transition.after.duplicate(true)
		again.after.action_points = 1
		observe(p, again)
		check(cue_types(p.frame()) == ["shine"], "repeated Shine is independently presented")
	var lost := F.shine_transition("shove", true)
	var p = controller(lost.before)
	observe(p, lost)
	check(p.frame().get("held", {}) == lost.before.stored,
		"source-killing Shine keeps its borrowed identity while its full ability resolves")
	p.advance(60.0)
	check(p.frame().held.is_empty() and not p.frame().busy, "ability_lost clears the settled motif after source death")
	p.reset(lost.after, 2)
	check(p.frame().held.is_empty() and p.frame().cues.is_empty(), "restored dead source cannot resurrect held power")

func test_detachment_time_and_generation() -> void:
	var transition := F.armed_hit()
	var p = controller(transition.before, 7)
	var initial: Dictionary = p.frame()
	var output: Dictionary = p.frame()
	output.announcements[0].cells.append([99, 99])
	check(p.frame() == initial, "nested announcement output detached")
	p.advance(-1.0)
	p.advance(0.0)
	check(p.frame() == initial, "nonpositive delta cannot advance presentation")
	var twin = controller(transition.before, 7)
	p.advance(0.125)
	twin.advance(0.125)
	check(p.frame() == twin.frame(), "same facts/delta produce deterministic shared phase")
	observe(p, transition, 7)
	var protected: Dictionary = p.frame()
	var frame: Dictionary = p.frame()
	frame.cues[0].cells.append([99, 99])
	frame.cue["source"] = "caller"
	check(p.frame() == protected, "active and planned cue data detached")
	check(not p.observe(transition.after, {"type": "capture"}, transition.after, 7)
		and p.frame() == protected, "rejected unchanged command never replays old damage or acquisition")
	p.reset(transition.after, 8)
	protected = p.frame()
	check(not p.observe(transition.before, transition.command, transition.after, 7)
		and not p.observe(transition.before, transition.command, transition.after, 9),
		"old or uninitialized future generation cannot revive a transfer")
	p.reset(transition.before, 7)
	check(p.frame() == protected and not p.frame().busy, "stale reset cannot undo cancellation")
	var supplied: Dictionary = transition.after.duplicate(true)
	p.reset(supplied, 9)
	protected = p.frame()
	supplied.stored.ability.range = 99
	supplied.enemies.clear()
	check(p.frame() == protected, "reset deeply owns held/actor input dictionaries")
	observe(p, transition, 9)
	protected = p.frame()
	transition.after.events.clear()
	transition.after.stored.ability.range = 99
	transition.command["type"] = "caller"
	check(p.frame() == protected, "observe deeply owns event, storage and command inputs")

func test_ordered_moves_and_fresh_warnings() -> void:
	var transition := MovementFixture.movement_transition()
	var saved := transition.duplicate(true)
	var p = controller(transition.before, 31)
	check(p.observe(transition.before, {"type": "end_turn"}, transition.after, 31), "ordered movement accepted")
	check(cue_types(p.frame()) == ["resolve", "resolve", "move", "move"], "slides remain separate from preceding ability displacement")
	var observed: Array = []
	var moving := false
	for _step in range(14400):
		var frame: Dictionary = p.frame()
		if not frame.busy: break
		check(frame.announcements.is_empty(), "fresh warnings stay quiet throughout old attacks AND slides")
		var cue: Dictionary = frame.cue
		var identity: int = cue.get("event_index", -1)
		if identity not in observed: observed.append(identity)
		if cue.get("type", "") == "move":
			var event: Dictionary = transition.after.events[identity]
			check(cue.get("actor", "") == event.actor and cue.get("from", []) == event.from
				and cue.get("to", []) == event.to, "slide preserves actual actor, event index and endpoints")
			moving = moving or cue.progress > 0.0
		p.advance(1.0 / 120.0)
	check(observed == [0, 3, 5, 6] and moving, "both slides progress only in their ordered stages")
	check(not p.frame().busy and p.frame().announcements[0].turn == transition.after.turn,
		"fresh rehearsal appears only when finite work settles")
	check(transition == saved, "presentation clock never changes combat facts")
	p.reset(transition.before, 32)
	check(not p.observe(transition.before, {"type": "end_turn"}, transition.after, 31) and not p.frame().busy,
		"restart cancels old movement generation")

func test_locked_swap_announcements_and_misses() -> void:
	for invalid in [false, true]:
		var t := F.swap_miss(invalid)
		var p = controller(t.before)
		var announcements: Array = p.frame().announcements
		check(announcements.size() == 1, "Switcher exposes its targeted announcement, not only shove rehearsals")
		if announcements.size() == 1:
			var row: Dictionary = announcements[0]
			check(row.get("kind", "") == "swap" and row.get("source", "") == "A"
				and row.get("cells", []) == [[2, 3]] and row.get("from", []) == t.before.intentions[0].from
				and row.get("target", []) == [2, 3], "announcement preserves current source and locked cell without homing on the moved player")
		observe(p, t)
		var frame := view(p, "swap miss")
		check(cue_types(frame) == ["resolve"], "even a missed exchange gets one finite mask-owned attack, never a fabricated swap or capture")
		var cue: Dictionary = frame.get("cue", {})
		var mask: Dictionary = t.after.events[0]
		check(cue.get("footprint_type", "") == "mask" and cue.get("cells", [99]) == mask.cells
			and cue.get("from", []) == mask.from and cue.get("to", []) == mask.target
			and cue.get("event_index", -1) == 0, "valid empty miss keeps its singleton mask; invalid geometry keeps the authoritative empty mask")
		p.advance(60.0)
		check(not p.frame().busy and p.frame().held.is_empty() and t.after.capture_armed
			and t.after.player == t.before.player, "miss finishes honestly without damage, relocation, acquisition or consuming arming")

func test_exchange_then_damage_then_acquisition() -> void:
	for pair in [false, true]:
		var t := F.swap_hit(pair, pair)
		var p = controller(t.before)
		observe(p, t)
		var frame := view(p, "Switcher attack")
		var expected := ["resolve", "capture", "resolve"] if pair else ["resolve", "capture"]
		check(cue_types(frame) == expected, "atomic paired movement remains INSIDE its mask-owned ability before acquisition and the other attack")
		var cues: Array = frame.cues
		if cues.size() != expected.size(): continue
		var mask: Dictionary = t.after.events[0]
		check(cues[0].kind == "swap" and cues[0].footprint_type == "mask"
			and cues[0].event_index == 0 and cues[0].cells == mask.cells
			and cues[0].from == mask.from and cues[0].to == mask.target,
			"resolve cue is owned by the explicit mask, not manufactured from the later exchange")
		check(t.after.events[1].type == "swap" and t.after.events[2].type == "damage"
			and cues[1].get("event_index", -1) == 3, "exchange completes before normal damage, then actual capture")
		check(cues[1].get("from", []) == [2, 3] and cues[1].get("to", []) == [2, 1],
			"capture transfer starts at the source AFTER exchanging and lands at the player's exchanged position")
		check(frame.held == t.before.stored, "old held ownership remains during the complete incoming exchange and damage")
		frame = seek(p, "capture")
		check(frame.get("held", {"missing": true}).is_empty(), "actual transfer never duplicates the acquired Swap motif")
		p.advance(60.0)
		check(p.frame().held == t.after.stored and not p.frame().busy,
			"settled captured Swap is reusable and retains actual source identity")
		p.reset(t.before, 2)
		check(not p.observe(t.before, t.command, t.after, 1) and not p.frame().busy,
			"old-generation exchange cannot restart after cancellation")
	var other := F.swap_other_occupant()
	var p = controller(other.before)
	observe(p, other)
	var cues: Array = p.frame().cues
	check(cue_types(p.frame()) == ["resolve", "resolve"], "another occupant is hit without inventing player acquisition")
	if cues.size() == 2:
		check(cues[0].to == [4, 1] and cues[1].get("source", "") == "B" and cues[1].get("from", []) == [2, 1],
			"B's later attack starts from its real exchanged position, not its old cell")
	check(other.after.capture_armed and other.after.stored.is_empty(), "hitting a different living occupant does not consume the player's armed capture")

func test_swap_shine_reuse_source_loss_and_detachment() -> void:
	for loss in [false, true]:
		var t := F.swap_shine(loss)
		var p = controller(t.before)
		observe(p, t)
		var frame := view(p, "Swap Shine")
		check(cue_types(frame) == ["shine"], "Shine owns mask, atomic exchange and damage as one finite ability")
		var cue: Dictionary = frame.get("cue", {})
		var mask: Dictionary = t.after.events[1]
		check(cue.get("kind", "") == "swap" and cue.get("footprint_type", "") == "mask"
			and cue.get("cells", []) == mask.cells and cue.get("from", []) == mask.from
			and cue.get("to", []) == mask.target and cue.get("event_index", -1) == 0,
			"Swap Shine uses its explicit mask and selected target, not a ray or final actor position")
		check(frame.held == t.before.stored and t.after.player.pos == [2, 1],
			"held Swap stays through the full source-killing exchange; player relocation is already authoritative")
		var saved: Dictionary = p.frame()
		if not frame.cue.is_empty():
			frame.cue["from"] = [99, 99]
			frame.cue["to"] = [99, 99]
			frame.cue.cells.append([99, 99])
		check(p.frame() == saved, "mask endpoints and geometry are deeply detached from consumers")
		p.advance(60.0)
		check(p.frame().held == t.after.stored and not p.frame().busy,
			"normal Shine retains Swap, while actual source death clears it only after full resolution")
		if not loss:
			var repeated := t.duplicate(true)
			repeated.before = t.after.duplicate(true)
			repeated.command.target = [2, 3]
			repeated.after = t.before.duplicate(true)
			repeated.after.action_points = 1
			repeated.after.enemies[0].hp = 3
			repeated.after.events = [
				{"type": "shine", "source": "A", "kind": "swap", "target": [2, 3]},
				{"type": "mask", "actor": "player", "kind": "swap", "from": [2, 1], "target": [2, 3], "cells": [[2, 3]]},
				{"type": "swap", "actor": "player", "other": "A", "from": [2, 1], "to": [2, 3]},
				{"type": "damage", "actor": "A", "amount": 1, "hp": 3},
			]
			observe(p, repeated)
			check(cue_types(p.frame()) == ["shine"] and p.frame().held == t.before.stored, "repeated retained Swap presents another actual exchange without reacquisition")

func _run() -> void:
	test_arm_is_not_acquisition()
	test_damage_then_acquisition_before_next_attack()
	test_reusable_shine_and_source_loss()
	test_detachment_time_and_generation()
	test_ordered_moves_and_fresh_warnings()
	test_locked_swap_announcements_and_misses()
	test_exchange_then_damage_then_acquisition()
	test_swap_shine_reuse_source_loss_and_detachment()
	print("Shadow presentation: %d checks, %d failures. Controlled events, not visual acceptance." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
