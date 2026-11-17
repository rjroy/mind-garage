extends RefCounted
## Exact unit-cell union boundaries. No ray/range or gameplay reconstruction.

static func boundaries(cells: Array) -> Array:
	var occupied := {}
	for cell in cells: occupied[Vector2i(cell[0], cell[1])] = true
	var ordered: Array = occupied.keys()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y if a.y != b.y else a.x < b.x)
	var outgoing := {}
	var edge_count := 0
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for cell in ordered:
		var corners := [cell, cell + Vector2i.RIGHT, cell + Vector2i.ONE, cell + Vector2i.DOWN]
		for i in range(4):
			if occupied.has(cell + directions[i]): continue
			var start: Vector2i = corners[i]
			if not outgoing.has(start): outgoing[start] = []
			outgoing[start].append(corners[(i + 1) % 4])
			edge_count += 1
	var contours: Array = []
	while not outgoing.is_empty():
		var start: Vector2i = outgoing.keys()[0]
		var current := start
		var incoming := Vector2i.ZERO
		var contour := PackedVector2Array()
		var closed := false
		for _step in range(edge_count + 1):
			contour.append(Vector2(current))
			if not outgoing.has(current): break
			var ends: Array = outgoing[current]
			var chosen := 0
			var priority := 4
			for i in range(ends.size()):
				var next_direction: Vector2i = ends[i] - current
				var cross := incoming.x * next_direction.y - incoming.y * next_direction.x
				var dot := incoming.x * next_direction.x + incoming.y * next_direction.y
				# Keep the occupied side to the right, including when two
				# disconnected cells touch only at one diagonal corner.
				var rank := 0 if cross > 0 else 1 if dot > 0 else 2 if cross < 0 else 3
				if rank < priority:
					priority = rank
					chosen = i
			var next: Vector2i = ends[chosen]
			ends.remove_at(chosen)
			if ends.is_empty(): outgoing.erase(current)
			incoming = next - current
			current = next
			if current == start:
				closed = true
				break
		if not closed:
			push_error("Borrowed Turns: cell-union boundary did not close.")
			return []
		contours.append(contour)
	return contours
