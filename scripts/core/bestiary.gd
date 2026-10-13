class_name Bestiary
extends RefCounted
static var _species: Dictionary = {}

static func all() -> Dictionary:
	if _species.is_empty():
		_species = JSON.parse_string(FileAccess.get_file_as_string("res://data/bestiary.json"))["species"]
	return _species

static func species(id: String) -> Dictionary:
	return all().get(id,{})

static func attack(mob: Dictionary) -> Dictionary:
	var definition := species(str(mob["species"])).duplicate()
	var abilities: Array = definition.get("abilities",[])
	if not abilities.is_empty(): definition.merge(abilities[int(mob.get("attack_index",0))%abilities.size()],true)
	return definition

static func population(region: String) -> Dictionary:
	var result := {}
	var offsets := [Vector2(-3,-2),Vector2(2,-3),Vector2(4,1),Vector2(1,4),Vector2(-3,3),Vector2(-4,0)]
	for camp in WorldContent.camps(region):
		var definition := species(camp["species"])
		for i in range(int(camp["count"])):
			var id := str(camp["id"]) + "_" + str(i)
			var at: Vector2 = WorldContent.cell(camp) + (Vector2.ZERO if definition.get("elite",false) else offsets[i%offsets.size()])
			result[id] = {"id":id,"species":camp["species"],"camp":camp["id"],"wild":true,"name":definition["name"],"cell":at,"spawn":at,"path":[],"hp":float(definition["hp"]),"max_hp":float(definition["hp"]),"state":"idle","dead":false,"respawn_left":0.0,"attack_left":0.0,"windup_left":0.0,"slow_left":0.0,"repath_left":0.0,"wander_left":2.0+i,"facing":Vector2.from_angle(i*2.39996+at.x*.17),"owned":false,"variant":0,"aim":at,"attack_index":0,"attack_age":100.0,"last_attack":{},"attack_geometry":{}}
	return result
