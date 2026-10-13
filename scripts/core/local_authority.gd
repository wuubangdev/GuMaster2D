class_name LocalAuthority
extends RefCounted
## Pure local simulation. No CanvasItem, input singleton, audio or UI dependencies.
## This is a single-player prototype authority, not an authenticated MMO server.

const PLAYER_SPEED: float = 3.0
const PLAYER_RUN_SPEED: float = 4.8
const RESPAWN_SECONDS: float = 5.0
var world := WorldGrid.new()
var expedition := ExpeditionModel.new()
var quests := QuestJournal.new()
var journey := JourneyModel.new()
var region_mobs: Dictionary = {}
var catalog := GuCatalog.new()
var inventory := InventoryModel.new()
var player: Dictionary = {}
var mobs: Dictionary = {}
var events: Array[Dictionary] = []
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var capture: Dictionary = {}
var progress: Dictionary = {"kills": 0, "captures": 0, "feeds": 0, "claimed": false}
var clock: float = 0.0
var combat_left: float = 0.0
var movement_direction: Vector2 = Vector2.ZERO
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 74021, demo: bool = false) -> void:
	rng.seed = seed_value
	player = {"cell": WorldGrid.SPAWN, "path": [], "facing": Vector2(1, -1), "hp": 200.0, "max_hp": 200.0, "mana": 100.0, "max_mana": 100.0, "shield": 0.0, "shield_left": 0.0, "level": 1, "xp": 0, "currency": 100, "dead": false, "respawn_left": 0.0, "running": false, "appearance": GuCharacterAppearance.default_data()}
	if demo:
		# Pre-used starting Gu for the teaching sandbox; newly captured Gu always start at100.
		inventory.gu[0]["hunger"] = 82.0
	mobs = _region_population("forest")

func drain_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = events.duplicate()
	events.clear()
	return result

func _emit(kind: String, at: Vector2, extra: Dictionary = {}) -> void:
	var event := {"kind": kind, "at": at}
	event.merge(extra)
	events.append(event)
	quests.observe(kind,event)

func _denied(code: String) -> Dictionary:
	return {"ok": false, "error": code}

func move_to(target: Vector2) -> Dictionary:
	if bool(player["dead"]):
		return _denied("DEAD")
	if not target.is_finite() or not world.is_walkable(target):
		return _denied("BAD_PATH")
	var path := world.path(player["cell"], target)
	if path.is_empty() and Vector2(player["cell"]).distance_to(target.round()) > 0.55:
		return _denied("NO_PATH")
	_cancel_capture("Đã ngừng bắt Cổ")
	movement_direction = Vector2.ZERO
	player["running"] = false
	player["path"] = path
	_emit("move", target.round())
	return {"ok": true}

func set_move_direction(direction: Vector2, running: bool = false) -> Dictionary:
	## A held movement intent; authority owns normalization, collision and capture cancellation.
	if not direction.is_finite():
		return _denied("BAD_PATH")
	if bool(player["dead"]):
		movement_direction = Vector2.ZERO
		player["running"] = false
		return _denied("DEAD")
	movement_direction = direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO
	player["running"] = running and movement_direction != Vector2.ZERO
	if movement_direction != Vector2.ZERO:
		player["path"] = []
		_cancel_capture("Đã ngừng bắt Cổ")
	return {"ok": true}

func closest_mob(point: Vector2, radius: float = 6.0) -> String:
	var best := ""
	var distance := radius
	for id in mobs:
		var mob: Dictionary = mobs[id]
		var gap := Vector2(mob["cell"]).distance_to(point)
		if not bool(mob["dead"]) and gap < distance:
			best = str(id)
			distance = gap
	return best

func preview_cast(slot: int, target_id: String, point: Vector2) -> Dictionary:
	## Pure query shared by HUD, aiming and cast. Never charges resources or emits events.
	if bool(player["dead"]):
		return _denied("DEAD")
	if slot < 0 or slot >= 4:
		return _denied("BAD_SLOT")
	var def := catalog.slot(slot)
	var item := inventory.slot_gu(slot)
	var origin: Vector2 = player["cell"]
	var cost := ceili(float(player["max_mana"]) * float(def["mana"]) / 100.0)
	var target: Dictionary = mobs.get(target_id, {})
	var valid_target := not target.is_empty() and not bool(target.get("dead", true))
	var probe := {"ok": true, "slot": slot, "cost": cost, "origin": origin, "destination": origin, "requested": origin, "clipped": false, "range": float(def["range"])}
	if str(def["target"]) == "enemy" and valid_target:
		probe["destination"] = target["cell"]
		probe["requested"] = target["cell"]
	elif str(def["kind"]) == "dash" and point.is_finite():
		var direction := point - origin
		if direction.length() < 0.1:
			direction = player["facing"]
		probe["requested"] = origin + direction.normalized() * minf(float(def["range"]), direction.length())
		probe["destination"] = world.sweep(origin, probe["requested"])
		probe["clipped"] = Vector2(probe["destination"]).distance_to(probe["requested"]) > 0.02
	if item.is_empty() or float(item["hunger"]) <= 0.0:
		return _block_preview(probe, "HUNGRY")
	if cooldowns[slot] > 0.001:
		return _block_preview(probe, "COOLDOWN")
	if float(player["mana"]) < cost:
		return _block_preview(probe, "NO_MANA")
	if str(def["target"]) == "enemy":
		if world.is_safe(origin):
			return _block_preview(probe, "SAFE_ZONE")
		if not valid_target:
			return _block_preview(probe, "NO_TARGET")
		if origin.distance_to(probe["destination"]) > float(def["range"]):
			return _block_preview(probe, "OUT_OF_RANGE")
		if not world.clear_segment(origin, probe["destination"]):
			return _block_preview(probe, "NO_LOS")
	elif str(def["kind"]) == "dash":
		if not point.is_finite():
			return _block_preview(probe, "BAD_PATH")
		if Vector2(probe["destination"]).distance_to(origin) < 0.25:
			return _block_preview(probe, "BAD_PATH")
	return probe

func _block_preview(probe: Dictionary, code: String) -> Dictionary:
	probe["ok"] = false
	probe["error"] = code
	return probe

func cast(slot: int, target_id: String, point: Vector2) -> Dictionary:
	var probe := preview_cast(slot, target_id, point)
	if not bool(probe["ok"]):
		return _denied(str(probe["error"]))
	var def := catalog.slot(slot)
	var item := inventory.slot_gu(slot)
	var cost := int(probe["cost"])
	var destination: Vector2 = probe["destination"]
	var target: Dictionary = mobs.get(target_id, {})
	_cancel_capture("Đã ngừng bắt Cổ")
	player["mana"] = float(player["mana"]) - cost
	var gu_stats := GuCultivationRules.stats(self, item)
	cooldowns[slot] = gu_stats["cooldown"]
	player["path"] = []
	movement_direction = Vector2.ZERO
	player["running"] = false
	match str(def["kind"]):
		"moon", "frost":
			combat_left = 5.0
			player["facing"] = (destination - Vector2(player["cell"])).normalized()
			var damage := int(gu_stats["damage"])
			_emit("cast_" + str(def["kind"]), player["cell"], {"to": destination, "target": target_id, "rank": int(item["rank"]), "strength": ExpeditionModel.strength(item)})
			_damage_mob(target_id, damage)
			if str(def["kind"]) == "frost" and not bool(target["dead"]):
				target["slow_left"] = 3.0
		"shield":
			player["shield"] = gu_stats["shield"]
			player["shield_left"] = 5.0
			_emit("shield", player["cell"], {"rank": int(item["rank"])})
		"dash":
			_emit("dash", player["cell"], {"to": destination, "rank": int(item["rank"])})
			player["facing"] = (destination - Vector2(player["cell"])).normalized()
			player["cell"] = destination
	return {"ok": true, "slot": slot, "cost": cost}

func _damage_mob(id: String, amount: int) -> void:
	var mob: Dictionary = mobs[id]
	if bool(mob["dead"]):
		return
	mob["owned"] = true
	mob["hp"] = maxf(0.0, float(mob["hp"]) - amount)
	_emit("hit", mob["cell"], {"amount": amount, "target": id})
	if float(mob["hp"]) <= 0.0:
		if capture.get("target", "") == id:
			_cancel_capture("Mục tiêu đã bị hạ")
		_remove_mob(id, false)
		progress["kills"] = int(progress["kills"]) + 1
		if mob.get("wild",false):
			var spec := Bestiary.species(mob["species"])
			player["currency"] = int(player["currency"])+int(spec["silver"])
			player["xp"] = int(player["xp"])+int(spec["xp"])
			for material in spec["loot"]: inventory.reward_material(material,int(spec["loot"][material]))
			_emit("loot",mob["cell"],{"text":QuestCatalog.reward_text(spec["loot"]) + " · %d bạc" % spec["silver"]})
		else:
			player["currency"] = int(player["currency"]) + 12
			player["xp"] = int(player["xp"]) + 35
			inventory.reward_material("meat", 1)
			inventory.reward_material("seal", 1)
			_emit("loot", mob["cell"], {"text": "+12 ngân lượng  ·  +1 thịt thú  ·  +1 phong ấn"})
			if expedition.region == "ruins":
				inventory.reward_material("essence", 1)
				inventory.reward_material("stone", 2)
				_emit("loot", mob["cell"], {"text": "+1 cổ tinh · +2 chân nguyên thạch"})
		_check_level()
		_check_quest()

func _remove_mob(id: String, captured: bool) -> void:
	var mob: Dictionary = mobs[id]
	mob["dead"] = true
	mob["state"] = "dead"
	mob["path"] = []
	mob["respawn_left"] = float(Bestiary.species(mob["species"])["respawn"]) if mob.get("wild",false) else 20.0
	_emit("capture_success" if captured else "defeat", mob["cell"], {"target": id,"camp":mob.get("camp","")})

func begin_capture(id: String) -> Dictionary:
	if bool(player["dead"]):
		return _denied("DEAD")
	if not capture.is_empty():
		return _denied("CAPTURING")
	if not mobs.has(id) or bool(mobs[id]["dead"]):
		return _denied("NO_TARGET")
	var mob: Dictionary = mobs[id]
	if not bool(mob["owned"]) or float(mob["hp"]) / float(mob["max_hp"]) > 0.30:
		return _denied("HP_TOO_HIGH")
	if Vector2(player["cell"]).distance_to(mob["cell"]) > 3.0 or not world.clear_segment(player["cell"], mob["cell"]):
		return _denied("OUT_OF_RANGE")
	if int(inventory.materials.get("seal", 0)) <= 0:
		return _denied("NO_SEAL")
	if not inventory.can_add_gu():
		return _denied("BAG_FULL")
	# Capacity is reserved by disallowing another capture; this local sandbox has one writer.
	inventory.materials["seal"] = int(inventory.materials["seal"]) - 1
	inventory.version += 1
	capture = {"target": id, "left": 2.0, "duration": 2.0}
	player["path"] = []
	movement_direction = Vector2.ZERO
	player["running"] = false
	_emit("capture_start", mob["cell"])
	return {"ok": true}

func _cancel_capture(message: String) -> void:
	if not capture.is_empty():
		capture.clear()
		_emit("notice", player["cell"], {"text": message})

func feed_gu(request_id: String, instance_id: String, food: String, expected_version: int) -> Dictionary:
	if bool(player["dead"]):
		return _denied("DEAD")
	var replay := inventory.receipts.has(request_id)
	var receipt := inventory.feed(request_id, instance_id, food, expected_version, catalog)
	if receipt.get("ok", false) and not replay:
		progress["feeds"] = int(progress["feeds"]) + 1
		_emit("feed", player["cell"], {"text": "Đã cho Cổ ăn  ·  +40 no đủ"})
		_check_quest()
	return receipt

func _check_level() -> void:
	var level := int(player["level"])
	while level < 20 and int(player["xp"]) >= 50 * level * (level + 1):
		level += 1
		player["level"] = level
		player["max_hp"] = 200.0 + 20.0 * (level - 1)
		player["hp"] = player["max_hp"]
		_emit("level_up", player["cell"], {"text": "Đột phá cấp %d" % level})

func _check_quest() -> void:
	if not bool(progress["claimed"]) and int(progress["kills"]) >= 3 and int(progress["captures"]) >= 1 and int(progress["feeds"]) >= 1:
		progress["claimed"] = true
		player["currency"] = int(player["currency"]) + 200
		_emit("quest_complete", player["cell"], {"text": "Khảo nghiệm hoàn thành  ·  +200 ngân lượng"})

func step(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	clock += delta
	journey.step(delta)
	_discover_locations()
	if expedition.step(delta):
		_emit("farm_ready", player["cell"], {"text": "Bí cảnh có sản vật sẵn sàng • mở H để xem"})
	inventory.recover_rewards()
	for i in range(cooldowns.size()):
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
	combat_left = maxf(0.0, combat_left - delta)
	inventory.advance_hunger(delta)
	player["shield_left"] = maxf(0.0, float(player["shield_left"]) - delta)
	if float(player["shield_left"]) <= 0.0:
		player["shield"] = 0.0
	if bool(player["dead"]):
		player["respawn_left"] = maxf(0.0, float(player["respawn_left"]) - delta)
		if float(player["respawn_left"]) <= 0.0:
			_respawn_player()
	else:
		if movement_direction != Vector2.ZERO:
			_advance_manual_player(delta)
		else:
			_advance_actor(player, PLAYER_SPEED, delta)
		player["mana"] = minf(float(player["max_mana"]), float(player["mana"]) + delta * (2.0 if combat_left <= 0.0 else 1.0))
		if world.is_safe(player["cell"]) and combat_left <= 0.0:
			player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + delta * 30.0)
	for id in mobs:
		if mobs[id].get("wild",false): WildlifeAI.step(self,str(id),delta)
		else: _step_mob(str(id), delta)
	if not capture.is_empty():
		var id := str(capture["target"])
		if not mobs.has(id) or bool(mobs[id]["dead"]) or Vector2(player["cell"]).distance_to(mobs[id]["cell"]) > 3.0:
			_cancel_capture("Bắt Cổ gián đoạn: mục tiêu đã rời tầm")
		else:
			capture["left"] = float(capture["left"]) - delta
			if float(capture["left"]) <= 0.0:
				capture.clear()
				if rng.randf() < 0.70:
					var capture_definition := GuCatalog.SLOT_IDS[int(mobs[id]["variant"]) % 4] if expedition.region == "ruins" else ("GU-01" if int(mobs[id]["variant"]) != 2 else "GU-07")
					if mobs[id].get("wild",false): capture_definition = Bestiary.species(mobs[id]["species"])["gu"]
					var item := inventory.add_gu(capture_definition)
					if not item.is_empty():
						_remove_mob(id, true)
						progress["captures"] = int(progress["captures"]) + 1
						_emit("notice", player["cell"], {"text": "Bắt Cổ thành công! Mở túi [Tab] để xem."})
						_check_quest()
				else:
					_emit("capture_fail", mobs[id]["cell"], {"text": "Phong ấn thất bại  ·  Có thể thử lại [C]"})

func _advance_manual_player(delta: float) -> void:
	var origin: Vector2 = player["cell"]
	var speed := PLAYER_RUN_SPEED if bool(player.get("running", false)) else PLAYER_SPEED
	var travel := movement_direction * speed * delta
	var destination := world.sweep(origin, origin + travel)
	# Slide along one clear axis after a blocked sweep. Each segment stays inside the budget.
	if destination.distance_to(origin + travel) > 0.001:
		var remaining := origin + travel - destination
		var slide_x := world.sweep(destination, destination + Vector2(remaining.x, 0))
		var slide_y := world.sweep(destination, destination + Vector2(0, remaining.y))
		destination = slide_x if slide_x.distance_to(destination) >= slide_y.distance_to(destination) else slide_y
	player["cell"] = destination
	player["facing"] = (destination - origin).normalized() if destination.distance_squared_to(origin) > 0.000001 else movement_direction

func _advance_actor(actor: Dictionary, speed: float, delta: float) -> void:
	var budget := speed * delta
	while budget > 0.0 and not actor["path"].is_empty():
		var destination: Vector2 = actor["path"][0]
		var position: Vector2 = actor["cell"]
		var distance := position.distance_to(destination)
		if distance < 0.01:
			actor["path"].pop_front()
			continue
		var next := position.move_toward(destination, minf(budget, distance))
		if not world.clear_segment(position, next):
			actor["path"] = []
			return
		actor["cell"] = next
		actor["facing"] = (destination - position).normalized()
		budget -= distance
		if next.distance_to(destination) < 0.01:
			actor["path"].pop_front()

func _step_mob(id: String, delta: float) -> void:
	var mob: Dictionary = mobs[id]
	if bool(mob["dead"]):
		mob["respawn_left"] = float(mob["respawn_left"]) - delta
		if float(mob["respawn_left"]) <= 0.0:
			mob.merge({"dead": false, "hp": mob["max_hp"], "cell": mob["spawn"], "state": "idle", "path": [], "owned": false, "windup_left": 0.0, "slow_left": 0.0}, true)
		return
	mob["slow_left"] = maxf(0.0, float(mob["slow_left"]) - delta)
	mob["attack_left"] = maxf(0.0, float(mob["attack_left"]) - delta)
	mob["repath_left"] = maxf(0.0, float(mob["repath_left"]) - delta)
	var distance := Vector2(mob["cell"]).distance_to(player["cell"])
	var should_return: bool = mob["state"] == "leash" or bool(player["dead"]) or world.is_safe(player["cell"]) or Vector2(mob["cell"]).distance_to(mob["spawn"]) > 7.0 or distance > 8.0
	if should_return:
		mob["windup_left"] = 0.0
		if mob["state"] != "idle" and Vector2(mob["cell"]).distance_to(mob["spawn"]) > 0.1:
			mob["state"] = "leash"
			if float(mob["repath_left"]) <= 0.0:
				mob["path"] = world.path(mob["cell"], mob["spawn"])
				mob["repath_left"] = 0.6
			_advance_actor(mob, 2.2, delta)
		else:
			mob["state"] = "idle"
			mob["hp"] = mob["max_hp"]
			mob["owned"] = false
		return
	if float(mob["windup_left"]) > 0.0:
		mob["windup_left"] = maxf(0.0, float(mob["windup_left"]) - delta)
		if float(mob["windup_left"]) <= 0.0:
			if distance <= 1.45 and world.clear_segment(mob["cell"], player["cell"]):
				_damage_player(12)
			mob["attack_left"] = 1.3
			mob["state"] = "chase"
		return
	if distance <= 1.1 and world.clear_segment(mob["cell"], player["cell"]):
		mob["path"] = []
		if float(mob["attack_left"]) <= 0.0:
			mob["state"] = "windup"
			mob["windup_left"] = 0.65
		return
	if distance < 4.5 or bool(mob["owned"]):
		mob["state"] = "chase"
		if float(mob["repath_left"]) <= 0.0:
			mob["path"] = world.path(mob["cell"], player["cell"])
			mob["repath_left"] = 0.6
		_advance_actor(mob, 1.5 * (0.7 if float(mob["slow_left"]) > 0.0 else 1.0), delta)
	else:
		mob["state"] = "idle"
		mob["wander_left"] = float(mob["wander_left"]) - delta
		if float(mob["wander_left"]) <= 0.0:
			mob["wander_left"] = rng.randf_range(3.0, 7.0)
			var destination: Vector2 = Vector2(mob["spawn"]) + Vector2(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
			mob["path"] = world.path(mob["cell"], destination)
		_advance_actor(mob, 0.5, delta)

func _damage_player(amount: int) -> void:
	if bool(player["dead"]) or world.is_safe(player["cell"]):
		return
	_cancel_capture("Bị tấn công: bắt Cổ gián đoạn")
	combat_left = 5.0
	var absorbed := minf(float(player["shield"]), amount)
	player["shield"] = float(player["shield"]) - absorbed
	player["hp"] = maxf(0.0, float(player["hp"]) - (amount - absorbed))
	_emit("player_hit", player["cell"], {"amount": int(amount - absorbed), "absorbed": absorbed})
	if float(player["hp"]) <= 0.0:
		player["dead"] = true
		player["path"] = []
		movement_direction = Vector2.ZERO
		player["running"] = false
		player["shield"] = 0.0
		player["respawn_left"] = RESPAWN_SECONDS
		var penalty := mini(50, floori(float(player["currency"]) * 0.05))
		player["currency"] = int(player["currency"]) - penalty
		_emit("player_death", player["cell"], {"text": "Trọng thương  ·  -%d ngân lượng" % penalty})

func _respawn_player() -> void:
	movement_direction = Vector2.ZERO
	player["running"] = false
	player.merge({"cell": WorldGrid.SPAWN, "path": [], "hp": player["max_hp"], "mana": player["max_mana"], "dead": false, "shield": 0.0}, true)
	combat_left = 0.0
	_emit("respawn", player["cell"], {"text": "Đã trở về điểm an toàn"})

func to_profile() -> Dictionary:
	var p: Vector2 = player["cell"] if not bool(player["dead"]) else WorldGrid.SPAWN
	var look := GuCharacterAppearance.sanitize(player["appearance"])
	var legacy_look := {"body": look["body"], "outfit": look["outfit"], "weapon": look["weapon"], "hair": look["hair"]}
	var accessories := {"boots": look["boots"], "hat": look["hat"]}
	return {"schema": 1, "cell": [p.x, p.y], "level": player["level"], "xp": player["xp"], "currency": player["currency"], "inventory": inventory.to_data(), "progress": progress.duplicate(true), "appearance": legacy_look, "appearance_v2": accessories, "expedition": expedition.to_data(), "quests": quests.to_data(), "journey": journey.to_data()}

func set_appearance(value: Dictionary) -> Dictionary:
	if not GuCharacterAppearance.validate(value):
		return _denied("BAD_APPEARANCE")
	player["appearance"] = GuCharacterAppearance.sanitize(value)
	_emit("appearance_changed", player["cell"])
	return {"ok": true}

func load_profile(profile: Dictionary) -> bool:
	if profile.get("schema", 0) != 1 or not profile.get("inventory") is Dictionary or not profile.get("progress") is Dictionary:
		return false
	for key in ["xp", "currency"]:
		if not InventoryModel.valid_number(profile.get(key, 0)):
			return false
	for key in ["kills", "captures", "feeds"]:
		if not InventoryModel.valid_number(profile["progress"].get(key, 0)):
			return false
	var appearance_source: Variant = profile.get("appearance", GuCharacterAppearance.default_data())
	var accessories_source: Variant = profile.get("appearance_v2", {}) if profile.has("appearance") else {}
	var appearance := GuCharacterAppearance.restore_saved(appearance_source, accessories_source)
	if appearance.is_empty():
		return false
	var loaded := InventoryModel.new()
	if not loaded.load_data(profile["inventory"], catalog):
		return false
	var loaded_expedition := ExpeditionModel.new()
	if profile.has("expedition") and not loaded_expedition.load_data(profile["expedition"]):
		return false
	var loaded_quests := QuestJournal.new()
	if profile.has("quests") and not loaded_quests.load_data(profile["quests"]):
		return false
	var loaded_journey := JourneyModel.new()
	if profile.has("journey") and not loaded_journey.load_data(profile["journey"]): return false
	var loaded_world := WorldGrid.new(loaded_expedition.region)
	var xp := clampi(int(profile.get("xp", 0)), 0, 19000)
	var level := 1
	while level < 20 and xp >= 50 * level * (level + 1):
		level += 1
	var location := WorldGrid.SPAWN
	if profile.get("cell") is Array and profile["cell"].size() == 2:
		if not InventoryModel.valid_number(profile["cell"][0]) or not InventoryModel.valid_number(profile["cell"][1]):
			return false
		var candidate := Vector2(float(profile["cell"][0]), float(profile["cell"][1]))
		if candidate.is_finite() and loaded_world.is_walkable(candidate):
			location = candidate
	quests = loaded_quests
	journey = loaded_journey
	expedition = loaded_expedition
	world = loaded_world
	region_mobs.clear()
	mobs = _region_population(expedition.region)
	inventory = loaded
	movement_direction = Vector2.ZERO
	player["running"] = false
	player.merge({"cell": location, "path": [], "level": level, "xp": xp, "currency": clampi(int(profile.get("currency", 0)), 0, 10000000), "max_hp": 200.0 + 20.0 * (level - 1), "hp": 200.0 + 20.0 * (level - 1), "appearance": appearance.duplicate(true)}, true)
	for key in ["kills", "captures", "feeds"]:
		progress[key] = maxi(0, int(profile["progress"].get(key, 0)))
	progress["claimed"] = bool(profile["progress"].get("claimed", false))
	return true

func cultivation_command(command: String, args: Dictionary = {}) -> Dictionary:
	return CultivationActions.perform(self, command, args)

func craft_item(request_id: String, recipe_id: String, batches: Variant, expected_version: int) -> Dictionary:
	return ItemCrafting.execute(self, request_id, recipe_id, batches, expected_version)

func at_portal() -> bool:
	var location: Vector2 = player["cell"]
	if location.distance_to(WorldGrid.SPAWN) <= 2.2 or location.distance_to(WorldGrid.SHRINE) <= 2.2: return true
	for site in WorldContent.waypoints(expedition.region):
		if site["id"] in journey.discovered and location.distance_to(WorldContent.cell(site)) <= 2.2: return true
	return false

func travel(destination: String) -> Dictionary:
	if bool(player["dead"]):
		return _denied("DEAD")
	if combat_left > 0.0 or not capture.is_empty():
		return _denied("IN_COMBAT")
	if not ExpeditionModel.REGIONS.has(destination) or destination == expedition.region:
		return _denied("BAD_REGION")
	if not at_portal():
		return _denied("AT_PORTAL")
	if destination == "ruins" and int(progress["kills"]) < 1:
		return _denied("NEED_FIRST_KILL")
	if destination == "realm" and not expedition.realm_unlocked:
		return _denied("REALM_LOCKED")
	region_mobs[expedition.region] = mobs
	expedition.region = destination
	world = WorldGrid.new(destination)
	mobs = region_mobs[destination] if region_mobs.has(destination) else _region_population(destination)
	movement_direction = Vector2.ZERO
	player.merge({"cell": WorldGrid.SPAWN, "path": [], "running": false, "shield": 0.0, "shield_left": 0.0}, true)
	# Retain health/mana/cooldowns: travel is not a combat reset or free heal.
	events.clear()
	_emit("region_changed", player["cell"], {"region": destination, "persistent": true, "text": "Đã đến " + str(ExpeditionModel.REGIONS[destination]["name"])})
	return {"ok": true}

func _region_population(region_id: String) -> Dictionary:
	var population := Bestiary.population(region_id)
	if region_id == "realm": return population
	var spawns: Array[Vector2] = [Vector2(16,19),Vector2(18,15),Vector2(8,14),Vector2(17,8),Vector2(8,22),Vector2(21,18)]
	if region_id == "ruins": spawns = [Vector2(17,20),Vector2(20,16),Vector2(7,17),Vector2(16,12),Vector2(8,12),Vector2(19,6)]
	for i in range(6):
		var id := "wolf_%d" % i
		var hp := 185.0 if region_id == "ruins" else 140.0
		population[id] = {"id":id,"name":"Sói cổ trận" if region_id == "ruins" else ("Sói linh" if i%3 == 2 else "Sói rừng"),"cell":spawns[i],"spawn":spawns[i],"path":[],"hp":hp,"max_hp":hp,"state":"idle","dead":false,"respawn_left":0.0,"attack_left":0.0,"windup_left":0.0,"slow_left":0.0,"repath_left":0.0,"wander_left":2.0+i,"facing":Vector2(-1,0),"owned":false,"variant":i%4 if region_id == "ruins" else i%3}
	return population

func stop_navigation() -> void:
	player["path"] = []
	set_move_direction(Vector2.ZERO)

func nearby_npc(radius: float = 1.8) -> String:
	var nearest := ""
	var distance := radius
	for id in QuestCatalog.npcs(expedition.region):
		var gap := Vector2(player["cell"]).distance_to(QuestCatalog.cell(id))
		if gap <= distance and world.clear_segment(player["cell"],QuestCatalog.cell(id)):
			distance = gap
			nearest = id
	return nearest

func interaction_npc() -> String:
	# E and the actor prompt use one nearest-interaction policy.
	var id := nearby_npc()
	if id == "": return ""
	var cell: Vector2 = player["cell"]
	var distance := minf(cell.distance_to(WorldGrid.SPAWN),cell.distance_to(WorldGrid.SHRINE))
	var nearest_world := distance if distance <= 2.2 else INF
	for site in WorldContent.waypoints(expedition.region) + WorldContent.resources(expedition.region):
		distance = cell.distance_to(WorldContent.cell(site))
		if distance <= 1.8: nearest_world = minf(nearest_world,distance)
	if expedition.region == "realm":
		for point in ExpeditionModel.PLOTS:
			distance = cell.distance_to(point)
			if distance <= 1.4: nearest_world = minf(nearest_world,distance)
		for point in ExpeditionModel.PENS:
			distance = cell.distance_to(point)
			if distance <= 1.6: nearest_world = minf(nearest_world,distance)
	return id if cell.distance_to(QuestCatalog.cell(id)) < nearest_world else ""

func can_talk(npc_id: String) -> Dictionary:
	if bool(player["dead"]): return _denied("DEAD")
	if combat_left > 0 or not capture.is_empty(): return _denied("IN_COMBAT")
	var npc := QuestCatalog.npc(npc_id)
	if npc.is_empty() or npc["region"] != expedition.region: return _denied("NPC_UNAVAILABLE")
	if Vector2(player["cell"]).distance_to(QuestCatalog.cell(npc_id)) > 1.8 or not world.clear_segment(player["cell"],QuestCatalog.cell(npc_id)):
		return _denied("NPC_TOO_FAR")
	return {"ok":true}

func talk_to(npc_id: String) -> Dictionary:
	var result := can_talk(npc_id)
	if not bool(result["ok"]): return result
	stop_navigation()
	_emit("npc_talk",player["cell"],{"npc":npc_id,"persistent":true})
	return {"ok":true}

func quest_command(command: String, npc_id: String, id: String) -> Dictionary:
	var definition := QuestCatalog.quest(id)
	if definition.is_empty(): return _denied("BAD_QUEST")
	if command == "track":
		if id not in quests.accepted or id in quests.claimed: return _denied("QUEST_UNAVAILABLE")
		quests.tracked = id
		quests.revision += 1
		_emit("quest_tracked",player["cell"],{"persistent":true})
		return {"ok":true}
	var access := can_talk(npc_id)
	if not bool(access["ok"]): return access
	if command == "accept":
		if definition["giver"] != npc_id or not quests.available(id): return _denied("QUEST_UNAVAILABLE")
		quests.accepted.append(id)
		quests.tracked = id
		quests.revision += 1
		_emit("quest_accepted",player["cell"],{"quest":id,"text":"Đã nhận: " + str(definition["title"]),"persistent":true})
		return {"ok":true}
	if command != "claim" or definition["turn_in"] != npc_id or not quests.ready(id,self): return _denied("QUEST_NOT_READY")
	var delivery: Dictionary = definition.get("delivery",{})
	if not CultivationActions.affordable(self,delivery): return _denied("QUEST_NOT_READY")
	if not delivery.is_empty(): CultivationActions.pay(self,delivery)
	# Mark claimed before awarding. Repeated clicks or reopened dialogue cannot pay twice.
	quests.claimed.append(id)
	quests.revision += 1
	if quests.tracked == id:
		quests.tracked = ""
		for active in quests.accepted:
			if active not in quests.claimed:
				quests.tracked = active
				break
	var reward: Dictionary = definition["reward"]
	for key in reward:
		if key == "silver": player["currency"] = int(player["currency"]) + int(reward[key])
		elif key == "xp": player["xp"] = int(player["xp"]) + int(reward[key])
		else: inventory.reward_material(key,int(reward[key]))
	_check_level()
	_emit("npc_quest_complete",player["cell"],{"quest":id,"text":"Hoàn thành: " + str(definition["title"]) + " • " + QuestCatalog.reward_text(reward,definition.get("unlocks",[])),"persistent":true})
	return {"ok":true}

func journey_command(command: String, args: Dictionary = {}) -> Dictionary:
	return JourneyActions.perform(self,command,args)

func _discover_locations() -> void:
	if bool(player["dead"]): return
	for site in WorldContent.waypoints(expedition.region) + WorldContent.camps(expedition.region):
		if site["id"] in journey.discovered: continue
		var radius := 2.2 if site.get("kind","") == "waypoint" else 6.5
		if Vector2(player["cell"]).distance_to(WorldContent.cell(site)) <= radius:
			journey.discovered.append(site["id"])
			journey.revision += 1
			_emit("discovery",player["cell"],{"text":"Đã khám phá: " + str(site["name"]),"persistent":true})

func nearby_resource() -> String:
	var best := ""
	var distance := 1.8
	for site in WorldContent.resources(expedition.region):
		var gap := Vector2(player["cell"]).distance_to(WorldContent.cell(site))
		if gap <= distance and world.clear_segment(player["cell"],WorldContent.cell(site)):
			distance = gap
			best = site["id"]
	return best
