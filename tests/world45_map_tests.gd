extends SceneTree
## World authority and streaming regression. Never reads or writes a player save.
var checks: Array[Dictionary] = []
var failures := 0
var metrics := {}
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures += 1; printerr("FAIL: ",label)
func run() -> void:
	var total_camps := 0
	var total_nodes := 0
	var total_gates := 0
	for id in ["forest","ruins","realm"]:
		var started := Time.get_ticks_msec()
		var world := WorldGrid.new(id)
		var build_ms := Time.get_ticks_msec()-started
		check(world.nav.region.size == Vector2i(256,256),id+" 256 by 256 authoritative cells")
		var legacy := legacy_reference(id)
		var saved_cells := 0
		var newly_blocked := 0
		var changed_props := 0
		var current_props := {}
		for prop in world.props: current_props[Vector2i(prop["cell"])] = prop
		for x in range(1,95):
			for y in range(1,95):
				if x < 27 and y < 28: continue
				var cell := Vector2i(x,y)
				if not legacy["blocked"].has(cell):
					saved_cells += 1
					if not world.is_walkable(Vector2(cell)): newly_blocked += 1
		for cell in legacy["props"]:
			if WorldContent.reserved(id,Vector2(cell)): continue
			var expected: Dictionary = legacy["props"][cell]
			var actual: Dictionary = current_props.get(cell,{})
			if expected.get("kind","") != actual.get("kind","") or expected.get("variant",-1) != actual.get("variant",-1): changed_props += 1
		check(newly_blocked == 0,id+" preserves "+str(saved_cells)+" legacy walkable save positions")
		check(changed_props == 0,id+" old scenery PRNG matches independent legacy generation")
		var visited := flood(world)
		for site in WorldContent.camps(id)+WorldContent.waypoints(id)+WorldContent.resources(id):
			check(visited.has(Vector2i(WorldContent.cell(site))),id+" reachable "+str(site["id"]))
		for npc in QuestCatalog.npcs(id): check(visited.has(Vector2i(QuestCatalog.cell(npc))),id+" reachable NPC "+npc)
		var water := 0
		var bridges := 0
		for cell in world.surfaces:
			if world.surfaces[cell] == "water":
				water += 1
				if world.is_walkable(cell): check(false,"Water remains blocked "+id+str(cell))
			elif world.surfaces[cell] == "stone" and WorldContent.water(id,Vector2(cell)): bridges += 1
		check(water > 1500 and bridges > 40,id+" wide waterways crossed by authored bridges")
		var points := [Vector2(12,20),Vector2(114,24),Vector2(28,202),Vector2(222,224)]
		var max_active := 0
		for point in points:
			var nearby := world.props_near(point,28)
			max_active = maxi(max_active,nearby.size())
			var actual := {}
			for prop in nearby: actual[int(prop["stream_id"])] = true
			var expected := 0
			for prop in world.props:
				if point.distance_squared_to(prop["cell"]) <= 28*28: expected += 1
			check(actual.size() == nearby.size() and expected == nearby.size(),id+" prop buckets include exact nearby set "+str(point))
		check(world.props_near(Vector2(128,128),400).size() == world.props.size(),id+" every prop can be streamed once")
		for camp in WorldContent.camps(id):
			check(not world.is_safe(WorldContent.cell(camp)),id+" hostile camp outside safe zones "+str(camp["id"]))
		for gate in WorldContent.waypoints(id): check(world.is_safe(WorldContent.cell(gate)),id+" rest stop safe "+str(gate["id"]))
		if id == "realm":
			for x in range(1,26):
				for y in range(1,28):
					if not world.is_safe(Vector2(x,y)): check(false,"Protected farming cell "+str(Vector2(x,y)))
			check(true,"Original farming district remains protected")
		started = Time.get_ticks_msec()
		var cached := WorldGrid.new(id)
		metrics[id] = {"first_build_ms":build_ms,"cached_build_ms":Time.get_ticks_msec()-started,"walkable_connected":visited.size(),"water_cells":water,"bridge_cells":bridges,"props":world.props.size(),"max_props_radius_28":max_active}
		world._set_block(Vector2i(WorldGrid.SPAWN))
		check(cached.is_walkable(WorldGrid.SPAWN),id+" independently mutable navigation from cache")
		total_camps += WorldContent.camps(id).size()
		total_gates += WorldContent.waypoints(id).size()
		total_nodes += WorldContent.resources(id).size()
	check(total_camps == 64 and total_gates == 33 and total_nodes == 176,"64 camps, 33 waypoints and 176 gathering sites")
	check(WorldContent.cell(WorldContent.location("f_bamboo")) == Vector2(38,20) and WorldContent.cell(WorldContent.location("r_guardian")) == Vector2(77,79) and WorldContent.cell(WorldContent.location("b_core")) == Vector2(78,77),"Legacy quest location IDs and coordinates preserved")
	await ground_streaming()
	var file := FileAccess.open("res://artifacts/world45_map_tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"metrics":metrics},"  "))
	print("WORLD45_MAP_TESTS ",checks.size()-failures,"/",checks.size()," ",metrics)
	quit(1 if failures else 0)
func flood(world: WorldGrid) -> Dictionary:
	var origin := Vector2i(WorldGrid.SPAWN)
	var seen := {origin:true}
	var frontier: Array[Vector2i] = [origin]
	var cursor := 0
	while cursor < frontier.size():
		var point := frontier[cursor]
		cursor += 1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = point+delta
			if not seen.has(next) and world.is_walkable(Vector2(next)):
				seen[next] = true
				frontier.append(next)
	return seen
func ground_streaming() -> void:
	root.size = Vector2i(1280,720)
	var canvas := Node2D.new()
	root.add_child(canvas)
	var world := WorldGrid.new()
	var ground := GroundView.new()
	ground.world = world
	canvas.add_child(ground)
	var camera := Camera2D.new()
	canvas.add_child(camera)
	camera.make_current()
	for zoom in [1.0,2.0,4.0]:
		camera.zoom = Vector2.ONE*zoom
		for point in [Vector2(12,20),Vector2(110,178),Vector2(222,224)]:
			camera.position = WorldGrid.project(point)
			camera.force_update_scroll()
			await process_frame
			ground._refresh_visible_tiles()
			var window := ground.visible_cell_rect()
			var size := ground.tiles.get_used_cells().size()
			check(size == window.get_area() and size < 6000,"Ground only allocates viewport window at "+str(point)+" zoom "+str(zoom))
			check(window.has_point(Vector2i(point)),"Ground window follows distant camera "+str(point))
			var waters_inside := true
			for cell in ground._water_cells: waters_inside = waters_inside and window.has_point(cell)
			check(waters_inside,"Only visible water animates at "+str(point))
	canvas.queue_free()
	await process_frame

func legacy_reference(id: String) -> Dictionary:
	# Independent pre-0.45 overland algorithm uses exact line/circle checks,
	# rather than the optimized geography masks under test.
	var lines: Array = WorldContent.region(id)["legacy_roads"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4031+["forest","ruins","realm"].find(id)
	var blocks := {}
	var scenery := {}
	if id == "forest":
		var village_rng := RandomNumberGenerator.new()
		village_rng.seed = 74021
		for x in range(28):
			for y in range(28):
				if x == 0 or y == 0: continue
				if (x < 4 or y < 3 or x > 24 or y > 24) and village_rng.randf() < .42:
					village_rng.randi_range(0,4)
					blocks[Vector2i(x,y)] = true
	for x in range(1,95):
		for y in range(1,95):
			if x < 27 and y < 28: continue
			var point := Vector2(x,y)
			var distance := INF
			for line in lines:
				for index in range(1,line.size()):
					var a := Vector2(line[index-1][0],line[index-1][1])
					var b := Vector2(line[index][0],line[index][1])
					distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)))
			var reserved := distance <= 2
			for camp in WorldContent.camps(id):
				if str(camp["id"]).begins_with("w45_"): continue
				if point.distance_to(WorldContent.cell(camp)) <= 7.5: reserved = true
			for site in WorldContent.waypoints(id)+WorldContent.resources(id):
				if str(site["id"]).begins_with("w45_"): continue
				if point.distance_to(WorldContent.cell(site)) <= 2.2: reserved = true
			for npc in QuestCatalog.npcs(id):
				if point.distance_to(QuestCatalog.cell(npc)) <= 2.5: reserved = true
			var water := WorldContent.water(id,point) and distance > 1.35 and not reserved
			if water: blocks[Vector2i(point)] = true
			elif not reserved and rng.randf() < (.09 if id == "ruins" else .12):
				var kind := "rock" if rng.randf() < .2 else "tree"
				if id == "ruins": kind = "ruin_column" if rng.randf() < .32 else "rock"
				elif id == "forest" and (y < 38 or x < 37): kind = "bamboo" if rng.randf() < .65 else kind
				scenery[Vector2i(point)] = {"kind":kind,"variant":rng.randi_range(0,4)}
				blocks[Vector2i(point)] = true
	# Same long-established gate opening connects the original camp.
	for x in range(23,29):
		for y in range(18,23):
			blocks.erase(Vector2i(x,y))
			scenery.erase(Vector2i(x,y))
	return {"blocked":blocks,"props":scenery}
