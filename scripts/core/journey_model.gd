class_name JourneyModel
extends RefCounted
## Saved exploration and gathering clocks. Cooldowns advance only while playing.
var discovered: Array[String] = []
var resources: Dictionary = {}
var medicine_left := 0.0
var revision := 0

func step(delta: float) -> void:
	medicine_left = maxf(0,medicine_left-delta)
	for id in resources.keys():
		resources[id] = maxf(0,float(resources[id])-delta)
		if resources[id] <= 0:
			resources.erase(id)
			revision += 1

func to_data() -> Dictionary:
	return {"version":1,"discovered":discovered.duplicate(),"resources":resources.duplicate(),"medicine_left":medicine_left}

func load_data(raw: Variant) -> bool:
	if not raw is Dictionary or raw.get("version",0) != 1 or not raw.get("discovered") is Array or not raw.get("resources") is Dictionary or not InventoryModel.valid_number(raw.get("medicine_left",0)): return false
	if float(raw.get("medicine_left",0)) < 0 or float(raw.get("medicine_left",0)) > 15: return false
	var seen := {}
	for id in raw["discovered"]:
		if not id is String or seen.has(id): return false
		var site := WorldContent.location(id)
		if not site.has("species") and site.get("kind","") != "waypoint": return false
		seen[id] = true
	for id in raw["resources"]:
		if not id is String: return false
		var site := WorldContent.location(id)
		if site.get("kind","") != "resource" or not InventoryModel.valid_number(raw["resources"][id]) or float(raw["resources"][id]) < 0 or float(raw["resources"][id]) > float(site["respawn"]): return false
	discovered.assign(raw["discovered"])
	resources = raw["resources"].duplicate()
	medicine_left = float(raw.get("medicine_left",0))
	return true
