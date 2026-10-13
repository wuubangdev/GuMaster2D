extends SceneTree
var checks: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	checks.append({"name": name, "passed": condition})
	if not condition: printerr("FAIL: ", name)

func fixture() -> LocalAuthority:
	var sim := LocalAuthority.new()
	sim.inventory.materials = {"herb": 30, "stone": 30, "silk": 10, "essence": 15}
	sim.player["currency"] = 1000
	return sim

func _run() -> void:
	var sim := fixture()
	check(GuCultivationRules.stats(sim, sim.inventory.slot_gu(0))["damage"] == 41 and GuCultivationRules.stats(sim, sim.inventory.slot_gu(1))["shield"] == 75.0 and GuCultivationRules.stats(sim, sim.inventory.slot_gu(2))["cooldown"] == 8.0 and GuCultivationRules.stats(sim, sim.inventory.slot_gu(3))["damage"] == 26, "Level-one reference values preserve existing combat balance")
	var before := sim.to_profile()
	var probe := GuCultivationRules.preview(sim, "upgrade", "gu_1")
	check(probe["ok"] and probe["after"]["cultivation"] == 2 and probe["cost"] == {"herb": 2, "stone": 1, "silver": 25}, "Upgrade preview shows actual next level and exact costs")
	check(sim.to_profile() == before and sim.events.is_empty(), "All progression previews are pure and emit no gameplay events")
	var version := sim.inventory.version
	check(sim.cultivation_command("upgrade", {"id": "gu_1", "version": version})["ok"] and sim.inventory.slot_gu(0)["cultivation"] == 2 and sim.inventory.materials["herb"] == 28 and sim.inventory.materials["stone"] == 29 and sim.player["currency"] == 975, "One upgrade commits exactly one level and one set of costs")
	var after := sim.to_profile()
	check(sim.cultivation_command("upgrade", {"id": "gu_1", "version": version}).get("error") == "VERSION_CONFLICT" and sim.to_profile() == after, "Repeated stale UI request cannot upgrade or charge twice")
	check(sim.cultivation_command("upgrade", {"id": "gu_1", "version": 1.5}).get("error") == "VERSION_CONFLICT" and sim.to_profile() == after, "Fractional version cannot bypass snapshot validation")
	for code in ["DEAD", "IN_COMBAT", "AT_CAMP", "NEED_MATERIALS", "MAX_CULTIVATION"]:
		sim = fixture()
		match code:
			"DEAD": sim.player["dead"] = true
			"IN_COMBAT": sim.capture = {"target": "wolf_0"}
			"AT_CAMP": sim.player["cell"] = Vector2(100, 100)
			"NEED_MATERIALS": sim.inventory.materials["herb"] = 1
			"MAX_CULTIVATION": sim.inventory.slot_gu(0)["cultivation"] = 5
		var unchanged := sim.to_profile()
		check(GuCultivationRules.preview(sim, "upgrade", "gu_1").get("error") == code and sim.cultivation_command("upgrade", {"id": "gu_1"}).get("error") == code and sim.to_profile() == unchanged, code + " agrees between preview and command without asset changes")
	sim = fixture()
	sim.inventory.slot_gu(0)["cultivation"] = 3
	var one := sim.inventory.add_gu("GU-01")
	var two := sim.inventory.add_gu("GU-01")
	one["cultivation"] = 4
	check(GuCultivationRules.donors(sim, sim.inventory.slot_gu(0)).size() == 2 and GuCultivationRules.preview(sim, "fuse", "gu_1").get("error") == "NEED_DONOR", "Eligible donors are shown but a donor must be selected explicitly")
	for id in ["gu_1", "gu_2", "missing"]:
		var unchanged := sim.to_profile()
		check(sim.cultivation_command("fuse", {"id": "gu_1", "donor": id}).get("error") == "NEED_DONOR" and sim.to_profile() == unchanged, "Unsafe donor " + id + " cannot be consumed")
	probe = GuCultivationRules.preview(sim, "fuse", "gu_1", str(one["instance_id"]))
	check(probe["ok"] and probe["after"]["rank"] == 2 and probe["after"]["cultivation"] == 1 and probe["after"]["hunger"] == 100.0, "Fusion preview shows rank, level reset and restored hunger")
	version = sim.inventory.version
	var args := {"id": "gu_1", "donor": str(one["instance_id"]), "version": version}
	check(sim.cultivation_command("fuse", args)["ok"] and sim.inventory.find_instance(str(one["instance_id"])).is_empty() and not sim.inventory.find_instance(str(two["instance_id"])).is_empty() and sim.inventory.slot_gu(0)["rank"] == 2 and sim.inventory.slot_gu(0)["cultivation"] == 1 and sim.inventory.materials["silk"] == 8 and sim.inventory.materials["essence"] == 12 and sim.player["currency"] == 900, "Fusion consumes only the chosen donor and exact materials, while preserving the main skill slot")
	after = sim.to_profile()
	check(sim.cultivation_command("fuse", args).get("error") == "VERSION_CONFLICT" and sim.to_profile() == after, "Replaying a confirmed fusion does not consume another donor")
	check(GuCultivationRules.preview(sim, "fuse", "gu_1", str(two["instance_id"])).get("error") == "NEED_CULTIVATION", "Rank II requires level five before rank III")
	sim.inventory.slot_gu(0)["rank"] = 3
	probe = GuCultivationRules.preview(sim, "fuse", "gu_1", str(two["instance_id"]))
	check(probe.get("error") == "MAX_RANK" and probe["cost"].is_empty() and probe["after"] == probe["item"], "Maximum rank does not promise a fictitious next rank or costs")
	var store := SaveStore.new("user://gu52_progression_test.json")
	store.clear_profile()
	check(store.save_profile(sim.to_profile()), "Gu progression writes through the real SaveStore")
	var restored := LocalAuthority.new()
	check(restored.load_profile(store.load_profile()) and restored.inventory.slot_gu(0)["rank"] == 3 and restored.inventory.find_instance(str(one["instance_id"])).is_empty() and not restored.inventory.find_instance(str(two["instance_id"])).is_empty() and restored.player["currency"] == 900, "Disk reload preserves the upgraded main Gu, chosen donor consumption and currency")
	store.clear_profile()
	# Compare the displayed values against actual casts at all ranks and levels,
	# including the hunger penalty and the shield/dash caps.
	sim = LocalAuthority.new()
	sim.player["cell"] = Vector2(15, 20)
	var effect_matches := true
	var cooldown_matches := true
	var cap_matches := true
	var samples := 0
	for slot in range(4):
		for rank_value in range(1, 4):
			for level in range(1, 6):
				for hunger in [10.0, 100.0]:
					var item := sim.inventory.slot_gu(slot)
					item.merge({"rank": rank_value, "cultivation": level, "hunger": hunger}, true)
					var stats := GuCultivationRules.stats(sim, item)
					sim.player["mana"] = 100.0
					sim.cooldowns.fill(0.0)
					sim.mobs["wolf_0"].merge({"cell": Vector2(18, 20), "hp": 100000.0, "max_hp": 100000.0, "dead": false}, true)
					var result := sim.cast(slot, "wolf_0", Vector2(16, 20) if slot == 2 else Vector2(18, 20))
					effect_matches = effect_matches and result.get("ok", false)
					if slot in [0, 3]: effect_matches = effect_matches and 100000.0 - float(sim.mobs["wolf_0"]["hp"]) == stats["damage"]
					if slot == 1: effect_matches = effect_matches and sim.player["shield"] == stats["shield"]
					cooldown_matches = cooldown_matches and is_equal_approx(sim.cooldowns[slot], stats["cooldown"])
					cap_matches = cap_matches and float(stats["shield"]) <= float(sim.player["max_hp"]) * .4 and (slot != 2 or float(stats["cooldown"]) >= 4.4)
					sim.player["cell"] = Vector2(15, 20)
					samples += 1
	check(effect_matches, "Displayed damage and shield agree with 120 real skill casts")
	check(cooldown_matches, "Displayed cooldowns agree with every real cast")
	check(cap_matches, "Preview respects the shield health cap and dash cooldown floor")
	var failed := checks.filter(func(result: Dictionary): return not result["passed"]).size()
	FileAccess.open("res://artifacts/gu52_tests_%s.json" % OS.get_name().to_lower(), FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "real_cast_samples": samples}, "  "))
	print("GU52_TESTS ", checks.size() - failed, "/", checks.size(), " real casts=", samples)
	quit(1 if failed else 0)
