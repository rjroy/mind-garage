extends RefCounted
## A stable visual field. Never consumes gameplay RNG or depends on model state.

func _hash(x: int, y: int, visual_seed: int) -> int:
	var value := (((x & 0x7fffffff) * 73856093) ^ ((y & 0x7fffffff) * 19349663) \
		^ ((visual_seed & 0x7fffffff) * 83492791)) & 0x7fffffff
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return value ^ (value >> 16)

func _unit(x: int, y: int, visual_seed: int) -> float:
	return float(_hash(x, y, visual_seed)) / 2147483647.0

func sample(cell: Array, visual_seed: int) -> Dictionary:
	if cell.size() != 2: return {}
	var x := int(cell[0])
	var y := int(cell[1])
	var extent := 0.32 + _unit(x, y, visual_seed + 1) * 0.15
	var uv := Rect2(Vector2(_unit(x, y, visual_seed + 2), _unit(x, y, visual_seed + 3)) * (1.0 - extent),
		Vector2.ONE * extent)
	var warmth := _unit(x, y, visual_seed + 4)
	var brightness := 0.95 + _unit(x, y, visual_seed + 5) * 0.09
	return {"uv_rect": uv, "quarter_turn": _hash(x, y, visual_seed) % 4,
		"tint": Color(brightness * (0.98 + warmth * 0.04), brightness,
			brightness * (1.01 - warmth * 0.05), 1.0)}
