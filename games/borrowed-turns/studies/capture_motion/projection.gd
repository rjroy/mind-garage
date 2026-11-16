extends RefCounted
## Study-only view of the existing controller. No rules, clock or event simulation.

func _occurrence(source: String, turn: int) -> Dictionary:
	return {"source": source, "turn": turn, "kind": "shove"}

func _stored(value: Dictionary, source: String) -> Dictionary:
	if value.get("source", "") != source or value.get("ability", {}).get("kind", "") != "shove": return {}
	if not value.get("captured_turn") is int: return {}
	return _occurrence(source, value.captured_turn)

func _capture_event(snapshot: Dictionary, cue: Dictionary, source: String) -> bool:
	var index: int = cue.get("event_index", -1)
	var events: Array = snapshot.get("events", [])
	if index < 0 or index >= events.size(): return false
	var event: Dictionary = events[index]
	return cue.get("type", "") == "capture" and cue.get("kind", "") == "shove" \
		and cue.get("source", "") == source and event.get("type", "") == "capture" \
		and event.get("source", "") == source and event.get("kind", "") == "shove"

func compose(snapshot: Dictionary, frame: Dictionary, expected_generation: int, source_id: String) -> Dictionary:
	if frame.is_empty() or frame.get("generation", -1) != expected_generation: return {}
	var source_occurrence: Dictionary = {}
	for announcement in frame.get("announcements", []):
		if announcement.get("source", "") == source_id and announcement.get("kind", "") == "shove":
			source_occurrence = _occurrence(source_id, announcement.turn)
			break
	var held := _stored(snapshot.get("stored", {}), source_id)
	if held != _stored(frame.get("held", {}), source_id): held = {}
	var cue: Dictionary = frame.get("cue", {})
	var transfer: Dictionary = {}
	var capture_pending := false
	if not held.is_empty() and not cue.is_empty():
		var current_index: int = cue.get("event_index", -1)
		for planned in frame.get("cues", []):
			if planned.get("event_index", -1) >= current_index and _capture_event(snapshot, planned, source_id):
				capture_pending = true
				break
		if _capture_event(snapshot, cue, source_id):
			var progress: float = cue.get("progress", 0.0)
			if is_finite(progress):
				transfer = {"occurrence": held.duplicate(), "progress": clampf(progress, 0.0, 1.0)}
				capture_pending = true
	return {"generation": expected_generation, "source_occurrence": source_occurrence,
		"held_occurrence": {} if capture_pending else held,
		"transfer": transfer, "busy": frame.get("busy", false), "loop_phase": frame.get("loop_phase", 0.0)}
