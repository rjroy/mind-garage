extends RefCounted
## Deterministic presentation projection. Never calls a model or computes game effects.

const DURATIONS := {"capture": 0.60, "shine": 0.44, "resolve": 0.38, "move": 0.26}
const TACTICAL_DURATION := 0.18
const SWAP_DURATION := 0.60
const P = preload("res://ui/presentation.gd")
var _generation := -1
var _announcements: Array = []
var _held: Dictionary = {}
var _cues: Array = []
var _held_stages: Array = []
var _source_identity_before: Dictionary = {}
var _actors_before: Dictionary = {}
var _index := 0
var _elapsed := 0.0
var _loop_cycles := 0.0
var _new_turn := false

func reset(snapshot: Dictionary, generation: int) -> void:
	if generation < _generation: return
	_generation = generation
	_set_facts(snapshot)
	_cues = []
	_held_stages = []
	_source_identity_before.clear()
	_actors_before.clear()
	_index = 0
	_elapsed = 0.0
	_loop_cycles = 0.0
	_new_turn = false

func observe(before: Dictionary, _command: Dictionary, after: Dictionary, generation: int) -> bool:
	if generation != _generation or before == after: return false
	_set_facts(after)
	_new_turn = after.turn != before.turn
	_cues = []
	_held_stages = []
	_source_identity_before.clear()
	_index = 0
	_elapsed = 0.0
	_actors_before = _actor_rows(before)
	var positions := {}
	for id in _actors_before: positions[id] = _actors_before[id].cell
	for enemy in before.enemies:
		# Identity remains available to earlier cues even if the final roster lost this actor.
		_source_identity_before[enemy.id] = {"name": P.enemy_name(enemy), "definition_backed": enemy.has("definition")}
	var held: Dictionary = before.get("stored", {}).duplicate(true)
	var pending: Dictionary = {}
	var events: Array = after.events
	for i in range(events.size()):
		var event: Dictionary = events[i]
		match event.type:
			"move":
				if event.actor != "player":
					var slide := _plan("move", event.actor, i, event.from, event.to, [], "move", "")
					slide["actor"] = event.actor
					_queue(slide, held)
				positions[event.actor] = event.to.duplicate()
			"displace": positions[event.actor] = event.to.duplicate()
			"swap":
				positions[event.actor] = event.to.duplicate()
				positions[event.other] = event.from.duplicate()
			"shine":
				pending = _plan("shine", event.source, i, positions.player, event.target, [], event.kind)
			"capture":
				# Acquisition follows all damage/displacement of its owning attack.
				# Join that actual event to its source facts even if the source dies
				# later in this transition and final storage is already empty.
				held = _acquired(before, after, event.source)
				var transfer := _plan("capture", event.source, i, positions.get(event.source, []), positions.player, [], event.kind)
				transfer["acquired"] = held.duplicate(true)
				_queue(transfer, {})
			"ability_lost":
				held = {}
			"ray", "area", "mask":
				if event.actor == "player":
					if not pending.is_empty():
						if event.type == "mask":
							pending.from = event.from.duplicate()
							pending.to = event.target.duplicate()
						pending.cells = event.cells.duplicate(true)
						pending.footprint_type = event.type
						_queue(pending, held)
						pending = {}
				else:
					var origin: Array = event.from if event.type == "mask" else positions.get(event.actor, [])
					var target: Array = event.target if event.type == "mask" else []
					_queue(_plan("resolve", event.actor, i, origin, target, event.cells, event.kind, event.type), held)
	return true

func _queue(cue: Dictionary, held: Dictionary) -> void:
	_cues.append(cue)
	_held_stages.append(held.duplicate(true))

func _acquired(before: Dictionary, after: Dictionary, source: String) -> Dictionary:
	var final_held: Dictionary = after.get("stored", {})
	if final_held.get("source", "") == source: return final_held.duplicate(true)
	for enemy in before.enemies:
		if enemy.id == source:
			return {"source": source, "ability": enemy.ability.duplicate(true),
				"dir": enemy.dir.duplicate(), "captured_turn": before.turn}
	return {}

func _set_facts(snapshot: Dictionary) -> void:
	_announcements = []
	for intent in snapshot.get("intentions", []):
		if P.stage_supports(snapshot, intent.source, intent.kind):
			var row := {"source": intent.source, "kind": intent.kind, "turn": snapshot.turn, "cells": intent.cells.duplicate(true)}
			if intent.kind == "swap":
				row["from"] = intent.from.duplicate()
				row["target"] = intent.target.duplicate()
			_announcements.append(row)
	_held = snapshot.get("stored", {}).duplicate(true)

func _plan(type: String, source: String, event_index: int, origin: Array, target: Array, cells: Array, kind: String = "shove", footprint_type: String = "ray") -> Dictionary:
	return {"type": type, "source": source, "kind": kind, "footprint_type": footprint_type, "event_index": event_index,
		"from": origin.duplicate(), "to": target.duplicate(), "cells": cells.duplicate(true)}

func _duration(cue: Dictionary) -> float:
	if cue.type == "move": return DURATIONS.move
	if cue.kind == "swap":
		return DURATIONS.capture if cue.type == "capture" else SWAP_DURATION
	# All footprints share one ordered timeline; only shove gets an animated hand.
	return DURATIONS[cue.type] if cue.kind == "shove" else TACTICAL_DURATION

static func exchange_progress(progress: float) -> float:
	return smoothstep(0.08, 0.58, progress)

static func impact_progress(progress: float) -> float:
	return smoothstep(0.64, 0.90, progress)

static func cue_event_end(event_count: int, cues: Array, cue: Dictionary) -> int:
	var end := event_count
	var start: int = cue.get("event_index", -1)
	for planned in cues:
		var next: int = planned.get("event_index", -1)
		if next > start: end = mini(end, next)
	return end

static func _actor_rows(snapshot: Dictionary) -> Dictionary:
	var actors := {}
	if snapshot.is_empty(): return actors
	actors.player = {"actor": "player", "cell": snapshot.player.pos.duplicate(), "hp": snapshot.player.hp}
	for enemy in snapshot.enemies:
		actors[enemy.id] = {"actor": enemy.id, "cell": enemy.pos.duplicate(), "hp": enemy.hp}
	for row in actors.values(): row["grid"] = Vector2(row.cell[0] + 0.5, row.cell[1] + 0.5)
	return actors

# Board and Director share the active cue. Only Board supplies a fallback for
# movement outside finite cues, such as an ordinary player step.
static func staged_actors(snapshot: Dictionary, frame: Dictionary, pulse_before: Dictionary = {},
	pulse_progress: float = 1.0) -> Dictionary:
	var actors := _actor_rows(snapshot)
	if snapshot.is_empty(): return actors
	var old: Dictionary = frame.get("actors_before", {})
	if old.is_empty(): old = _actor_rows(pulse_before)
	if old.is_empty(): return actors
	var cue: Dictionary = frame.get("cue", {})
	var events: Array = snapshot.get("events", [])
	var end := events.size() if cue.is_empty() else cue_event_end(events.size(), frame.get("cues", []), cue)
	var start: int = cue.get("event_index", -1)
	var progress: float = cue.get("progress", pulse_progress)
	var swap_cue: bool = cue.get("kind", "") == "swap"
	var positions := {}
	var health := {}
	for id in old:
		positions[id] = old[id].cell
		health[id] = old[id].hp
	var alive := positions.keys()
	for i in range(end):
		var event: Dictionary = events[i]
		var amount := smoothstep(0.18, 0.80, progress) if i >= start else 1.0
		if event.type in ["move", "displace"]:
			var from := Vector2(event.from[0], event.from[1])
			var to := Vector2(event.to[0], event.to[1])
			positions[event.actor] = from.lerp(to, amount)
		if event.type == "swap":
			var from := Vector2(event.from[0], event.from[1])
			var to := Vector2(event.to[0], event.to[1])
			var exchanged := exchange_progress(progress) if i >= start else 1.0
			positions[event.actor] = from.lerp(to, exchanged)
			positions[event.other] = to.lerp(from, exchanged)
		var impacted := impact_progress(progress) if swap_cue and i >= start else amount
		if event.type == "damage" and (i < start or impacted >= 0.5): health[event.actor] = event.hp
		if event.type == "death" and impacted >= 1.0: alive.erase(event.actor)
	for id in old:
		if id not in alive:
			actors.erase(id)
			continue
		if not actors.has(id): actors[id] = old[id].duplicate(true)
		var pos = positions[id]
		actors[id]["grid"] = Vector2(pos[0] + 0.5, pos[1] + 0.5)
		if swap_cue: actors[id].hp = health[id]
	return actors

func advance(delta: float) -> void:
	if delta <= 0.0: return
	_loop_cycles += delta / 1.8
	var remaining := delta
	while _index < _cues.size() and remaining > 0.0:
		var duration := _duration(_cues[_index])
		var step := minf(remaining, duration - _elapsed)
		_elapsed += step
		remaining -= step
		if _elapsed >= duration:
			_index += 1
			_elapsed = 0.0

func frame() -> Dictionary:
	var cue: Dictionary = {}
	if _index < _cues.size():
		cue = _cues[_index].duplicate(true)
		cue.progress = clampf(_elapsed / _duration(cue), 0.0, 1.0)
	var deferred := _new_turn and not cue.is_empty()
	return {
		"generation": _generation,
		"announcements": [] if deferred else _announcements.duplicate(true),
		"announcements_deferred": deferred,
		"held": (_held_stages[_index] if not cue.is_empty() else _held).duplicate(true),
		"source_identity_before": {} if cue.is_empty() else _source_identity_before.duplicate(true),
		"actors_before": {} if cue.is_empty() else _actors_before.duplicate(true),
		"cues": _cues.duplicate(true),
		"cue": cue,
		"busy": not cue.is_empty(),
		"loop_phase": fposmod(_loop_cycles, 1.0),
		"loop_cycles": _loop_cycles,
	}
