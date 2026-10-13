class_name QuestJournal
extends RefCounted
## One-time quest state; current objective values are pure authority queries.
var accepted: Array[String] = []
var claimed: Array[String] = []
var counters: Dictionary = {}
var tracked: String = ""
var revision := 0

func observe(kind: String, event: Dictionary) -> void:
	var key := ""
	if kind == "npc_talk":
		key = "talk_" + str(event.get("npc", ""))
	elif kind == "defeat" and not str(event.get("camp","")).is_empty():
		key = "camp_" + str(event["camp"])
	elif kind == "animal_harvest":
		key = "animal_products"
	elif kind == "gu_upgrade" and event.get("cultivated_gu", false):
		key = "upgrades"
	if not valid_counter(key):
		return
	var previous := int(counters.get(key,0))
	counters[key] = mini(1 if key.begins_with("talk_") else 1000000, previous+1)
	if previous != counters[key]:
		revision += 1

func available(id: String) -> bool:
	var definition := QuestCatalog.quest(id)
	if definition.is_empty() or id in accepted:
		return false
	for requirement in definition["requires"]:
		if requirement not in claimed:
			return false
	return true

func value(id: String, sim: RefCounted) -> int:
	var definition := QuestCatalog.quest(id)
	match str(definition.get("metric","")):
		"discover": return 1 if definition["target"] in sim.journey.discovered else 0
		"camp_kills": return mini(int(definition["goal"]),int(counters.get("camp_"+str(definition["target"]),0)))
		"deliver":
			var total := 0
			for material in definition["delivery"]:
				total += mini(int(definition["delivery"][material]),int(sim.inventory.materials.get(material,0)))
			return total
		"kills", "feeds": return mini(int(definition["goal"]), int(sim.progress.get(definition["metric"],0)))
		"realm": return 1 if sim.expedition.realm_unlocked else 0
		"harvests": return mini(int(definition["goal"]),sim.expedition.harvests)
		"cultivation_loop":
			var upgraded: bool = int(counters.get("upgrades",0)) > 0 or sim.inventory.gu.any(func(item: Dictionary): return int(item.get("cultivation",1)) > 1 or int(item["rank"]) > 1)
			return (1 if int(counters.get("animal_products",0)) > 0 else 0) + (1 if upgraded else 0)
	return mini(int(definition.get("goal",1)),int(counters.get(definition.get("metric",""),0)))

func ready(id: String, sim: RefCounted) -> bool:
	return id in accepted and id not in claimed and value(id,sim) >= int(QuestCatalog.quest(id).get("goal",1))

func status(id: String, sim: RefCounted) -> String:
	if id in claimed: return "claimed"
	if ready(id,sim): return "ready"
	if id in accepted: return "active"
	return "available" if available(id) else "locked"

func npc_marker(npc_id: String, sim: RefCounted) -> String:
	var offer := false
	var active := false
	for definition in QuestCatalog.quests():
		var id := str(definition["id"])
		if definition["turn_in"] == npc_id and ready(id,sim):
			return "?"
		if definition["giver"] == npc_id and available(id):
			offer = true
		if id in accepted and id not in claimed and npc_id in [definition["giver"],definition["turn_in"]]:
			active = true
	return "!" if offer else ("…" if active else "")

func destination(id: String, sim: RefCounted) -> String:
	var definition := QuestCatalog.quest(id)
	return str(definition["turn_in"] if ready(id,sim) else definition.get("destination",definition.get("giver","lam_an")))

func to_data() -> Dictionary:
	return {"version":1,"accepted":accepted.duplicate(),"claimed":claimed.duplicate(),"counters":counters.duplicate(),"tracked":tracked}

func load_data(raw: Variant) -> bool:
	if not raw is Dictionary or raw.get("version",0) != 1 or not raw.get("accepted") is Array or not raw.get("claimed") is Array or not raw.get("counters") is Dictionary or not raw.get("tracked") is String:
		return false
	for key in ["accepted","claimed"]:
		var seen := {}
		if raw[key].size() > QuestCatalog.quests().size(): return false
		for id in raw[key]:
			if not id is String or QuestCatalog.quest(id).is_empty() or seen.has(id): return false
			seen[id] = true
	for id in raw["claimed"]:
		if id not in raw["accepted"]: return false
	for id in raw["accepted"]:
		for requirement in QuestCatalog.quest(id)["requires"]:
			if requirement not in raw["claimed"]: return false
	for key in raw["counters"]:
		if not key is String or not valid_counter(key) or not ExpeditionModel._integer(raw["counters"][key],0,1 if str(key).begins_with("talk_") else 1000000): return false
	if raw["tracked"] != "" and (raw["tracked"] not in raw["accepted"] or raw["tracked"] in raw["claimed"]): return false
	accepted.assign(raw["accepted"])
	claimed.assign(raw["claimed"])
	counters = raw["counters"].duplicate()
	tracked = raw["tracked"]
	return true

static func valid_counter(key: String) -> bool:
	if key in ["animal_products","upgrades"]: return true
	if key.begins_with("talk_"): return not QuestCatalog.npc(key.trim_prefix("talk_")).is_empty()
	if key.begins_with("camp_"): return WorldContent.location(key.trim_prefix("camp_")).has("species")
	return false

func has_unlock(id: String) -> bool:
	for quest_id in claimed:
		if id in QuestCatalog.quest(quest_id).get("unlocks",[]): return true
	return false
