class_name GuCultivationRules
extends RefCounted
## Shared, pure progression queries and the values used by actual skill casts.

static func donors(sim: RefCounted, item: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for candidate in sim.inventory.gu:
		if candidate["instance_id"] != item.get("instance_id") and int(candidate["slot"]) < 0 and candidate["definition_id"] == item.get("definition_id") and int(candidate["rank"]) == 1:
			result.append(candidate)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("cultivation", 1)) < int(b.get("cultivation", 1)) if a.get("cultivation", 1) != b.get("cultivation", 1) else str(a["instance_id"]).naturalnocasecmp_to(str(b["instance_id"])) < 0)
	return result

static func stats(sim: RefCounted, item: Dictionary) -> Dictionary:
	var definition: Dictionary = sim.catalog.get_gu(str(item["definition_id"]))
	var strength := ExpeditionModel.strength(item)
	var factor := strength * (.8 if float(item["hunger"]) < 20.0 else 1.0)
	var attack := 10.0 + 2.0 * (int(sim.player["level"]) - 1)
	return {
		"strength": strength,
		"damage": maxi(1, floori((float(definition["power"]) + .8 * attack) * factor * 100.0 / 104.0)),
		"shield": minf(float(sim.player["max_hp"]) * .4, floorf((float(definition["power"]) + .5 * attack) * factor)),
		"cooldown": float(definition["cooldown"]) * (maxf(.55, 1.0 / strength) if definition["kind"] == "dash" else 1.0),
		"mana": int(definition["mana"]), "hunger": float(item["hunger"])
	}

static func preview(sim: RefCounted, command: String, id: String, donor_id: String = "") -> Dictionary:
	var item: Dictionary = sim.inventory.find_instance(id)
	if item.is_empty(): return {"ok": false, "error": "NOT_OWNED"}
	if command not in ["upgrade", "fuse"]: return {"ok": false, "error": "BAD_RECIPE"}
	var level := int(item.get("cultivation", 1))
	var rank_value := int(item["rank"])
	var after := item.duplicate(true)
	var maximum := level >= 5 if command == "upgrade" else rank_value >= 3
	var cost: Dictionary = {}
	if not maximum:
		cost = ExpeditionModel.upgrade_cost(item) if command == "upgrade" else ExpeditionModel.fusion_cost(item)
		if command == "upgrade": after["cultivation"] = level + 1
		else: after.merge({"rank": rank_value + 1, "cultivation": 1, "hunger": 100.0}, true)
	var error := ""
	if bool(sim.player["dead"]): error = "DEAD"
	elif sim.combat_left > 0 or not sim.capture.is_empty(): error = "IN_COMBAT"
	elif not sim.world.is_safe(sim.player["cell"]): error = "AT_CAMP"
	elif maximum: error = "MAX_CULTIVATION" if command == "upgrade" else "MAX_RANK"
	elif command == "fuse" and level < (3 if rank_value == 1 else 5): error = "NEED_CULTIVATION"
	elif command == "fuse" and not donors(sim, item).any(func(candidate: Dictionary): return candidate["instance_id"] == donor_id): error = "NEED_DONOR"
	elif not CultivationActions.affordable(sim, cost): error = "NEED_MATERIALS"
	return {"ok": error.is_empty(), "error": error, "cost": cost, "item": item.duplicate(true), "after": after, "before_stats": stats(sim, item), "after_stats": stats(sim, after), "version": sim.inventory.version}
