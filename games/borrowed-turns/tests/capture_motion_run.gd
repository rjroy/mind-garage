extends SceneTree
## Isolated motion-study contracts. Synthetic textures and test-owned encounter only.

const Encounter = preload("res://model/encounter.gd")
const Controller = preload("res://ui/shadow_presentation.gd")
const F = preload("res://tests/shadow_fixtures.gd")
const PROJECTION := "res://studies/capture_motion/projection.gd"
const RIG := "res://studies/capture_motion/rig.gd"
var projection_script: Script
var rig_script: Script
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func setup_script(path: String, base: String, methods: Dictionary) -> Script:
	if not ResourceLoader.exists(path):
		printerr("SETUP REQUIRED: missing ", path, "; this is not behavioral RED")
		return null
	var script: Script = load(path)
	if script == null or not script.can_instantiate():
		printerr("SETUP REQUIRED: loadable script required: ", path)
		return null
	var instance = script.new()
	if not instance.is_class(base):
		printerr("SETUP REQUIRED: ", path, " must extend ", base)
		if instance is Node: instance.free()
		return null
	for name in methods:
		var found := false
		for method in instance.get_method_list():
			if method.name == name and method.args.size() == methods[name]: found = true
		if not found:
			printerr("SETUP REQUIRED: ", path, " needs ", name, " with ", methods[name], " arguments")
			if instance is Node: instance.free()
			return null
	if instance is Node: instance.free()
	return script

func setup() -> bool:
	projection_script = setup_script(PROJECTION, "RefCounted", {"compose": 4})
	rig_script = setup_script(RIG, "Node2D", {"configure_assets": 2, "present": 2, "hand_instances": 0})
	return projection_script != null and rig_script != null

func game(fixture: Dictionary):
	var model = Encounter.new()
	model.configure(fixture, "R2")
	return model

func commit(model, controller, action: Dictionary, generation: int) -> Dictionary:
	var before: Dictionary = model.snapshot()
	var assessment: Dictionary = model.assess(action)
	check(assessment.get("legal", false), "controlled action is legal: " + str(action))
	if not assessment.get("legal", false): return {}
	check(model.snapshot() == before, "assessment is nonmutating")
	if not model.act(action):
		check(false, "controlled action commits")
		return {}
	var after: Dictionary = model.snapshot()
	check(after == assessment.get("preview", {}), "committed state equals prediction")
	check(controller.observe(before, action, after, generation), "controller observes committed action")
	return after

func occurrence(source: String, turn: int) -> Dictionary:
	return {"source": source, "turn": turn, "kind": "shove"}

func project(projector, snapshot: Dictionary, frame: Dictionary, generation: int, source: String) -> Dictionary:
	var state_copy := snapshot.duplicate(true)
	var frame_copy := frame.duplicate(true)
	var result = projector.compose(snapshot, frame, generation, source)
	check(result is Dictionary, "projection returns a dictionary")
	check(snapshot == state_copy and frame == frame_copy, "projection does not mutate inputs")
	return result if result is Dictionary else {}

func test_real_capture() -> void:
	var model = game(F.single())
	var before: Dictionary = model.snapshot()
	var controller = Controller.new()
	controller.reset(before, 7)
	var projector = projection_script.new()
	var frame: Dictionary = controller.frame()
	var desc := project(projector, before, frame, 7, "shover")
	check(desc.get("source_occurrence", {}) == occurrence("shover", before.turn), "real announcement identifies source and announcement turn")
	check(desc.get("held_occurrence", {}).is_empty() and desc.get("transfer", {}).is_empty(), "rehearsal is neither held nor transferring")
	check(not desc.get("busy", true) and desc.get("loop_phase", -1.0) == frame.loop_phase, "idle loop uses shared phase without finite busy")
	check(projector.compose(before, frame, 8, "shover") == {}, "stale generation returns empty descriptor")
	var prediction: Dictionary = model.assess({"type": "capture", "source": "shover"})
	var prediction_desc := project(projector, before, frame, 7, "shover")
	check(prediction.get("legal", false) and prediction_desc.get("transfer", {}).is_empty(), "prediction alone cannot create transfer")
	var after := commit(model, controller, {"type": "capture", "source": "shover"}, 7)
	if after.is_empty(): return
	frame = controller.frame()
	desc = project(projector, after, frame, 7, "shover")
	var transfer: Dictionary = desc.get("transfer", {})
	check(transfer.get("occurrence", {}) == occurrence("shover", before.turn), "actual capture transfers the acquired occurrence")
	check(transfer.get("progress", -1.0) == frame.get("cue", {}).get("progress", -2.0), "transfer uses shared finite cue progress")
	check(desc.get("held_occurrence", {}).is_empty(), "active transfer suppresses duplicate held hands")
	check(desc.get("busy", false) == frame.busy, "busy copies controller")
	var reference := desc.duplicate(true)
	if transfer.get("occurrence", {}) is Dictionary: transfer.get("occurrence", {})["source"] = "edited"
	check(projector.compose(after, frame, 7, "shover") == reference, "projection output is detached")
	var wrong := project(projector, after, frame, 7, "another")
	check(wrong.get("transfer", {}).is_empty() and wrong.get("held_occurrence", {}).is_empty(), "wrong source cannot claim transfer or storage")
	var forged := frame.duplicate(true)
	forged.cue.event_index = after.events.size() + 5
	check(projector.compose(after, forged, 7, "shover").get("transfer", {}).is_empty(), "cue must point to an actual capture event")
	forged = frame.duplicate(true)
	forged.cue.event_index = -1
	check(projector.compose(after, forged, 7, "shover").get("transfer", {}).is_empty(), "negative capture event index is invalid")
	forged = frame.duplicate(true)
	forged.held.source = "another"
	check(projector.compose(after, forged, 7, "shover").get("transfer", {}).is_empty(), "frame storage must agree with acquired storage")
	controller.advance(60.0)
	frame = controller.frame()
	desc = project(projector, after, frame, 7, "shover")
	check(desc.get("held_occurrence", {}) == occurrence("shover", before.turn) and desc.get("transfer", {}).is_empty(), "settled hands retain capture turn")
	check(not desc.get("busy", true), "persistent held motion does not keep finite feedback busy")
	var next := commit(model, controller, {"type": "end_turn"}, 7)
	if next.is_empty(): return
	controller.advance(60.0)
	desc = project(projector, next, controller.frame(), 7, "shover")
	check(desc.get("source_occurrence", {}) == occurrence("shover", next.turn), "new announcement has its own turn identity")
	check(desc.get("held_occurrence", {}) == occurrence("shover", before.turn), "old held occurrence coexists with fresh announcement")

func test_queued_and_failed() -> void:
	# The controller suite already covers the other failed/lethal replacement cases.
	for outcome in ["acquired", "source_dead"]:
		var model = game(F.replacement(outcome))
		var controller = Controller.new()
		controller.reset(model.snapshot(), 3)
		var first := commit(model, controller, {"type": "capture", "source": "old"}, 3)
		if first.is_empty(): continue
		controller.advance(60.0)
		var after := commit(model, controller, {"type": "capture", "source": "new"}, 3)
		if after.is_empty(): continue
		var frame: Dictionary = controller.frame()
		var projector = projection_script.new()
		var desc := project(projector, after, frame, 3, "new")
		check(desc.get("transfer", {}).is_empty(), outcome + ": backlash is active, not a capture transfer")
		check(desc.get("held_occurrence", {}).is_empty(), outcome + ": no premature or failed held hands")
		if outcome == "acquired":
			check(frame.get("cues", []).size() == 2 and frame.get("cue", {}).get("type", "") == "backlash", "fixture queues capture behind real backlash")
			controller.advance(Controller.DURATIONS.backlash + 0.01)
			frame = controller.frame()
			desc = project(projector, after, frame, 3, "new")
			check(desc.get("transfer", {}).get("occurrence", {}) == occurrence("new", after.turn), "queued actual capture transfers after backlash")
			check(desc.get("held_occurrence", {}).is_empty(), "active queued capture has no duplicate held hands")
		else:
			controller.advance(60.0)
			desc = project(projector, after, controller.frame(), 3, "new")
			check(desc.get("transfer", {}).is_empty() and desc.get("held_occurrence", {}).is_empty(), outcome + ": failed acquisition never creates hands")

func texture(size: Vector2i) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func assets() -> Dictionary:
	return {"a_body": texture(Vector2i(290, 145)), "a_hands": texture(Vector2i(290, 145)), "p_lantern": texture(Vector2i(145, 145))}

func assembly() -> Dictionary:
	return {
		"a_canvas": Vector2(290, 145), "p_canvas": Vector2(145, 145),
		"a_baseline": Vector2(105, 145), "a_hinge": Vector2(171, 96),
		"p_baseline": Vector2(56, 145), "p_handle": Vector2(105, 60),
		"held_hinge": Vector2(143, 74), "held_scale": 0.45,
		"a_position": Vector2(0.29, 0.45), "p_position": Vector2(0.54, 0.45),
		"height_fraction": 0.30,
	}

func visible_instances(rig) -> Array:
	var value = rig.hand_instances()
	check(value is Array, "hand_instances returns an array")
	if not value is Array: return []
	var visible := []
	for entry in value:
		if not entry is Dictionary:
			check(false, "hand instance is a dictionary")
			continue
		check(entry.get("visible") is bool and entry.get("transform") is Transform2D, "instance reports visibility and actual transform")
		if entry.get("visible", false): visible.append(entry)
	return visible

func find_instance(rows: Array, occ: Dictionary, role: String) -> Dictionary:
	for row in rows:
		if row.get("occurrence", {}) == occ and row.get("role", "") == role: return row
	return {}

func test_rig() -> void:
	var rig = rig_script.new()
	root.add_child(rig)
	var textures := assets()
	var parts := assembly()
	var textures_copy := textures.duplicate()
	var parts_copy := parts.duplicate(true)
	check(not rig.configure_assets({}, parts), "missing textures fail configuration")
	check(not rig.configure_assets(textures, {}), "missing assembly fails configuration")
	if not rig.configure_assets(textures, parts):
		check(false, "synthetic valid assets configure")
		rig.queue_free()
		return
	check(textures == textures_copy and parts == parts_copy, "rig configuration does not mutate inputs")
	var old := occurrence("shover", 1)
	var fresh := occurrence("shover", 2)
	var rect := Rect2(0, 0, 1000, 600)
	var desc := {"generation": 4, "source_occurrence": old, "held_occurrence": {}, "transfer": {}, "busy": false, "loop_phase": 0.2}
	rig.present(desc, rect)
	await process_frame
	var rows := visible_instances(rig)
	check(rows.size() == 1 and not find_instance(rows, old, "rehearsal").is_empty(), "one actual rehearsal hand for source occurrence")
	var rehearsal := find_instance(rows, old, "rehearsal")
	desc.source_occurrence = {}
	desc.transfer = {"occurrence": old.duplicate(true), "progress": 0.5}
	desc.busy = true
	rig.present(desc, rect)
	await process_frame
	rows = visible_instances(rig)
	var traveling := find_instance(rows, old, "transfer")
	check(rows.size() == 1 and not traveling.is_empty(), "same occurrence has one transfer hand, not duplicate source and held hands")
	if not rehearsal.is_empty() and not traveling.is_empty():
		check(rehearsal.get("transform") != traveling.get("transform"), "transfer changes actual hand transform")
	desc.transfer = {}
	desc.held_occurrence = old.duplicate(true)
	desc.source_occurrence = fresh.duplicate(true)
	desc.busy = false
	rig.present(desc, rect)
	await process_frame
	rows = visible_instances(rig)
	check(rows.size() == 2 and not find_instance(rows, old, "held").is_empty() and not find_instance(rows, fresh, "rehearsal").is_empty(), "fresh source and old held occurrences have distinct actual hands")
	var held := find_instance(rows, old, "held")
	rig.present(desc, Rect2(0, 0, 1500, 900))
	await process_frame
	rows = visible_instances(rig)
	var resized := find_instance(rows, old, "held")
	check(rows.size() == 2 and not resized.is_empty(), "resize preserves occurrence identities")
	if not held.is_empty() and not resized.is_empty():
		check(held.get("transform") != resized.get("transform"), "resize recomputes actual hand placement")
	desc.generation = 5
	desc.source_occurrence = fresh
	desc.held_occurrence = {}
	rig.present(desc, rect)
	await process_frame
	rows = visible_instances(rig)
	check(rows.size() == 1 and not find_instance(rows, fresh, "rehearsal").is_empty(), "new generation has only current occurrence")
	rig.present({}, rect)
	await process_frame
	check(visible_instances(rig).is_empty(), "empty descriptor cancels stale hand instances")
	rig.queue_free()

func _run() -> void:
	if not setup():
		quit(2)
		return
	test_real_capture()
	test_queued_and_failed()
	await test_rig()
	print("Capture motion: %d checks, %d failures. Synthetic assets; no visual acceptance." % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
