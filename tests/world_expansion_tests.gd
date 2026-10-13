extends SceneTree
## Deterministic authority fixtures exercise actual commands; no player save access.
var checks: Array[Dictionary] = []
var failures := 0
var metrics := {}
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures += 1; printerr("FAIL: ",label)
func region(sim: LocalAuthority, id: String) -> void:
	if sim.expedition.region == id: return
	sim.player["cell"] = WorldGrid.SPAWN
	sim.combat_left = 0
	check(sim.travel(id)["ok"],"Travel command to "+id)
func npc(sim: LocalAuthority, id: String) -> void:
	region(sim,QuestCatalog.npc(id)["region"])
	sim.player["cell"] = QuestCatalog.cell(id)+Vector2(0,.7)
	sim.combat_left = 0
func deny(sim: LocalAuthority, verb: String, args: Dictionary, error: String) -> void:
	var before := sim.to_profile()
	var result := sim.journey_command(verb,args)
	check(not result["ok"] and result.get("error","") == error and sim.to_profile() == before,"Atomic "+verb+" denial: "+error)
func run() -> void:
	var start := Time.get_ticks_msec()
	geography()
	metrics["geography_ms"] = Time.get_ticks_msec()-start
	var sim := LocalAuthority.new(74021,true)
	deny(sim,"waygate",{"id":"f_east"},"NEED_WAYGATES")
	deny(sim,"medicine",{},"NEED_MEDICINE")
	deny(sim,"irrigate",{},"NEED_IRRIGATION")
	quest_chain(sim)
	utilities(sim)
	gathering()
	ai()
	ai_geometry()
	delivery_atomicity()
	persistence(sim)
	var idle := LocalAuthority.new()
	start = Time.get_ticks_msec()
	for i in range(600): idle.step(1.0/60)
	metrics["idle_600_steps_ms"] = Time.get_ticks_msec()-start
	check(idle.player["hp"] == idle.player["max_hp"],"Distant wildlife cannot harm spawn")
	var file := FileAccess.open("res://artifacts/world45_mechanics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"metrics":metrics},"  "))
	print("WORLD45_WORLD_REGRESSION ",checks.size()-failures,"/",checks.size()," ",metrics)
	quit(1 if failures else 0)
func geography() -> void:
	var camp_count := 0
	var total_mobs := 0
	var types := {}
	for id in ExpeditionModel.REGIONS:
		var world := WorldGrid.new(id)
		check(world.nav.region.size == Vector2i(256,256),id+" 256 by 256 collision grid")
		var population := LocalAuthority.new()._region_population(id)
		total_mobs += population.size()
		for site in WorldContent.camps(id)+WorldContent.waypoints(id)+WorldContent.resources(id):
			var at := WorldContent.cell(site)
			check(world.is_walkable(at) and not world.path(WorldGrid.SPAWN,at).is_empty(),"Reachable "+str(site["id"]))
		for mob in population.values():
			if not mob.get("wild",false): continue
			types[mob["species"]] = true
			check(world.is_walkable(mob["spawn"]) and not world.is_safe(mob["spawn"]) and not world.path(WorldGrid.SPAWN,mob["spawn"]).is_empty(),"Reachable hostile spawn "+str(mob["id"]))
		camp_count += WorldContent.camps(id).size()
		var water := 0
		var bridge := 0
		for point in world.surfaces:
			if world.surfaces[point] == "water":
				water += 1
				if world.is_walkable(point): check(false,"Water collision "+id+str(point))
			if world.surfaces[point] == "stone" and WorldContent.water(id,Vector2(point)) and world.is_walkable(point): bridge += 1
		check(water > 20 and bridge > 0,id+" waterways have collision and walkable bridges")
		var copy := WorldGrid.new(id)
		world._set_block(Vector2i(WorldGrid.SPAWN))
		check(not world.is_walkable(WorldGrid.SPAWN) and copy.is_walkable(WorldGrid.SPAWN),"Grid instances have independent collision dictionaries "+id)
	check(camp_count == 64 and total_mobs == 351 and types.size() == 8,"64 camps, 351 creatures and eight species across three maps")
	var category := {"main":0,"side":0}
	for quest in QuestCatalog.quests():
		category[quest["category"]] += 1
		for requirement in quest["requires"]: check(not QuestCatalog.quest(requirement).is_empty(),quest["id"]+" prerequisite exists")
		if quest.has("target"): check(not WorldContent.location(quest["target"]).is_empty(),quest["id"]+" objective exists")
	check(category == {"main":10,"side":8},"Ten main quests and eight side quests")
	var catalog := GuCatalog.new()
	for id in Bestiary.all(): check(not catalog.get_gu(Bestiary.species(id)["gu"]).is_empty(),id+" captures a valid Gu")
func quest_chain(sim: LocalAuthority) -> void:
	# Start from a new character; simulated kills skip combat duration, all progression uses commands.
	for pass_index in range(18):
		var completed := false
		for q in QuestCatalog.quests():
			var id: String = q["id"]
			if not sim.quests.available(id): continue
			npc(sim,q["giver"])
			check(sim.quest_command("accept",q["giver"],id)["ok"],"Accept "+id)
			match str(q["metric"]):
				"talk_yen_chi": npc(sim,"yen_chi"); sim.talk_to("yen_chi")
				"kills":
					for mob_id in ["wolf_0","wolf_1"]: sim._damage_mob(mob_id,9999)
				"feeds": sim.feed_gu("world40-feed","gu_1","meat",sim.inventory.version)
				"realm":
					sim._damage_mob("wolf_0",9999)
					sim._damage_mob("wolf_1",9999)
					sim.player["cell"] = WorldGrid.SHRINE
					check(sim.cultivation_command("unlock")["ok"],"Story restores the realm entrance")
				"harvests":
					check(sim.cultivation_command("plant",{"plot":0,"crop":"herb"})["ok"],"Story plants a crop")
					sim.cultivation_command("water",{"plot":0})
					sim.step(45)
					check(sim.cultivation_command("harvest",{"plot":0})["ok"],"Story harvests a crop")
				"cultivation_loop":
					sim.cultivation_command("buy_animal",{"pen":0,"kind":"silkworm"})
					sim.cultivation_command("feed_animal",{"pen":0})
					sim.step(60)
					sim.cultivation_command("collect_animal",{"pen":0})
					check(sim.cultivation_command("upgrade",{"id":"gu_1"})["ok"],"Story resources pay for a Gu upgrade")
				"discover":
					var site := WorldContent.location(q["target"])
					region(sim,site["region"])
					sim.player["cell"] = WorldContent.cell(site)
					sim.step(.001)
				"camp_kills","deliver":
					var site := WorldContent.location(q["target"])
					region(sim,site["region"])
					for mob_id in sim.mobs:
						if sim.mobs[mob_id].get("camp","") == q["target"]: sim._damage_mob(mob_id,9999)
			check(sim.quests.ready(id,sim),"Real objective ready: "+id)
			npc(sim,q["turn_in"])
			var supplies := sim.inventory.materials.duplicate()
			check(sim.quest_command("claim",q["turn_in"],id)["ok"],"Claim "+id)
			for material in q.get("delivery",{}):
				check(int(sim.inventory.materials[material]) == int(supplies[material])-int(q["delivery"][material])+int(q["reward"].get(material,0)),id+" consumes exact delivery "+material)
			var after := sim.to_profile()
			check(not sim.quest_command("claim",q["turn_in"],id)["ok"] and sim.to_profile() == after,id+" pays only once")
			completed = true
			break
		if not completed: break
	check(sim.quests.claimed.size() == 18,"All eighteen quests complete from a new character without dependency deadlock")
	check(sim.quests.has_unlock("waygates") and sim.quests.has_unlock("field_medicine") and sim.quests.has_unlock("irrigation"),"Three functional rewards unlocked by claims")
func utilities(sim: LocalAuthority) -> void:
	region(sim,"forest")
	sim.player["cell"] = WorldGrid.SPAWN
	deny(sim,"waygate",{"id":"f_east"},"SITE_UNDISCOVERED")
	sim.player["cell"] = WorldContent.cell(WorldContent.location("f_east"))
	sim.step(.001)
	check("f_east" in sim.journey.discovered and sim.at_portal(),"Walking to a waypoint activates it")
	sim.player["cell"] = WorldGrid.SPAWN
	sim.player["hp"] = 73.0
	sim.player["mana"] = 41.0
	sim.cooldowns[0] = 1.5
	var silver := int(sim.player["currency"])
	check(sim.journey_command("waygate",{"id":"f_east"})["ok"] and sim.player["currency"] == silver-5 and sim.player["cell"] == Vector2(32,32),"Local waypoint travel charges exactly five silver")
	check(sim.player["hp"] == 73 and sim.player["mana"] == 41 and sim.cooldowns[0] == 1.5,"Local travel cannot heal or reset cooldowns")
	deny(sim,"waygate",{"id":"f_east"},"ALREADY_HERE")
	check(sim.journey_command("waygate",{"id":"camp"})["ok"],"Local waypoint can return to camp")
	sim.player["cell"] = Vector2(30,20)
	deny(sim,"waygate",{"id":"f_east"},"AT_PORTAL")
	var herb := int(sim.inventory.materials["herb"])
	var hp := float(sim.player["hp"])
	check(sim.journey_command("medicine")["ok"] and sim.player["hp"] == minf(sim.player["max_hp"],hp+sim.player["max_hp"]*.4) and sim.inventory.materials["herb"] == herb-2,"Medicine consumes recipe and heals up to forty percent")
	sim.player["hp"] = 50.0
	deny(sim,"medicine",{},"MEDICINE_COOLDOWN")
	sim.journey.step(15)
	sim.combat_left = 1
	deny(sim,"medicine",{},"IN_COMBAT")
	sim.combat_left = 0
	sim.player["hp"] = sim.player["max_hp"]
	deny(sim,"medicine",{},"FULL_HEALTH")
	deny(sim,"irrigate",{},"AT_REALM")
	region(sim,"realm")
	for i in range(3): sim.cultivation_command("plant",{"plot":i,"crop":"herb"})
	var before := sim.inventory.to_data()
	check(sim.journey_command("irrigate")["ok"] and sim.expedition.plots[0]["watered"] and sim.inventory.to_data() == before,"Irrigation waters planted plots without consuming materials")
	check(sim.expedition.plots[0]["left"] == 45,"Irrigation does not skip crop growth")
	deny(sim,"irrigate",{},"NO_DRY_PLOTS")
func gathering() -> void:
	var sim := LocalAuthority.new()
	var site: Dictionary = WorldContent.resources("forest")[0]
	var id: String = site["id"]
	deny(sim,"gather",{"id":id},"SITE_TOO_FAR")
	sim.player["cell"] = WorldContent.cell(site)
	var count := int(sim.inventory.materials.get(site["material"],0))
	check(sim.journey_command("gather",{"id":id})["ok"] and sim.inventory.materials[site["material"]] == count+2,"Gather resource at its real world position")
	deny(sim,"gather",{"id":id},"RESOURCE_RESTING")
	var load_sim := LocalAuthority.new()
	check(load_sim.load_profile(sim.to_profile()) and load_sim.journey.resources[id] == 75,"Gather cooldown persists without offline advancement")
	load_sim.journey.step(74)
	deny(load_sim,"gather",{"id":id},"RESOURCE_RESTING")
	load_sim.journey.step(1)
	check(load_sim.journey_command("gather",{"id":id})["ok"],"Resource yields again after seventy-five active seconds")
	load_sim.player["dead"] = true
	deny(load_sim,"gather",{"id":id},"DEAD")
	load_sim.player["cell"] = Vector2(78,77)
	load_sim._discover_locations()
	check("f_thunder" not in load_sim.journey.discovered,"Dead players cannot discover camps")
	var full := LocalAuthority.new()
	while full.inventory.can_add_gu(): full.inventory.add_gu("GU-01")
	full.player["cell"] = WorldContent.cell(site)
	check(full.journey_command("gather",{"id":id})["ok"] and full.inventory.pending_materials.get(site["material"],0) == 2,"Full bag queues gathered material")
func ai() -> void:
	for kind in Bestiary.all():
		var sim := LocalAuthority.new()
		var spec := Bestiary.species(kind)
		var mob: Dictionary = sim.mobs["f_bamboo_0"]
		mob["species"] = kind
		mob["cell"] = Vector2(38,20)
		mob["spawn"] = mob["cell"]
		mob["max_hp"] = float(spec["hp"])
		mob["hp"] = mob["max_hp"]
		sim.mobs = {"subject":mob}
		sim.player["cell"] = mob["cell"]+Vector2(1,0)
		WildlifeAI.step(sim,"subject",.01)
		var locked: Vector2 = mob["aim"]
		check(mob["state"] == "windup" and mob["windup_left"] > 0,kind+" telegraphs before dealing damage")
		sim.player["cell"] = Vector2(38,24)
		var hp := float(sim.player["hp"])
		WildlifeAI.step(sim,"subject",float(spec["windup"])+.01)
		check(sim.player["hp"] == hp and mob["aim"] == locked,kind+" attack can be dodged after aim locks")
		mob["cell"] = Vector2(38,20)
		mob["attack_left"] = 0.0
		sim.player["cell"] = Vector2(39,20)
		WildlifeAI.step(sim,"subject",.01)
		WildlifeAI.step(sim,"subject",float(spec["windup"])+.01)
		check(sim.player["hp"] == hp-float(spec["damage"]),kind+" hits once for authored damage")
		var supplies := sim.inventory.materials.duplicate()
		sim._damage_mob("subject",9999)
		for material in spec["loot"]: check(sim.inventory.materials[material] == int(supplies.get(material,0))+int(spec["loot"][material]),kind+" correct drop: "+material)
		var profile := sim.to_profile()
		sim._damage_mob("subject",9999)
		check(sim.to_profile() == profile,kind+" dead creature cannot pay twice")
		WildlifeAI.step(sim,"subject",float(spec["respawn"])-1)
		check(mob["dead"],kind+" respects respawn duration")
		WildlifeAI.step(sim,"subject",1)
		check(not mob["dead"] and mob["cell"] == mob["spawn"] and mob["hp"] == mob["max_hp"],kind+" respawns at full health at its camp")
		mob["hp"] = 10.0
		sim.player["cell"] = WorldGrid.SPAWN
		WildlifeAI.step(sim,"subject",.1)
		check(mob["state"] == "idle" and mob["hp"] == mob["max_hp"] and mob["path"].is_empty(),kind+" sleeps/reset at home while player is far away")
	var captured := LocalAuthority.new()
	captured._remove_mob("f_thunder_0",true)
	check(captured.quests.counters.get("camp_f_thunder",0) == 0,"Capture does not impersonate kill objective")
	var saved: Dictionary = captured.mobs["f_bamboo_0"]
	saved["hp"] = 81.0
	captured.progress["kills"] = 1
	region(captured,"ruins")
	region(captured,"forest")
	check(captured.mobs["f_bamboo_0"]["hp"] == 81 and captured.mobs["f_thunder_0"]["dead"],"Region switching retains camp population and cooldown in session")
func persistence(sim: LocalAuthority) -> void:
	var loaded := LocalAuthority.new()
	check(loaded.load_profile(sim.to_profile()) and loaded.quests.to_data() == sim.quests.to_data() and loaded.journey.to_data() == sim.journey.to_data(),"Expanded story, unlocks, exploration and timers round trip")
	var legacy := sim.to_profile()
	legacy.erase("journey")
	check(loaded.load_profile(legacy) and loaded.journey.discovered.is_empty() and loaded.quests.claimed.size() == 18,"Old saves gain default exploration without losing quests")
	for variant in ["duplicate","unknown","wrong_timer","negative","nan","bad_counter"]:
		var broken := sim.to_profile()
		match variant:
			"duplicate": broken["journey"]["discovered"] = ["f_east","f_east"]
			"unknown": broken["journey"]["discovered"] = ["missing"]
			"wrong_timer": broken["journey"]["resources"] = {"f_east":50}
			"negative": broken["journey"]["medicine_left"] = -1
			"nan": broken["journey"]["medicine_left"] = NAN
			"bad_counter": broken["quests"]["counters"]["camp_missing"] = 1
		var before := loaded.to_profile()
		check(not loaded.load_profile(broken) and loaded.to_profile() == before,"Invalid exploration save rejected atomically: "+variant)

func ai_geometry() -> void:
	for kind in ["boar","toad","wolf"]:
		var sim := LocalAuthority.new()
		var mob: Dictionary = sim.mobs["f_bamboo_0"]
		mob["species"] = kind
		mob["cell"] = Vector2(38,20)
		mob["spawn"] = mob["cell"]
		mob["aim"] = Vector2(40,20)
		mob["facing"] = Vector2.RIGHT
		sim.mobs = {"subject":mob}
		sim.player["cell"] = Vector2(40,20)
		sim.world._set_block(Vector2i(39,20))
		WildlifeAI.step(sim,"subject",.01)
		check(mob["windup_left"] == 0,kind+" cannot start an attack through terrain")
		WildlifeAI.resolve_attack(sim,"subject")
		check(sim.player["hp"] == sim.player["max_hp"] and sim.world.is_walkable(mob["cell"]),kind+" wall blocks damage and displacement")
		sim.player["cell"] = Vector2(32,32)
		mob["cell"] = Vector2(33,32)
		mob["windup_left"] = .1
		WildlifeAI.step(sim,"subject",.2)
		check(mob["windup_left"] == 0 and sim.player["hp"] == sim.player["max_hp"],kind+" entering a rest point cancels windup")
	var sim := LocalAuthority.new()
	var mob: Dictionary = sim.mobs["f_bamboo_0"]
	mob["cell"] = Vector2(38,20)
	mob["aim"] = Vector2(39,20)
	mob["facing"] = Vector2.RIGHT
	sim.player["cell"] = Vector2(38,20)+Vector2.from_angle(1.1)
	WildlifeAI.resolve_attack(sim,"f_bamboo_0")
	check(sim.player["hp"] == sim.player["max_hp"],"Melee cannot hit outside the drawn 0.9-radian cone")
	sim.player["cell"] = Vector2(38,20)+Vector2.from_angle(.5)
	WildlifeAI.resolve_attack(sim,"f_bamboo_0")
	check(sim.player["hp"] < sim.player["max_hp"],"Melee hits inside the drawn sector")
	var distant := LocalAuthority.new()
	var target: Dictionary = distant.mobs["f_bamboo_0"]
	target["cell"] = Vector2(38,20)
	target["spawn"] = target["cell"]
	distant.player["cell"] = Vector2(42,20)
	WildlifeAI.step(distant,"f_bamboo_0",.1)
	var normal := Vector2(target["cell"]).distance_to(Vector2(38,20))
	target["cell"] = Vector2(38,20)
	target["slow_left"] = 2.0
	target["repath_left"] = 0.0
	WildlifeAI.step(distant,"f_bamboo_0",.1)
	check(is_equal_approx(Vector2(target["cell"]).distance_to(Vector2(38,20)),normal*.7),"Frost slow changes wildlife chase speed")
func delivery_atomicity() -> void:
	var sim := LocalAuthority.new()
	sim.quests.accepted.append("arrival")
	sim.quests.claimed.append("arrival")
	npc(sim,"trac_su")
	sim.quest_command("accept","trac_su","boar_supply")
	sim.inventory.reward_material("hide",3)
	var before := sim.to_profile()
	check(not sim.quest_command("claim","trac_su","boar_supply")["ok"] and sim.to_profile() == before,"Partial delivery is denied without taking items or paying rewards")
	sim.inventory.reward_material("hide",1)
	while sim.inventory.can_add_gu(): sim.inventory.add_gu("GU-01")
	check(sim.quest_command("claim","trac_su","boar_supply")["ok"] and sim.inventory.materials["hide"] == 0,"Full-bag delivery consumes the required stack")
	check(int(sim.inventory.materials.get("herb_seed",0))+int(sim.inventory.pending_materials.get("herb_seed",0)) == 3,"Full-bag delivery reward is stored or queued without loss")
	check(LocalAuthority.new().load_profile(sim.to_profile()),"New camp material and quest payout validate on save-load")
