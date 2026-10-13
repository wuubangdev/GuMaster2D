class_name RegionalAtlas
extends Control
signal site_selected(id: String)
var simulation: LocalAuthority
var selected := "camp"
var refresh_left := 0.0
static var _terrain_previews: Dictionary = {}

func _ready() -> void:
	custom_minimum_size.y = 340
	mouse_filter = Control.MOUSE_FILTER_STOP

func bounds() -> Rect2:
	var edge := minf(size.y-30,size.x*.56)
	return Rect2(12,14,edge,edge)

func project(cell: Vector2) -> Vector2:
	return bounds().position+cell/float(WorldGrid.SIZE)*bounds().size

func sites() -> Array:
	var result: Array = [{"id":"camp","name":"Trại ngọc","cell":[12,20],"kind":"camp","region":simulation.expedition.region}]
	result.append_array(WorldContent.camps(simulation.expedition.region))
	result.append_array(WorldContent.waypoints(simulation.expedition.region))
	for id in QuestCatalog.npcs(simulation.expedition.region):
		var npc := QuestCatalog.npc(id).duplicate()
		npc["id"] = "npc:"+id
		npc["kind"] = "npc"
		result.append(npc)
	return result

func current_site() -> Dictionary:
	for site in sites():
		if site["id"] == selected: return site
	return sites()[0]

func _process(delta: float) -> void:
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = .2
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var closest := 14.0
		for site in sites():
			var gap: float = event.position.distance_to(project(WorldContent.cell(site)))
			if gap < closest:
				closest = gap
				selected = site["id"]
		if closest < 14:
			site_selected.emit(selected)
			queue_redraw()
		accept_event()

func _draw() -> void:
	if simulation == null: return
	var area := bounds()
	draw_rect(area,Color("a5b48b"))
	draw_texture_rect(terrain_preview(),area,false)
	for district in WorldContent.region(simulation.expedition.region).get("districts",[]):
		var box: Array = district["bounds"]
		var corner := project(Vector2(box[0]+3,box[1]+8))
		draw_string(GuPixelUI.HAND_FONT,corner,str(district["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("647451"))
	for line in WorldContent.roads(simulation.expedition.region):
		var points := PackedVector2Array()
		for point in line: points.append(project(point))
		draw_polyline(points,Color("d7c599"),4,true)
		draw_polyline(points,Color("9e8764"),.8,true)
	for site in sites():
		var at := project(WorldContent.cell(site))
		var color := GuPixelUI.VERMILION if site.has("species") else GuPixelUI.JADE
		if site.get("kind","") == "npc": color = GuPixelUI.INK_SOFT
		draw_circle(at,4.5,color,true,-1,true)
		draw_arc(at,5,0,TAU,20,GuPixelUI.PAPER_LIGHT,1,true)
		if site["id"] == selected:
			draw_arc(at,8,0,TAU,24,GuPixelUI.INK,1.7,true)
	var player := project(simulation.player["cell"])
	var facing := Vector2(simulation.player["facing"]).normalized()
	if facing.length_squared() < .01: facing = Vector2.DOWN
	var side := Vector2(-facing.y, facing.x)
	var arrow := PackedVector2Array([player+facing*10,player-facing*5+side*5,player-facing*2,player-facing*5-side*5])
	draw_circle(player,8,GuPixelUI.INK,true,-1,true)
	draw_colored_polygon(arrow,GuPixelUI.PAPER_LIGHT)
	draw_rect(area,GuPixelUI.INK_SOFT,false,1.5)
	var x := area.end.x+24
	var y := 32.0
	draw_string(GuPixelUI.HAND_FONT,Vector2(x,y),"ĐỊA ĐỒ VÙNG • %d × %d" % [WorldGrid.SIZE,WorldGrid.SIZE],HORIZONTAL_ALIGNMENT_LEFT,-1,19,GuPixelUI.JADE)
	y += 26
	draw_string(GuPixelUI.HAND_FONT,Vector2(x,y),"Bạn: %d, %d  •  mũi tên chỉ hướng nhìn" % [roundi(Vector2(simulation.player["cell"]).x),roundi(Vector2(simulation.player["cell"]).y)],HORIZONTAL_ALIGNMENT_LEFT,size.x-x-4,14,GuPixelUI.INK_SOFT)
	y += 23
	draw_string(GuPixelUI.HAND_FONT,Vector2(x,y),"Chọn dấu trên bản đồ hoặc danh sách bên dưới.",HORIZONTAL_ALIGNMENT_LEFT,size.x-x-4,14,GuPixelUI.MUTED)
	y += 30
	for text in ["● Đỏ: bãi quái / đầu lĩnh", "● Ngọc: trạm nghỉ / cổ trận", "● Nâu: NPC giao nhiệm vụ", "● Trắng: vị trí hiện tại", "%d bãi • %d trạm • 6 địa khu" % [WorldContent.camps(simulation.expedition.region).size(),WorldContent.waypoints(simulation.expedition.region).size()],"Đường sáng nối các khu vực và cầu.","Trạm phải được khám phá trước khi dịch chuyển."]:
		draw_string(GuPixelUI.HAND_FONT,Vector2(x,y),text,HORIZONTAL_ALIGNMENT_LEFT,size.x-x-4,15,GuPixelUI.INK_SOFT)
		y += 25
	var current := current_site()
	draw_string(GuPixelUI.HAND_FONT,Vector2(x,y+12),str(current["name"]),HORIZONTAL_ALIGNMENT_LEFT,size.x-x-4,20,GuPixelUI.JADE)
	draw_string(GuPixelUI.HAND_FONT,Vector2(x,y+38),"Tọa độ %d, %d" % [current["cell"][0],current["cell"][1]],HORIZONTAL_ALIGNMENT_LEFT,-1,15,GuPixelUI.MUTED)

func terrain_preview() -> Texture2D:
	return terrain_preview_for(simulation)

static func terrain_preview_for(authority: LocalAuthority, simplified: bool = false) -> Texture2D:
	var region_id: String = authority.expedition.region
	var key := region_id + (":local" if simplified else "")
	if not _terrain_previews.has(key):
		var image := Image.create(WorldGrid.SIZE,WorldGrid.SIZE,false,Image.FORMAT_RGB8)
		var palette := {"grass":Color("a5b48b"),"stone":Color("c6bba1"),"water":Color("789e9a"),"dirt":Color("c2aa7a")}
		for y in range(WorldGrid.SIZE):
			for x in range(WorldGrid.SIZE):
				var cell := Vector2i(x,y)
				var terrain := authority.world.terrain_at(cell) if x >= 27 or y >= 28 else GroundView.surface_kind(cell)
				var tint: Color = palette[terrain]
				if not simplified and not authority.world.is_walkable(cell) and terrain != "water": tint = tint.darkened(.19)
				image.set_pixel(x,y,tint)
		_terrain_previews[key] = ImageTexture.create_from_image(image)
	return _terrain_previews[key]
