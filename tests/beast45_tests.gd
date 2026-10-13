extends SceneTree
var checks: Array[Dictionary] = []
var failures := 0
var geometry_probes := 0
var bone_probes := 0
var max_bone_error := 0.0
var max_stance_slip := 0.0
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2);return
	_run.call_deferred()
func check(ok: bool, name: String) -> void:
	checks.append({"name":name,"passed":ok})
	if not ok: failures+=1;printerr("FAIL: ",name)
func subject(species: String, index: int = 0) -> Dictionary:
	var spec := Bestiary.species(species)
	return {"id":"subject","species":species,"wild":true,"camp":"f_bamboo","cell":Vector2(38,20),"spawn":Vector2(38,20),"aim":Vector2(39,20),"facing":Vector2.RIGHT,"state":"idle","dead":false,"hp":float(spec["hp"]),"max_hp":float(spec["hp"]),"path":[],"attack_index":index,"windup_left":0.0,"attack_left":0.0,"slow_left":0.0,"repath_left":0.0,"wander_left":2.0,"owned":false,"attack_age":100.0,"attack_geometry":{}}
func _run() -> void:
	var sim := LocalAuthority.new()
	for x in range(34,46):
		for y in range(15,27):
			sim.world.blocked.erase(Vector2i(x,y));sim.world.nav.set_point_solid(Vector2i(x,y),false)
	for species in Bestiary.all():
		var spec := Bestiary.species(species)
		for ability in range(spec["abilities"].size()):
			var mob := subject(species,ability)
			var attack := Bestiary.attack(mob)
			var name: String = species+"/"+str(ability)
			sim.mobs={"subject":mob};sim.player["cell"]=Vector2(39,20);sim.player["hp"]=200.0;sim.player["dead"]=false;sim.player["shield"]=0.0
			WildlifeAI.step(sim,"subject",.01)
			check(mob["state"]=="windup" and sim.player["hp"]==200,name+" anticipates without damage")
			var geometry: Dictionary = mob["attack_geometry"].duplicate(true)
			WildlifeAI.step(sim,"subject",float(attack["windup"])-.01)
			check(sim.player["hp"]==200,name+" cannot hit before contact")
			WildlifeAI.step(sim,"subject",.02)
			check(sim.player["hp"]==200-int(attack["damage"]) and mob["state"]=="recovery",name+" contact hits once and commits recovery")
			var at: Vector2 = mob["cell"]
			WildlifeAI.step(sim,"subject",.15)
			check(sim.player["hp"]==200-int(attack["damage"]) and mob["cell"]==at,name+" recovery cannot re-hit or chase")
			var strike: Dictionary={}
			for event in sim.drain_events():
				if event["kind"]=="beast_strike":strike=event
			check(strike.get("geometry",{}).get("kind","")==attack["style"] and strike.get("species","")==species,name+" VFX receives same footprint")
			mob=subject(species,ability);sim.mobs={"subject":mob};sim.player["cell"]=Vector2(39,20);sim.player["hp"]=200.0
			WildlifeAI.step(sim,"subject",.01)
			var locked: Vector2=mob["aim"]
			sim.player["cell"]=Vector2(39,24)
			WildlifeAI.step(sim,"subject",float(attack["windup"])+.01)
			check(mob["aim"]==locked and sim.player["hp"]==200,name+" aim locks and sideways dodge succeeds")
			# Interior samples compare rendered polygons to actual analytic hit shape.
			var mismatches:=0
			var polygons:=BeastAttackGeometry.polygons(geometry)
			for ix in range(-28,29):
				for iy in range(-28,29):
					var p:=Vector2(38.007,20.003)+Vector2(ix,iy)*.19
					var inside:=false
					for polygon in polygons:inside=inside or Geometry2D.is_point_in_polygon(p,polygon)
					if inside!=BeastAttackGeometry.contains(geometry,p):
						# Curve tessellation is inscribed; only subpixel boundary differences are allowed.
						var boundary:=100.0
						for polygon in polygons:
							for j in range(polygon.size()-1):boundary=minf(boundary,p.distance_to(Geometry2D.get_closest_point_to_segment(p,polygon[j],polygon[j+1])))
						if boundary>.006:mismatches+=1
					geometry_probes+=1
			check(mismatches==0,name+" warning polygon matches damage footprint within .192px")
			# Walls and resting areas block both direct resolution and windup.
			mob=subject(species,ability);sim.mobs={"subject":mob};sim.player["cell"]=Vector2(39,20);sim.player["hp"]=200.0
			sim.world._set_block(Vector2i(39,20))
			WildlifeAI.resolve_attack(sim,"subject")
			check(sim.player["hp"]==200 and sim.world.is_walkable(mob["cell"]),name+" terrain blocks damage and displacement")
			sim.world.blocked.erase(Vector2i(39,20));sim.world.nav.set_point_solid(Vector2i(39,20),false)
			mob["cell"]=WorldGrid.SPAWN+Vector2(3,0);mob["aim"]=WorldGrid.SPAWN;sim.player["cell"]=WorldGrid.SPAWN
			WildlifeAI.resolve_attack(sim,"subject")
			check(sim.player["hp"]==200,name+" direct resolve cannot bypass safe camp")
		_rig(species)
	check(max_bone_error<.0001,"All articulated legs preserve both bone lengths")
	check(max_stance_slip<.0001,"Stable gait keeps each stance foot planted in world coordinates")
	var output:={"passed":checks.size()-failures,"failed":failures,"geometry_probes":geometry_probes,"bone_probes":bone_probes,"maximum_bone_error":max_bone_error,"maximum_stance_slip":max_stance_slip,"checks":checks}
	FileAccess.open("res://artifacts/beast45_tests.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("BEAST45_TESTS ",checks.size()-failures,"/",checks.size()," footprint samples=",geometry_probes," legs=",bone_probes)
	quit(1 if failures else 0)
func _rig(species: String) -> void:
	var mob:=subject(species)
	var shape: String=Bestiary.species(species)["shape"]
	var count:=4 if shape=="spider" else (3 if shape in ["hornet","beetle"] else 2)
	for direction in range(8):
		mob["facing"]=Vector2.DOWN.rotated(direction*PI/4)
		for frame in range(32):
			var pose:=BeastMotion.pose(mob,frame*.08,frame*TAU/32,.8,false,0,false,0)
			for i in range(count):
				for side in [-1,1]:
					var joints:=BeastMotion.leg(pose,lerpf(-11,11,float(i)/maxf(1,count-1)),side,i,count)
					var lengths:=BeastMotion.bone_lengths(shape,i)
					max_bone_error=maxf(max_bone_error,maxf(absf(joints[0].distance_to(joints[1])-lengths.x),absf(joints[1].distance_to(joints[2])-lengths.y)))
					bone_probes+=1
	# Anticipation and hit recoil move the body over fixed support feet.
	for kind in ["windup","hit","strike"]:
		mob["state"]="windup" if kind=="windup" else "idle"
		mob["windup_left"]=float(Bestiary.species(species)["windup"])*.3
		mob["attack_age"]=.04 if kind=="strike" else 100.0
		var p:=BeastMotion.pose(mob,0,0,0,false,.12 if kind=="hit" else 0,false,0)
		var joints:=BeastMotion.leg(p,-11,-1,0,count)
		check(absf(joints[2].x+float(p["body_shift"])+11+(count-1)*1.5 if shape in ["spider","hornet","beetle"] else joints[2].x+float(p["body_shift"])+11)<.001,species+" "+kind+" keeps support feet grounded")
	mob["state"]="idle";mob["attack_age"]=100.0
	for weight in [.3,.6,1.0]:
		var a:=BeastMotion.pose(mob,0,TAU*.1,weight,false,0,false,0)
		var b:=BeastMotion.pose(mob,0,TAU*.4,weight,false,0,false,0)
		var first:=BeastMotion.leg(a,-11,-1,0,count)[2]
		var second:=BeastMotion.leg(b,-11,-1,0,count)[2]
		var scale_value:=BeastMotion.body_scale(mob)
		var advancement:=BeastMotion.stride_length(weight)*scale_value*.3
		max_stance_slip=maxf(max_stance_slip,absf(second.x*scale_value+advancement-first.x*scale_value))
