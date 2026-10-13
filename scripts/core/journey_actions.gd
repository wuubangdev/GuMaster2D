class_name JourneyActions
extends RefCounted
## Travel, resources and quest-granted utility features. Validate before mutation.
static func perform(sim: RefCounted, command: String, args: Dictionary) -> Dictionary:
	if bool(sim.player["dead"]): return CultivationActions.fail("DEAD")
	if sim.combat_left > 0 or not sim.capture.is_empty(): return CultivationActions.fail("IN_COMBAT")
	var id := str(args.get("id",""))
	var site := WorldContent.location(id)
	match command:
		"gather":
			if site.get("kind","") != "resource" or site["region"] != sim.expedition.region: return CultivationActions.fail("BAD_SITE")
			if Vector2(sim.player["cell"]).distance_to(WorldContent.cell(site)) > 1.8 or not sim.world.clear_segment(sim.player["cell"],WorldContent.cell(site)): return CultivationActions.fail("SITE_TOO_FAR")
			if float(sim.journey.resources.get(id,0)) > 0: return CultivationActions.fail("RESOURCE_RESTING")
			sim.inventory.reward_material(site["material"],int(site["yield_count"]))
			sim.journey.resources[id] = float(site["respawn"])
			sim.journey.revision += 1
			sim._emit("farm_harvest",WorldContent.cell(site),{"text":"+%d %s • nguồn hồi sau %ds" % [site["yield_count"],ExpeditionModel.material_name(site["material"]),site["respawn"]],"persistent":true,"harvest_action":"mine" if site["material"] in ["ore","stone"] else "gather","site_id":id,"origin":sim.player["cell"]})
		"waygate":
			if not sim.quests.has_unlock("waygates"): return CultivationActions.fail("NEED_WAYGATES")
			if not sim.at_portal(): return CultivationActions.fail("AT_PORTAL")
			var destination: Vector2 = WorldGrid.SPAWN
			if id != "camp":
				if site.get("kind","") != "waypoint" or site["region"] != sim.expedition.region: return CultivationActions.fail("BAD_SITE")
				if id not in sim.journey.discovered: return CultivationActions.fail("SITE_UNDISCOVERED")
				destination = WorldContent.cell(site)
			if Vector2(sim.player["cell"]).distance_to(destination) < 2: return CultivationActions.fail("ALREADY_HERE")
			if int(sim.player["currency"]) < 5: return CultivationActions.fail("NEED_MATERIALS")
			sim.player["currency"] = int(sim.player["currency"])-5
			sim.stop_navigation()
			sim.player["cell"] = destination
			sim._emit("waygate",destination,{"text":"Đã đến " + ("trại" if id == "camp" else str(site["name"])) + " • -5 bạc","persistent":true})
		"medicine":
			if not sim.quests.has_unlock("field_medicine"): return CultivationActions.fail("NEED_MEDICINE")
			if float(sim.player["hp"]) >= float(sim.player["max_hp"]): return CultivationActions.fail("FULL_HEALTH")
			if sim.journey.medicine_left > 0: return CultivationActions.fail("MEDICINE_COOLDOWN")
			var cost := {"herb":2,"nectar":1}
			if not CultivationActions.affordable(sim,cost): return CultivationActions.fail("NEED_MATERIALS")
			CultivationActions.pay(sim,cost)
			sim.player["hp"] = minf(float(sim.player["max_hp"]),float(sim.player["hp"])+float(sim.player["max_hp"])*.4)
			sim.journey.medicine_left = 15
			sim._emit("feed",sim.player["cell"],{"text":"Dược phương • hồi tối đa 40% sinh lực","persistent":true})
		"irrigate":
			if not sim.quests.has_unlock("irrigation"): return CultivationActions.fail("NEED_IRRIGATION")
			if sim.expedition.region != "realm": return CultivationActions.fail("AT_REALM")
			var count := 0
			for plot in sim.expedition.plots:
				if plot["crop"] != "" and not bool(plot["watered"]):
					plot["watered"] = true
					count += 1
			if count == 0: return CultivationActions.fail("NO_DRY_PLOTS")
			sim.expedition.revision += 1
			sim._emit("farm_water",sim.player["cell"],{"text":"Linh mương đã tưới %d luống" % count,"persistent":true})
		_: return CultivationActions.fail("BAD_SITE")
	return {"ok":true}
