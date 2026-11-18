extends SceneTree
## Controlled mixed legacy/definition composition at the Board/Director boundary.

const Board = preload("res://ui/board.gd")
const Rig = preload("res://ui/two_pursuer_rig.gd")
const Waves = preload("res://ui/wavefront_overlay.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func texture(size: Vector2i) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func legacy(id: String, pos: Array) -> Dictionary:
	return {"id": id, "pos": pos, "hp": 10, "kind": "shove",
		"dir": [0, 1], "ability": {"kind": "shove"}}

func defined(id: String, pos: Array) -> Dictionary:
	var enemy := legacy(id, pos)
	enemy["definition"] = "paper"
	enemy["presentation"] = {"kit": "A"}
	return enemy

func row_for(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if row.actor == id: return row
	return {}

func exercise(enemies: Array, roles: Array, label: String) -> void:
	var board = Board.new()
	board.size = Vector2(1280, 650)
	var art := {"A": texture(Vector2i(12, 20)), "B": texture(Vector2i(12, 20)),
		"player": texture(Vector2i(12, 20))}
	var assembly := {}
	for id in art:
		assembly[id] = {"canvas": Vector2(12, 20), "foot": Vector2(6, 19), "height_fraction": 0.4}
	check(board.configure_standees(art, assembly), label + ": configure standees")
	board.bind_composition(enemies)
	board.set_view({"width": 5, "height": 5, "walls": [],
		"player": {"pos": [1, 2], "hp": 20}, "enemies": enemies,
		"intentions": [], "stored": {}, "capture_armed": false}, {}, [], [], "")

	var rig = Rig.new()
	var rig_art := {}
	for key in ["a_body", "a_hands", "b_body", "b_hands"]:
		rig_art[key] = texture(Vector2i(290, 145))
	rig_art["p_lantern"] = texture(Vector2i(145, 145))
	check(rig.configure_assets(rig_art), label + ": configure Director")
	rig.bind_composition(enemies)
	var sources := {}
	for enemy in enemies:
		sources[enemy.id] = {"present": true}
	rig.present({"generation": 0, "loop_phase": 0.0, "sources": sources,
		"current_cue": {}, "transfer": {}, "held_occurrence": {}, "busy": false},
		Rect2(0, 0, 1000, 500))

	var rows: Array = board.standee_layout()
	var rects: Array[Rect2] = []
	for i in range(enemies.size()):
		var id: String = enemies[i].id
		var role: String = roles[i]
		var row := row_for(rows, id)
		check(not row.is_empty(), label + ": roster contains " + id)
		if row.is_empty(): continue
		var rect: Rect2 = row.roster_rect
		check(rect.has_area() and board.actor_at(rect.get_center()) == id,
			label + ": roster target selects " + id)
		for other in rects:
			check(not rect.intersects(other), label + ": distinct roster slots")
		rects.append(rect)
		check(board._source_color(id) == (Waves.COOL if role == "A" else Waves.WARM),
			label + ": " + id + " roster accent matches expected role " + role)
		check(rig._roles.get(id, "") == role, label + ": " + id + " Director role is " + role)
		var expected_marker := ("◇ " if role == "A" else "○ ") + id
		var found := false
		for item in rig._labels:
			if str(item.text).begins_with(expected_marker): found = true
		check(found, label + ": " + id + " Director marker matches roster accent")
	board.free()
	rig.free()

func _run() -> void:
	# Mixed compositions use placement order for both consumers, regardless of
	# the legacy ID. Reversed all-legacy input retains its historical ID roles.
	exercise([legacy("B", [2, 1]), defined("north", [2, 3])], ["A", "B"], "legacy B first")
	exercise([defined("north", [2, 1]), legacy("A", [2, 3])], ["A", "B"], "legacy A second")
	exercise([legacy("A", [2, 1]), defined("north", [2, 3])], ["A", "B"], "legacy A first")
	exercise([defined("north", [2, 1]), legacy("B", [2, 3])], ["A", "B"], "legacy B second")
	exercise([legacy("B", [2, 1]), legacy("A", [2, 3])], ["B", "A"], "reversed legacy control")
	print("Mixed Stage roles: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
