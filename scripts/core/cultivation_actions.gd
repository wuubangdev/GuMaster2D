class_name CultivationActions
extends RefCounted
## Atomic single-player commands. Validate all inputs before consuming inventory.

static func perform(sim: RefCounted, command: String, args: Dictionary) -> Dictionary:
	if bool(sim.player["dead"]):
		return fail("DEAD")
	if sim.combat_left > 0.0 or not sim.capture.is_empty():
		return fail("IN_COMBAT")
	var state: ExpeditionModel = sim.expedition
	match command:
		"travel": return sim.travel(str(args.get("region", "")))
		"unlock":
			if state.realm_unlocked:
				return fail("ALREADY_UNLOCKED")
			if state.region != "ruins" or Vector2(sim.player["cell"]).distance_to(WorldGrid.SHRINE) > 2.2:
				return fail("AT_RUIN_SHRINE")
			if int(sim.progress["kills"]) < 3:
				return fail("NEED_TRIAL")
			if not affordable(sim, {"essence": 2}):
				return fail("NEED_MATERIALS")
			pay(sim, {"essence": 2})
			state.realm_unlocked = true
			for key in ["herb_seed", "flower_seed", "fruit_seed"]:
				sim.inventory.reward_material(key, 2)
			sim.inventory.reward_material("fruit", 3)
			return done(sim, "realm_unlocked", "Thanh Nang mở cửa! Nhận 6 hạt giống và 3 linh quả.")
		"upgrade", "fuse":
			if args.has("version") and (not ExpeditionModel._integer(args["version"], 0, 9007199254740991) or int(args["version"]) != sim.inventory.version):
				return fail("VERSION_CONFLICT")
			var probe := GuCultivationRules.preview(sim, command, str(args.get("id", "")), str(args.get("donor", "")))
			if not probe["ok"]: return fail(str(probe["error"]))
			var item: Dictionary = sim.inventory.find_instance(str(args["id"]))
			var level := int(item.get("cultivation", 1))
			var rank_value := int(item["rank"])
			if command == "upgrade":
				pay(sim, probe["cost"])
				item["cultivation"] = level + 1
				return done(sim, "gu_upgrade", "Tu luyện thành công • mức %d / 5" % (level + 1), Vector2.INF, {"cultivated_gu": true})
			var donor: Dictionary = sim.inventory.find_instance(str(args.get("donor", "")))
			pay(sim, probe["cost"])
			sim.inventory.gu.erase(donor)
			item["rank"] = rank_value + 1
			item["cultivation"] = 1
			item["hunger"] = 100.0
			return done(sim, "gu_fusion", "Hợp thành thành công • Cổ bậc %d, mức 1" % (rank_value + 1))
	if state.region != "realm" or not state.realm_unlocked:
		return fail("AT_REALM")
	match command:
		"buy_seed":
			var crop := str(args.get("crop", ""))
			if not ExpeditionModel.CROPS.has(crop):
				return fail("BAD_RECIPE")
			var definition: Dictionary = ExpeditionModel.CROPS[crop]
			if not affordable(sim, {"silver": definition["price"]}):
				return fail("NEED_MATERIALS")
			pay(sim, {"silver": definition["price"]})
			sim.inventory.reward_material(str(definition["seed"]), 1)
			return done(sim, "farm_supply", "Đã mua hạt " + str(definition["name"]))
		"plant", "water", "harvest":
			if not ExpeditionModel._integer(args.get("plot"), 0, state.plots.size()-1):
				return fail("BAD_PLOT")
			var index := int(args.get("plot", -1))
			if index < 0 or index >= state.plots.size():
				return fail("BAD_PLOT")
			var plot := state.plots[index]
			if command == "plant":
				var crop := str(args.get("crop", ""))
				if plot["crop"] != "" or not ExpeditionModel.CROPS.has(crop):
					return fail("BAD_PLOT")
				var definition: Dictionary = ExpeditionModel.CROPS[crop]
				if not affordable(sim, {str(definition["seed"]): 1}):
					return fail("NO_SEED")
				pay(sim, {str(definition["seed"]): 1})
				plot.merge({"crop": crop, "watered": false, "left": definition["time"]}, true)
				return done(sim, "farm_plant", "Đã gieo " + str(definition["name"]) + " • cần tưới nước", ExpeditionModel.PLOTS[index])
			if plot["crop"] == "":
				return fail("BAD_PLOT")
			if command == "water":
				if bool(plot["watered"]):
					return fail("ALREADY_WATERED")
				plot["watered"] = true
				return done(sim, "farm_water", "Đã tưới • cây bắt đầu phát triển", ExpeditionModel.PLOTS[index])
			if not bool(plot["watered"]) or float(plot["left"]) > 0:
				return fail("NOT_READY")
			var definition: Dictionary = ExpeditionModel.CROPS[plot["crop"]]
			sim.inventory.reward_material(str(definition["product"]), int(definition["yield"]))
			sim.inventory.reward_material(str(definition["seed"]), 1)
			plot.merge({"crop": "", "watered": false, "left": 0.0}, true)
			state.harvests += 1
			return done(sim, "farm_harvest", "+%d %s • hoàn lại 1 hạt" % [definition["yield"], ExpeditionModel.material_name(str(definition["product"]))], ExpeditionModel.PLOTS[index],{"harvest_action":"gather","origin":sim.player["cell"]})
		"buy_animal", "feed_animal", "collect_animal", "release_animal":
			if not ExpeditionModel._integer(args.get("pen"), 0, state.animals.size()-1):
				return fail("BAD_PLOT")
			var index := int(args.get("pen", -1))
			if index < 0 or index >= state.animals.size():
				return fail("BAD_PLOT")
			var animal := state.animals[index]
			if command == "buy_animal":
				var kind := str(args.get("kind", ""))
				if animal["kind"] != "" or not ExpeditionModel.ANIMALS.has(kind):
					return fail("BAD_RECIPE")
				var definition: Dictionary = ExpeditionModel.ANIMALS[kind]
				if not affordable(sim, {"silver": definition["price"]}):
					return fail("NEED_MATERIALS")
				pay(sim, {"silver": definition["price"]})
				animal.merge({"kind": kind, "fed": false, "left": 0.0}, true)
				return done(sim, "farm_supply", "Đã nhận " + str(definition["name"]), ExpeditionModel.PENS[index])
			if animal["kind"] == "":
				return fail("BAD_PLOT")
			if command == "release_animal":
				if bool(animal["fed"]):
					return fail("ALREADY_FED")
				animal.merge({"kind": "", "fed": false, "left": 0.0}, true)
				return done(sim, "farm_supply", "Đã thả vật nuôi • chuồng trống, không hoàn bạc")
			var definition: Dictionary = ExpeditionModel.ANIMALS[animal["kind"]]
			if command == "feed_animal":
				if bool(animal["fed"]):
					return fail("ALREADY_FED")
				if not affordable(sim, {"fruit": 1}):
					return fail("NO_FOOD")
				pay(sim, {"fruit": 1})
				animal["fed"] = true
				animal["left"] = definition["time"]
				return done(sim, "farm_water", "Đã cho ăn • chờ thu sản vật", ExpeditionModel.PENS[index])
			if not bool(animal["fed"]) or float(animal["left"]) > 0:
				return fail("NOT_READY")
			sim.inventory.reward_material(str(definition["product"]), int(definition["yield"]))
			animal["fed"] = false
			return done(sim, "animal_harvest", "+%d %s" % [definition["yield"], ExpeditionModel.material_name(str(definition["product"]))], ExpeditionModel.PENS[index])
		"transmute":
			if not affordable(sim, {"egg": 2}):
				return fail("NEED_MATERIALS")
			pay(sim, {"egg": 2})
			sim.inventory.reward_material("stone", 3)
			return done(sim, "gu_upgrade", "Đổi 2 trứng linh kê → 3 chân nguyên thạch")
	return fail("BAD_RECIPE")

static func affordable(sim: RefCounted, cost: Dictionary) -> bool:
	for key in cost:
		if int(sim.player["currency"] if key == "silver" else sim.inventory.materials.get(key, 0)) < int(cost[key]):
			return false
	return true

static func pay(sim: RefCounted, cost: Dictionary) -> void:
	for key in cost:
		if key == "silver":
			sim.player["currency"] = int(sim.player["currency"]) - int(cost[key])
		else:
			sim.inventory.materials[key] = int(sim.inventory.materials[key]) - int(cost[key])
	sim.inventory.version += 1

static func done(sim: RefCounted, kind: String, message: String, at: Vector2 = Vector2.INF, metadata: Dictionary = {}) -> Dictionary:
	sim.expedition.revision += 1
	sim.inventory.version += 1
	var event := {"text": message, "persistent": true}
	event.merge(metadata)
	sim._emit(kind, sim.player["cell"] if not at.is_finite() else at, event)
	return {"ok": true}

static func fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}
