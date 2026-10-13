class_name WildlifeAI
extends RefCounted
## Camp-bound enemies: aim locks at windup, damage occurs once, recovery is committed.
static func step(sim: RefCounted, id: String, delta: float) -> void:
	var mob: Dictionary = sim.mobs[id]
	var spec := Bestiary.species(mob["species"])
	if bool(mob["dead"]):
		mob["respawn_left"] = maxf(0,float(mob["respawn_left"])-delta)
		if mob["respawn_left"] <= 0:
			mob.merge({"dead":false,"hp":mob["max_hp"],"cell":mob["spawn"],"state":"idle","path":[],"owned":false,"windup_left":0.0,"slow_left":0.0,"attack_left":0.0,"attack_index":0,"attack_age":100.0,"attack_geometry":{},"last_attack":{}},true)
		return
	for timer in ["slow_left","attack_left","repath_left"]:
		mob[timer] = maxf(0,float(mob[timer])-delta)
	mob["attack_age"] = minf(100,float(mob.get("attack_age",100.0))+delta)
	var at: Vector2 = mob["cell"]
	var target: Vector2 = sim.player["cell"]
	var distance := at.distance_to(target)
	var home_distance := at.distance_to(mob["spawn"])
	# Expanded maps can contain hundreds of dormant animals; remote camps do not
	# run waypoint-safezone scans or pathfinding every simulation tick.
	if distance > 14 and home_distance <= .15:
		mob.merge({"state":"idle","hp":mob["max_hp"],"owned":false,"path":[],"windup_left":0.0,"attack_geometry":{}},true)
		return
	var returning: bool = mob["state"] == "leash" or bool(sim.player["dead"]) or sim.world.is_safe(target) or sim.world.is_safe(at) or home_distance > 8 or distance > 14
	if returning:
		mob["windup_left"] = 0.0
		mob["attack_geometry"] = {}
		if home_distance <= .15:
			mob.merge({"state":"idle","hp":mob["max_hp"],"owned":false,"path":[]},true)
			return
		mob["state"] = "leash"
		if mob["repath_left"] <= 0:
			mob["path"] = sim.world.path(at,mob["spawn"])
			mob["repath_left"] = 1.2
		sim._advance_actor(mob,2.8,delta)
		return
	if float(mob["windup_left"]) > 0:
		mob["windup_left"] = maxf(0,float(mob["windup_left"])-delta)
		if mob["windup_left"] <= 0:
			var attack := Bestiary.attack(mob)
			resolve_attack(sim,id)
			mob["attack_left"] = float(attack["recovery"])
			mob["state"] = "recovery"
			mob["attack_index"] = int(mob.get("attack_index",0))+1
		return
	# A deliberate recovery window lets the player punish a dodged heavy attack.
	if mob["state"] == "recovery" and float(mob["attack_left"]) > 0:
		mob["path"] = []
		return
	var attack := Bestiary.attack(mob)
	var attack_range := float(attack["range"])
	if distance <= attack_range and sim.world.clear_segment(at,target):
		mob["path"] = []
		if mob["attack_left"] <= 0:
			mob["state"] = "windup"
			mob["windup_left"] = float(attack["windup"])
			mob["aim"] = safe_sweep(sim.world,at,at.move_toward(target,attack_range))
			var facing := Vector2(mob["aim"])-at
			if facing.length_squared() > .001: mob["facing"] = facing.normalized()
			mob["attack_geometry"] = BeastAttackGeometry.build(mob,attack)
		return
	if distance < 6 or bool(mob["owned"]):
		mob["state"] = "chase"
		if mob["repath_left"] <= 0:
			mob["path"] = sim.world.path(at,target)
			mob["repath_left"] = .9
		sim._advance_actor(mob,float(spec["speed"])*(.7 if mob["slow_left"] > 0 else 1.0),delta)
	else:
		mob["state"] = "idle"
		mob["wander_left"] = float(mob["wander_left"])-delta
		if mob["wander_left"] <= 0:
			mob["wander_left"] = sim.rng.randf_range(4,8)
			var point: Vector2 = Vector2(mob["spawn"])+Vector2(sim.rng.randi_range(-1,1),sim.rng.randi_range(-1,1))
			if not sim.world.is_safe(point): mob["path"] = sim.world.path(at,point)
		sim._advance_actor(mob,.45,delta)

static func safe_sweep(world: WorldGrid, origin: Vector2, aim: Vector2) -> Vector2:
	var end := world.sweep(origin,aim)
	var steps := maxi(1,ceili(origin.distance_to(end)/.06))
	var previous := origin
	for i in range(1,steps+1):
		var point := origin.lerp(end,float(i)/steps)
		if world.is_safe(point): break
		previous = point
	return previous

static func resolve_attack(sim: RefCounted, id: String) -> void:
	var mob: Dictionary = sim.mobs[id]
	if bool(mob["dead"]) or bool(sim.player["dead"]): return
	var attack := Bestiary.attack(mob)
	var origin: Vector2 = mob["cell"]
	var player: Vector2 = sim.player["cell"]
	if sim.world.is_safe(origin) or sim.world.is_safe(player): return
	var geometry: Dictionary = mob.get("attack_geometry",{})
	if geometry.is_empty(): geometry = BeastAttackGeometry.build(mob,attack)
	else: geometry = geometry.duplicate(true)
	if attack["style"] == "charge":
		geometry["aim"] = safe_sweep(sim.world,origin,geometry["aim"])
		mob["cell"] = geometry["aim"]
	if BeastAttackGeometry.contains(geometry,player) and sim.world.clear_segment(origin,player):
		sim._damage_player(int(attack["damage"]))
	mob["attack_age"] = 0.0
	mob["last_attack"] = attack
	mob["attack_geometry"] = {}
	sim._emit("beast_strike",geometry["aim"],{"target":id,"source":id,"species":mob["species"],"from":origin,"to":geometry["aim"],"style":attack["style"],"radius":geometry["radius"],"range":geometry["range"],"half_angle":geometry["half_angle"],"geometry":geometry,"skill_name":attack.get("name","")})
