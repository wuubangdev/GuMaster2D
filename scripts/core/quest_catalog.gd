class_name QuestCatalog
extends RefCounted
const UNLOCK_NAMES := {"waygates":"Trạm dịch chuyển nội vùng", "field_medicine":"Dược phương hồi phục [R]", "irrigation":"Tưới toàn bộ linh điền [H]"}
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/quest_catalog.json"))
		assert(parsed is Dictionary and parsed.get("version",0) == 1, "Invalid quest catalog")
		_data = parsed
	return _data

static func npc(id: String) -> Dictionary:
	return data()["npcs"].get(id,{})

static func npcs(region: String) -> Array[String]:
	var result: Array[String] = []
	for id in data()["npcs"]:
		if npc(id)["region"] == region:
			result.append(id)
	return result

static func cell(id: String) -> Vector2:
	var value: Array = npc(id).get("cell",[0,0])
	return Vector2(value[0],value[1])

static func quests() -> Array:
	return data()["quests"]

static func quest(id: String) -> Dictionary:
	for entry in quests():
		if entry["id"] == id:
			return entry
	return {}

static func reward_text(reward: Dictionary, unlocks: Array = []) -> String:
	var pieces := PackedStringArray()
	for key in reward:
		pieces.append("%d %s" % [reward[key], "kinh nghiệm" if key == "xp" else ExpeditionModel.material_name(key)])
	for unlock in unlocks: pieces.append("Mở " + str(UNLOCK_NAMES[unlock]))
	return " · ".join(pieces)

static func objective_location(id: String, sim: RefCounted) -> Dictionary:
	var definition := quest(id)
	var status: String = sim.quests.status(id,sim)
	if status in ["active","ready"] and status != "ready" and definition.has("target"):
		var site := WorldContent.location(definition["target"])
		if not site.is_empty(): return {"name":site["name"],"region":site["region"],"cell":WorldContent.cell(site)}
	var npc_id := str(definition["giver"]) if status == "available" else str(sim.quests.destination(id,sim))
	var person := npc(npc_id)
	return {"name":person["name"],"region":person["region"],"cell":cell(npc_id)+Vector2(0,1)}
