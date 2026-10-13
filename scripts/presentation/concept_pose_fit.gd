extends RefCounted
## Art fitting on top of the solved skeleton. A single painted sleeve morphs
## continuously between authored rest/reach/fold envelopes; no alpha crossfade
## or second sleeve is left at the old arm position.

static func weights(view: Dictionary, asset: Dictionary, pose: Dictionary) -> Vector3:
	if not asset.has("pose_fit"): return Vector3.ZERO
	var side: String = asset["side"]
	var chain: PackedVector2Array = pose["arm_"+side]
	var rest := GuConceptCharacterRig._joint_list(view,"arm_"+side)
	var flex := (chain[1]-chain[0]).angle_to(chain[2]-chain[1])
	var rest_flex := (rest[1]-rest[0]).angle_to(rest[2]-rest[1])
	var bend := smoothstep(.22,1.85,maxf(0,absf(flex)-absf(rest_flex)))
	var rest_axis := (rest[1]-rest[0]).rotated(float(pose["torso_rotation"]))
	var rise := smoothstep(.20,1.55,absf(rest_axis.angle_to(chain[1]-chain[0])))
	return Vector3(bend,rise,-signf(flex))

static func curve(values: Array, t: float) -> float:
	var at := clampf(t,0,1)*(values.size()-1)
	var index := mini(values.size()-2,floori(at))
	return lerpf(float(values[index]),float(values[index+1]),smoothstep(0,1,at-index))

static func vertex(point: Vector2, length: float, asset: Dictionary, fit: Vector3) -> Vector2:
	if not asset.has("pose_fit"): return point
	var guide: Dictionary = asset["pose_fit"]
	var t := clampf(point.y/maxf(.01,length),0,1)
	# Bend-side fabric compresses while the outer elbow keeps its volume.
	# The root and tip centerline remain exact bone anchors in every pose.
	var inside := smoothstep(-.28,.28,point.x*fit.z)
	var fold := lerpf(curve(guide["fold_outer"],t),curve(guide["fold_inner"],t),inside)
	var width := lerpf(1,fold,fit.x)*lerpf(1,curve(guide["reach"],t),fit.y)
	return Vector2(point.x*width,point.y)

static func shoulder(point: Vector2, view: Dictionary, asset: Dictionary, pose: Dictionary) -> Vector2:
	if not asset.has("stitch_length"): return point
	var side: String = asset["side"]
	var rest := GuConceptCharacterRig._joint_list(view,"arm_"+side)
	var chain: PackedVector2Array = pose["arm_"+side]
	var delta := (rest[1]-rest[0]).rotated(float(pose["torso_rotation"])).angle_to(chain[1]-chain[0])
	# The chest stitch is fixed to the torso. The outer shoulder cap follows
	# the sleeve, avoiding the stationary rectangular flap during raised arms.
	var stitch := Vector2(asset["anchors"]["chest_stitch"][0],0)
	var along := clampf((point.x-stitch.x)/(-stitch.x),0,1)
	# This is a vertical shear depending only on x: its Jacobian is one,
	# so the connection cannot fold over itself when the arm is overhead.
	return point+Vector2(0,point.x*sin(delta)*.42*smoothstep(0,1,along))
