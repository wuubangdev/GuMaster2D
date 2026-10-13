class_name GuMinimap
extends Control
## North-up local map; the player stays centered while terrain scrolls beneath.
signal open_requested
var simulation: LocalAuthority
var refresh_left := 0.0
const SPAN := 28.0
var terrain: Texture2D
var rendered_region := ""

static func direction_label(facing: Vector2) -> String:
	if facing.length_squared() < .001: return "Nam"
	return ["Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc", "Bắc", "Đông Bắc"][posmod(roundi(facing.angle() / (PI / 4)), 8)]

func map_bounds() -> Rect2:
	return Rect2(Vector2(3, 3), size - Vector2(6, 6))

func factor() -> float:
	return maxf(1.0, map_bounds().size.x / SPAN)

func project(cell: Vector2) -> Vector2:
	return map_bounds().get_center() + (cell - Vector2(simulation.player["cell"])) * factor()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Mở địa đồ lớn [F2]"
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_requested.emit()
		accept_event()

func _process(delta: float) -> void:
	if simulation == null: return
	refresh_left -= delta
	if refresh_left > 0: return
	refresh_left = 1.0 / 15.0
	if rendered_region != simulation.expedition.region or terrain == null:
		rendered_region = simulation.expedition.region
		terrain = RegionalAtlas.terrain_preview_for(simulation, true)
	queue_redraw()

func _draw() -> void:
	if simulation == null or terrain == null: return
	var area := map_bounds()
	var scale_value := factor()
	var source := Rect2(Vector2(simulation.player["cell"]) - area.size / scale_value * .5, area.size / scale_value)
	var visible_area := source.intersection(Rect2(0, 0, WorldGrid.SIZE, WorldGrid.SIZE))
	draw_rect(area, Color("49533f"))
	if visible_area.has_area():
		var destination := Rect2(area.position + (visible_area.position - source.position) * scale_value, visible_area.size * scale_value)
		draw_texture_rect_region(terrain, destination, visible_area)
	for prop in simulation.world.props_near(simulation.player["cell"], SPAN * .7):
		var at := project(prop["cell"])
		if not area.grow(-4).has_point(at): continue
		if prop["kind"] == "tree":
			draw_circle(at, 2.7, Color("718358", .72), true, -1, true)
		elif prop["kind"] in ["wall", "rock", "pillar", "monolith"]:
			draw_circle(at, 2.6, Color("726e5e", .82), true, -1, true)
	for road in WorldContent.roads(simulation.expedition.region):
		var path := PackedVector2Array()
		for cell in road: path.append(project(cell))
		draw_polyline(path, Color("e6d4a1"), 2.5, true)
	for mob in simulation.mobs.values():
		if not bool(mob["dead"]): _marker(project(mob["cell"]), GuPixelUI.VERMILION, 2.4)
	for point in [WorldGrid.SPAWN, WorldGrid.SHRINE]: _marker(project(point), GuPixelUI.GOLD, 3.8)
	for site in WorldContent.waypoints(simulation.expedition.region): _marker(project(WorldContent.cell(site)), GuPixelUI.JADE, 3.6)
	for id in QuestCatalog.npcs(simulation.expedition.region):
		_marker(project(QuestCatalog.cell(id)), GuPixelUI.INK, 4.0)
		_marker(project(QuestCatalog.cell(id)), GuPixelUI.PAPER_LIGHT, 2.0)
	var center := area.get_center()
	var facing := Vector2(simulation.player["facing"]).normalized()
	if facing.length_squared() < .01: facing = Vector2.DOWN
	var side := Vector2(-facing.y, facing.x)
	draw_colored_polygon(PackedVector2Array([center, center + facing.rotated(-.42) * 22, center + facing.rotated(.42) * 22]), Color(GuPixelUI.PAPER_LIGHT, .32))
	var arrow := PackedVector2Array([center + facing * 8, center - facing * 5 + side * 4.8, center - facing * 2, center - facing * 5 - side * 4.8])
	draw_circle(center, 7.3, GuPixelUI.INK, true, -1, true)
	draw_colored_polygon(arrow, GuPixelUI.PAPER_LIGHT)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), GuPixelUI.INK, 1.2, true)
	# The border hugs the terrain itself, with no tall surrounding paper panel.
	draw_rect(area, GuPixelUI.INK, false, 2.0)
	draw_rect(area.grow(-1.3), Color("cfbc87"), false, 1.0)
	var north := Rect2(Vector2(area.get_center().x - 8, area.position.y + 3), Vector2(16, 16))
	draw_rect(north, GuPixelUI.INK)
	draw_string(GuPixelUI.HAND_FONT, north.position + Vector2(4, 12), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GuPixelUI.PAPER_LIGHT)

func _marker(point: Vector2, color: Color, radius: float) -> void:
	if not map_bounds().grow(-radius - 3).has_point(point): return
	draw_circle(point, radius + .7, GuPixelUI.INK, true, -1, true)
	draw_colored_polygon(PackedVector2Array([point + Vector2(0, -radius), point + Vector2(radius, 0), point + Vector2(0, radius), point + Vector2(-radius, 0)]), color)
