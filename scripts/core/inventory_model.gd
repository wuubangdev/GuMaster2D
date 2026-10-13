class_name InventoryModel
extends RefCounted

const CAPACITY: int = 30
var gu: Array[Dictionary] = []
var materials: Dictionary = {"meat": 3, "stone": 2, "fruit": 2, "nectar": 2, "seal": 5}
var receipts: Dictionary = {}
var version: int = 0
var next_id: int = 5
var pending_materials: Dictionary = {}
var display_order: Array[String] = []
var slot_layout: Array[String] = []

static func valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _init() -> void:
	for i in range(GuCatalog.SLOT_IDS.size()):
		gu.append({"instance_id": "gu_%d" % (i + 1), "definition_id": GuCatalog.SLOT_IDS[i], "hunger": 100.0, "slot": i, "rank": 1, "cultivation": 1})

func occupied_slots() -> int:
	var count := gu.size()
	for qty in materials.values():
		count += ceili(float(qty) / 99.0)
	return count

func find_instance(instance_id: String) -> Dictionary:
	for item in gu:
		if item["instance_id"] == instance_id:
			return item
	return {}

func slot_gu(slot: int) -> Dictionary:
	for item in gu:
		if int(item["slot"]) == slot:
			return item
	return {}

func add_material(kind: String, qty: int) -> bool:
	if qty <= 0:
		return false
	var old := int(materials.get(kind, 0))
	var needed := ceili(float(old + qty) / 99.0) - ceili(float(old) / 99.0)
	if occupied_slots() + needed > CAPACITY:
		return false
	materials[kind] = old + qty
	version += 1
	return true

func can_add_gu() -> bool:
	return occupied_slots() < CAPACITY

func entry_keys() -> Array[String]:
	var keys: Array[String] = []
	for item in gu:
		keys.append("gu:" + str(item["instance_id"]))
	for kind in ExpeditionModel.MATERIAL_NAMES:
		for stack in range(ceili(float(int(materials.get(kind, 0))) / 99.0)):
			keys.append("material:%s:%d" % [kind, stack])
	return keys

func display_slots() -> Array[String]:
	var available := entry_keys()
	var result: Array[String] = []
	result.resize(CAPACITY)
	result.fill("")
	if slot_layout.size() == CAPACITY:
		for index in range(CAPACITY):
			var key := slot_layout[index]
			if key in available and key not in result:
				result[index] = key
	else:
		for key in display_order:
			if key in available and key not in result:
				result[result.find("")] = key
	for key in available:
		if key not in result:
			var empty := result.find("")
			if empty >= 0: result[empty] = key
	return result

func ordered_keys() -> Array[String]:
	var result: Array[String] = []
	for key in display_slots():
		if key != "": result.append(key)
	return result

func move_to_slot(source: String, destination: int, expected_version: int) -> bool:
	if expected_version != version or destination < 0 or destination >= CAPACITY:
		return false
	var layout := display_slots()
	var source_index := layout.find(source)
	if source.is_empty() or source_index < 0 or source_index == destination: return false
	var target := layout[destination]
	layout[destination] = source
	layout[source_index] = target
	slot_layout = layout
	display_order = ordered_keys()
	version += 1
	return true

func move_entry(source: String, destination: String) -> bool:
	var keys := ordered_keys()
	if source == destination or source not in keys or destination not in keys:
		return false
	keys.erase(source)
	keys.insert(keys.find(destination), source)
	display_order = keys
	slot_layout.clear()
	version += 1
	return true

func discard_entry(key: String, quantity: int) -> bool:
	if key.begins_with("gu:"):
		var item := find_instance(key.trim_prefix("gu:"))
		if item.is_empty() or int(item["slot"]) >= 0:
			return false
		gu.erase(item)
	elif key.begins_with("material:"):
		var fields := key.split(":")
		if fields.size() != 3 or not ExpeditionModel.MATERIAL_NAMES.has(fields[1]) or not fields[2].is_valid_int() or quantity <= 0:
			return false
		var kind := fields[1]
		var total := int(materials.get(kind, 0))
		var stack_index := int(fields[2])
		var stack_count := mini(99, total - stack_index * 99)
		if stack_index < 0 or stack_count <= 0 or quantity > stack_count:
			return false
		materials[kind] = total - quantity
	else:
		return false
	display_order.erase(key)
	var cell := slot_layout.find(key)
	if cell >= 0: slot_layout[cell] = ""
	version += 1
	recover_rewards()
	return true

func reward_material(kind: String, qty: int) -> void:
	if not add_material(kind, qty):
		pending_materials[kind] = int(pending_materials.get(kind, 0)) + qty
		version += 1

func recover_rewards() -> void:
	for kind in pending_materials.keys():
		var qty := int(pending_materials[kind])
		var old := int(materials.get(kind, 0))
		var space := (CAPACITY - occupied_slots()) * 99 + (99 - old % 99 if old % 99 != 0 else 0)
		var claim := mini(qty, space)
		if claim > 0 and add_material(str(kind), claim):
			pending_materials[kind] = qty - claim
			if int(pending_materials[kind]) == 0:
				pending_materials.erase(kind)

func add_gu(definition_id: String) -> Dictionary:
	if not can_add_gu():
		return {}
	var item := {"instance_id": "gu_%d" % next_id, "definition_id": definition_id, "hunger": 100.0, "slot": -1, "rank": 1, "cultivation": 1}
	next_id += 1
	gu.append(item)
	version += 1
	return item

func feed(request_id: String, instance_id: String, food: String, expected_version: int, catalog: GuCatalog) -> Dictionary:
	var fingerprint := instance_id + ":" + food + ":" + str(expected_version)
	if request_id.is_empty():
		return {"ok": false, "error": "INVALID_REQUEST"}
	if receipts.has(request_id):
		if receipts[request_id]["fingerprint"] != fingerprint:
			return {"ok": false, "error": "REQUEST_CONFLICT"}
		return receipts[request_id].duplicate(true)
	var item := find_instance(instance_id)
	if item.is_empty() or catalog.get_gu(str(item["definition_id"])).is_empty():
		return {"ok": false, "error": "NOT_OWNED"}
	if expected_version != version:
		return {"ok": false, "error": "VERSION_CONFLICT"}
	if food != catalog.get_gu(str(item["definition_id"]))["food"]:
		return {"ok": false, "error": "WRONG_FOOD"}
	if float(item["hunger"]) >= 100.0:
		return {"ok": false, "error": "FULL_HUNGER"}
	if int(materials.get(food, 0)) < 1:
		return {"ok": false, "error": "NO_FOOD"}
	materials[food] = int(materials[food]) - 1
	item["hunger"] = minf(100.0, float(item["hunger"]) + 40.0)
	version += 1
	var receipt := {"ok": true, "fingerprint": fingerprint, "request_id": request_id, "hunger": item["hunger"], "version": version}
	receipts[request_id] = receipt.duplicate(true)
	if receipts.size() > 128:
		receipts.erase(receipts.keys()[0])
	return receipt

func advance_hunger(delta: float) -> void:
	for item in gu:
		if int(item["slot"]) >= 0:
			item["hunger"] = maxf(0.0, float(item["hunger"]) - delta / 300.0)

func to_data() -> Dictionary:
	return {"gu": gu.duplicate(true), "materials": materials.duplicate(true), "version": version, "next_id": next_id, "receipts": receipts.duplicate(true), "pending_materials": pending_materials.duplicate(true), "display_order": ordered_keys(), "slot_layout": display_slots()}

func load_data(data: Dictionary, catalog: GuCatalog) -> bool:
	if not data.get("gu") is Array or not data.get("materials") is Dictionary:
		return false
	if data["gu"].size() > CAPACITY:
		return false
	var checked: Array[Dictionary] = []
	var seen: Dictionary = {}
	var seen_slots: Dictionary = {}
	for raw in data["gu"]:
		if not raw is Dictionary or not raw.has_all(["instance_id", "definition_id", "hunger", "slot", "rank"]):
			return false
		if not valid_number(raw["slot"]) or not valid_number(raw["hunger"]) or not valid_number(raw["rank"]) or not ExpeditionModel._integer(raw["rank"], 1, 3) or not ExpeditionModel._integer(raw.get("cultivation", 1), 1, 5):
			return false
		var id := str(raw["instance_id"])
		var slot := int(raw["slot"])
		if id.is_empty() or seen.has(id) or catalog.get_gu(str(raw["definition_id"])).is_empty() or slot < -1 or slot > 3 or (slot >= 0 and seen_slots.has(slot)):
			return false
		seen[id] = true
		if slot >= 0:
			if str(raw["definition_id"]) != GuCatalog.SLOT_IDS[slot]:
				return false
			seen_slots[slot] = true
		var item: Dictionary = raw.duplicate(true)
		item["hunger"] = clampf(float(raw["hunger"]), 0.0, 100.0)
		checked.append(item)
	var mats: Dictionary = data["materials"].duplicate(true)
	var used := checked.size()
	for amount in mats.values():
		if not valid_number(amount) or int(amount) < 0 or int(amount) > 2970 or float(amount) != floorf(float(amount)):
			return false
		used += ceili(float(amount) / 99.0)
	if used > CAPACITY or seen_slots.size() != 4:
		return false
	var pending = data.get("pending_materials", {})
	if not pending is Dictionary:
		return false
	for key in pending:
		if not ExpeditionModel.MATERIAL_NAMES.has(key) or not valid_number(pending[key]) or float(pending[key]) < 0 or float(pending[key]) > 1000000 or float(pending[key]) != floorf(float(pending[key])):
			return false
	if not valid_number(data.get("version", 0)) or not valid_number(data.get("next_id", 5)):
		return false
	gu = checked
	materials = mats
	pending_materials = pending.duplicate(true)
	display_order.clear()
	var saved_order = data.get("display_order", [])
	if saved_order is Array:
		var available := entry_keys()
		for key in saved_order:
			if key is String and key in available and key not in display_order and display_order.size() < CAPACITY:
				display_order.append(key)
	slot_layout.clear()
	var saved_layout = data.get("slot_layout", [])
	if saved_layout is Array and saved_layout.size() == CAPACITY:
		var layout_valid := true
		for key in saved_layout:
			layout_valid = layout_valid and key is String
		if layout_valid:
			for key in saved_layout: slot_layout.append(str(key))
	# Invalid/deleted cosmetic keys are pruned without discarding progression.
	slot_layout = display_slots()
	version = maxi(0, int(data.get("version", 0)))
	next_id = maxi(5, int(data.get("next_id", 5)))
	# Recompute the next serial to avoid collisions after editing/old profiles.
	for item in gu:
		next_id = maxi(next_id, str(item["instance_id"]).trim_prefix("gu_").to_int() + 1)
	receipts = {}
	var stored = data.get("receipts", {})
	if stored is Dictionary:
		for key in stored:
			var receipt = stored[key]
			if receipt is Dictionary and receipt.get("ok", false) == true and receipt.get("fingerprint") is String and receipts.size() < 128:
				receipts[str(key)] = receipt.duplicate(true)
	return true
