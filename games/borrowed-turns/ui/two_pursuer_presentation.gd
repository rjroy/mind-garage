extends RefCounted
## Factual two-source view of the existing model and shared presentation clock.

func _occurrence(source: String, turn: int) -> Dictionary:
	return {"source": source, "turn": turn, "kind": "shove"}

func _stored(value: Dictionary, source_ids: Array) -> Dictionary:
	var source: String = value.get("source", "")
	if source not in source_ids or value.get("ability", {}).get("kind", "") != "shove":
		return {}
	if not value.get("captured_turn") is int:
		return {}
	return _occurrence(source, value.captured_turn)

func _event_matches(events: Array, cue: Dictionary) -> bool:
	var index: int = cue.get("event_index", -1)
	if index < 0 or index >= events.size():
		return false
	var event: Dictionary = events[index]
	var cue_type: String = cue.get("type", "")
	var event_type: String = event.get("type", "")
	var source: String = cue.get("source", "")
	if cue_type == "move":
		return event_type == "move" and event.get("actor", "") == cue.get("actor", "") \
			and event.get("from", []) == cue.get("from", []) and event.get("to", []) == cue.get("to", [])
	if cue_type == "resolve":
		return event_type in ["ray", "area"] and event.get("actor", "") == source \
			and event.get("kind", "") == cue.get("kind", "")
	return cue_type in ["capture", "shine"] and event_type == cue_type \
		and event.get("source", "") == source and event.get("kind", "") == cue.get("kind", "")

func _source_rows(snapshot: Dictionary, frame: Dictionary, source_ids: Array, inspected_source: String) -> Dictionary:
	var result := {}
	for i in range(mini(source_ids.size(), 2)):
		var id: String = source_ids[i]
		var row := {"slot": "left" if i == 0 else "right", "occurrence": {},
			"cells": [], "threatens_player": false, "inspected": id == inspected_source}
		for intent in snapshot.get("intentions", []):
			if intent.get("source", "") != id or intent.get("kind", "") != "shove":
				continue
			for announcement in frame.get("announcements", []):
				if announcement.get("source", "") == id and announcement.get("kind", "") == "shove" \
					and announcement.get("turn", -1) == snapshot.get("turn", -2):
					row.occurrence = _occurrence(id, announcement.turn)
					row.cells = intent.get("cells", []).duplicate(true)
					row.threatens_player = row.cells.has(snapshot.get("player", {}).get("pos", []))
					break
			break
		result[id] = row
	return result

func _current_cue(events: Array, frame: Dictionary) -> Dictionary:
	var cue: Dictionary = frame.get("cue", {})
	if cue.is_empty() or not _event_matches(events, cue):
		return {}
	var result := cue.duplicate(true)
	if cue.type != "move":
		result["actor"] = "player" if cue.type == "shine" else cue.source
	var end := events.size()
	for planned in frame.get("cues", []):
		var next: int = planned.get("event_index", -1)
		if next > cue.event_index:
			end = mini(end, next)
	result["events"] = events.slice(cue.event_index, end).duplicate(true)
	return result

func compose(snapshot: Dictionary, frame: Dictionary, expected_generation: int, source_ids: Array, inspected_source: String = "") -> Dictionary:
	if frame.is_empty() or frame.get("generation", -1) != expected_generation:
		return {}
	# The final snapshot may already contain a later acquisition or source death.
	# The shared finite timeline owns which held occurrence is visible now.
	var held := _stored(frame.get("held", {}), source_ids)
	var events: Array = snapshot.get("events", [])
	var cue: Dictionary = frame.get("cue", {})
	var transfer := {}
	if cue.get("type", "") == "capture" and _event_matches(events, cue):
		var acquired := _stored(cue.get("acquired", {}), source_ids)
		var progress: float = cue.get("progress", 0.0)
		if not acquired.is_empty() and is_finite(progress):
			transfer = {"occurrence": acquired, "progress": clampf(progress, 0.0, 1.0)}
	return {
		"generation": expected_generation, "player_slot": "center",
		"sources": _source_rows(snapshot, frame, source_ids, inspected_source),
		"held_occurrence": held, "transfer": transfer,
		"current_cue": _current_cue(events, frame),
		"busy": frame.get("busy", false), "loop_phase": frame.get("loop_phase", 0.0),
		"announcements_deferred": frame.get("announcements_deferred", false),
	}
