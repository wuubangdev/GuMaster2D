class_name GuPixelUI
extends RefCounted
## Shared ink-on-paper treatment with restrained jade, vermilion and brass accents.

const HAND_FONT: Font = preload("res://assets/fonts/PatrickHand-Regular.ttf")

const INK := Color("302923")
const INK_SOFT := Color("574637")
const PAPER := Color("e8d3ad")
const PAPER_LIGHT := Color("f1e1c2")
const PAPER_SHADE := Color("c5a879")
const MUTED := Color("75634d")
const JADE := Color("3e6550")
const JADE_LIGHT := Color("a7b392")
const VERMILION := Color("a24d3a")
const GOLD := Color("9a7040")

static func popup_theme() -> Theme:
	var result := Theme.new()
	result.default_font = GuPixelUI.HAND_FONT
	result.default_font_size = 14
	result.set_stylebox("panel", "PopupMenu", GuPixelUI.frame("panel", 10))
	result.set_stylebox("hover", "PopupMenu", GuPixelUI.frame("pressed", 4))
	result.set_constant("v_separation", "PopupMenu", 10)
	result.set_color("font_color", "PopupMenu", GuPixelUI.INK)
	result.set_color("font_hover_color", "PopupMenu", GuPixelUI.INK)
	result.set_color("font_disabled_color", "PopupMenu", Color(GuPixelUI.MUTED, .65))
	result.set_stylebox("panel", "AcceptDialog", GuPixelUI.frame("panel", 14))
	result.set_color("font_color", "Label", GuPixelUI.INK)
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.set_stylebox(state, "Button", GuPixelUI.frame("slot" if state == "normal" else state, 8))
	result.set_color("font_color", "Button", GuPixelUI.INK)
	result.set_color("font_hover_color", "Button", GuPixelUI.INK)
	result.set_color("font_pressed_color", "Button", GuPixelUI.INK)
	result.set_color("font_focus_color", "Button", GuPixelUI.INK)
	result.set_stylebox("focus", "Button", GuPixelUI.frame("hover", 8))
	var border := GuPixelUI.frame("panel", 0)
	border.expand_margin_top = 30
	border.expand_margin_left = 4
	border.expand_margin_right = 4
	border.expand_margin_bottom = 4
	result.set_stylebox("embedded_border", "Window", border)
	result.set_stylebox("embedded_unfocused_border", "Window", border)
	result.set_constant("title_height", "Window", 28)
	result.set_color("title_color", "Window", GuPixelUI.INK)
	result.set_color("close_icon_modulate", "Window", GuPixelUI.INK)
	result.set_color("close_pressed_color", "Window", GuPixelUI.VERMILION)
	return result


static func frame(kind: String, padding: int = 10) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = PAPER
	result.border_color = Color(INK_SOFT, 0.52)
	if kind == "hover":
		result.bg_color = PAPER_LIGHT
		result.border_color = JADE
	elif kind == "pressed":
		result.bg_color = JADE_LIGHT
		result.border_color = JADE
	elif kind == "disabled":
		result.bg_color = Color("d7c7a7")
		result.border_color = Color("a99775")
	elif kind == "panel":
		result.bg_color = PAPER
		result.border_color = Color(INK_SOFT, 0.22)
		result.shadow_color = Color(INK, 0.28)
		result.shadow_size = 5
		result.shadow_offset = Vector2(1, 3)
	result.set_border_width_all(0 if kind == "panel" else 1)
	result.set_corner_radius_all(4 if kind == "panel" else 3)
	result.anti_aliasing = true
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_content_margin(side, padding)
	return result

static func corners(canvas: CanvasItem, bounds: Rect2, tint: Color = GOLD) -> void:
	var p := bounds.position
	var end := bounds.end - Vector2.ONE
	for index in range(4):
		var origin := [p, Vector2(end.x, p.y), end, Vector2(p.x, end.y)][index] as Vector2
		var direction := Vector2(1 if index in [0, 3] else -1, 1 if index < 2 else -1)
		var shape := PackedVector2Array()
		for point in _cubic(Vector2(0, 12), Vector2(2, 5), Vector2(5, 2), Vector2(12, 0), 12):
			shape.append(origin + point * direction)
		canvas.draw_polyline(shape, tint, 1.45, true)
		var dry_stroke := PackedVector2Array([origin + direction * Vector2(3, 9), origin + direction * Vector2(5, 6), origin + direction * Vector2(8, 4)])
		canvas.draw_polyline(dry_stroke, Color(tint, 0.52), 0.8, true)

static func _paper_outline(bounds: Rect2, seed: int, amplitude: float = 1.0, steps: int = 9) -> PackedVector2Array:
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	var points := PackedVector2Array()
	for edge in range(4):
		var start: Vector2 = corners[edge]
		var finish: Vector2 = corners[(edge + 1) % 4]
		var tangent := (finish - start).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		for index in range(steps):
			if edge > 0 and index == 0:
				continue
			var t := float(index) / float(steps - 1)
			var fade := minf(1.0, minf(t * 5.0 + 0.2, (1.0 - t) * 5.0 + 0.2))
			var wobble := sin(float(seed * 13 + edge * 29 + index * 17) * 1.371) * amplitude * fade
			points.append(start.lerp(finish, t) + normal * wobble)
	return points

static func paper_panel(canvas: CanvasItem, bounds: Rect2, seed: int = 0) -> void:
	if bounds.size.x < 24 or bounds.size.y < 24:
		canvas.draw_rect(bounds, PAPER_LIGHT)
		return
	canvas.draw_rect(Rect2(bounds.position + Vector2(2.0, 3.0), bounds.size).grow(-1.2), Color(INK, 0.30))
	canvas.draw_rect(bounds.grow(-1.2), PAPER_LIGHT)
	var inner_bounds := bounds.grow(-5.0)
	paper_wash(canvas, inner_bounds, seed + 31)
	paper_grain(canvas, inner_bounds, seed + 17)
	var contour := _paper_outline(bounds.grow(-1.8), seed + 5, 1.2, 11)
	canvas.draw_polyline(contour, Color(INK, 0.72), 4.1, true)
	canvas.draw_polyline(contour, Color(INK_SOFT, 0.86), 2.0, true)
	var inner_ink := _paper_outline(bounds.grow(-5.2), seed + 23, 0.65, 8)
	canvas.draw_polyline(inner_ink, Color(INK_SOFT, 0.22), 0.8, true)
	# Broken, dry-brush strokes and small corner hooks echo the concept's hand-inked frames.
	var top_x := bounds.position.x + minf(15.0 + float(posmod(seed, 13)), bounds.size.x * 0.18)
	canvas.draw_line(Vector2(top_x, bounds.position.y + 1.5), Vector2(top_x + minf(62.0, bounds.size.x * 0.2), bounds.position.y + 2.2), Color(JADE, 0.82), 2.1, true)
	canvas.draw_line(Vector2(bounds.end.x - 56.0, bounds.end.y - 2.0), Vector2(bounds.end.x - 13.0, bounds.end.y - 1.2), Color(GOLD, 0.65), 1.3, true)
	var left_top := bounds.position + Vector2(8, 18)
	canvas.draw_polyline(PackedVector2Array([left_top, left_top + Vector2(3, -6), left_top + Vector2(9, -9), left_top + Vector2(15, -8)]), Color(INK_SOFT, 0.7), 1.1, true)
	var right_bottom := bounds.end - Vector2(8, 18)
	canvas.draw_polyline(PackedVector2Array([right_bottom, right_bottom + Vector2(-3, 6), right_bottom + Vector2(-9, 9), right_bottom + Vector2(-15, 8)]), Color(INK_SOFT, 0.64), 1.0, true)

static func paper_grain(canvas: CanvasItem, bounds: Rect2, seed: int = 0) -> void:
	# Stable fibers, flecks and pigment blooms; deterministic so paused UI never shimmers.
	if bounds.size.x <= 4 or bounds.size.y <= 4:
		return
	var count := clampi(int(bounds.size.x * bounds.size.y / 320.0), 8, 700)
	for index in range(count):
		var x := fposmod(float(index * 47 + seed * 19) * 1.731, maxf(1.0, bounds.size.x - 5)) + 2.0
		var y := fposmod(float(index * 83 + seed * 31) * 1.137, maxf(1.0, bounds.size.y - 5)) + 2.0
		var origin := bounds.position + Vector2(x, y)
		if index % 4 == 0:
			var fiber := 2.0 + fposmod(float(index * 13 + seed), 5.0)
			canvas.draw_line(origin, origin + Vector2(fiber, 0.25 if index % 2 == 0 else -0.3), Color(INK_SOFT, 0.095), 0.65, true)
		else:
			canvas.draw_rect(Rect2(origin, Vector2(1 if index % 5 else 2, 1)), Color(INK_SOFT, 0.06 if index % 3 == 0 else 0.038))

static func paper_wash(canvas: CanvasItem, bounds: Rect2, seed: int = 0) -> void:
	if bounds.size.x <= 8 or bounds.size.y <= 8:
		return
	var centers := [
		Vector2(0.17, 0.25), Vector2(0.79, 0.2), Vector2(0.58, 0.72), Vector2(0.22, 0.83)
	]
	for index in range(centers.size()):
		var point: Vector2 = centers[(index + absi(seed) % centers.size()) % centers.size()]
		var center := bounds.position + bounds.size * point
		var radius := minf(bounds.size.x, bounds.size.y) * (0.13 + 0.025 * float(index % 2))
		var wash := PackedVector2Array()
		for segment in range(18):
			var angle := TAU * float(segment) / 18.0
			var wobble := 0.91 + 0.07 * sin(float(segment * 7 + seed * 3))
			wash.append(center + Vector2(cos(angle) * radius * 1.7, sin(angle) * radius) * wobble)
		canvas.draw_colored_polygon(wash, Color(PAPER_SHADE, 0.105 if index % 2 == 0 else 0.072))

static func brush_fill(canvas: CanvasItem, bounds: Rect2, tint: Color, seed: int = 0, roughness: float = 0.6) -> void:
	if bounds.size.x < 4 or bounds.size.y < 4:
		canvas.draw_rect(bounds, tint)
		return
	var inner := bounds.grow(-0.8)
	var drift := sin(float(seed % 19) * 1.19) * roughness * 0.24
	var points := PackedVector2Array([
		inner.position + Vector2(0.2 + drift, 0.1),
		Vector2(inner.end.x - 0.2, inner.position.y + drift),
		inner.end - Vector2(0.1 + drift, 0.15),
		Vector2(inner.position.x + 0.1, inner.end.y - drift),
	])
	canvas.draw_colored_polygon(points, tint)

static func brush_frame(canvas: CanvasItem, bounds: Rect2, tint: Color = INK_SOFT, seed: int = 0, weight: float = 1.7, distortion: float = 0.58) -> void:
	if bounds.size.x < 8 or bounds.size.y < 8:
		return
	var margin := 1.5
	var inner := bounds.grow(-margin)
	var corners := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
	var outline := PackedVector2Array()
	for edge in range(4):
		var start: Vector2 = corners[edge]
		var finish: Vector2 = corners[(edge + 1) % 4]
		var direction := (finish - start).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var steps := 9
		for point_index in range(steps):
			if edge > 0 and point_index == 0:
				continue
			var t := float(point_index) / float(steps - 1)
			var wobble := sin(float((edge * 31 + point_index * 17 + seed * 3) % 53) * 1.37) * distortion
			if point_index == 0 or point_index == steps - 1:
				wobble *= 0.42
			outline.append(start.lerp(finish, t) + normal * wobble)
	canvas.draw_polyline(outline, Color(INK, tint.a * 0.26), weight + 0.8, true)
	canvas.draw_polyline(outline, Color(tint, tint.a * 0.87), weight, true)
	# A couple of broken dry-brush traces make the perimeter feel drawn, not machined.
	var upper_start := inner.position + Vector2(10 + posmod(seed, 7), -0.9)
	var upper_end := upper_start + Vector2(minf(32.0, bounds.size.x * 0.16), 0.25)
	canvas.draw_line(upper_start, upper_end, Color(PAPER_LIGHT, tint.a * 0.42), 0.7, true)
	var lower_start := Vector2(inner.position.x + bounds.size.x * 0.62, inner.end.y + 1.1)
	canvas.draw_line(lower_start, lower_start + Vector2(minf(21.0, bounds.size.x * 0.11), -0.2), Color(tint, tint.a * 0.34), 0.8, true)

static func icon(canvas: CanvasItem, kind: String, center: Vector2, radius: float, tint: Color) -> void:
	if GuSkillArt.supports(kind):
		# Keep authored pigments. The old call sites communicate availability
		# by darkening their tint, so preserve that state without repainting it.
		var brightness := clampf(tint.v / .88, .20, 1.0)
		GuSkillArt.draw(canvas, kind, center, radius, Color(brightness, brightness, brightness, tint.a))

static func material_icon(canvas: CanvasItem, kind: String, center: Vector2, radius: float = 16) -> void:
	var ink := Color("28373b")
	match kind:
		"seal":
			var scroll := _curves(Vector2(-9,-12), [
				[Vector2(-4,-14),Vector2(3,-10),Vector2(9,-12)],
				[Vector2(7,-4),Vector2(7,6),Vector2(9,12)],
				[Vector2(3,10),Vector2(-4,14),Vector2(-9,12)],
				[Vector2(-7,5),Vector2(-7,-5),Vector2(-9,-12)],
			])
			_shape(canvas, center, radius, scroll, Color("ead8aa"), ink)
			_curve_stroke(canvas, center, radius, Vector2(-9,-12), [Vector2(-3,-14),Vector2(3,-10),Vector2(9,-12)], Color("b68c58"), 2.8)
			_curve_stroke(canvas, center, radius, Vector2(-9,12), [Vector2(-3,14),Vector2(3,10),Vector2(9,12)], Color("b68c58"), 2.8)
			_curve_stroke(canvas, center, radius, Vector2(-3,-6), [Vector2(4,-9),Vector2(2,-3),Vector2(-2,-1)], Color("a75243"), 1.8)
			_curve_stroke(canvas, center, radius, Vector2(-2,-1), [Vector2(5,0),Vector2(4,5),Vector2(-3,6)], Color("a75243"), 1.8)
			_line(canvas, center, radius, Vector2(0,-7), Vector2(0,9), Color("a75243"), 1.4)
		"meat":
			var bone := _curves(Vector2(3,-3), [
				[Vector2(6,-7),Vector2(8,-9),Vector2(10,-11)],
				[Vector2(5,-15),Vector2(11,-17),Vector2(12,-13)],
				[Vector2(16,-14),Vector2(17,-9),Vector2(12,-9)],
				[Vector2(10,-6),Vector2(7,-2),Vector2(5,0)],
			])
			_shape(canvas, center, radius, bone, Color("eae4cb"), ink)
			var meat := _curves(Vector2(-13,-1), [
				[Vector2(-12,-8),Vector2(-5,-12),Vector2(2,-8)],
				[Vector2(12,-4),Vector2(9,6),Vector2(1,11)],
				[Vector2(-6,16),Vector2(-16,9),Vector2(-13,-1)],
			])
			_shape(canvas, center, radius, meat, Color("bc765c"), ink)
			_curve_stroke(canvas, center, radius, Vector2(-10,0), [Vector2(-9,-6),Vector2(-3,-9),Vector2(2,-5)], Color("e5b193"), 2.0)
			_curve_stroke(canvas, center, radius, Vector2(-8,5), [Vector2(-6,8),Vector2(-1,9),Vector2(3,5)], Color("915446"), 1.5)
		"stone":
			_polygon(canvas, center, radius, [[0,-15],[10,-8],[13,6],[3,14],[-10,8],[-13,-6]], ink)
			_polygon(canvas, center, radius, [[0,-13],[9,-7],[3,3],[-11,-5]], Color("b8dbdc"))
			_polygon(canvas, center, radius, [[3,3],[9,-7],[11,6],[3,12]], Color("7ea8b8"))
			_polygon(canvas, center, radius, [[3,3],[3,12],[-9,7],[-11,-5]], Color("427c91"))
			_line(canvas, center, radius, Vector2(0,-13), Vector2(9,-7), Color("e2edef"), 1.2)
		"fruit":
			var apple := _curves(Vector2(0,-7), [
				[Vector2(6,-12),Vector2(16,-7),Vector2(13,3)],
				[Vector2(11,13),Vector2(4,14),Vector2(0,11)],
				[Vector2(-6,16),Vector2(-13,10),Vector2(-13,1)],
				[Vector2(-15,-8),Vector2(-6,-12),Vector2(0,-7)],
			])
			_shape(canvas, center, radius, apple, Color("a7bc6c"), ink)
			var leaf := _curves(Vector2(1,-8), [
				[Vector2(2,-14),Vector2(8,-17),Vector2(12,-13)],
				[Vector2(10,-9),Vector2(6,-8),Vector2(1,-8)],
			])
			_shape(canvas, center, radius, leaf, Color("7da574"), ink, 0.7)
			_curve_stroke(canvas, center, radius, Vector2(-9,0), [Vector2(-9,-5),Vector2(-5,-7),Vector2(-3,-6)], Color("dfe2aa"), 2.0)
			_curve_stroke(canvas, center, radius, Vector2(0,-7), [Vector2(-1,-11),Vector2(-1,-12),Vector2(0,-14)], Color("725c3d"), 1.5)
		"nectar":
			var bottle := _curves(Vector2(-4,-11), [
				[Vector2(-4,-6),Vector2(-4,-4),Vector2(-9,1)],
				[Vector2(-14,9),Vector2(-7,15),Vector2(0,14)],
				[Vector2(7,15),Vector2(14,9),Vector2(9,1)],
				[Vector2(4,-4),Vector2(4,-6),Vector2(4,-11)],
			])
			_shape(canvas, center, radius, bottle, Color("b18a51"), ink)
			var liquid := _curves(Vector2(-8,3), [
				[Vector2(-3,4),Vector2(3,1),Vector2(8,3)],
				[Vector2(11,10),Vector2(5,12),Vector2(0,12)],
				[Vector2(-5,12),Vector2(-11,10),Vector2(-8,3)],
			])
			_shape(canvas, center, radius, liquid, Color("dda946"), Color("b5843d"), 0.6)
			_curve_stroke(canvas, center, radius, Vector2(-6,-1), [Vector2(-9,5),Vector2(-7,8),Vector2(-6,9)], Color("efd9a8"), 1.5)
			_line(canvas, center, radius, Vector2(-5,-12), Vector2(5,-12), Color("d5c6a0"), 3.6)

		"herb", "herb_seed", "flower_seed", "fruit_seed":
			if kind.ends_with("_seed"):
				_polygon(canvas, center, radius, [[-10,-7],[-7,-14],[8,-13],[11,-6],[9,13],[-9,13]], Color("c6ad79"))
				_line(canvas, center, radius, Vector2(-8,-7),Vector2(9,-7),ink,1.3)
			_line(canvas,center,radius,Vector2(0,11),Vector2(1,-9),ink,1.8)
			for i in range(3):
				var y := 6-i*6
				var side := -1 if i%2 == 0 else 1
				_polygon(canvas,center,radius,[[0,y],[side*9,y-6],[side*6,y+1]],Color("759266"))
		"essence":
			_polygon(canvas,center,radius,[[0,-15],[11,-3],[7,12],[-6,14],[-12,-2]],ink)
			_polygon(canvas,center,radius,[[0,-12],[8,-2],[4,10],[-7,0]],Color("be9573"))
			_curve_stroke(canvas,center,radius,Vector2(-3,-8),[Vector2(8,-4),Vector2(-8,4),Vector2(3,8)],Color("eddbb4"),1.6)
		"silk":
			_polygon(canvas,center,radius,[[-9,-12],[9,-12],[6,11],[-6,11]],ink)
			for y in range(-8,10,3):
				_curve_stroke(canvas,center,radius,Vector2(-8,y),[Vector2(-3,y+3),Vector2(3,y-2),Vector2(8,y)],Color("ded9b5"),2.0)
		"hide":
			var hide := _curves(Vector2(-9,-13),[[Vector2(-4,-7),Vector2(4,-7),Vector2(9,-13)],[Vector2(7,-4),Vector2(6,5),Vector2(12,13)],[Vector2(3,10),Vector2(-3,10),Vector2(-12,13)],[Vector2(-6,5),Vector2(-7,-4),Vector2(-9,-13)]])
			_shape(canvas,center,radius,hide,Color("b28b63"),ink)
			_curve_stroke(canvas,center,radius,Vector2(-5,-4),[Vector2(-1,-2),Vector2(-3,6),Vector2(5,8)],Color("e0c59d"),1.2)
		"fang":
			var fang := _curves(Vector2(-6,-12),[[Vector2(0,-15),Vector2(9,-12),Vector2(8,-8)],[Vector2(6,3),Vector2(0,11),Vector2(-10,14)],[Vector2(-2,3),Vector2(-2,-4),Vector2(-6,-12)]])
			_shape(canvas,center,radius,fang,Color("e1d4b2"),ink)
			_line(canvas,center,radius,Vector2(-5,-9),Vector2(7,-7),Color("978f6f"),1.3)
		"venom":
			var vial := _curves(Vector2(-4,-12),[[Vector2(-4,-5),Vector2(-10,-2),Vector2(-10,5)],[Vector2(-10,15),Vector2(10,15),Vector2(10,5)],[Vector2(10,-2),Vector2(4,-5),Vector2(4,-12)]])
			_shape(canvas,center,radius,vial,Color("71966c"),ink)
			_line(canvas,center,radius,Vector2(-5,-12),Vector2(5,-12),Color("b8a17b"),4)
			_curve_stroke(canvas,center,radius,Vector2(-6,0),[Vector2(-8,4),Vector2(-6,9),Vector2(-4,10)],Color("d3dda9"),1.4)
		"ore":
			_polygon(canvas,center,radius,[[-14,9],[-10,-7],[-3,-14],[5,-5],[12,-9],[15,9],[4,14]],ink)
			_polygon(canvas,center,radius,[[-11,8],[-8,-6],[-3,-11],[4,-3],[5,9]],Color("99a0a0"))
			_polygon(canvas,center,radius,[[5,-3],[11,-6],[12,8],[4,11]],Color("727878"))
			_line(canvas,center,radius,Vector2(-8,-5),Vector2(-3,3),Color("d0c591"),2)
		"relic":
			_polygon(canvas,center,radius,[[-10,-13],[9,-13],[12,-5],[7,1],[10,12],[-11,13]],ink)
			_polygon(canvas,center,radius,[[-8,-11],[7,-11],[9,-5],[4,1],[7,10],[-9,11]],Color("c4b08b"))
			for y in [-6,0,6]: _line(canvas,center,radius,Vector2(-5,y),Vector2(3,y-1),Color("756452"),1.4)
		"pollen":
			for i in range(5):
				var at := center+Vector2.from_angle(i*TAU/5)*radius*.5
				canvas.draw_circle(at,radius*.3,Color("d4b276"),true,-1,true)
				canvas.draw_arc(at,radius*.3,0,TAU,20,ink,1,true)
			canvas.draw_circle(center,radius*.26,Color("7b8863"),true,-1,true)
		"egg":
			var egg := _curves(Vector2(0,-14),[[Vector2(8,-14),Vector2(16,12),Vector2(0,14)],[Vector2(-16,12),Vector2(-8,-14),Vector2(0,-14)]])
			_shape(canvas,center,radius,egg,Color("e1d9b7"),ink)
			_curve_stroke(canvas,center,radius,Vector2(-5,-5),[Vector2(-7,0),Vector2(-6,4),Vector2(-5,6)],Color("faf0d3"),1.5)

static func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2, segments: int = 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / segments
		var inverse := 1.0 - t
		points.append(a * inverse * inverse * inverse + b * 3.0 * inverse * inverse * t + c * 3.0 * inverse * t * t + d * t * t * t)
	return points

static func _curves(start: Vector2, segments: Array) -> PackedVector2Array:
	var result := PackedVector2Array([start])
	var previous := start
	for segment in segments:
		var curve := _cubic(previous, segment[0], segment[1], segment[2])
		for i in range(1, curve.size()):
			result.append(curve[i])
		previous = segment[2]
	return result

static func _shape(canvas: CanvasItem, center: Vector2, radius: float, points: PackedVector2Array, tint: Color, outline: Color, width: float = 1.15) -> void:
	var shape := PackedVector2Array()
	for point in points:
		shape.append(center + point * radius / 16.0)
	canvas.draw_colored_polygon(shape, tint)
	shape.append(shape[0])
	canvas.draw_polyline(shape, outline, width, true)

static func _polygon(canvas: CanvasItem, center: Vector2, radius: float, points: Array, tint: Color) -> void:
	var shape := PackedVector2Array()
	for p in points:
		shape.append(center + Vector2(p[0], p[1]) * radius / 16.0)
	canvas.draw_colored_polygon(shape, tint)
	shape.append(shape[0])
	canvas.draw_polyline(shape, tint, 0.75, true)

static func _stroke(canvas: CanvasItem, center: Vector2, radius: float, points: Array, tint: Color, width: float = 1) -> void:
	var shape := PackedVector2Array()
	for p in points:
		shape.append(center + Vector2(p[0], p[1]) * radius / 16.0)
	canvas.draw_polyline(shape, tint, width, true)

static func _line(canvas: CanvasItem, center: Vector2, radius: float, start: Vector2, end: Vector2, tint: Color, width: float) -> void:
	canvas.draw_line(center + start * radius / 16.0, center + end * radius / 16.0, tint, width, true)

static func _curve_stroke(canvas: CanvasItem, center: Vector2, radius: float, start: Vector2, controls: Array, tint: Color, width: float) -> void:
	var shape := PackedVector2Array()
	for point in _cubic(start, controls[0], controls[1], controls[2]):
		shape.append(center + point * radius / 16.0)
	canvas.draw_polyline(shape, tint, width, true)
