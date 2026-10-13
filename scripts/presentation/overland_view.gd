class_name OverlandView
extends Node2D
## Camp identity, waypoint silhouettes and gatherable plants/ore. WorldGrid owns collision.
var simulation: LocalAuthority
var reduced_motion := false
var phase := 0.0
var refresh_left := 0.0
var water_cells: Array[Vector2i] = []
var water_buckets: Dictionary = {}
const WATER_BUCKET_SIZE := 16
const INK := Color("414637")
const PAPER := Color("d9c89f")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for cell in simulation.world.surfaces:
		if simulation.world.surfaces[cell] == "water":
			water_cells.append(cell)
			var bucket := Vector2i(floori(float(cell.x)/WATER_BUCKET_SIZE),floori(float(cell.y)/WATER_BUCKET_SIZE))
			if not water_buckets.has(bucket): water_buckets[bucket] = []
			water_buckets[bucket].append(cell)

func _process(delta: float) -> void:
	if not reduced_motion: phase += delta
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = .1
		queue_redraw()

func nearby(point: Vector2) -> bool:
	return point.distance_squared_to(simulation.player["cell"]) < pow(visible_radius(),2)

func visible_radius() -> float:
	var zoom := maxf(.1,get_canvas_transform().get_scale().x)
	return get_viewport_rect().size.length()/(2*zoom*WorldGrid.CELL_SIZE.x)+6

func nearby_water() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var center: Vector2 = simulation.player["cell"]
	var radius := visible_radius()
	var low := Vector2i(floori((center.x-radius)/WATER_BUCKET_SIZE),floori((center.y-radius)/WATER_BUCKET_SIZE))
	var high := Vector2i(floori((center.x+radius)/WATER_BUCKET_SIZE),floori((center.y+radius)/WATER_BUCKET_SIZE))
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			for cell in water_buckets.get(Vector2i(x,y),[]):
				if center.distance_squared_to(Vector2(cell)) <= radius*radius: result.append(cell)
	return result

func label_at(point: Vector2, text: String, font_size: int = 11) -> void:
	var width := GuPixelUI.HAND_FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_rect(Rect2(point+Vector2(-width*.5-5,-font_size),Vector2(width+10,font_size+5)),Color(.16,.21,.14,.83))
	draw_string(GuPixelUI.HAND_FONT,point+Vector2(-width*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,PAPER)

func _draw() -> void:
	if simulation == null: return
	draw_waterways()
	for camp in WorldContent.camps(simulation.expedition.region):
		var cell := WorldContent.cell(camp)
		if not nearby(cell): continue
		var at := WorldGrid.project(cell+Vector2(0,-5.8))
		var spec := Bestiary.species(camp["species"])
		# Staked signs and torn pennants sit at the entrance, outside creature silhouettes.
		draw_line(at+Vector2(-23,3),at+Vector2(-23,-34),INK,3,true)
		draw_line(at+Vector2(23,3),at+Vector2(23,-34),INK,3,true)
		var tint := Color("a89269") if simulation.expedition.region == "ruins" else Color("72875c")
		draw_colored_polygon(PackedVector2Array([at+Vector2(-28,-33),at+Vector2(29,-34),at+Vector2(26,-15),at+Vector2(1,-12),at+Vector2(-28,-16)]),tint)
		draw_line(at+Vector2(-27,-33),at+Vector2(28,-34),INK,2,true)
		label_at(at+Vector2(0,17),str(camp["name"]) + " • Lv.%d" % spec["level"])
		var center := WorldGrid.project(cell)
		if spec.get("elite",false):
			for radius in [47.0,61.0]:
				for arc in range(8): draw_arc(center,radius,arc*TAU/8+.05,(arc+1)*TAU/8-.08,12,Color("999277"),1.4,true)
			for i in range(8):
				var point := center+Vector2.from_angle(i*TAU/8)*54
				draw_line(point-Vector2(2,3),point+Vector2(2,-3),Color("d2bf99"),1.5,true)
		elif camp["species"] == "hornet":
			for i in range(28):
				var point := center+Vector2.from_angle(i*2.39996)*sqrt((i+1)/28.0)*185
				draw_line(point,point+Vector2(-2,-8),INK,1,true)
				for petal in range(5): draw_circle(point+Vector2(-2,-8)+Vector2.from_angle(petal*TAU/5)*2.1,2,Color("d9c8a0"),true,-1,true)
				draw_circle(point+Vector2(-2,-8),1.6,Color("af9065"),true,-1,true)
		elif simulation.expedition.region == "ruins":
			for i in range(12):
				var point := center+Vector2.from_angle(i*2.39996)*(120+(i%3)*22)
				draw_colored_polygon(PackedVector2Array([point+Vector2(-7,0),point+Vector2(-4,-3),point+Vector2(5,-1),point+Vector2(8,3),point+Vector2(-5,4)]),Color("a19a7d"))
		elif camp["species"] == "spider":
			for i in range(4):
				var point := center+Vector2.from_angle(i*PI/2+.5)*185
				for j in range(3): draw_arc(point,9+j*5,PI*.9,PI*1.8,18,Color(.83,.83,.72,.55),.6,true)
				for j in range(4): draw_line(point,point+Vector2.from_angle(PI*.9+j*.3*PI)*19,Color(.83,.83,.72,.55),.7,true)
	for site in WorldContent.waypoints(simulation.expedition.region):
		var cell := WorldContent.cell(site)
		if not nearby(cell): continue
		var at := WorldGrid.project(cell)
		var known: bool = site["id"] in simulation.journey.discovered
		var tint := Color("9ebbaa") if known else Color("a59875")
		draw_set_transform(at,0,Vector2(1,.6))
		draw_circle(Vector2.ZERO,21,Color(tint,.2),true,-1,true)
		draw_arc(Vector2.ZERO,25,0,TAU,44,tint,1.8,true)
		draw_set_transform(Vector2.ZERO)
		for side in [-1,1]:
			var x: float = side*23
			draw_colored_polygon(PackedVector2Array([at+Vector2(x-5,1),at+Vector2(x-6,-36),at+Vector2(x+3,-43),at+Vector2(x+7,-5)]),Color("96947a"))
			draw_polyline(PackedVector2Array([at+Vector2(x-5,1),at+Vector2(x-6,-36),at+Vector2(x+3,-43),at+Vector2(x+7,-5)]),INK,1.5,true)
			draw_line(at+Vector2(x,-29),at+Vector2(x,-14),tint,2,true)
		label_at(at+Vector2(0,35),str(site["name"]))
		if cell.distance_to(simulation.player["cell"]) <= 2.2: label_at(at+Vector2(0,51),"T / E • Địa đồ",10)
	for site in WorldContent.resources(simulation.expedition.region):
		var cell := WorldContent.cell(site)
		if not nearby(cell): continue
		var at := WorldGrid.project(cell)
		var resting := float(simulation.journey.resources.get(site["id"],0))
		var tint := Color("91a471") if resting <= 0 else Color("827f5e")
		if site["material"] in ["stone","ore"]:
			for i in range(3):
				var offset := at+Vector2(i*8-8,-i%2*5)
				var vertices := PackedVector2Array([offset+Vector2(-8,0),offset+Vector2(-5,-13),offset+Vector2(4,-17),offset+Vector2(10,-4),offset+Vector2(5,3)])
				draw_colored_polygon(vertices,Color("9d9f8b") if resting <= 0 else Color("7e816e"))
				vertices.append(vertices[0]); draw_polyline(vertices,INK,1.1,true)
				if resting <= 0: draw_line(offset+Vector2(-3,-9),offset+Vector2(4,-13),PAPER,1.4,true)
		else:
			for i in range(4):
				var root := at+Vector2(i*6-9,i%2*3)
				var tip := root+Vector2(sin(phase*1.2+i)*(0 if reduced_motion else 1),-17 if resting <= 0 else -5)
				draw_line(root,tip,INK,1.8,true)
				for side in [-1,1]:
					var leaf := PackedVector2Array([root+Vector2(0,-5),tip+Vector2(side*8,3),tip+Vector2(side*5,8)])
					draw_colored_polygon(leaf,tint)
				if resting <= 0 and site["material"] in ["fruit","nectar"]:
					draw_circle(tip,3,Color("b78164") if site["material"] == "fruit" else PAPER,true,-1,true)
		if cell.distance_to(simulation.player["cell"]) <= 1.8:
			label_at(at+Vector2(0,20),("E • "+str(site["name"])) if resting <= 0 else ("Hồi lại %ds" % ceili(resting)),10)

func draw_waterways() -> void:
	# The original atlas water is an isolated puddle. Continuous rivers need one
	# uninterrupted surface, following the exact colliding cell boundary.
	var edges := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	var corners := [Vector2(-16,-16),Vector2(16,-16),Vector2(16,16),Vector2(-16,16)]
	for cell in nearby_water():
		var at := WorldGrid.project(Vector2(cell))
		draw_rect(Rect2(at-Vector2(16,16),Vector2(32,32)),Color("708f88"))
		for i in range(4):
			if simulation.world.terrain_at(cell+edges[i]) == "water": continue
			draw_line(at+corners[i],at+corners[(i+1)%4],Color("b1ae84"),3,true)
			draw_line(at+corners[i]-Vector2(edges[i]),at+corners[(i+1)%4]-Vector2(edges[i]),Color("536f65"),1,true)
		if posmod(cell.x*3+cell.y,4) == 0:
			var wave := PackedVector2Array()
			for i in range(16): wave.append(at+Vector2(i-8,sin(i*.35+phase*.9+cell.x)*1.1))
			draw_polyline(wave,Color("a6bdb0"),.8,true)
