extends SceneTree
var checks: Array[Dictionary] = []
var failures := 0
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	run.call_deferred()
func check(value: bool, title: String) -> void:
	checks.append({"name":title,"passed":value})
	if not value:
		failures += 1
		printerr("FAIL: ",title)
func at(sim: LocalAuthority, npc: String) -> void:
	sim.player["cell"] = QuestCatalog.cell(npc) + Vector2(0,.7)
	sim.combat_left = 0
func command(sim: LocalAuthority, verb: String, npc: String, quest: String) -> bool:
	return bool(sim.quest_command(verb,npc,quest)["ok"])
func run() -> void:
	var sim := LocalAuthority.new(74021,true)
	check(QuestCatalog.data()["npcs"].size() == 7 and QuestCatalog.quests().size() == 18,"Catalog has seven NPCs and eighteen authored quests")
	for id in QuestCatalog.data()["npcs"]:
		check(GuCharacterAppearance.validate(QuestCatalog.npc(id)["appearance"]),"Valid NPC appearance: "+id)
	for region in ExpeditionModel.REGIONS:
		var world := WorldGrid.new(region)
		check(not world.path(WorldGrid.SPAWN,WorldGrid.SHRINE).is_empty(),region+" portal route survives environment additions")
		for npc in QuestCatalog.npcs(region):
			check(not world.path(WorldGrid.SPAWN,QuestCatalog.cell(npc)).is_empty() and world.is_safe(QuestCatalog.cell(npc)),npc+" is reachable and protected during dialogue")
		for landmark in world.landmarks:
			check(not world.is_walkable(landmark["cell"]),"Landmark footprint blocks movement: "+str(landmark["kind"]))
		if region == "realm":
			check(not world.is_walkable(Vector2(6,16)),"Pond has collision")
			for point in ExpeditionModel.PLOTS + ExpeditionModel.PENS:
				check(not world.path(WorldGrid.SPAWN,point).is_empty(),"Farm interaction remains reachable: "+str(point))
	check(sim.quests.npc_marker("lam_an",sim) == "!","Starter NPC offers a visible quest")
	check(not sim.talk_to("missing")["ok"] and not sim.talk_to("moc_mien")["ok"],"Unknown/cross-region NPC talk is denied")
	check(not sim.talk_to("yen_chi")["ok"],"Distant NPC cannot open dialogue")
	at(sim,"lam_an")
	check(sim.talk_to("lam_an")["ok"],"Nearby NPC talk accepted")
	check(not command(sim,"accept","lam_an","path_guard"),"Prerequisite quest cannot be skipped")
	check(command(sim,"accept","lam_an","arrival"),"Accept starter quest from correct giver")
	var accepted := sim.to_profile()
	check(not command(sim,"accept","lam_an","arrival") and sim.to_profile() == accepted,"Repeated accept is atomic")
	check(not command(sim,"claim","lam_an","arrival"),"Incomplete quest cannot pay reward")
	at(sim,"yen_chi")
	check(sim.talk_to("yen_chi")["ok"] and sim.quests.ready("arrival",sim),"Talking to the named NPC completes the first objective")
	check(not command(sim,"claim","yen_chi","arrival"),"Wrong turn-in NPC cannot issue reward")
	at(sim,"lam_an")
	var silver := int(sim.player["currency"])
	check(sim.quests.npc_marker("lam_an",sim) == "?","Ready quest has turn-in marker")
	check(command(sim,"claim","lam_an","arrival") and int(sim.player["currency"]) == silver+35,"Turn-in grants exact authored reward")
	var claimed := sim.to_profile()
	check(not command(sim,"claim","lam_an","arrival") and sim.to_profile() == claimed,"Turn-in cannot duplicate reward")
	check(command(sim,"accept","lam_an","path_guard"),"Starter handoff opens combat quest")
	at(sim,"yen_chi")
	check(command(sim,"accept","yen_chi","first_feed"),"Parallel care quest opens independently")
	check(sim.feed_gu("quest-test-food","gu_1","meat",sim.inventory.version)["ok"],"Normal inventory feeding progresses care quest")
	check(command(sim,"claim","yen_chi","first_feed"),"Care quest can be turned in")
	sim._damage_mob("wolf_0",999)
	sim._damage_mob("wolf_1",999)
	at(sim,"lam_an")
	check(command(sim,"claim","lam_an","path_guard"),"Actual kill progression completes the combat quest")
	sim.player["cell"] = WorldGrid.SPAWN
	check(sim.travel("ruins")["ok"],"Quest chain reaches ruins through existing travel")
	at(sim,"tham_nghi")
	check(command(sim,"accept","tham_nghi","lost_seal"),"Archaeologist gives realm quest")
	sim._damage_mob("wolf_0",999)
	sim._damage_mob("wolf_1",999)
	sim.player["cell"] = WorldGrid.SHRINE
	check(sim.cultivation_command("unlock")["ok"],"Existing unlock command satisfies quest objective")
	check(sim.travel("realm")["ok"],"Travel enters quest destination")
	at(sim,"moc_mien")
	check(sim.quests.npc_marker("moc_mien",sim) == "?" and command(sim,"claim","moc_mien","lost_seal"),"Realm quest turns in at destination NPC, without backtracking")
	check(command(sim,"accept","moc_mien","first_harvest"),"Gardener offers first crop quest")
	sim.cultivation_command("plant",{"plot":0,"crop":"herb"})
	sim.cultivation_command("water",{"plot":0})
	sim.step(45)
	check(sim.cultivation_command("harvest",{"plot":0})["ok"] and sim.quests.ready("first_harvest",sim),"Harvest completion comes from real farm state")
	check(command(sim,"claim","moc_mien","first_harvest"),"First harvest pays through NPC")
	check(command(sim,"accept","moc_mien","silk_and_gu"),"Farm quest opens livestock/cultivation loop")
	sim.cultivation_command("buy_animal",{"pen":0,"kind":"silkworm"})
	sim.cultivation_command("feed_animal",{"pen":0})
	sim.step(60)
	sim.cultivation_command("collect_animal",{"pen":0})
	check(sim.quests.value("silk_and_gu",sim) == 1,"Animal harvest is counted separately from crops")
	sim.inventory.reward_material("egg",2)
	sim.cultivation_command("transmute")
	check(sim.quests.value("silk_and_gu",sim) == 1,"Egg exchange cannot impersonate a Gu upgrade")
	check(sim.cultivation_command("upgrade",{"id":"gu_1"})["ok"] and sim.quests.ready("silk_and_gu",sim),"Real Gu upgrade finishes the cultivation objective")
	check(command(sim,"claim","moc_mien","silk_and_gu") and sim.quests.claimed.size() == 6,"All six quests form a complete playable chain")
	var loaded := LocalAuthority.new()
	check(loaded.load_profile(sim.to_profile()) and loaded.quests.to_data() == sim.quests.to_data(),"Quest completion/counters survive save-load")
	var legacy := LocalAuthority.new().to_profile()
	legacy.erase("quests")
	legacy["progress"]["kills"] = 3
	legacy["progress"]["feeds"] = 1
	check(loaded.load_profile(legacy) and loaded.quests.accepted.is_empty() and loaded.quests.value("path_guard",loaded) == 2,"Old profiles retain progress and receive default journal")
	for kind in ["duplicate","unknown","claimed_without_accept","prerequisite","counter","tracked"]:
		var broken := legacy.duplicate(true)
		broken["quests"] = QuestJournal.new().to_data()
		match kind:
			"duplicate": broken["quests"]["accepted"] = ["arrival","arrival"]
			"unknown": broken["quests"]["accepted"] = ["not_a_quest"]
			"claimed_without_accept": broken["quests"]["claimed"] = ["arrival"]
			"prerequisite": broken["quests"]["accepted"] = ["lost_seal"]
			"counter": broken["quests"]["counters"] = {"animal_products":-1}
			"tracked": broken["quests"]["tracked"] = "arrival"
		var before := loaded.to_profile()
		check(not loaded.load_profile(broken) and loaded.to_profile() == before,"Corrupt quest state rejects atomically: "+kind)
	at(loaded,"lam_an")
	loaded.combat_left = 1
	check(not loaded.talk_to("lam_an")["ok"] and not command(loaded,"accept","lam_an","arrival"),"Combat blocks dialogue and quest commands")
	loaded.combat_left = 0
	loaded.player["dead"] = true
	check(not loaded.talk_to("lam_an")["ok"],"Dead players cannot talk")
	var full := LocalAuthority.new()
	at(full,"lam_an")
	command(full,"accept","lam_an","arrival")
	full.quests.counters["talk_yen_chi"] = 1
	while full.inventory.can_add_gu(): full.inventory.add_gu("GU-01")
	full.inventory.materials["meat"] = 99
	check(command(full,"claim","lam_an","arrival") and int(full.inventory.pending_materials.get("meat",0)) == 2,"Full bag queues quest materials while marking reward claimed once")
	var store := SaveStore.new("user://quests39_test.json")
	check(store.save_profile(full.to_profile()) and not store.load_profile().is_empty(),"SaveStore validates quest payouts and queued materials")
	store.clear_profile()
	var file := FileAccess.open("res://artifacts/quests39_mechanics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks},"  "))
	file.close()
	print("QUEST_TESTS ",checks.size()-failures,"/",checks.size()," passed")
	quit(1 if failures else 0)
