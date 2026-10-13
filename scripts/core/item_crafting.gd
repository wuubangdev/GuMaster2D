class_name ItemCrafting
extends RefCounted
## Shared recipe queries and atomic, replay-safe inventory transactions.
static var _recipes: Dictionary = {}
static var _loaded := false
const DESCRIPTIONS := {
	"meat": "Thức ăn của Nguyệt Quang Cổ. Mỗi phần hồi tối đa 40 no đủ.",
	"stone": "Thức ăn của Bạch Ngọc Cổ; nguyên liệu tu luyện và ép phong ấn.",
	"fruit": "Thức ăn của Bạch Hạc Cổ và vật nuôi trong Thanh Nang.",
	"nectar": "Thức ăn của Băng Tằm Cổ. Mỗi phần hồi tối đa 40 no đủ.",
	"seal": "Phong ấn quái đã chọn, do mình đánh, có HP ≤30%, trong tầm 3 ô. Thi triển 2 giây.",
	"hide": "Da thú dùng trong công thức ép phong ấn.",
	"fang": "Nanh điện lang thu từ đầu lĩnh; nguyên liệu hiếm để tích trữ.",
	"venom": "Độc nang thu từ nhện và cóc; nguyên liệu nhiệm vụ và Cổ giới.",
	"ore": "Khoáng thạch thu ở mỏ; nguyên liệu nhiệm vụ và tu luyện.",
	"relic": "Tàn quyển truyền thừa thu tại cổ địa; nguyên liệu nhiệm vụ.",
	"pollen": "Phấn linh hoa dùng để tinh lọc mật nuôi Băng Tằm Cổ.",
	"essence": "Cổ tinh dùng phục hồi cổ trận và luyện hợp Cổ trùng.",
	"herb": "Linh thảo trồng trong bí cảnh; dùng tu luyện và chế tạo vật phẩm.",
	"silk": "Tơ linh tằm dùng trong công thức luyện hợp Cổ.",
	"egg": "Sản vật linh kê; chưng 2 trứng thành 3 chân nguyên thạch.",
	"herb_seed": "Hạt linh thảo. Vào bí cảnh, chọn ô đất trống để gieo.",
	"flower_seed": "Hạt linh hoa. Vào bí cảnh, chọn ô đất trống để gieo.",
	"fruit_seed": "Hạt linh quả. Vào bí cảnh, chọn ô đất trống để gieo."
}

static func all() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/item_recipes.json"))
		if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("recipes") is Dictionary:
			for id in parsed["recipes"]:
				var recipe = parsed["recipes"][id]
				if _valid_recipe(recipe):
					_recipes[str(id)] = recipe.duplicate(true)
	return _recipes

static func _valid_recipe(recipe: Variant) -> bool:
	if not recipe is Dictionary or not recipe.get("name") is String or not recipe.get("description") is String: return false
	if not recipe.get("cost") is Dictionary or not recipe.get("output") is Dictionary or recipe["cost"].is_empty() or recipe["output"].is_empty(): return false
	for group in ["cost", "output"]:
		for key in recipe[group]:
			if not ExpeditionModel.MATERIAL_NAMES.has(key) and not (group == "cost" and key == "silver"): return false
			if not ExpeditionModel._integer(recipe[group][key], 1, 2970): return false
	return true

static func for_material(material: String) -> Array[String]:
	var result: Array[String] = []
	for id in all():
		var recipe: Dictionary = all()[id]
		if recipe["cost"].has(material) or recipe["output"].has(material): result.append(str(id))
	return result

static func description(material: String) -> String:
	return str(DESCRIPTIONS.get(material, "Vật liệu Cổ giới."))

static func preview(sim: RefCounted, recipe_id: String, batches: Variant = 1) -> Dictionary:
	if not all().has(recipe_id) or not ExpeditionModel._integer(batches, 1, 99): return _fail("BAD_RECIPE")
	if bool(sim.player["dead"]): return _fail("DEAD")
	if sim.combat_left > 0 or not sim.capture.is_empty(): return _fail("IN_COMBAT")
	if not sim.world.is_safe(sim.player["cell"]): return _fail("AT_CAMP")
	var recipe: Dictionary = all()[recipe_id]
	var next: Dictionary = sim.inventory.materials.duplicate()
	var silver := int(sim.player["currency"])
	for key in recipe["cost"]:
		var required := int(recipe["cost"][key]) * int(batches)
		if key == "silver":
			if silver < required: return _fail("NEED_MATERIALS")
			silver -= required
		else:
			if int(next.get(key, 0)) < required: return _fail("NEED_MATERIALS")
			next[key] = int(next[key]) - required
	for key in recipe["output"]: next[key] = int(next.get(key, 0)) + int(recipe["output"][key]) * int(batches)
	var occupied: int = sim.inventory.gu.size()
	for amount in next.values(): occupied += ceili(float(amount) / 99.0)
	if occupied > InventoryModel.CAPACITY: return _fail("BAG_FULL")
	return {"ok": true, "materials": next, "silver": silver, "occupied": occupied}

static func execute(sim: RefCounted, request_id: String, recipe_id: String, batches: Variant, expected_version: int) -> Dictionary:
	if request_id.is_empty() or request_id.length() > 128: return _fail("INVALID_REQUEST")
	var fingerprint := "craft:%s:%s:%d" % [recipe_id, str(batches), expected_version]
	if sim.inventory.receipts.has(request_id):
		var previous: Dictionary = sim.inventory.receipts[request_id]
		return previous.duplicate(true) if previous.get("fingerprint") == fingerprint else _fail("REQUEST_CONFLICT")
	if expected_version != sim.inventory.version: return _fail("VERSION_CONFLICT")
	var probe := preview(sim, recipe_id, batches)
	if not probe["ok"]: return probe
	var recipe: Dictionary = all()[recipe_id]
	sim.inventory.materials = probe["materials"]
	sim.player["currency"] = probe["silver"]
	sim.inventory.version += 1
	sim.inventory.recover_rewards()
	var output := {}
	var names: Array[String] = []
	for key in recipe["output"]:
		output[key] = int(recipe["output"][key]) * int(batches)
		names.append("%s ×%d" % [ExpeditionModel.material_name(str(key)), output[key]])
	var receipt := {"ok": true, "request_id": request_id, "fingerprint": fingerprint, "version": sim.inventory.version, "output": output}
	sim.inventory.receipts[request_id] = receipt.duplicate(true)
	if sim.inventory.receipts.size() > 128: sim.inventory.receipts.erase(sim.inventory.receipts.keys()[0])
	sim._emit("item_crafted", sim.player["cell"], {"text": "Chế tạo thành công • " + ", ".join(names), "persistent": true, "recipe": recipe_id, "batches": int(batches)})
	return receipt

static func _fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}
