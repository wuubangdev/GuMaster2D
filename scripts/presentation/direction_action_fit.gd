extends RefCounted
## Authored, direction-first fitting in native source space. Arm x is outward
## from that shoulder; y is screen-down. Both are fractions of that arm's
## unchanged upper + lower bone length. Body offsets are native drawing units.
## A view enters this table only after its own rest and action review.
## Preparation stays near .56 of native arm reach: the former .27-.33 targets
## always hit the 135 degree elbow stop and made every load a cramped hook.

const SOUTH := {
	"attack:sword": {
		"id":"south/sword/v1",
		"arm_R":[Vector2(.27,.49),Vector2(-.08,.985),Vector2(-.36,.85)],
		"pole_outward_R":1.0,
		"arm_L":[Vector2(.10,.93),Vector2(.08,.975),Vector2(.12,.945)],
		"axes":[Vector2(.25,-1),Vector2(-.15,1),Vector2(-.5,.9)],
		"body":[Vector2(-.55,.7),Vector2(.35,1.6),Vector2(.2,1.0)],
		"rotation":[-.05,.035,.02]
	},
	"gather": {
		"id":"south/gather/v1",
		"arm_R":[Vector2(.13,.86),Vector2(-.10,.985),Vector2(-.20,.65)],
		"arm_L":[Vector2(.10,.93),Vector2(.04,.975),Vector2(.08,.94)],
		"body":[Vector2(.1,2.9),Vector2(-.25,6.4),Vector2(-.15,5.9)],
		"rotation":[.012,.026,.018]
	},
	"mine": {
		"id":"south/mine/v1",
		"arm_R":[Vector2(.34,.45),Vector2(-.04,.985),Vector2(-.20,.92)],
		"pole_outward_R":1.0,
		"arm_L":[Vector2(.10,.92),Vector2(.06,.97),Vector2(.08,.94)],
		"axes":[Vector2(.20,-1),Vector2(-.12,1),Vector2(-.3,.95)],
		"body":[Vector2(-.45,.6),Vector2(.15,3.9),Vector2(.1,3.2)],
		"rotation":[-.045,.035,.022]
	},
	"defend": {"id":"south/defend/v1","guard_L":Vector2(-.27,.31),"guard_R":Vector2(-.32,.28)}
}

# Separate authored targets for every remaining drawing. Similar numbers are
# intentional where the pose shares a beat; each row still uses that drawing's
# own shoulder, bone lengths, rest flexion and occlusion, never a flipped mesh.
const VIEWS := {
	1:{"name":"southwest","sword":[Vector2(.27,.49),Vector2(.58,.78),Vector2(.30,.89)],"sword_pole":1.0,
		"support":[Vector2(.08,.93),Vector2(.14,.95),Vector2(.10,.945)],"sword_axes":[Vector2(.25,-1),Vector2(.72,.72),Vector2(.4,.9)],
		"attack_body":[Vector2(.45,.5),Vector2(-.85,1.25),Vector2(-.4,.8)],"attack_rotation":[.04,-.045,-.025],
		"gather":[Vector2(.14,.83),Vector2(.46,.86),Vector2(.16,.65)],"gather_body":[Vector2(-.1,1.8),Vector2(-.6,4.5),Vector2(-.25,3.8)],"gather_rotation":[-.04,-.09,-.05],
		"mine":[Vector2(.34,.45),Vector2(.60,.75),Vector2(.45,.82)],"mine_pole":1.0,"mine_axes":[Vector2(.2,-1),Vector2(.65,.75),Vector2(.4,.9)],"mine_body":[Vector2(.3,.4),Vector2(-.6,2.7),Vector2(-.3,2.1)],"mine_rotation":[.035,-.065,-.04],"pick":Vector2(-.5,1)},
	2:{"name":"west","sword":[Vector2(-.13,.55),Vector2(.99,.08),Vector2(.53,.70)],"sword_pole":-1.0,
		"support":[Vector2(.06,.92),Vector2(.18,.92),Vector2(.10,.95)],"sword_axes":[Vector2(-.80,-.75),Vector2(1,0),Vector2(.75,.85)],
		"attack_body":[Vector2(.65,.35),Vector2(-1.35,.65),Vector2(-.8,.45)],"attack_rotation":[.085,-.105,-.06],
		"gather":[Vector2(.15,.64),Vector2(.65,.74),Vector2(.30,.60)],"gather_body":[Vector2(-.15,1.5),Vector2(-.8,3.8),Vector2(-.3,3.0)],"gather_rotation":[-.08,-.19,-.11],
		"mine":[Vector2(.22,.52),Vector2(.78,.56),Vector2(.64,.69)],"mine_pole":1.0,"mine_axes":[Vector2(.1,-1),Vector2(.85,.60),Vector2(.70,.80)],"mine_body":[Vector2(.2,.4),Vector2(-.8,2.7),Vector2(-.4,2.0)],"mine_rotation":[.04,-.12,-.08],"pick":Vector2(-.65,1)},
	# NW reaches below the head, then outboard. An upward far-hand contact is
	# anatomically valid but disappears behind this drawing's large head.
	3:{"name":"northwest","sword":[Vector2(-.24,.51),Vector2(-.945,.06),Vector2(.15,.35)],"sword_pole":-1.0,
		"support":[Vector2(.10,.92),Vector2(.15,.93),Vector2(.11,.945)],"sword_axes":[Vector2(.20,-1),Vector2(-.65,-.76),Vector2(-.55,.40)],
		"attack_body":[Vector2(.35,.35),Vector2(-.65,1.1),Vector2(-.3,.65)],"attack_rotation":[.04,-.055,-.03],
		"gather":[Vector2(.14,.82),Vector2(-.985,.10),Vector2(.10,.56)],"gather_body":[Vector2(-.1,1.3),Vector2(-.6,3.7),Vector2(-.3,3.1)],"gather_rotation":[-.035,-.07,-.04],
		"mine":[Vector2(.35,.45),Vector2(-.40,-.56),Vector2(.08,.28)],"mine_pole":-1.0,"mine_axes":[Vector2(.2,-1),Vector2(-.65,-.75),Vector2(-.45,-.60)],"mine_body":[Vector2(.25,.35),Vector2(-.45,2.7),Vector2(-.25,2.1)],"mine_rotation":[.03,-.055,-.035],"pick":Vector2(.5,1)},
	4:{"name":"north","sword":[Vector2(.41,.39),Vector2(.68,-.58),Vector2(.60,.35)],"sword_pole":-1.0,
		"support":[Vector2(.10,.93),Vector2(.10,.975),Vector2(.12,.945)],"sword_axes":[Vector2(.40,-1),Vector2(.10,-1),Vector2(.70,.50)],
		"attack_body":[Vector2(-.4,.6),Vector2(.35,.85),Vector2(.15,.6)],"attack_rotation":[.04,-.05,-.025],
		"gather":[Vector2(.14,.84),Vector2(.32,-.72),Vector2(.18,.55)],"gather_body":[Vector2(0,1.3),Vector2(.2,3.5),Vector2(.1,3.0)],"gather_rotation":[-.012,-.028,-.016],
		"mine":[Vector2(.35,.45),Vector2(.45,-.72),Vector2(.38,.25)],"mine_pole":-1.0,"mine_axes":[Vector2(.2,-1),Vector2(.32,-1),Vector2(.4,-.65)],"mine_body":[Vector2(-.2,.3),Vector2(.2,2.5),Vector2(.15,1.8)],"mine_rotation":[.025,-.04,-.025],"pick":Vector2(.5,1)},
	5:{"name":"northeast","sword":[Vector2(.23,.52),Vector2(.56,-.58),Vector2(.60,.35)],"sword_pole":-1.0,
		"support":[Vector2(.10,.92),Vector2(.15,.93),Vector2(.11,.945)],"sword_axes":[Vector2(.20,-1),Vector2(.65,-.76),Vector2(.60,.40)],
		"attack_body":[Vector2(-.35,.35),Vector2(.65,1.1),Vector2(.3,.65)],"attack_rotation":[-.04,.055,.03],
		"gather":[Vector2(.14,.82),Vector2(.42,-.62),Vector2(.10,.56)],"gather_body":[Vector2(.1,1.3),Vector2(.6,3.7),Vector2(.3,3.1)],"gather_rotation":[.035,.07,.04],
		"mine":[Vector2(.35,.45),Vector2(.58,-.42),Vector2(.45,.28)],"mine_pole":-1.0,"mine_axes":[Vector2(.2,-1),Vector2(.65,-.75),Vector2(.45,-.60)],"mine_body":[Vector2(-.25,.35),Vector2(.45,2.7),Vector2(.25,2.1)],"mine_rotation":[-.03,.055,.035],"pick":Vector2(.5,1)},
	6:{"name":"east","sword":[Vector2(-.13,.55),Vector2(.99,.08),Vector2(.53,.70)],"sword_pole":-1.0,
		"support":[Vector2(.06,.92),Vector2(.18,.92),Vector2(.10,.95)],"sword_axes":[Vector2(-.80,-.75),Vector2(1,0),Vector2(.75,.85)],
		"attack_body":[Vector2(-.65,.35),Vector2(1.35,.65),Vector2(.8,.45)],"attack_rotation":[-.085,.105,.06],
		"gather":[Vector2(.15,.64),Vector2(.65,.74),Vector2(.30,.60)],"gather_body":[Vector2(.15,1.5),Vector2(.8,3.8),Vector2(.3,3.0)],"gather_rotation":[.08,.19,.11],
		"mine":[Vector2(.22,.52),Vector2(.78,.56),Vector2(.64,.69)],"mine_pole":1.0,"mine_axes":[Vector2(.1,-1),Vector2(.85,.60),Vector2(.70,.80)],"mine_body":[Vector2(-.2,.4),Vector2(.8,2.7),Vector2(.4,2.0)],"mine_rotation":[-.04,.12,.08],"pick":Vector2(.65,1)},
	7:{"name":"southeast","sword":[Vector2(.27,.49),Vector2(-.58,.78),Vector2(-.30,.89)],"sword_pole":1.0,
		"support":[Vector2(.08,.93),Vector2(-.10,.95),Vector2(.02,.945)],"sword_axes":[Vector2(.25,-1),Vector2(-.72,.72),Vector2(-.4,.9)],
		"attack_body":[Vector2(-.45,.5),Vector2(.85,1.25),Vector2(.4,.8)],"attack_rotation":[-.04,.045,.025],
		"gather":[Vector2(.14,.83),Vector2(-.46,.86),Vector2(-.16,.65)],"gather_body":[Vector2(.1,1.8),Vector2(.6,4.5),Vector2(.25,3.8)],"gather_rotation":[.04,.09,.05],
		"mine":[Vector2(.34,.45),Vector2(-.60,.75),Vector2(-.45,.82)],"mine_pole":1.0,"mine_axes":[Vector2(.2,-1),Vector2(-.65,.75),Vector2(-.4,.9)],"mine_body":[Vector2(-.3,.4),Vector2(.6,2.7),Vector2(.3,2.1)],"mine_rotation":[-.035,.065,.04],"pick":Vector2(-.5,1)}
}
static var _profiles: Dictionary = {}

static func profile(direction: int, action: String, weapon: String) -> Dictionary:
	if direction==0: return SOUTH.get(action+":"+weapon,SOUTH.get(action,{}))
	if not VIEWS.has(direction): return {}
	var key := "%d/%s/%s" % [direction,action,weapon]
	if _profiles.has(key): return _profiles[key]
	var view: Dictionary = VIEWS[direction]
	var result := {"id":str(view["name"])+"/"+action+"/v1"}
	if action=="attack" and weapon=="sword":
		result.merge({"arm_R":view["sword"],"arm_L":view["support"],"axes":view["sword_axes"],"pole_outward_R":view["sword_pole"],"body":view["attack_body"],"rotation":view["attack_rotation"]})
		if direction==7: result["timing"]=Vector4(.34,.56,.14,.16)
		elif direction==4: result["timing"]=Vector4(.34,.56,.15,.17)
	elif action in ["gather","mine"]:
		result.merge({"arm_R":view[action],"arm_L":view["support"],"body":view[action+"_body"],"rotation":view[action+"_rotation"]})
		if action=="mine": result.merge({"axes":view["mine_axes"],"pole_outward_R":view["mine_pole"]})
	elif action not in ["idle","walk","run","defend"]: return {}
	_profiles[key]=result
	return result

static func arm_targets(profile_data: Dictionary, side: String, root: Vector2, reach: float, outward: float) -> Array:
	var result := []
	for key: Vector2 in profile_data["arm_"+side]: result.append(root+key*Vector2(outward,1)*reach)
	return result

static func timing(action: String) -> Vector4:
	if action=="gather": return Vector4(.50,.64,.16,.18)
	if action=="mine": return Vector4(.48,.64,.28,.30)
	return Vector4(.34,.56,.16,.18)

static func body(profile_data: Dictionary, action: String, phase: float) -> Vector2:
	if not profile_data.has("body"): return Vector2.ZERO
	var t: Vector4 = profile_data.get("timing",timing(action))
	return GuCharacterActionMotion.track(Vector2.ZERO,profile_data["body"][0],profile_data["body"][1],profile_data["body"][2],phase,t.x,t.y,t.z,t.w)

static func rotation(profile_data: Dictionary, action: String, phase: float) -> float:
	if not profile_data.has("rotation"): return 0.0
	var t: Vector4 = profile_data.get("timing",timing(action))
	var values: Array = profile_data["rotation"]
	return GuCharacterActionMotion.track(Vector2.ZERO,Vector2(values[0],0),Vector2(values[1],0),Vector2(values[2],0),phase,t.x,t.y,t.z,t.w).x

static func pick_axis(direction: int, outward: float) -> Vector2:
	# The prospecting pick is hidden at rest. Its authored south socket points
	# out through the palm, so elbow extension drives the head toward the rock.
	return Vector2(outward*.50,1).normalized() if direction==0 else Vector2(VIEWS[direction]["pick"]).normalized()
