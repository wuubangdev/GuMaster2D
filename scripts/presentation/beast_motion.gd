class_name BeastMotion
extends RefCounted
## Height-aware cutout rig. Ground feet and joints are solved before projection;
## changing heading never rotates the vertical axis of an animal onto the floor.
static func body_scale(state: Dictionary) -> float:
	var species := str(state.get("species", "wolf"))
	var spec := Bestiary.species(species)
	if spec.get("elite", false):
		return 1.05 if spec.get("shape", "") == "wolf" else 1.02
	return {"wolf": .72, "boar": .77, "spider": .72, "hornet": .76, "toad": .76, "beetle": .76}.get(str(spec.get("shape", "wolf")), .75)

static func bone_lengths(shape: String, index: int) -> Vector2:
	match shape:
		"wolf": return Vector2(9.4, 8.8)
		"boar": return Vector2(9.8, 8.8)
		"toad": return Vector2(9.0, 7.0) if index == 0 else Vector2(7.4, 6.6)
		"spider": return Vector2(10.0, 9.5)
		"hornet": return Vector2(9.0, 8.0)
		"beetle": return Vector2(9.3, 8.7)
	return Vector2(9.4, 8.8)

static func stride_length(motion: float) -> float:
	return maxf(.3,10.4/.62*clampf(motion,0,1))

static func pose(state: Dictionary, phase: float, stride: float, motion: float, reduced: bool, flash: float, fallen: bool, death_age: float) -> Dictionary:
	var species: String = state.get("species","wolf")
	var spec := Bestiary.species(species)
	var facing: Vector2 = state.get("facing",Vector2.RIGHT)
	if facing.length_squared() < .001: facing = Vector2.RIGHT
	var load := 0.0
	if state.get("state","") == "windup" and not fallen:
		load = smoothstep(0,1,1-float(state.get("windup_left",0))/float(state.get("windup_duration",spec["windup"])))
	var age := float(state.get("attack_age",100.0))
	var strike := exp(-age*12.0) if age < .6 and not fallen else 0.0
	var settle := sin(minf(1,age/.42)*PI)*exp(-age*4) if age < .6 and not fallen else 0.0
	var death := smoothstep(0,.52,death_age) if fallen else 0.0
	var gait := 0.0 if reduced or fallen or load>0 or state.get("state","") == "recovery" else clampf(motion,0,1)
	var breath := sin(phase*2.4)*.35 if not reduced and not fallen else 0.0
	var body_height := 16.0
	match spec["shape"]:
		"spider": body_height=10
		"hornet": body_height=24
		"toad": body_height=9
		"beetle": body_height=12
	var body_bob := -absf(sin(stride))*1.15*gait
	var hurt := 0.0 if reduced or fallen else sin(clampf(flash/.19,0,1)*PI)
	var style: String = state.get("last_attack",{}).get("style",spec["style"])
	if reduced: strike=0; settle=0; breath=0
	var crouch := load*3.2 + settle*1.7
	var lift := strike*(3.0 if style == "stomp" else 1.2)
	return {"species":species,"shape":spec["shape"],"facing":facing.normalized(),"side":facing.normalized().orthogonal(),"stride":stride,"gait":gait,"load":load,"strike":strike,"settle":settle,"death":death,"height":maxf(2,(body_height+body_bob+breath-crouch+lift)*(1-death*.82)),"head_shift":-load*2.5+strike*5-hurt*2.5,"head_lift":-load*1.2+strike*2,"jaw":load*.7+strike*1.9,"phase":phase,"reduced":reduced,"flash":flash,"body_shift":-load*1.1+strike*1.5-hurt*1.2,"style":style}

static func point(p: Vector3, pose_data: Dictionary) -> Vector2:
	var ground: Vector2 = Vector2(pose_data["facing"])*(p.x+float(pose_data["body_shift"]))+Vector2(pose_data["side"])*p.y
	return ground+Vector2(0,-p.z)

static func leg(pose_data: Dictionary, x: float, side: float, index: int, count: int = 2) -> Array[Vector3]:
	var phase: float = fposmod(float(pose_data["stride"])/TAU+index*.5+(0.5 if side>0 else 0.0),1)
	# 62% of a cycle is a planted stance; the returning paw lifts along a smooth arc.
	var stance := .62
	var forward := lerpf(5.2,-5.2,phase/stance) if phase < stance else lerpf(-5.2,5.2,smoothstep(0,1,(phase-stance)/(1-stance)))
	var lift := 0.0 if phase < stance else pow(sin(PI*(phase-stance)/(1-stance)),2)*4.0
	forward *= float(pose_data["gait"])
	lift *= float(pose_data["gait"])
	var insect: bool = pose_data["shape"] in ["spider","hornet","beetle"]
	var width := 7.0 if not insect else 9.0
	var spread := 9.0 if not insect else (21.0 if pose_data["shape"] == "spider" else 16.0)
	if pose_data["shape"] == "toad": spread=15.5 if index==0 else 13.0
	var height: float = pose_data["height"]
	var hip := Vector3(x,side*width,height)
	var foot := Vector3(x+forward,side*spread,lift)
	if insect: foot.x += (index-(count-1)*.5)*3
	if pose_data["shape"] == "hornet": foot.z+=12
	var bend := Vector3(-1 if x>0 else 1,side*.35,0)
	if insect: bend = Vector3((index-(count-1)*.5)*.4,side,-.05)
	var lengths := bone_lengths(str(pose_data["shape"]), index)
	if float(pose_data["death"])>0:
		foot = foot.lerp(Vector3(x-3,side*(width+3),2),float(pose_data["death"]))
	# Body anticipation/flinch shifts the hip, not the planted foot. The
	# projection applies body_shift, so compensate only the ground target.
	foot.x-=float(pose_data["body_shift"])
	return solve(hip,foot,lengths.x,lengths.y,bend)

static func solve(hip: Vector3, target: Vector3, upper: float, lower: float, bend: Vector3) -> Array[Vector3]:
	var delta := target-hip
	var distance := clampf(delta.length(),.01,upper+lower-.025)
	var axis := delta.normalized() if delta.length()>.001 else Vector3.DOWN
	var normal := bend-axis*bend.dot(axis)
	if normal.length_squared()<.001: normal=axis.cross(Vector3.FORWARD)
	normal=normal.normalized()
	var along := (upper*upper-lower*lower+distance*distance)/(2*distance)
	var offset := sqrt(maxf(0,upper*upper-along*along))
	return [hip,hip+axis*along+normal*offset,hip+axis*distance]
