class_name TargetingView
extends Node2D
## Read-only world affordances. Every endpoint comes from the authority's pure cast query.

var simulation: LocalAuthority
var actor_views: Dictionary = {}
var selected_id: String = ""
var hovered_id: String = ""
var cursor_cell: Vector2 = Vector2.ZERO
var show_pointer: bool = false
var slot: int = -1
var probe: Dictionary = {}
var selection_left: float = 0.0
var reduced_motion: bool = false
var redraw_left: float = 0.0

func _process(delta: float) -> void:
	selection_left = maxf(0.0, selection_left - delta)
	redraw_left -= delta
	if show_pointer or slot >= 0 or selection_left > 0.0 or redraw_left <= 0.0:
		redraw_left = 1.0 / 30.0
		queue_redraw()

func _draw() -> void:
	if simulation == null:
		return
	if show_pointer and hovered_id.is_empty():
		var cell := cursor_cell.round()
		var at := WorldGrid.project(cell)
		var walkable := simulation.world.is_walkable(cell)
		var color := Color(0.63, 0.84, 0.73, 0.45) if walkable else Color(0.93, 0.63, 0.40, 0.8)
		draw_rect(Rect2(at - Vector2(13,13), Vector2(26,26)), color, false, 1.0)
		if not walkable:
			_cross(at, color)
	if not hovered_id.is_empty() and hovered_id != selected_id and _alive(hovered_id):
		var at: Vector2 = actor_views[hovered_id].position
		_brackets(at, Vector2(24, 11), Color("b9dcc6"))
		_caption(at + Vector2(-46, -65), "Click chọn", Color("d4e8ce"), 12, 92)
	if _alive(selected_id):
		var at: Vector2 = actor_views[selected_id].position
		var expansion := selection_left * 15.0 if not reduced_motion else 0.0
		var color := Color("ddc38e")
		for sign in [-1, 1]:
			draw_polyline(PackedVector2Array([at + Vector2(sign * (20 + expansion), -9), at + Vector2(sign * (27 + expansion), -3), at + Vector2(sign * (20 + expansion), 4)]), color, 1, false)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-4, -62), at + Vector2(4, -62), at + Vector2(0, -57)]), color)
	if slot < 0 or probe.is_empty() or not probe.has("origin"):
		return
	var origin := WorldGrid.project(probe["origin"])
	var definition := simulation.catalog.slot(slot)
	var ready := bool(probe["ok"])
	var color := Color(str(definition["color"])) if ready else Color("d9a374")
	var radius := float(probe["range"])
	if radius > 0.0:
		_pixel_ring(origin, WorldGrid.CELL_SIZE.x * radius, Color(color, 0.32))
	else:
		_brackets(origin, Vector2(24, 12), Color(color, 0.7))
		return
	var end := WorldGrid.project(probe["destination"])
	if end.distance_to(origin) < 1.0:
		return
	_dashed_line(origin, end, Color(color, 0.8))
	var direction := (end - origin).normalized()
	var side := direction.orthogonal()
	draw_polyline(PackedVector2Array([end - direction * 10 + side * 4, end, end - direction * 10 - side * 4]), color, 1, false)
	_brackets(end, Vector2(13, 8), color)
	if bool(probe["clipped"]):
		var requested := WorldGrid.project(probe["requested"])
		_dashed_line(end, requested, Color("d9986d"))
		_cross(requested, Color("e5ac7c"))
	elif not ready:
		_cross(end, color)

func _alive(id: String) -> bool:
	return actor_views.has(id) and not bool(simulation.mobs[id]["dead"])

func _cross(at: Vector2, color: Color) -> void:
	draw_line(at + Vector2(-4, -3), at + Vector2(4, 3), color, 1, false)
	draw_line(at + Vector2(-4, 3), at + Vector2(4, -3), color, 1, false)

func _dashed_line(start: Vector2, end: Vector2, color: Color) -> void:
	var count := maxi(1, ceili(start.distance_to(end) / 9.0))
	for i in range(count):
		if i % 2 == 0:
			draw_line(start.lerp(end, float(i) / count), start.lerp(end, float(i + 1) / count), Color(color, 0.65), 1, false)

func _caption(at: Vector2, text: String, color: Color, font_size: int, width: int) -> void:
	draw_string_outline(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color("10231e"))
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _pixel_ring(at: Vector2, radius: float, color: Color) -> void:
	var count := maxi(32, ceili(radius*.45))
	for i in range(count):
		var point := (at+Vector2.from_angle(float(i)/count*TAU)*radius).round()
		draw_rect(Rect2(point, Vector2(2, 2)), color)

func _brackets(at: Vector2, extent: Vector2, color: Color) -> void:
	for sign_x in [-1, 1]:
		for sign_y in [-1, 1]:
			var corner := (at+extent*Vector2(sign_x, sign_y)).round()
			draw_line(corner, corner-Vector2(sign_x*5, 0), color, 1, false)
			draw_line(corner, corner-Vector2(0, sign_y*4), color, 1, false)
