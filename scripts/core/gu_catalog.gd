class_name GuCatalog
extends RefCounted

var definitions: Dictionary = {}
const SLOT_IDS: Array[String] = ["GU-01", "GU-03", "GU-05", "GU-07"]
const FOOD_NAMES: Dictionary = {"meat": "Thịt thú", "stone": "Chân nguyên thạch", "fruit": "Linh quả", "nectar": "Mật linh hoa"}

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/gu_catalog.json"))
	assert(parsed is Dictionary and parsed.has("gu"), "Invalid Gu catalog")
	for definition in parsed["gu"]:
		definitions[str(definition["id"])] = definition

func get_gu(id: String) -> Dictionary:
	return definitions.get(id, {})

func slot(index: int) -> Dictionary:
	return get_gu(SLOT_IDS[index]) if index >= 0 and index < SLOT_IDS.size() else {}
