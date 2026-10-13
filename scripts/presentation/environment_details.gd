class_name EnvironmentDetails
extends Node2D
## Ground decoration: deterministic placement, bounded animation, no gameplay state.
var simulation: LocalAuthority
var reduced_motion := false
var phase := 0.0
var elapsed := 0.0
var patches: Array[Vector2] = []
var patch_buckets: Dictionary = {}
const PATCH_BUCKET_SIZE := 512.0

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var random := RandomNumberGenerator.new()
	random.seed = 391 + ["forest","ruins","realm"].find(simulation.expedition.region)
	# Preserve ground detail density as the world expands; draw only local buckets.
	for i in range(roundi(1600.0*WorldGrid.SIZE*WorldGrid.SIZE/(96.0*96.0))):
		var cell := Vector2(random.randf_range(2,WorldGrid.SIZE-2),random.randf_range(3,WorldGrid.SIZE-2))
		var quiet_ground := not simulation.world.is_safe(cell) if simulation.expedition.region != "realm" else (cell.x < 8 or cell.x > 20)
		if simulation.world.is_walkable(cell) and quiet_ground and absi(roundi(cell.x)-12)>2:
			var at := WorldGrid.project(cell)
			patches.append(at)
			var bucket := Vector2i(floori(at.x/PATCH_BUCKET_SIZE),floori(at.y/PATCH_BUCKET_SIZE))
			if not patch_buckets.has(bucket): patch_buckets[bucket] = []
			patch_buckets[bucket].append(patches.size()-1)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= .1:
		# Reduced motion freezes the blades, not the spatial query. Moving or
		# using a waygate must still reveal decoration in the new camera area.
		phase = 0.0 if reduced_motion else phase + elapsed
		elapsed = 0
		queue_redraw()

func _draw() -> void:
	if simulation == null: return
	var region := simulation.expedition.region
	var center := WorldGrid.project(simulation.player["cell"])
	var radius := get_viewport_rect().size.length()/(2*maxf(.1,get_canvas_transform().get_scale().x))+64
	var low := Vector2i(floori((center.x-radius)/PATCH_BUCKET_SIZE),floori((center.y-radius)/PATCH_BUCKET_SIZE))
	var high := Vector2i(floori((center.x+radius)/PATCH_BUCKET_SIZE),floori((center.y+radius)/PATCH_BUCKET_SIZE))
	var visible_patches: Array = []
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1): visible_patches.append_array(patch_buckets.get(Vector2i(x,y),[]))
	for i in visible_patches:
		var at := patches[i]
		if at.distance_squared_to(center) > radius*radius: continue
		var lean := sin(phase*1.1+i*.73)*1.3
		for blade in range(3):
			draw_polyline(PackedVector2Array([at+Vector2(blade*2,0),at+Vector2(blade*2-1,-3),at+Vector2(blade*2+lean-3,-7-i%3)]),Color("7e8f63") if region != "ruins" else Color("95936d"),.8,true)
		if region != "ruins" and i%(4 if region == "realm" else 9) == 0:
			draw_circle(at+Vector2(-2,-7),1.5,Color("ded6a4"),true,-1,true)
	if region == "realm":
		pond(WorldGrid.project(Vector2(6,16)))
	elif region == "ruins":
		var at := WorldGrid.project(WorldGrid.SHRINE)
		for ring in [42.0,53.0]:
			for i in range(6):
				draw_arc(at,ring,i*TAU/6+.06,(i+1)*TAU/6-.14,16,Color("8c8970"),1.4,true)
		for i in range(8):
			var point := at+Vector2.from_angle(i*TAU/8)*64
			draw_polyline(PackedVector2Array([point+Vector2(-3,-2),point+Vector2(0,1),point+Vector2(5,-3)]),Color("aba180"),1,true)
	else:
		# Woven resting mat anchors the inhabited camp, leaving the portal clear.
		var at := WorldGrid.project(Vector2(10,19))
		draw_rect(Rect2(at-Vector2(23,15),Vector2(46,30)),Color("b5a377"))
		for y in range(-12,14,4):
			draw_line(at+Vector2(-20,y),at+Vector2(20,y),Color("8f865f"),.8,true)

func pond(at: Vector2) -> void:
	var outline := PackedVector2Array()
	for i in range(65):
		var angle := float(i)*TAU/64
		outline.append(at+Vector2(cos(angle)*39,sin(angle)*72)*(1+.045*sin(angle*5)))
	draw_colored_polygon(outline,Color("6b8075"))
	draw_polyline(outline,Color("a9ab85"),6,true)
	draw_polyline(outline,Color("4e6458"),1.3,true)
	for i in range(6):
		var point := at+Vector2(sin(i*2.1)*22,-46+i*19)
		var ripple := PackedVector2Array()
		for j in range(15):
			ripple.append(point+Vector2(j-7,sin(j*.4+phase*.8+i)*1.0))
		draw_polyline(ripple,Color("9aada0"),.9,true)
	for offset in [Vector2(-11,-25),Vector2(16,24),Vector2(-14,41)]:
		draw_arc(at+offset,7,.3,TAU-.2,28,Color("879d71"),7,true)
		draw_circle(at+offset+Vector2(1,-1),2,Color("dbc9a4"),true,-1,true)

	# Reeds follow the dry bank; moving tips never change the water silhouette.
	for i in range(9):
		var angle := -.9 + i*.65
		var base := at + Vector2(cos(angle)*43,sin(angle)*77)
		for blade in range(3):
			var lean := sin(phase*.8+i)*.8
			draw_polyline(PackedVector2Array([base+Vector2(blade*2,0),base+Vector2(blade-2,-6),base+Vector2(blade-5+lean,-12-blade*2)]),Color("536b50"),.95,true)
