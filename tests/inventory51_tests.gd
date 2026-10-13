extends SceneTree
var results: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	results.append({"name": name, "passed": condition})
	if not condition: printerr("FAIL: ", name)

func assets(sim: LocalAuthority) -> Dictionary:
	return {"inventory": sim.inventory.to_data(), "currency": sim.player["currency"]}

func same_amounts(left: Dictionary, right: Dictionary) -> bool:
	# JSON numbers reload as floats; compare quantities, including their keys.
	if left.size() != right.size(): return false
	for key in left:
		if not right.has(key) or left[key] != right[key]: return false
	return true

func fixture() -> LocalAuthority:
	var sim := LocalAuthority.new()
	sim.player["cell"] = WorldGrid.SPAWN
	sim.inventory.materials = {"hide": 8, "herb": 4, "stone": 3, "pollen": 6, "egg": 4}
	sim.player["currency"] = 100
	return sim

func _run() -> void:
	check(ItemCrafting.all().size() == 3 and ItemCrafting.for_material("egg") == ["transmute_eggs"], "Catalog contains three valid recipes and item-specific queries")
	var sim := fixture()
	var inv := sim.inventory
	var original_materials := inv.materials.duplicate(true)
	var original_gu := inv.gu.duplicate(true)
	check(inv.move_to_slot("gu:gu_1", 29, inv.version), "An item moves into an empty physical slot")
	check(inv.display_slots()[29] == "gu:gu_1" and inv.display_slots()[0] == "" and inv.gu == original_gu and inv.materials == original_materials, "Empty positions are retained and drag never changes item amounts")
	var saved := inv.to_data()
	var restored := InventoryModel.new()
	check(restored.load_data(saved, sim.catalog) and restored.display_slots() == inv.display_slots(), "Empty-slot layout survives save roundtrip")
	var destination := inv.display_slots().find("gu:gu_2")
	check(inv.move_to_slot("gu:gu_1", destination, inv.version) and inv.display_slots()[29] == "gu:gu_2", "Dropping onto an occupied slot swaps both items")
	var stable := inv.to_data()
	check(not inv.move_to_slot("gu:gu_1", 20, inv.version - 1) and inv.to_data() == stable, "Stale drags are rejected without changing layout")
	check(not inv.move_to_slot("gu:unknown", 2, inv.version) and not inv.move_to_slot("gu:gu_1", 30, inv.version) and not inv.move_to_slot("gu:gu_1", -1, inv.version), "Invalid drag sources and out-of-bounds slots are rejected")
	check(inv.add_material("seal", 1) and inv.display_slots()[0] == "material:seal:0", "New loot fills a free slot without compressing arranged items")
	var legacy := inv.to_data()
	legacy.erase("slot_layout")
	check(restored.load_data(legacy, sim.catalog) and restored.ordered_keys() == inv.ordered_keys(), "Old order-only profiles migrate while preserving item order")
	legacy["slot_layout"] = [false, "broken"]
	check(restored.load_data(legacy, sim.catalog) and restored.gu == inv.gu and restored.materials == inv.materials, "Malformed cosmetic layout falls back without losing progression")
	check(not inv.discard_entry("gu:gu_1", 1), "Equipped Cổ remains protected")
	var extra := inv.add_gu("GU-01")
	check(inv.discard_entry("gu:" + str(extra["instance_id"]), 1) and inv.find_instance(str(extra["instance_id"])).is_empty(), "Reserve Cổ can be discarded")
	sim = fixture()
	var version := sim.inventory.version
	var receipt := sim.craft_item("craft-first", "press_seal", 2, version)
	check(receipt.get("ok", false) and sim.inventory.materials["hide"] == 4 and sim.inventory.materials["herb"] == 2 and sim.inventory.materials["stone"] == 1 and sim.inventory.materials["seal"] == 4 and sim.player["currency"] == 80, "Craft batch consumes exact cost and produces exact output")
	var after := assets(sim)
	for retry in range(5): check(sim.craft_item("craft-first", "press_seal", 2, version) == receipt and assets(sim) == after, "Craft retry %d is idempotent" % retry)
	check(sim.drain_events().filter(func(event: Dictionary): return event["kind"] == "item_crafted").size() == 1, "Craft retry emits one persistent reward event")
	check(sim.craft_item("craft-first", "press_seal", 1, version).get("error") == "REQUEST_CONFLICT" and assets(sim) == after, "A receipt cannot be reused for a different payload")
	var loaded := LocalAuthority.new()
	check(loaded.load_profile(sim.to_profile()), "Crafted profile loads")
	var loaded_before := assets(loaded)
	check(loaded.craft_item("craft-first", "press_seal", 2, version) == receipt and assets(loaded) == loaded_before, "Craft receipt survives reload and prevents double consumption")
	sim.inventory.move_to_slot("gu:gu_1", 29, sim.inventory.version)
	var store := SaveStore.new("user://inventory51_profile_test.json")
	store.clear_profile()
	check(store.save_profile(sim.to_profile()), "Inventory layout and craft receipt are written through the real SaveStore")
	var disk_loaded := LocalAuthority.new()
	var disk_profile := store.load_profile()
	var profile_ok := disk_loaded.load_profile(disk_profile)
	check(profile_ok and disk_loaded.inventory.display_slots() == sim.inventory.display_slots() and same_amounts(disk_loaded.inventory.materials, sim.inventory.materials) and disk_loaded.player["currency"] == sim.player["currency"], "Disk profile restores physical gaps, crafted materials, and currency")
	var disk_before := assets(disk_loaded)
	var replay := disk_loaded.craft_item("craft-first", "press_seal", 2, version)
	check(replay.get("ok", false) and replay.get("fingerprint") == receipt["fingerprint"] and replay.get("version") == receipt["version"] and same_amounts(replay.get("output", {}), receipt["output"]) and replay == disk_loaded.inventory.receipts["craft-first"] and assets(disk_loaded) == disk_before, "Craft retry after disk reload cannot consume inputs or award outputs twice")
	store.clear_profile()
	sim = fixture()
	for value in [0, -1, 100, 1.5, NAN, INF, "2"]:
		var before := assets(sim)
		check(not sim.craft_item("bad-" + str(value), "press_seal", value, sim.inventory.version).get("ok", false) and assets(sim) == before, "Invalid craft batch %s consumes nothing" % str(value))
	for failure in ["version", "materials", "combat", "dead", "location"]:
		sim = fixture()
		var expected := sim.inventory.version
		var code := ""
		match failure:
			"version": expected -= 1; code = "VERSION_CONFLICT"
			"materials": sim.inventory.materials["hide"] = 0; code = "NEED_MATERIALS"
			"combat": sim.combat_left = 1; code = "IN_COMBAT"
			"dead": sim.player["dead"] = true; code = "DEAD"
			"location": sim.player["cell"] = Vector2(100, 100); code = "AT_CAMP"
		var before := assets(sim)
		check(sim.craft_item("blocked", "press_seal", 1, expected).get("error") == code and assets(sim) == before, failure + " rejects craft before consuming assets")
	sim = fixture()
	sim.inventory.materials = {"egg": 99, "meat": 99, "fruit": 99, "nectar": 99}
	for i in range(22): sim.inventory.add_gu("GU-01")
	var full_before := assets(sim)
	check(sim.inventory.occupied_slots() == 30 and sim.craft_item("full", "transmute_eggs", 1, sim.inventory.version).get("error") == "BAG_FULL" and assets(sim) == full_before, "Output overflow rejects craft atomically")
	sim.inventory.materials = {"egg": 2, "meat": 99, "fruit": 99, "nectar": 99}
	check(sim.craft_item("replaces-stack", "transmute_eggs", 1, sim.inventory.version).get("ok", false) and sim.inventory.occupied_slots() == 30, "Craft succeeds in a full bag when consumed input frees the output slot")
	sim = fixture()
	sim.inventory.materials = {"egg": 198}
	check(sim.craft_item("max-batch", "transmute_eggs", 99, sim.inventory.version).get("ok", false) and sim.inventory.materials["egg"] == 0 and sim.inventory.materials["stone"] == 297, "Maximum batch preserves all quantities")
	var failed := results.filter(func(result: Dictionary): return not result["passed"]).size()
	FileAccess.open("res://artifacts/inventory51_tests_%s.json" % OS.get_name().to_lower(), FileAccess.WRITE).store_string(JSON.stringify({"passed": results.size() - failed, "failed": failed, "results": results}, "  "))
	print("INVENTORY51_TESTS ", results.size() - failed, "/", results.size())
	quit(1 if failed else 0)
