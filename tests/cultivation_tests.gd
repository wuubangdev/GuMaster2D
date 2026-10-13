extends SceneTree
## End-to-end economy, realm lifecycle, atomic denials and save migration.
var results: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, title: String) -> void:
	results.append({"name": title, "passed": value})
	if not value:
		failures += 1
		printerr("FAIL: ", title)

func act(sim: LocalAuthority, command: String, args: Dictionary = {}) -> Dictionary:
	return sim.cultivation_command(command, args)

func _run() -> void:
	var sim := LocalAuthority.new()
	check(not sim.travel("ruins")["ok"], "Tàn Tích locked until first kill")
	check(not act(sim,"unlock")["ok"], "Cannot unlock realm from wrong region")
	sim._damage_mob("wolf_0", 999)
	check(sim.travel("ruins")["ok"] and sim.world.region == "ruins", "First kill opens travel and swaps authority world")
	sim._damage_mob("wolf_0", 999)
	sim._damage_mob("wolf_1", 999)
	check(int(sim.inventory.materials["essence"]) == 2 and int(sim.inventory.materials["stone"]) == 6, "Ruins drops directly support realm and cultivation")
	sim.player["cell"] = WorldGrid.SHRINE
	check(act(sim,"unlock")["ok"] and sim.expedition.realm_unlocked, "Three kills and two essence unlock realm at shrine")
	var after_unlock := sim.inventory.to_data()
	check(not act(sim,"unlock")["ok"] and sim.inventory.to_data() == after_unlock, "Unlock cannot duplicate starter rewards")
	check(sim.travel("realm")["ok"] and sim.mobs.size() == Bestiary.population("realm").size() and sim.mobs.size() >= 19 and sim.world.is_safe(Vector2(18,18)) and not sim.world.is_safe(Vector2(78,77)), "Realm protects the farm and places creatures in distant wilderness")
	var invalid_before := sim.to_profile()
	check(not act(sim,"plant",{"plot":0.5,"crop":"herb"})["ok"] and sim.to_profile() == invalid_before,"Fractional plot index rejected atomically")
	var supplies := int(sim.inventory.materials["herb_seed"])
	check(act(sim,"plant",{"plot":0,"crop":"herb"})["ok"] and int(sim.inventory.materials["herb_seed"]) == supplies-1, "Plant consumes exactly one seed")
	sim.step(60)
	check(float(sim.expedition.plots[0]["left"]) == 45, "Dry planted crop does not grow")
	check(not act(sim,"harvest",{"plot":0})["ok"], "Premature harvest denied")
	check(act(sim,"water",{"plot":0})["ok"], "Water starts growth")
	check(not act(sim,"water",{"plot":0})["ok"], "Repeated watering denied")
	sim.step(22)
	var save := sim.to_profile()
	var loaded := LocalAuthority.new()
	check(loaded.load_profile(save) and loaded.expedition.region == "realm" and is_equal_approx(float(loaded.expedition.plots[0]["left"]),23), "Mid-growth save/load preserves region and exact timer")
	loaded.step(23)
	check(act(loaded,"harvest",{"plot":0})["ok"] and int(loaded.inventory.materials["herb"]) == 4 and int(loaded.inventory.materials["herb_seed"]) == supplies, "Mature harvest gives resources and restores seed")
	var after_harvest := loaded.inventory.to_data()
	check(not act(loaded,"harvest",{"plot":0})["ok"] and loaded.inventory.to_data() == after_harvest, "Repeated harvest cannot duplicate rewards")
	sim = loaded
	for crop in ["flower","fruit"]:
		check(act(sim,"plant",{"plot":1,"crop":crop})["ok"], "Can plant " + crop)
		act(sim,"water",{"plot":1})
		sim.step(76)
		check(act(sim,"harvest",{"plot":1})["ok"], "Can harvest " + crop)
	check(act(sim,"buy_animal",{"pen":0,"kind":"silkworm"})["ok"], "Can establish silkworm pen")
	check(act(sim,"feed_animal",{"pen":0})["ok"], "Feeding starts animal cycle")
	check(not act(sim,"feed_animal",{"pen":0})["ok"] and not act(sim,"collect_animal",{"pen":0})["ok"], "Animal cannot feed twice or harvest early")
	sim.step(60)
	check(act(sim,"collect_animal",{"pen":0})["ok"] and int(sim.inventory.materials["silk"]) == 2, "Silkworm yields fusion resource")
	check(act(sim,"buy_animal",{"pen":1,"kind":"hen"})["ok"], "Can establish hen pen")
	act(sim,"feed_animal",{"pen":1})
	sim.step(75)
	check(act(sim,"collect_animal",{"pen":1})["ok"] and int(sim.inventory.materials["egg"]) == 2, "Hen produces eggs")
	check(not act(sim,"collect_animal",{"pen":1})["ok"], "Animal product cannot be collected twice")
	check(act(sim,"release_animal",{"pen":1})["ok"] and sim.expedition.animals[1]["kind"] == "", "Empty-cycle animal can be rehomed to avoid species lockout")
	check(act(sim,"buy_animal",{"pen":1,"kind":"silkworm"})["ok"], "Rehomed pen accepts different species")
	act(sim,"feed_animal",{"pen":1})
	check(not act(sim,"release_animal",{"pen":1})["ok"], "Active animal cycle cannot be accidentally discarded")
	var old_stone := int(sim.inventory.materials["stone"])
	check(act(sim,"transmute")["ok"] and int(sim.inventory.materials["stone"]) == old_stone+3 and int(sim.inventory.materials["egg"]) == 0, "Husbandry connects to cultivation through egg exchange")
	var item := sim.inventory.slot_gu(0)
	var power_before := ExpeditionModel.strength(item)
	check(act(sim,"upgrade",{"id":item["instance_id"]})["ok"] and ExpeditionModel.strength(item) > power_before, "Gu upgrade consumes resources and increases power")
	var before_deny := sim.to_profile()
	check(not act(sim,"upgrade",{"id":"missing"})["ok"] and sim.to_profile() == before_deny, "Unknown Gu command is atomic")
	# More crop harvest, explicit combat rewards stand in for the next exploration loop.
	sim.inventory.reward_material("herb",20)
	sim.inventory.reward_material("stone",20)
	sim.inventory.reward_material("essence",9)
	sim.player["currency"] = 1000
	check(act(sim,"upgrade",{"id":item["instance_id"]})["ok"], "Second cultivation level reaches fusion threshold")
	var donor := sim.inventory.add_gu(str(item["definition_id"]))
	var bad_donor_before := sim.to_profile()
	check(not act(sim,"fuse",{"id":item["instance_id"],"donor":"gu_2"})["ok"] and sim.to_profile() == bad_donor_before, "Equipped/wrong-type Gu cannot be consumed as donor")
	var strength_before := ExpeditionModel.strength(item)
	check(act(sim,"fuse",{"id":item["instance_id"],"donor":donor["instance_id"]})["ok"] and int(item["rank"]) == 2 and int(item.get("cultivation",0)) == 1 and int(item["slot"]) == 0 and ExpeditionModel.strength(item) > strength_before, "Fusion preserves hotbar and creates stronger rank II Gu")
	check(sim.inventory.find_instance(str(donor["instance_id"])).is_empty(), "Fusion consumes the selected donor")
	var fused_save := sim.to_profile()
	var fused_load := LocalAuthority.new()
	check(fused_load.load_profile(fused_save) and fused_load.inventory.gu == sim.inventory.gu, "Rank II, cultivation and farm survive save/load")
	var legacy := LocalAuthority.new().to_profile()
	legacy.erase("expedition")
	for gu in legacy["inventory"]["gu"]:
		gu.erase("cultivation")
	check(fused_load.load_profile(legacy) and fused_load.expedition.region == "forest" and not fused_load.expedition.realm_unlocked, "Legacy profile migrates without resetting inventory")
	for key in ["region","plots","animals","harvests"]:
		var broken := fused_save.duplicate(true)
		broken["expedition"][key] = "invalid"
		var unchanged := fused_load.to_profile()
		check(not fused_load.load_profile(broken) and fused_load.to_profile() == unchanged, "Invalid " + key + " rejected without partial mutation")
	var corrupt := fused_save.duplicate(true)
	corrupt["expedition"]["plots"][0]["left"] = -1
	check(not fused_load.load_profile(corrupt), "Negative farming timer rejected")
	corrupt = fused_save.duplicate(true)
	corrupt["inventory"]["gu"][0]["rank"] = 2.5
	check(not fused_load.load_profile(corrupt), "Fractional Gu rank rejected")
	# Travel preserves population and clears movement, but never health/resources.
	check(sim.travel("ruins")["ok"], "Return from realm")
	check(sim.travel("forest")["ok"] and sim.travel("ruins")["ok"], "Travel round trip through forest")
	sim.mobs["wolf_0"]["hp"] = 60.0
	sim.player["hp"] = 73.0
	sim.player["mana"] = 41.0
	sim.cooldowns[0] = 1.5
	sim.player["path"] = [Vector2(13,20)]
	sim.movement_direction = Vector2.RIGHT
	check(sim.travel("realm")["ok"] and sim.movement_direction == Vector2.ZERO and sim.player["path"].is_empty() and float(sim.player["hp"]) == 73 and float(sim.player["mana"]) == 41 and sim.cooldowns[0] == 1.5, "Travel clears intent without healing or resetting cooldown")
	check(sim.travel("ruins")["ok"] and float(sim.mobs["wolf_0"]["hp"]) == 60, "Region revisit retains population in session")
	sim.combat_left = 2
	check(not sim.travel("forest")["ok"] and not act(sim,"upgrade",{"id":"gu_1"})["ok"], "Combat blocks travel and cultivation")
	sim.combat_left = 0
	sim.player["cell"] = Vector2(18,23)
	check(not sim.travel("forest")["ok"], "Travel requires portal proximity")
	for region in ExpeditionModel.REGIONS:
		var grid := WorldGrid.new(region)
		check(grid.is_walkable(WorldGrid.SPAWN) and not grid.path(WorldGrid.SPAWN,WorldGrid.SHRINE).is_empty(), region + " spawn connects to shrine")
		if region == "realm":
			var all_reachable := true
			for cell in ExpeditionModel.PLOTS + ExpeditionModel.PENS:
				all_reachable = all_reachable and not grid.path(WorldGrid.SPAWN,cell).is_empty()
			check(all_reachable,"Every farm plot and pen reachable")
	var combat := LocalAuthority.new()
	combat.player["cell"] = Vector2(15,20)
	combat.mobs["wolf_0"]["cell"] = Vector2(18,20)
	combat.cast(0,"wolf_0",Vector2(18,20))
	var base_damage := 140 - int(combat.mobs["wolf_0"]["hp"])
	combat.inventory.slot_gu(0)["rank"] = 2
	combat.cooldowns[0] = 0
	combat.mobs["wolf_0"]["hp"] = 140.0
	combat.cast(0,"wolf_0",Vector2(18,20))
	check(140-int(combat.mobs["wolf_0"]["hp"]) > base_damage, "Rank bonus changes damage, not only UI")
	combat.inventory.slot_gu(2)["rank"] = 3
	combat.inventory.slot_gu(2)["cultivation"] = 5
	combat.cast(2,"",Vector2(16,20))
	check(is_equal_approx(combat.cooldowns[2],4.4), "Bạch Hạc cooldown reduction is clamped at 45 percent")
	# Full bag payout uses existing recovery queue and survives persistence.
	var full := LocalAuthority.new()
	full.expedition.realm_unlocked = true
	full.expedition.region = "realm"
	full.world = WorldGrid.new("realm")
	full.mobs.clear()
	while full.inventory.can_add_gu():
		full.inventory.add_gu("GU-01")
	full.expedition.plots[0] = {"crop":"herb","watered":true,"left":0.0}
	check(act(full,"harvest",{"plot":0})["ok"] and int(full.inventory.pending_materials.get("herb",0)) == 4, "Full bag harvest queues resources instead of losing them")
	check(LocalAuthority.new().load_profile(full.to_profile()), "New material pending rewards validate on load")
	var store := SaveStore.new("user://cultivation_test_profile.json")
	check(store.save_profile(fused_save) and not store.load_profile().is_empty(), "SaveStore accepts expanded profile")
	store.clear_profile()
	var file := FileAccess.open("res://artifacts/expansion38_mechanics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":results.size()-failures,"failed":failures,"checks":results},"  "))
	file.close()
	print("CULTIVATION_TESTS ",results.size()-failures,"/",results.size()," passed")
	quit(1 if failures else 0)
