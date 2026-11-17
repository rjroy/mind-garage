extends RefCounted
## Deterministic presentation projection. Never calls a model or computes game effects.

const DURATIONS := {"capture": 0.60, "release": 0.44, "backlash": 0.52, "resolve": 0.38}
const TACTICAL_DURATION := 0.18
var _generation := -1
var _announcements: Array = []
var _held: Dictionary = {}
var _cues: Array = []
var _index := 0
var _elapsed := 0.0
var _loop_cycles := 0.0

func reset(snapshot: Dictionary, generation: int) -> void:
	if generation < _generation: return
	_generation = generation
	_set_facts(snapshot)
	_cues = []
	_index = 0
	_elapsed = 0.0
	_loop_cycles = 0.0

func observe(before: Dictionary, command: Dictionary, after: Dictionary, generation: int) -> bool:
	if generation != _generation or before == after: return false
	_set_facts(after)
	_cues = []
	_index = 0
	_elapsed = 0.0
	var positions := {"player": before.player.pos.duplicate()}
	for enemy in before.enemies: positions[enemy.id] = enemy.pos.duplicate()
	var pending: Dictionary = {}
	var events: Array = after.events
	for i in range(events.size()):
		var event: Dictionary = events[i]
		match event.type:
			"move", "displace": positions[event.actor] = event.to.duplicate()
			"release", "backlash":
				var target: Array = command.get("target", []) if event.type == "release" else []
				pending = _plan(event.type, event.source, i, positions.player, target, [], event.kind)
			"capture":
				if event.kind == "shove":
					_cues.append(_plan("capture", event.source, i, positions.get(event.source, []), positions.player, []))
			"ray", "area":
				if event.actor == "player":
					if not pending.is_empty():
						pending.cells = event.cells.duplicate(true)
						pending.footprint_type = event.type
						_cues.append(pending)
						pending = {}
				else:
					_cues.append(_plan("resolve", event.actor, i, positions.get(event.actor, []), [], event.cells, event.kind, event.type))
	return true

func _set_facts(snapshot: Dictionary) -> void:
	_announcements = []
	for intent in snapshot.get("intentions", []):
		if intent.kind == "shove":
			_announcements.append({"source": intent.source, "kind": "shove", "turn": snapshot.turn, "cells": intent.cells.duplicate(true)})
	var stored: Dictionary = snapshot.get("stored", {})
	_held = stored.duplicate(true) if not stored.is_empty() and stored.ability.kind == "shove" else {}

func _plan(type: String, source: String, event_index: int, origin: Array, target: Array, cells: Array, kind: String = "shove", footprint_type: String = "ray") -> Dictionary:
	return {"type": type, "source": source, "kind": kind, "footprint_type": footprint_type, "event_index": event_index,
		"from": origin.duplicate(), "to": target.duplicate(), "cells": cells.duplicate(true)}

func _duration(cue: Dictionary) -> float:
	# All footprints share one ordered timeline; only shove gets an animated hand.
	return DURATIONS[cue.type] if cue.kind == "shove" else TACTICAL_DURATION

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
	return {
		"generation": _generation,
		"announcements": _announcements.duplicate(true),
		"held": _held.duplicate(true),
		"cues": _cues.duplicate(true),
		"cue": cue,
		"busy": not cue.is_empty(),
		"loop_phase": fposmod(_loop_cycles, 1.0),
		"loop_cycles": _loop_cycles,
	}
