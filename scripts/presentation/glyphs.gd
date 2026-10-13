class_name GuGlyphs
extends RefCounted

static var unit_circle: PackedVector2Array = PackedVector2Array()

static func draw(node: CanvasItem, kind: String, center: Vector2, radius: float, color: Color) -> void:
	match kind:
		"moon":
			var curve := PackedVector2Array()
			for i in range(25):
				var a := -1.25 + float(i) / 24.0 * 4.8
				curve.append(center + Vector2(cos(a), sin(a)) * radius)
			node.draw_polyline(curve, color, 2.4, true)
			node.draw_line(center + Vector2(-radius * 0.15, -radius * 0.5), center + Vector2(radius * 0.2, radius * 0.6), color, 1.5, true)
			node.draw_circle(center + Vector2(radius * 0.15, -radius * 0.05), 2.4, color)
		"shield":
			var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.8, -radius * 0.5), center + Vector2(radius * 0.65, radius * 0.5), center + Vector2(0, radius), center + Vector2(-radius * 0.65, radius * 0.5), center + Vector2(-radius * 0.8, -radius * 0.5), center + Vector2(0, -radius)])
			node.draw_polyline(points, color, 2.0, true)
			node.draw_line(center + Vector2(0, -radius * 0.6), center + Vector2(0, radius * 0.6), color, 1.3, true)
		"dash":
			for i in range(3):
				var x := center.x + (i - 1) * radius * 0.65
				node.draw_polyline(PackedVector2Array([Vector2(x - radius * 0.35, center.y - radius * 0.65), Vector2(x + radius * 0.2, center.y), Vector2(x - radius * 0.35, center.y + radius * 0.65)]), color, 2.0, true)
		"frost":
			for i in range(6):
				var a := float(i) * TAU / 6.0
				var tip := center + Vector2.from_angle(a) * radius
				node.draw_line(center, tip, color, 1.8, true)
				for sign in [-1.0, 1.0]:
					node.draw_line(center + Vector2.from_angle(a) * radius * 0.55, tip + Vector2.from_angle(a + sign * 2.4) * radius * 0.42, color, 1.4, true)

static func ellipse(node: CanvasItem, center: Vector2, size: Vector2, color: Color, filled: bool = true, width: float = 1.0) -> void:
	if unit_circle.is_empty():
		for i in range(40):
			unit_circle.append(Vector2.from_angle(float(i) / 40.0 * TAU))
	var points := PackedVector2Array()
	for point in unit_circle:
		points.append(center + point * size)
	if filled:
		node.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		node.draw_polyline(points, color, width, true)
