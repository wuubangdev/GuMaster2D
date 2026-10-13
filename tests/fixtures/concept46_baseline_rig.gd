extends RefCounted
## Native source proportions, hierarchical attachment and constrained bones.
## Combat uses native grip targets and a shoulder/elbow pole. The palm is
## rigid around its cuff pivot; bounded sword attacks share its local roll.

const ARM_MAX_FLEX := 2.35619449 # 135 degrees; zero is a straight elbow.
const WRIST_LIMIT := .85
const ATTACK_RECOVERY := .56
const SUPPORT_CONTACT := .38
const SUPPORT_RECOVERY := .62
const SUPPORT_WRIST_LIMIT := .22

static func _ease(a: float, b: float, phase: float) -> float:
	var t := clampf((phase-a)/(b-a),0,1)
	return t*t*(3-2*t)

static func attack_track(neutral: Vector2, load: Vector2, strike: Vector2, follow: Vector2, phase: float, contact: float = .34, recovery: float = ATTACK_RECOVERY, load_end: float = .16, release: float = .18) -> Vector2:
	return GuCharacterActionMotion.track(neutral,load,strike,follow,phase,contact,recovery,load_end,release)

static func arm_reach(upper: float, lower: float, flex: float) -> float:
	return sqrt(upper*upper+lower*lower+2*upper*lower*cos(flex))

static func solve_arm(root: Vector2, target: Vector2, upper: float, lower: float, pole: float) -> PackedVector2Array:
	var reach := target-root
	var axis := reach.normalized() if reach.length_squared()>.000001 else Vector2.DOWN
	var distance := clampf(reach.length(),arm_reach(upper,lower,ARM_MAX_FLEX),arm_reach(upper,lower,.14))
	return solve_limb(root,root+axis*distance,upper,lower,pole)

static func _blend_arm(source: PackedVector2Array, solved: PackedVector2Array, pose: Dictionary, weight: float) -> PackedVector2Array:
	var rest := (source[1]-source[0]).rotated(float(pose["torso_rotation"]))
	var target := solved[1]-solved[0]
	var upper_angle := lerp_angle(rest.angle(),target.angle(),weight)
	var rest_flex := (source[1]-source[0]).angle_to(source[2]-source[1])
	var target_flex := target.angle_to(solved[2]-solved[1])
	var flex := lerpf(rest_flex,target_flex,weight)
	var root := body_point(pose,source[0])
	var elbow := root+Vector2.from_angle(upper_angle)*source[0].distance_to(source[1])
	return PackedVector2Array([root,elbow,elbow+Vector2.from_angle(upper_angle+flex)*source[1].distance_to(source[2])])

static func _keyed_arm(source: PackedVector2Array, targets: Array, pose: Dictionary, phase: float, pole: float, contact: float = .34, recovery_phase: float = ATTACK_RECOVERY, load_end: float = .16, release: float = .18) -> PackedVector2Array:
	var rest_upper := (source[1]-source[0]).rotated(float(pose["torso_rotation"]))
	var rest_flex := (source[1]-source[0]).angle_to(source[2]-source[1])
	var keys := [Vector2(rest_upper.angle(),rest_flex)]
	var previous := rest_upper
	for target: Vector2 in targets:
		var chain := solve_arm(body_point(pose,source[0]),body_point(pose,target),source[0].distance_to(source[1]),source[1].distance_to(source[2]),pole)
		var upper := chain[1]-chain[0]
		var angle := Vector2(keys[-1]).x+previous.angle_to(upper)
		keys.append(Vector2(angle,upper.angle_to(chain[2]-chain[1])))
		previous=upper
	var recovery := Vector2(Vector2(keys[-1]).x+previous.angle_to(rest_upper),rest_flex)
	var angles := attack_track(keys[0],keys[1],keys[2],keys[3],phase,contact,recovery_phase,load_end,release)
	if phase>=recovery_phase: angles=Vector2(keys[3]).lerp(recovery,_ease(recovery_phase,1,phase))
	var root := body_point(pose,source[0])
	var elbow := root+Vector2.from_angle(angles.x)*source[0].distance_to(source[1])
	return PackedVector2Array([root,elbow,elbow+Vector2.from_angle(angles.x+angles.y)*source[1].distance_to(source[2])])

static func _weapon_source_axis(view: Dictionary, look: Dictionary) -> Vector2:
	if str(look["weapon"])=="spear":
		return Vector2.UP.rotated(signf(_joint_list(view,"arm_R")[2].x)*.40)
	var hand := _joint_list(view,"arm_R")[2]
	var mirror := -1.0 if hand.x>0 else 1.0
	var weapon: Dictionary = GuConceptCharacterArt.manifest()["sword"]
	return (GuConceptCharacterArt._point(weapon["tip"])-GuConceptCharacterArt._point(weapon["pivot"]))*Vector2(mirror,1)

static func forearm_delta(pose: Dictionary, view: Dictionary) -> float:
	var source := _joint_list(view,"arm_R")
	var actual: PackedVector2Array = pose["arm_R"]
	return (source[2]-source[1]).angle_to(actual[2]-actual[1])

static func source_wrist(source: PackedVector2Array) -> Vector2:
	# Authored endpoint 2 is the centre of the gripping palm, not the wrist.
	# Keep that legacy IK chain's proportions; articulate the short palm
	# separately around a cuff landmark derived in native drawing units.
	var forearm := source[2]-source[1]
	return source[2]-forearm.normalized()*minf(1.35,forearm.length()*.32)

static func hand_vertex(point: Vector2, source: PackedVector2Array, chain: PackedVector2Array, turn: float) -> Vector2:
	var wrist := source_wrist(source)
	var delta := (source[2]-source[1]).angle_to(chain[2]-chain[1])
	var pivot := chain[1]+(wrist-source[1]).rotated(delta)
	return pivot+(point-wrist).rotated(delta+turn)

static func _set_weapon_axis(pose: Dictionary, view: Dictionary, look: Dictionary, axis: Vector2, limit: bool = true) -> void:
	var held := _weapon_source_axis(view,look).rotated(forearm_delta(pose,view))
	var wrist := held.angle_to(axis)
	pose["weapon_wrist"] = clampf(wrist,-WRIST_LIMIT,WRIST_LIMIT) if limit else wrist

static func bind_weapon(pose: Dictionary, view: Dictionary, look: Dictionary, direction: int) -> void:
	# One attachment calculation is used after IK, turns, blends and secondary
	# motion. The weapon root includes the articulated palm offset; bounded
	# sword attacks share the same local roll as their visible hand mesh.
	for side in ["L","R"]:
		var source := _joint_list(view,"arm_"+side)
		var turn := 0.0
		if side=="R" and (str(look["weapon"])=="sword" or pose.get("harvest_action","")=="mine" or pose.get("held_prop","")=="pick"): turn=clampf(float(pose.get("weapon_wrist",0)),-WRIST_LIMIT,WRIST_LIMIT)
		elif side=="L" and str(look["weapon"])=="sword": turn=clampf(float(pose.get("support_wrist",0)),-SUPPORT_WRIST_LIMIT,SUPPORT_WRIST_LIMIT)
		pose["hand_rotation_"+side]=turn
		pose["wrist_"+side]=hand_vertex(source_wrist(source),source,pose["arm_"+side],turn)
		pose["grip_"+side]=hand_vertex(source[2],source,pose["arm_"+side],turn)
	# Keep the tool socket valid through an interrupted mine-to-walk blend.
	var aim := Vector2.DOWN.rotated(direction*PI/4)
	pose["tool_angle"]=Vector2(aim.x*.65,-1).angle()+PI/2+forearm_delta(pose,view)+float(pose["weapon_wrist"])
	pose["cloth_guides"]={}
	for side in ["L","R"]:
		pose["cloth_guides"][side]=GuConceptClothGuides.sample(_joint_list(view,"arm_"+side),pose["arm_"+side])
	var delta := forearm_delta(pose,view)+float(pose.get("weapon_wrist",0))
	var rest := GuIllustratedCharacterArt.sample("idle",0,direction,look,true)
	if str(look["weapon"])=="spear":
		pose["weapon_angle"] = _weapon_source_axis(view,look).angle()+PI/2+delta
		pose["weapon_rotation"] = float(pose["weapon_angle"])-float(rest["weapon_angle"])
	else:
		var mirror := -1.0 if _joint_list(view,"arm_R")[2].x>0 else 1.0
		pose["weapon_rotation"] = delta*mirror
		pose["weapon_angle"] = float(rest["weapon_angle"])+delta*mirror

static func _combat_arms(snapshot: Dictionary, pose: Dictionary, view: Dictionary, aim: Vector2) -> void:
	var phase := float(snapshot["phase"])
	var weapon := str(snapshot["appearance"]["weapon"])
	var torso: Vector2 = pose["rest_torso"]
	var active := _ease(0,.18,phase)*(1-_ease(.58,1,phase))
	var right_targets := []
	if weapon=="spear":
		_spear_arms(pose,view,snapshot["appearance"],aim,phase,active)
		return
	for side in ["L","R"]:
		var source := _joint_list(view,"arm_"+side)
		var upper := source[0].distance_to(source[1])
		var lower := source[1].distance_to(source[2])
		var reach := upper+lower
		var outward := signf(source[0].x-torso.x)
		var load: Vector2
		var strike: Vector2
		var follow: Vector2
		if side=="L":
			if weapon=="unarmed":
				# Keep the other fist protecting the chest during the punch.
				load=torso+Vector2(outward*3.5,-5.0)
				strike=torso+Vector2(outward*2.5-aim.x*.8,-6.5)
				follow=torso+Vector2(outward*3.2,-5.5)
			else:
				# A free hand counterbalances the sword instead of remaining
				# locked horizontally beside the waist. Side views trail behind
				# the release; frontal views open gently away from the hip.
				var frontal := absf(aim.y)
				load=source[0]+Vector2(-aim.x*.12,.76).lerp(Vector2(outward*.25,.75),frontal)*reach
				strike=source[0]+Vector2(-aim.x*.43,.76).lerp(Vector2(outward*.56,.66),frontal)*reach
				follow=source[0]+Vector2(-aim.x*.22,.81).lerp(Vector2(outward*.38,.80),frontal)*reach
		elif weapon=="unarmed":
			load=source[0]+Vector2(aim.x*.30+outward*.10*absf(aim.y),.62)*reach
			strike=source[0]+Vector2(aim.x*.92, .42 if aim.y>=0 else -.48)*reach
			if absf(aim.x)<.1:
				strike=source[0]+Vector2(-outward*.50,.38)*reach if aim.y>=0 else source[0]+Vector2(outward*.65,-.52)*reach
			follow=strike.lerp(load,.35)
		else:
			var frontal := absf(aim.y)
			# Coil toward the chest and behind the release line. Keep preparation
			# inside native reach rather than rushing an overhead 180-degree turn.
			var profile_load := Vector2(-aim.x*.12,.50)
			# Release through the target with an almost extended elbow. The
			# former short/downward target retained ~40 degrees of flexion at
			# contact, making the visible weapon arm look hooked in profile.
			var profile_strike := Vector2(aim.x*.99,.08)
			var profile_follow := Vector2(aim.x*.53,.70)
			var front_load := Vector2(outward*.45,.32)
			var front_strike := Vector2(-outward*.64,.40)
			var front_follow := Vector2(-outward*.32,.80)
			if aim.y<0:
				front_load=Vector2(outward*.32,.30)
				front_strike=Vector2(outward*.68,-.58)
				front_follow=Vector2(outward*.60,.35)
			load=source[0]+profile_load.lerp(front_load,frontal)*reach
			strike=source[0]+profile_strike.lerp(front_strike,frontal)*reach
			follow=source[0]+profile_follow.lerp(front_follow,frontal)*reach
		if side=="R": right_targets=[load,strike,follow]
		# Keys are solved in the native reach envelope, then interpolated in
		# shoulder + LOCAL elbow space. A Cartesian wrist path can cross the
		# shoulder, flip the pole or blend two valid bones into a reversed elbow.
		if side=="L" and weapon=="sword":
			# The free arm settles after the weapon, with a relaxed cuff roll.
			pose["arm_L"]=_keyed_arm(source,[load,strike,follow],pose,phase,-outward,SUPPORT_CONTACT,SUPPORT_RECOVERY)
			pose["support_wrist"]=attack_track(Vector2.ZERO,Vector2(outward*.08,0),Vector2(-outward*.18,0),Vector2(-outward*.06,0),phase,SUPPORT_CONTACT,SUPPORT_RECOVERY).x
		else:
			pose["arm_"+side]=_keyed_arm(source,[load,strike,follow],pose,phase,-outward)
	if weapon=="sword":
		var outward := signf(_joint_list(view,"arm_R")[0].x-torso.x)
		var front_load := Vector2(outward*.35,-1)
		var front_strike := Vector2(-outward*.80,.55)
		var front_follow := Vector2(-outward*.10,1)
		if aim.y<0:
			front_load=Vector2(outward*.40,-1)
			front_strike=Vector2(outward*.65,-.70)
			front_follow=Vector2(outward*.90,.45)
		var load := Vector2(-aim.x*.80,-.75).lerp(front_load,absf(aim.y)).normalized()
		var strike := Vector2(aim.x,aim.y*.40).lerp(front_strike,absf(aim.y)).normalized()
		var follow := Vector2(aim.x*.75,.85).lerp(front_follow,absf(aim.y)).normalized()
		var source_axis := _weapon_source_axis(view,snapshot["appearance"])
		var source := _joint_list(view,"arm_R")
		var wrist_keys := []
		for i in range(3):
			var chain := solve_arm(body_point(pose,source[0]),body_point(pose,right_targets[i]),source[0].distance_to(source[1]),source[1].distance_to(source[2]),-outward)
			var delta := (source[2]-source[1]).angle_to(chain[2]-chain[1])
			var axis: Vector2 = [load,strike,follow][i]
			wrist_keys.append(Vector2(clampf(source_axis.rotated(delta).angle_to(axis),-WRIST_LIMIT,WRIST_LIMIT),0))
		# The shoulder/forearm carry preparation. A large simultaneous wrist
		# cock adds another blade spin before contact; keep that load relaxed.
		wrist_keys[0]=Vector2(clampf(Vector2(wrist_keys[0]).x,-.30,.30),0)
		# Interpolate LOCAL wrist keys. Clamping a world-space blade angle each
		# frame flips +/-PI at the antipode and creates a one-frame sword snap.
		pose["weapon_wrist"]=attack_track(Vector2.ZERO,wrist_keys[0],wrist_keys[1],wrist_keys[2],phase).x

static func _harvest_arms(snapshot: Dictionary, pose: Dictionary, view: Dictionary, aim: Vector2) -> void:
	var action: String = snapshot["action"]
	var phase := float(snapshot["phase"])
	var contact := float(GuCharacterActionMotion.HARVEST_CONTACT[action])
	var recovery := .64
	var torso: Vector2 = pose["rest_torso"]
	pose["harvest_action"]=action
	var right_targets := []
	for side in ["L","R"]:
		var source := _joint_list(view,"arm_"+side)
		var reach := source[0].distance_to(source[1])+source[1].distance_to(source[2])
		var outward := signf(source[0].x-torso.x)
		var frontal := absf(aim.y)
		var load: Vector2
		var touch: Vector2
		var follow: Vector2
		if side=="L":
			# Counterweight, not a second identical reaching arm.
			load=Vector2(-aim.x*.16,.75).lerp(Vector2(outward*.28,.78),frontal)
			touch=Vector2(-aim.x*.38,.73).lerp(Vector2(outward*.42,.76),frontal)
			follow=Vector2(-aim.x*.18,.78).lerp(Vector2(outward*.3,.77),frontal)
		elif action=="gather":
			load=Vector2(aim.x*.22,.60).lerp(Vector2(outward*.32,.61),frontal)
			touch=Vector2(aim.x*.62,.74).lerp(Vector2(-outward*.2,.97),frontal)
			follow=Vector2(aim.x*.35,.55).lerp(Vector2(outward*.12,.56),frontal)
		else:
			load=Vector2(-aim.x*.08,-.46).lerp(Vector2(outward*.57,-.36),frontal)
			touch=Vector2(aim.x*.72,.60).lerp(Vector2(-outward*.32,.85),frontal)
			follow=Vector2(aim.x*.58,.71).lerp(Vector2(-outward*.2,.89),frontal)
			if aim.y<-.1:
				touch=Vector2(aim.x*.72,.25).lerp(Vector2(outward*.58,-.15),frontal)
				follow=Vector2(aim.x*.58,.51).lerp(Vector2(outward*.55,.20),frontal)
		var targets := [source[0]+load*reach,source[0]+touch*reach,source[0]+follow*reach]
		pose["arm_"+side]=_keyed_arm(source,targets,pose,phase,-outward,contact+.035 if side=="L" else contact,recovery+.045 if side=="L" else recovery,.28 if action=="mine" else .16,.30 if action=="mine" else .18)
		if side=="R": right_targets=targets
	if action=="mine":
		var source := _joint_list(view,"arm_R")
		var outward := signf(source[0].x-torso.x)
		var axis := Vector2(aim.x*.65,-1)
		var axes := [Vector2(-aim.x*.3,-1),Vector2(aim.x*.85,.65),Vector2(aim.x*.65,.82)]
		if absf(aim.y)>.1:
			axes[1]=Vector2(outward*.65,-.65 if aim.y<0 else .8)
			axes[2]=Vector2(outward*.7,-.1 if aim.y<0 else 1)
		var wrists := []
		for i in range(3):
			var chain := solve_arm(body_point(pose,source[0]),body_point(pose,right_targets[i]),source[0].distance_to(source[1]),source[1].distance_to(source[2]),-outward)
			var delta := (source[2]-source[1]).angle_to(chain[2]-chain[1])
			wrists.append(Vector2(clampf(axis.rotated(delta).angle_to(axes[i]),-.7,.7),0))
		pose["weapon_wrist"]=attack_track(Vector2.ZERO,wrists[0],wrists[1],wrists[2],phase,contact,recovery,.28,.30).x

static func _project_reach(point: Vector2, root: Vector2, upper: float, lower: float) -> Vector2:
	var delta := point-root
	var distance := clampf(delta.length(),arm_reach(upper,lower,ARM_MAX_FLEX),arm_reach(upper,lower,.14))
	return root+delta.normalized()*distance

static func _spear_arms(pose: Dictionary, view: Dictionary, look: Dictionary, aim: Vector2, phase: float, active: float) -> void:
	var right := _joint_list(view,"arm_R")
	var left := _joint_list(view,"arm_L")
	var axis := Vector2(aim.x,aim.y*.55).normalized().rotated(float(pose["torso_rotation"])*.25)
	var spacing := 5.5
	var center := Vector2(pose["torso"])+Vector2(0,-4.5)
	var travel := attack_track(Vector2.ZERO,Vector2(-2,0),Vector2(4.5,0),Vector2(3,0),phase).x
	var grip := center+axis*(travel-2)
	var roots := [body_point(pose,right[0]),body_point(pose,left[0])-axis*spacing]
	# Both grips share one rigid shaft. Project the common rear grip into
	# both arm envelopes before solving, instead of stretching the support arm.
	for iteration in range(32):
		grip=_project_reach(grip,roots[0],right[0].distance_to(right[1]),right[1].distance_to(right[2]))
		grip=_project_reach(grip,roots[1],left[0].distance_to(left[1]),left[1].distance_to(left[2]))
	for side in ["L","R"]:
		var source := left if side=="L" else right
		var outward := signf(source[0].x-Vector2(pose["rest_torso"]).x)
		var target := grip+axis*spacing if side=="L" else grip
		var solved := solve_arm(body_point(pose,source[0]),target,source[0].distance_to(source[1]),source[1].distance_to(source[2]),-outward)
		pose["arm_"+side]=_blend_arm(source,solved,pose,active)
	var held := _weapon_source_axis(view,look).rotated(forearm_delta(pose,view))
	_set_weapon_axis(pose,view,look,held.rotated(held.angle_to(axis)*active),false)
	pose["spear_support_weight"]=active

static func _joint_list(view: Dictionary, key: String) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Array in view["parts"][key]["joints"]:
		result.append(GuConceptCharacterArt.source_position(view,value))
	return result

static func body_point(pose: Dictionary, point: Vector2) -> Vector2:
	return Vector2(pose["torso"])+(point-Vector2(pose["rest_torso"])).rotated(float(pose["torso_rotation"]))

static func solve_limb(root: Vector2, target: Vector2, upper: float, lower: float, bend_sign: float) -> PackedVector2Array:
	var reach := target-root
	var distance := clampf(reach.length(),absf(upper-lower)+.0001,upper+lower-.0001)
	var axis := reach.normalized() if reach.length_squared()>.000001 else Vector2.DOWN
	var end := root+axis*distance
	var along := (upper*upper-lower*lower+distance*distance)/(2*distance)
	var height := sqrt(maxf(0,upper*upper-along*along))
	var joint := root+axis*along+Vector2(-axis.y,axis.x)*height*bend_sign
	return PackedVector2Array([root,joint,end])

static func _guard_arm(view: Dictionary, pose: Dictionary, side: String, aim: Vector2) -> PackedVector2Array:
	var source := _joint_list(view,"arm_"+side)
	var torso: Vector2 = pose["rest_torso"]
	var outward := -1.0 if source[0].x<torso.x else 1.0
	var grip := torso+Vector2(outward*3.5+aim.x*2.0,-5.8 if side=="L" else -4.5)
	return solve_limb(body_point(pose,source[0]),body_point(pose,grip),source[0].distance_to(source[1]),source[1].distance_to(source[2]),-outward)

static func _channel_arm(view: Dictionary, pose: Dictionary, side: String, phase: float) -> PackedVector2Array:
	var source := _joint_list(view,"arm_"+side)
	var torso: Vector2 = pose["rest_torso"]
	var outward := -1.0 if source[0].x<torso.x else 1.0
	var grip := torso+Vector2(outward*2.4,-4.2+sin(phase*TAU)*.10)
	return solve_limb(body_point(pose,source[0]),body_point(pose,grip),source[0].distance_to(source[1]),source[1].distance_to(source[2]),-outward)

static func foot_height(control: Dictionary, side: String) -> float:
	# A profile exposes the folded knee and needs actual toe clearance;
	# front/back projection has less visible vertical travel.
	return float(control.get("foot_lift_"+side,0))*(.65+.30*absf(Vector2(control["leg_forward"]).x))

static func foot_target(source: PackedVector2Array, control: Dictionary, rest: Dictionary, side: String) -> Vector2:
	var movement := Vector2(control["foot_ground_"+side])-Vector2(rest["foot_ground_"+side])
	# Shorten the travelled distance, not one axis. An anisotropic y scale
	# makes a diagonal foot follow a different direction from the actor.
	return source[2]+movement*GuConceptMotionFrames.projection(control["leg_forward"])-Vector2(0,foot_height(control,side))

static func plant_pelvis(pose: Dictionary, view: Dictionary, control: Dictionary, rest: Dictionary) -> void:
	var feet := {}
	for side in ["L","R"]:
		feet[side]=foot_target(_joint_list(view,"leg_"+side),control,rest,side)
	_fit_pelvis(pose,view,feet,control)

static func _fit_pelvis(pose: Dictionary, view: Dictionary, feet: Dictionary, contacts: Dictionary) -> void:
	# Source views have different thigh/shin ratios. A universal crouch still
	# hits maximum reach in profiles and minimum reach in back-facing steps.
	# Intersect the planted legs' valid vertical intervals before solving IK.
	var low := -INF
	var high := INF
	for side in ["L","R"]:
		# A lifted foot may fold beyond the projected shin envelope. It must
		# not push the pelvis outside the supporting leg's valid interval.
		if float(contacts["foot_contact_"+side])<=.995: continue
		var source := _joint_list(view,"leg_"+side)
		var hip := body_point(pose,source[0])
		var foot: Vector2 = feet[side]
		var upper := source[0].distance_to(source[1])
		var lower := source[1].distance_to(source[2])
		var x := foot.x-hip.x
		var max_height := sqrt(maxf(0,pow(upper+lower-.001,2)-x*x))
		var offset := hip.y-Vector2(pose["torso"]).y
		low=maxf(low,foot.y-max_height-offset)
		if float(contacts["foot_contact_"+side])>.995:
			var min_height := sqrt(maxf(0,pow(absf(upper-lower)+.001,2)-x*x))
			high=minf(high,foot.y-min_height-offset)
	var before: Vector2 = pose["torso"]
	var target := clampf(before.y,low,high) if low<=high else (low+high)*.5
	pose["torso"]=Vector2(before.x,target)
	for side in ["L","R"]: pose["cloth_lift_"+side]+= (target-before.y)*.75

static func _place_transition_feet(pose: Dictionary, view: Dictionary, feet: Dictionary, grounds: Dictionary) -> void:
	# Blending leg angles moves a planted toe along an arc. Blend its floor
	# target instead, then solve the native bones after fitting the pelvis.
	_fit_pelvis(pose,view,feet,pose)
	attach(pose,view)
	var direction := Vector2(pose["leg_forward"])
	if view.has("directional_art"):
		direction=Vector2.DOWN.rotated(int(view["directional_art"]["direction"])*PI/4)
	for side in ["L","R"]:
		var source := _joint_list(view,"leg_"+side)
		var hip := body_point(pose,source[0])
		var bend := -signf(direction.x) if absf(direction.x)>.1 else -signf(source[0].x-Vector2(pose["rest_torso"]).x)
		var leg := solve_limb(hip,feet[side],source[0].distance_to(source[1]),source[1].distance_to(source[2]),bend)
		pose["leg_"+side]=leg
		pose["foot_ground_"+side]=leg[2]+Vector2(grounds[side])-Vector2(feet[side])

static func sample(snapshot: Dictionary) -> Dictionary:
	var view := GuConceptCharacterArt.view_for(snapshot["appearance"],int(snapshot["direction_index"]))
	var control: Dictionary = snapshot["pose"]
	var rest := GuIllustratedCharacterArt.sample("idle",0,int(snapshot["direction_index"]),snapshot["appearance"],true)
	var walking: bool = snapshot["action"] in ["walk","run"] or float(snapshot.get("gait_weight",0))>.01
	var aim := Vector2.DOWN.rotated(int(snapshot["direction_index"])*PI/4)
	var torso := GuConceptCharacterArt.source_position(view,view["parts"]["torso"]["pivot"])
	var rotation := float(control["torso_rotation"])
	var translation := Vector2(control["torso"])-Vector2(rest["torso"])
	var crouch := 0.0
	if walking:
		# A short painted figure cannot use the old tall rig's stride envelope.
		# Lower the pelvis slightly to leave flexion room; do not squash artwork.
		translation *= .35
		crouch=lerpf(2.2,4.2,absf(aim.y))*float(snapshot.get("gait_weight",1))
		translation.y += crouch
		rotation *= .75
		# Shift onto the supporting hip as the opposite foot leaves the floor.
		# This follows contact, rather than swaying independently of the feet.
		var left_hip := _joint_list(view,"leg_L")[0]
		var right_hip := _joint_list(view,"leg_R")[0]
		var support := float(control["foot_contact_L"])-float(control["foot_contact_R"])
		translation.x += signf(left_hip.x-right_hip.x)*support*(.65 if snapshot["action"]=="run" else .45)*absf(aim.y)
	var result := {"torso":torso+translation,"rest_torso":torso,
		"torso_rotation":rotation,"head_rotation":float(control["head_rotation"]),
		"weapon_angle":control["weapon_angle"],
		"weapon_rotation":wrapf(float(control["weapon_angle"])-float(rest["weapon_angle"]),-PI,PI),
		"weapon_wrist":0.0,
		"support_wrist":0.0,
		"tail_rotation":control["tail_rotation"],"leg_forward":control["leg_forward"],
		"arm_depth_L":control["arm_depth_L"],"arm_depth_R":control["arm_depth_R"],
		"alpha":control["alpha"],"blink":control["blink"],
		"cloth_sway":float(control["cloth_sway"])*.55,
		"cloth_lift_L":float(control["cloth_lift_L"])*.55+crouch*.75,
		"cloth_lift_R":float(control["cloth_lift_R"])*.55+crouch*.75}
	var neck := GuConceptCharacterArt.source_position(view,view["neck"])
	var working: bool = snapshot["action"]=="attack" or GuCharacterActionMotion.harvesting(snapshot["action"])
	if walking or working and float(snapshot["phase"])>.00001 and float(snapshot["phase"])<.99999: plant_pelvis(result,view,control,rest)
	var original_head := GuConceptCharacterArt.source_position(view,view["parts"]["head"]["pivot"])
	result["neck"] = body_point(result,neck)
	result["head"] = Vector2(result["neck"])+(original_head-neck).rotated(float(result["head_rotation"]))
	for side in ["L","R"]:
		var key: String = "arm_"+side
		var source := _joint_list(view,key)
		var original: Array = rest[key]
		var target: Array = control[key]
		var shoulder := body_point(result,source[0])
		var arm := PackedVector2Array([shoulder])
		var locomotion: bool = walking and snapshot["action"] in ["walk","run"] and not bool(snapshot.get("reduced",false))
		var sleeve := GuConceptMotionFrames.arm_angles(float(snapshot["phase"]),side,snapshot["action"]=="run",aim)*float(snapshot.get("gait_weight",1)) if locomotion else Vector2.ZERO
		for bone in range(2):
			var reference: Vector2 = Vector2(original[bone+1])-Vector2(original[bone])
			var gesture: Vector2 = Vector2(target[bone+1])-Vector2(target[bone])
			var delta := reference.angle_to(gesture)
			if walking and snapshot["action"] in ["walk","run"]:
				delta *= .75
			if locomotion: delta=sleeve[bone]+float(result["torso_rotation"])
			arm.append(arm[bone]+(source[bone+1]-source[bone]).rotated(delta))
		result[key] = _guard_arm(view,result,side,aim) if snapshot["action"]=="defend" else _channel_arm(view,result,side,float(snapshot["phase"])) if snapshot["action"]=="channel" else arm
		if snapshot["action"] not in ["idle","walk","run","attack","defend","channel"]:
			# Retargeted legacy gestures may fold a short native forearm back
			# through its sleeve. Bound flexion without changing the painted bones.
			var chain: PackedVector2Array = result[key]
			var a := chain[1]-chain[0]
			var b := chain[2]-chain[1]
			var flex := a.angle_to(b)
			chain[2]=chain[1]+a.normalized().rotated(clampf(flex,-ARM_MAX_FLEX,ARM_MAX_FLEX))*b.length()
			result[key]=chain
		key = "leg_"+side
		source = _joint_list(view,key)
		var hip := body_point(result,source[0])
		var lift := foot_height(control,side)
		# Ground stride keeps its direction and source-dependent reach; height
		# stays separate so shortening the ground stride cannot erase foot lift.
		var foot := foot_target(source,control,rest,side)
		var bend := -signf(aim.x) if absf(aim.x)>.1 else -signf(source[0].x-torso.x)
		var upper := source[0].distance_to(source[1])
		var lower := source[1].distance_to(source[2])
		var leg := solve_limb(hip,foot,upper,lower,bend)
		result[key] = leg
		# Frontal toe/heel motion is depth and height, not an in-plane profile
		# rotation. Keep the painted cuff upright through upward/downward steps.
		result["foot_rotation_"+side] = GuConceptMotionFrames.toe_roll(float(snapshot["phase"]),side,snapshot["action"]=="run",aim)*float(snapshot.get("gait_weight",1)) if locomotion else float(control["foot_rotation_"+side])*.75*absf(aim.x)
		result["foot_contact_"+side] = float(control["foot_contact_"+side])
		result["foot_ground_"+side] = leg[2]+Vector2(0,lift)
	if snapshot["action"]=="defend":
		var outward := signf(_joint_list(view,"arm_R")[2].x)
		var desired := Vector2(outward*.40+aim.x*.08,-1).normalized()
		_set_weapon_axis(result,view,snapshot["appearance"],desired,false)
	elif GuCharacterActionMotion.harvesting(snapshot["action"]):
		_harvest_arms(snapshot,result,view,aim)
	elif snapshot["action"]=="attack" and not bool(snapshot.get("reduced",false)):
		_combat_arms(snapshot,result,view,aim)
	elif snapshot["action"] not in ["idle","walk","run"]:
		result["weapon_wrist"]=clampf(float(result["weapon_rotation"]),-WRIST_LIMIT,WRIST_LIMIT)
	bind_weapon(result,view,snapshot["appearance"],int(snapshot["direction_index"]))
	return result

static func attach(pose: Dictionary, view: Dictionary) -> void:
	# Rebuild the hierarchy after blending. Interpolating absolute shoulder and
	# neck coordinates describes a chord through the chest when it rotates.
	var source_neck := GuConceptCharacterArt.source_position(view,view["neck"])
	var source_head := GuConceptCharacterArt.source_position(view,view["parts"]["head"]["pivot"])
	pose["neck"] = body_point(pose,source_neck)
	pose["head"] = Vector2(pose["neck"])+(source_head-source_neck).rotated(float(pose["head_rotation"]))
	for side in ["L","R"]:
		for prefix in ["arm_","leg_"]:
			var key: String = prefix+side
			var chain: PackedVector2Array = pose[key]
			var source := _joint_list(view,key)
			var translation := body_point(pose,source[0])-chain[0]
			for i in range(3): chain[i] += translation
			pose[key] = chain
			if prefix=="leg_": pose["foot_ground_"+side] += translation

static func retarget(previous: Dictionary, from_view: Dictionary, to_view: Dictionary) -> Dictionary:
	# Carry motion relative to the authored pose, not the previous view's
	# absolute silhouette. A 45-degree drawing change must not drag the wrist
	# across the coat or interpolate between unrelated limb lengths.
	var result := previous.duplicate(true)
	var rest_torso := GuConceptCharacterArt.source_position(to_view,to_view["parts"]["torso"]["pivot"])
	result["torso"] = rest_torso+Vector2(previous["torso"])-Vector2(previous["rest_torso"])
	result["rest_torso"] = rest_torso
	var feet := {}
	var grounds := {}
	for side in ["L","R"]:
		for prefix in ["arm_","leg_"]:
			var key: String = prefix+side
			var old_source := _joint_list(from_view,key)
			var source := _joint_list(to_view,key)
			var old: PackedVector2Array = previous[key]
			var chain := PackedVector2Array([body_point(result,source[0])])
			for bone in range(2):
				var delta := (old_source[bone+1]-old_source[bone]).angle_to(old[bone+1]-old[bone])
				chain.append(chain[bone]+(source[bone+1]-source[bone]).rotated(delta))
			result[key] = chain
			if prefix=="leg_":
				feet[side]=source[2]+old[2]-old_source[2]
				grounds[side]=source[2]+Vector2(previous["foot_ground_"+side])-old_source[2]
	_place_transition_feet(result,to_view,feet,grounds)
	return result

static func blend(previous: Dictionary, target: Dictionary, weight: float, view: Dictionary = {}) -> Dictionary:
	var w := clampf(weight,0,1)
	if w<=0: return previous.duplicate(true)
	if w>=1: return target.duplicate(true)
	var result := target.duplicate(true)
	for key: String in target:
		if not previous.has(key): continue
		# Occlusion belongs to the drawing currently rendered, not a blended
		# number that swaps front/back sleeves halfway through the next view.
		if key.begins_with("arm_depth_"): continue
		if target[key] is Vector2:
			result[key] = Vector2(previous[key]).lerp(target[key],w)
		elif target[key] is float:
			result[key] = lerp_angle(previous[key],target[key],w) if "rotation" in key or key in ["weapon_angle","weapon_wrist"] else lerpf(previous[key],target[key],w)
		elif target[key] is PackedVector2Array:
			var a: PackedVector2Array = previous[key]
			var b: PackedVector2Array = target[key]
			var chain := PackedVector2Array([a[0].lerp(b[0],w)])
			if key.begins_with("arm_"):
				var upper_a := a[1]-a[0]
				var upper_b := b[1]-b[0]
				var upper_angle := lerp_angle(upper_a.angle(),upper_b.angle(),w)
				var flex := lerpf(upper_a.angle_to(a[2]-a[1]),upper_b.angle_to(b[2]-b[1]),w)
				chain.append(chain[0]+Vector2.from_angle(upper_angle)*lerpf(upper_a.length(),upper_b.length(),w))
				chain.append(chain[1]+Vector2.from_angle(upper_angle+flex)*lerpf(a[1].distance_to(a[2]),b[1].distance_to(b[2]),w))
				result[key]=chain
				continue
			for bone in range(2):
				var before := a[bone+1]-a[bone]
				var after := b[bone+1]-b[bone]
				chain.append(chain[bone]+Vector2.from_angle(lerp_angle(before.angle(),after.angle(),w))*lerpf(before.length(),after.length(),w))
			result[key] = chain
	for side in ["L","R"]:
		var ground_key: String = "foot_ground_"+side
		var leg_key: String = "leg_"+side
		var before := Vector2(previous[ground_key])-Vector2(previous[leg_key][2])
		var after := Vector2(target[ground_key])-Vector2(target[leg_key][2])
		result[ground_key] = Vector2(result[leg_key][2])+before.lerp(after,w)
	if not view.is_empty():
		var feet := {}
		var grounds := {}
		for side in ["L","R"]:
			feet[side]=Vector2(previous["leg_"+side][2]).lerp(target["leg_"+side][2],w)
			grounds[side]=Vector2(previous["foot_ground_"+side]).lerp(target["foot_ground_"+side],w)
		_place_transition_feet(result,view,feet,grounds)
	return result
