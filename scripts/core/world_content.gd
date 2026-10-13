class_name WorldContent
extends RefCounted
## Immutable authored geography shared by simulation, map UI and renderer.
static var _data: Dictionary = {}
static var _locations: Dictionary = {}
static var _roads: Dictionary = {}
static var _clearance: Dictionary = {}
static var _roadbeds: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_content.json"))
		for region in _data["regions"]:
			for item in camps(region) + waypoints(region) + resources(region):
				_locations[item["id"]] = item
	return _data

static func region(id: String) -> Dictionary:
	return data()["regions"][id]

static func camps(id: String) -> Array:
	return region(id)["camps"]

static func waypoints(id: String) -> Array:
	return region(id)["waypoints"]

static func resources(id: String) -> Array:
	return region(id)["resources"]

static func location(id: String) -> Dictionary:
	data()
	return _locations.get(id,{})

static func cell(item: Dictionary) -> Vector2:
	return Vector2(item["cell"][0],item["cell"][1])

static func roads(id: String) -> Array:
	if not _roads.has(id):
		var lines: Array = []
		for line in region(id)["roads"]:
			var points := PackedVector2Array()
			for point in line: points.append(Vector2(point[0],point[1]))
			lines.append(points)
		_roads[id] = lines
	return _roads[id]

static func road_distance(id: String, point: Vector2) -> float:
	var result := INF
	for line in roads(id):
		for i in range(1,line.size()):
			result = minf(result,point.distance_to(Geometry2D.get_closest_point_to_segment(point,line[i-1],line[i])))
	return result

static func _mark_disc(mask: PackedByteArray, center: Vector2, radius: float, size: int) -> void:
	for y in range(maxi(1,floori(center.y-radius)),mini(size-1,ceili(center.y+radius)+1)):
		for x in range(maxi(1,floori(center.x-radius)),mini(size-1,ceili(center.x+radius)+1)):
			if Vector2(x,y).distance_squared_to(center) <= radius*radius: mask[y*size+x] = 1

static func _prepare_geography(id: String, legacy: bool = false) -> void:
	var key := id+"_legacy" if legacy else id
	if _clearance.has(key): return
	var size: int = int(data()["size"])
	var clear := PackedByteArray()
	var roadbed := PackedByteArray()
	clear.resize(size*size)
	roadbed.resize(size*size)
	# Raster each narrow road corridor once, rather than scanning every road at
	# every terrain cell. The authoring geometry still defines the exact bridge.
	var paths: Array = roads(id)
	if legacy:
		paths = []
		for source in region(id).get("legacy_roads",region(id)["roads"]):
			var points := PackedVector2Array()
			for point in source: points.append(Vector2(point[0],point[1]))
			paths.append(points)
	for line in paths:
		for index in range(1,line.size()):
			var start: Vector2 = line[index-1]
			var end: Vector2 = line[index]
			for y in range(maxi(1,floori(minf(start.y,end.y)-2)),mini(size-1,ceili(maxf(start.y,end.y)+2)+1)):
				for x in range(maxi(1,floori(minf(start.x,end.x)-2)),mini(size-1,ceili(maxf(start.x,end.x)+2)+1)):
					var point := Vector2(x,y)
					var distance := point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point,start,end))
					if distance <= 4.0: clear[y*size+x] = 1
					if distance <= 1.35*1.35: roadbed[y*size+x] = 1
	for camp in camps(id): _mark_disc(clear,cell(camp),7.5,size)
	for site in waypoints(id)+resources(id): _mark_disc(clear,cell(site),2.2,size)
	for npc_id in QuestCatalog.npcs(id): _mark_disc(clear,QuestCatalog.cell(npc_id),2.5,size)
	_clearance[key] = clear
	_roadbeds[key] = roadbed

static func reserved(id: String, point: Vector2, legacy: bool = false) -> bool:
	_prepare_geography(id,legacy)
	var key := id+"_legacy" if legacy else id
	var size: int = int(data()["size"])
	var at := Vector2i(roundi(point.x),roundi(point.y))
	if at.x < 0 or at.y < 0 or at.x >= size or at.y >= size: return false
	return _clearance[key][at.y*size+at.x] != 0

static func district(id: String, point: Vector2) -> Dictionary:
	for item in region(id).get("districts",[]):
		var bounds: Array = item["bounds"]
		if Rect2(bounds[0],bounds[1],bounds[2],bounds[3]).has_point(point): return item
	return {}

static func _expanded_water(id: String, point: Vector2) -> bool:
	for item in region(id).get("waterways",[]):
		if item["kind"] == "pond":
			var center := Vector2(item["center"][0],item["center"][1])
			var radii := Vector2(item["radii"][0],item["radii"][1])
			if ((point-center)/radii).length_squared() < 1: return true
		else:
			var along: float = point.y if item["axis"] == "y" else point.x
			var across: float = point.x if item["axis"] == "y" else point.y
			if along > item["start"] and along < item["end"] and absf(across-float(item["center"])-sin(along*float(item["frequency"]))*float(item["amplitude"])) < float(item["width"]): return true
	return false

static func water(id: String, point: Vector2) -> bool:
	if point.x < 27 and point.y < 28: return false
	if _expanded_water(id,point): return true
	if id == "forest":
		return ((point-Vector2(86,40))/Vector2(6,8)).length() < 1 or (point.y > 28 and point.y < 91 and absf(point.x-43-sin(point.y*.105)*4) < 1.6) or ((point-Vector2(65,58))/Vector2(6,4)).length() < 1
	if id == "ruins":
		return ((point-Vector2(75,22))/Vector2(6,5)).length() < 1 or (point.y > 32 and point.y < 89 and absf(point.x-58-sin(point.y*.12)*3) < 2.0)
	return ((point-Vector2(81,39))/Vector2(6,7)).length() < 1 or (point.y > 32 and point.y < 89 and absf(point.x-35-sin(point.y*.085)*4) < 2) or ((point-Vector2(72,54))/Vector2(7,5)).length() < 1

static func surface(id: String, point: Vector2, legacy: bool = false) -> String:
	_prepare_geography(id,legacy)
	var key := id+"_legacy" if legacy else id
	var size: int = int(data()["size"])
	var at := Vector2i(roundi(point.x),roundi(point.y))
	var paved: bool = at.x >= 0 and at.y >= 0 and at.x < size and at.y < size and _roadbeds[key][at.y*size+at.x] != 0
	if paved: return "stone" if id == "ruins" or water(id,point) else "dirt"
	if water(id,point) and not reserved(id,point,legacy): return "water"
	if id == "forest" and ((point-Vector2(62,16))/Vector2(7,5)).length() < 1: return "dirt"
	if id == "ruins": return "stone" if sin(point.x*.17)*cos(point.y*.2) > .55 else "dirt"
	return "grass"
