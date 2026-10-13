class_name WorldGrid
extends RefCounted

const SIZE: int = 256
const CELL_SIZE: Vector2 = Vector2(32.0, 32.0)
const HALF_TILE: Vector2 = CELL_SIZE * 0.5
const SPAWN: Vector2 = Vector2(12, 20)
const SHRINE: Vector2 = Vector2(12, 12)
const LANDMARKS := {
	"forest": [{"cell":Vector2(8,20),"kind":"camp_awning"},{"cell":Vector2(14,23),"kind":"herbal_table"},{"cell":Vector2(11,16),"kind":"waypost"}],
	"ruins": [{"cell":Vector2(9,22),"kind":"survey_table"},{"cell":Vector2(14,14),"kind":"ruin_banner"}],
	"realm": [{"cell":Vector2(18,22),"kind":"tool_shed"}]
}
var landmarks: Array[Dictionary] = []
static var _blueprints: Dictionary = {}
var surfaces: Dictionary = {}
var region: String = "forest"
var nav: AStarGrid2D
var blocked: Dictionary = {}
var props: Array[Dictionary] = []
const PROP_BUCKET_SIZE := 16
var _prop_buckets: Dictionary = {}

func _init(region_id: String = "forest") -> void:
	region = region_id
	nav = AStarGrid2D.new()
	nav.region = Rect2i(0, 0, SIZE, SIZE)
	nav.cell_size = Vector2.ONE
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	nav.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	nav.update()
	if _blueprints.has(region):
		var cached: Dictionary = _blueprints[region]
		blocked = cached["blocked"].duplicate()
		surfaces = cached["surfaces"].duplicate()
		props.assign(cached["props"].duplicate(true))
		landmarks.assign(cached["landmarks"].duplicate(true))
		for point in blocked: nav.set_point_solid(point,true)
		_index_props()
		return
	if region != "forest":
		_build_region()
		_add_landmarks()
		_build_overland()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 74021
	for x in range(28):
		for y in range(28):
			var cell := Vector2i(x, y)
			if x == 0 or y == 0:
				_set_block(cell)
			elif (x < 4 or y < 3 or x > 24 or y > 24) and rng.randf() < 0.42:
				add_prop(cell, "tree", rng.randi_range(0, 4))
	for cell in [Vector2i(7, 17), Vector2i(8, 16), Vector2i(8, 15), Vector2i(19, 17), Vector2i(20, 18), Vector2i(19, 9), Vector2i(6, 21), Vector2i(16, 22)]:
		add_prop(cell, "tree", rng.randi_range(0, 4))
	for cell in [Vector2i(9, 18), Vector2i(15, 16), Vector2i(17, 11), Vector2i(6, 13), Vector2i(21, 21)]:
		add_prop(cell, "rock", rng.randi_range(0, 3))
	for x in range(8, 17):
		if x not in [11, 12, 13]:
			add_prop(Vector2i(x, 10), "wall", x % 3)
	add_prop(Vector2i(10, 11), "pillar", 0)
	add_prop(Vector2i(14, 11), "pillar", 1)
	add_prop(Vector2i(12, 9), "monolith", 0)
	# Walkable lanterns mark the safe camp; they are presentation only.
	props.append({"cell": Vector2(10, 21), "kind": "lantern", "variant": 0})
	props.append({"cell": Vector2(14, 21), "kind": "lantern", "variant": 1})
	props.append({"cell": SHRINE, "kind": "altar", "variant": 0})
	_add_landmarks()
	_build_overland()

static func project(cell: Vector2) -> Vector2:
	return cell * CELL_SIZE

static func unproject(point: Vector2) -> Vector2:
	return point / CELL_SIZE

func _set_block(cell: Vector2i) -> void:
	blocked[cell] = true
	nav.set_point_solid(cell, true)

func add_prop(cell: Vector2i, kind: String, variant: int) -> void:
	_set_block(cell)
	props.append({"cell": Vector2(cell), "kind": kind, "variant": variant})

func is_walkable(point: Vector2) -> bool:
	var cell := Vector2i(roundi(point.x), roundi(point.y))
	return nav.is_in_boundsv(cell) and not nav.is_point_solid(cell)

func is_safe(point: Vector2) -> bool:
	if (region == "realm" and point.x < 26 and point.y < 28) or point.distance_to(SPAWN) <= 2.0:
		return true
	for waypoint in WorldContent.waypoints(region):
		if point.distance_to(WorldContent.cell(waypoint)) <= 2.2: return true
	for id in QuestCatalog.npcs(region):
		if point.distance_to(QuestCatalog.cell(id)) <= 1.8:
			return true
	return false

func path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if not is_walkable(from) or not is_walkable(to):
		return result
	var cells: Array[Vector2i] = nav.get_id_path(Vector2i(roundi(from.x), roundi(from.y)), Vector2i(roundi(to.x), roundi(to.y)))
	for i in range(1, cells.size()):
		result.append(Vector2(cells[i]))
	return result

func clear_segment(from: Vector2, to: Vector2) -> bool:
	return sweep(from, to).distance_to(to) < 0.02

func sweep(from: Vector2, to: Vector2) -> Vector2:
	var previous := from
	var count := maxi(1, ceili(from.distance_to(to) / 0.06))
	for i in range(1, count + 1):
		var next := from.lerp(to, float(i) / float(count))
		if not is_walkable(next):
			break
		var a := Vector2i(roundi(previous.x), roundi(previous.y))
		var b := Vector2i(roundi(next.x), roundi(next.y))
		if a.x != b.x and a.y != b.y:
			if not is_walkable(Vector2(a.x, b.y)) or not is_walkable(Vector2(b.x, a.y)):
				break
		previous = next
	return previous

func _build_region() -> void:
	for x in range(SIZE):
		for y in range(SIZE):
			if x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1:
				_set_block(Vector2i(x, y))
	if region == "ruins":
		for x in [5, 6, 7, 8, 9, 15, 16, 17, 18, 19, 20, 21, 22]:
			add_prop(Vector2i(x, 9), "wall", x % 3)
		for cell in [Vector2i(6,13), Vector2i(20,13), Vector2i(9,16), Vector2i(17,16), Vector2i(5,21), Vector2i(22,22)]:
			add_prop(cell, "pillar", cell.x % 2)
		for cell in [Vector2i(8,5), Vector2i(18,5), Vector2i(6,7), Vector2i(21,6)]:
			add_prop(cell, "rock", cell.x % 3)
		add_prop(Vector2i(12,8), "monolith", 0)
	else:
		for cell in [Vector2i(6,12), Vector2i(7,9), Vector2i(9,7), Vector2i(16,7), Vector2i(21,12), Vector2i(21,21), Vector2i(6,22), Vector2i(18,24)]:
			add_prop(cell, "tree", cell.x % 4)
		for cell in [Vector2i(8,14), Vector2i(8,16), Vector2i(8,18), Vector2i(19,14), Vector2i(19,16), Vector2i(19,18)]:
			props.append({"cell": Vector2(cell), "kind": "fence", "variant": 0})
	props.append({"cell": SPAWN + Vector2(-2,1), "kind": "lantern", "variant": 0})
	props.append({"cell": SPAWN + Vector2(2,1), "kind": "lantern", "variant": 1})
	props.append({"cell": SHRINE, "kind": "altar", "variant": 0})

func _add_landmarks() -> void:
	landmarks.assign(LANDMARKS.get(region,[]))
	for data in landmarks:
		_set_block(Vector2i(data["cell"]))
	if region == "realm":
		for x in range(5,8):
			for y in range(14,19):
				if Vector2(x-6,(y-16)*.5).length() <= 1.2:
					_set_block(Vector2i(x,y))

func _build_overland() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 4031 + ["forest","ruins","realm"].find(region)
	# Preserve the old random sequence and coordinates inside the original 96²
	# region; expanded scenery cannot invalidate a saved location there.
	for pass_index in range(2):
		for x in range(96 if pass_index == 0 else SIZE):
			for y in range(96 if pass_index == 0 else SIZE):
				if pass_index == 0 and (x == 95 or y == 95): continue
				if pass_index == 1 and x < 95 and y < 95: continue
				var at := Vector2i(x,y)
				if x == 0 or y == 0 or x == SIZE-1 or y == SIZE-1:
					_set_block(at)
					continue
				if x < 27 and y < 28: continue
				var terrain := WorldContent.surface(region,Vector2(at),pass_index == 0)
				surfaces[at] = terrain
				if terrain == "water":
					_set_block(at)
				elif not WorldContent.reserved(region,Vector2(at),pass_index == 0) and random.randf() < (.09 if region == "ruins" else .12):
					var kind := "rock" if random.randf() < .2 else "tree"
					if region == "ruins": kind = "ruin_column" if random.randf() < .32 else "rock"
					elif region == "forest" and (at.y < 38 or at.x < 37 or (at.x > 96 and at.y < 96)): kind = "bamboo" if random.randf() < .65 else kind
					add_prop(at,kind,random.randi_range(0,4))
	# New links may open an old obstacle, but never relocate old props into a
	# previously walkable save position. Keep the legacy PRNG untouched above.
	var opened := {}
	for x in range(27,95):
		for y in range(28,95):
			var point := Vector2(x,y)
			if WorldContent.reserved(region,point) and not WorldContent.reserved(region,point,true):
				var cell := Vector2i(x,y)
				blocked.erase(cell)
				nav.set_point_solid(cell,false)
				surfaces[cell] = WorldContent.surface(region,point)
				opened[cell] = true
	if not opened.is_empty():
		props.assign(props.filter(func(item: Dictionary) -> bool: return not opened.has(Vector2i(item["cell"]))))
	# Clear the existing village edge where the main trail enters the wide world.
	for x in range(23,29):
		for y in range(18,23):
			var at := Vector2i(x,y)
			blocked.erase(at)
			nav.set_point_solid(at,false)
			for i in range(props.size()-1,-1,-1):
				if Vector2i(props[i]["cell"]) == at: props.remove_at(i)

	_index_props()
	_blueprints[region] = {"blocked":blocked.duplicate(),"surfaces":surfaces.duplicate(),"props":props.duplicate(true),"landmarks":landmarks.duplicate(true)}

func terrain_at(cell: Vector2i) -> String:
	return str(surfaces.get(cell,"grass"))

func _index_props() -> void:
	_prop_buckets.clear()
	for index in range(props.size()):
		var item: Dictionary = props[index]
		item["stream_id"] = index
		var point: Vector2 = item["cell"]
		var key := Vector2i(floori(point.x/PROP_BUCKET_SIZE),floori(point.y/PROP_BUCKET_SIZE))
		if not _prop_buckets.has(key): _prop_buckets[key] = []
		_prop_buckets[key].append(item)

func props_near(center: Vector2, radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var low := Vector2i(floori((center.x-radius)/PROP_BUCKET_SIZE),floori((center.y-radius)/PROP_BUCKET_SIZE))
	var high := Vector2i(floori((center.x+radius)/PROP_BUCKET_SIZE),floori((center.y+radius)/PROP_BUCKET_SIZE))
	for x in range(low.x,high.x+1):
		for y in range(low.y,high.y+1):
			for item in _prop_buckets.get(Vector2i(x,y),[]):
				if center.distance_squared_to(item["cell"]) <= radius*radius: result.append(item)
	return result
