class_name ExpeditionModel
extends RefCounted
## Persistent cultivation state. Timers advance only through authority.step().

const REGIONS := {
	"forest": {"name": "Thanh Mao Sơn", "subtitle": "Trại tông tộc • rừng trúc • lang triều", "reward": "Thịt thú, phong ấn và Cổ hoang"},
	"ruins": {"name": "Tam Vương Cổ Địa", "subtitle": "Truyền thừa • mỏ thạch • độc đàm", "reward": "Cổ tinh, chân nguyên thạch và Cổ hoang"},
	"realm": {"name": "Thanh Nang Phúc Địa", "subtitle": "Điền viên an toàn • vùng hoang linh mạch", "reward": "Linh thảo, mật hoa, linh quả và tơ tằm"},
}
const MATERIAL_NAMES := {"hide":"Da thú", "fang":"Nanh điện lang", "venom":"Độc nang", "ore":"Khoáng thạch", "relic":"Tàn quyển", "pollen":"Phấn linh hoa", "meat": "Thịt thú", "stone": "Chân nguyên thạch", "fruit": "Linh quả", "nectar": "Mật linh hoa", "seal": "Phong ấn", "essence": "Cổ tinh", "herb": "Linh thảo", "silk": "Tơ linh tằm", "egg": "Trứng linh kê", "herb_seed": "Hạt linh thảo", "flower_seed": "Hạt linh hoa", "fruit_seed": "Hạt linh quả"}
const CROPS := {
	"herb": {"name": "Linh thảo", "seed": "herb_seed", "time": 45.0, "yield": 4, "product": "herb", "price": 8},
	"flower": {"name": "Linh hoa", "seed": "flower_seed", "time": 60.0, "yield": 3, "product": "nectar", "price": 10},
	"fruit": {"name": "Linh quả", "seed": "fruit_seed", "time": 75.0, "yield": 4, "product": "fruit", "price": 12},
}
const ANIMALS := {
	"silkworm": {"name": "Linh tằm", "time": 60.0, "product": "silk", "yield": 2, "price": 30},
	"hen": {"name": "Linh kê", "time": 75.0, "product": "egg", "yield": 2, "price": 35},
}
const PLOTS: Array[Vector2] = [Vector2(10,15), Vector2(12,15), Vector2(14,15), Vector2(10,17), Vector2(12,17), Vector2(14,17)]
const PENS: Array[Vector2] = [Vector2(17,15), Vector2(17,18)]
var region: String = "forest"
var realm_unlocked: bool = false
var harvests: int = 0
var plots: Array[Dictionary] = []
var animals: Array[Dictionary] = []
var revision: int = 0

func _init() -> void:
	for i in range(PLOTS.size()):
		plots.append({"crop": "", "watered": false, "left": 0.0})
	for i in range(PENS.size()):
		animals.append({"kind": "", "fed": false, "left": 0.0})

func step(delta: float) -> bool:
	var ready := false
	for plot in plots:
		if bool(plot["watered"]) and float(plot["left"]) > 0.0:
			plot["left"] = maxf(0, float(plot["left"]) - delta)
			ready = ready or float(plot["left"]) == 0.0
	for animal in animals:
		if bool(animal["fed"]) and float(animal["left"]) > 0.0:
			animal["left"] = maxf(0, float(animal["left"]) - delta)
			ready = ready or float(animal["left"]) == 0.0
	return ready

static func strength(item: Dictionary) -> float:
	return 1.0 + .12 * (int(item.get("cultivation", 1)) - 1) + .6 * (int(item.get("rank", 1)) - 1)

static func upgrade_cost(item: Dictionary) -> Dictionary:
	var level := int(item.get("cultivation", 1))
	return {"herb": level * 2, "stone": level, "silver": level * 25}

static func fusion_cost(item: Dictionary) -> Dictionary:
	var rank_value := int(item.get("rank", 1))
	return {"silk": rank_value * 2, "essence": rank_value * 3, "silver": rank_value * 100}

static func material_name(key: String) -> String:
	return str(MATERIAL_NAMES.get(key, "Bạc" if key == "silver" else key))

func to_data() -> Dictionary:
	return {"version": 1, "region": region, "realm_unlocked": realm_unlocked, "harvests": harvests, "plots": plots.duplicate(true), "animals": animals.duplicate(true)}

func load_data(raw: Variant) -> bool:
	if not raw is Dictionary or raw.get("version", 0) != 1 or not REGIONS.has(raw.get("region", "")):
		return false
	if not raw.get("realm_unlocked") is bool or not _integer(raw.get("harvests"), 0, 1000000):
		return false
	if raw["region"] == "realm" and not raw["realm_unlocked"]:
		return false
	if not raw.get("plots") is Array or raw["plots"].size() != PLOTS.size() or not raw.get("animals") is Array or raw["animals"].size() != PENS.size():
		return false
	for plot in raw["plots"]:
		if not _valid_timer(plot, "crop", "watered", CROPS):
			return false
	for animal in raw["animals"]:
		if not _valid_timer(animal, "kind", "fed", ANIMALS):
			return false
	if not raw["realm_unlocked"]:
		for entry in raw["plots"] + raw["animals"]:
			if str(entry.get("crop", entry.get("kind", ""))) != "":
				return false
	region = raw["region"]
	realm_unlocked = raw["realm_unlocked"]
	harvests = int(raw["harvests"])
	plots.assign(raw["plots"].duplicate(true))
	animals.assign(raw["animals"].duplicate(true))
	return true

static func _integer(value: Variant, low: int, high: int) -> bool:
	return InventoryModel.valid_number(value) and float(value) == floorf(float(value)) and float(value) >= low and float(value) <= high

static func _valid_timer(raw: Variant, key: String, flag: String, definitions: Dictionary) -> bool:
	if not raw is Dictionary or not raw.get(key) is String or not raw.get(flag) is bool or not InventoryModel.valid_number(raw.get("left")):
		return false
	var id := str(raw[key])
	var seconds := float(raw["left"])
	if id == "":
		return not raw[flag] and seconds == 0
	return definitions.has(id) and seconds >= 0 and seconds <= float(definitions[id]["time"]) and (raw[flag] or seconds == float(definitions[id]["time"]) or (key == "kind" and seconds == 0))
