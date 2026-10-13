class_name GuCharacterFootPlant
extends RefCounted
## Rendered floor contacts, driven by actual ActorView travel. Clip previews
## without a moving root remain deterministic and use their authored gait.

const CONTACT := .985
const SETTLE_SECONDS := .18
var anchors: Dictionary = {}
var planted: Dictionary = {}
var release_offsets: Dictionary = {}
var direction := -1
var idle_age := 0.0
var settle_side := ""
var settle_age := 0.0
var settle_from := Vector2.ZERO
var settle_to := Vector2.ZERO

func reset() -> void:
	anchors.clear()
	planted.clear()
	release_offsets.clear()
	direction=-1
	idle_age=0
	settle_side=""
	settle_age=0

func _start(previous: Dictionary) -> void:
	var pose: Dictionary = previous["source_pose"]
	direction=int(previous["direction_index"])
	for side in ["L","R"]:
		anchors[side]=Vector2(pose["foot_ground_"+side])
		planted[side]=float(pose["foot_contact_"+side])>=CONTACT
		release_offsets[side]=Vector2.ZERO

func advance(snapshot: Dictionary, previous: Dictionary, root_step: Vector2, delta: float) -> void:
	if delta<=0: return
	if not root_step.is_finite() or bool(snapshot["reduced"]) or snapshot["action"] in ["dash","death","respawn"] or root_step.length()>12:
		reset()
		return
	if previous.is_empty(): return
	if anchors.is_empty(): _start(previous)
	var pose: Dictionary = snapshot["source_pose"]
	var view := GuConceptCharacterArt.view_for(snapshot["appearance"],int(snapshot["direction_index"]))
	if direction!=int(snapshot["direction_index"]):
		# A view change has different projected sole landmarks. Carry only the
		# contact offset, not a foot from another drawing's anatomical side.
		var old_view := GuConceptCharacterArt.view_for(snapshot["appearance"],direction)
		for side in ["L","R"]:
			var shift := GuConceptCharacterRig._joint_list(view,"leg_"+side)[2]-GuConceptCharacterRig._joint_list(old_view,"leg_"+side)[2]
			anchors[side]+=shift
		settle_side=""
		direction=int(snapshot["direction_index"])
	var gait: bool = snapshot.get("gait_active",false)
	var idle: bool = snapshot["action"]=="idle" and root_step.length()<.025
	idle_age=idle_age+delta if idle else 0.0
	if not idle: settle_side=""
	var feet := {}
	var grounds := {}
	for side in ["L","R"]:
		anchors[side]-=root_step
		var ground := Vector2(pose["foot_ground_"+side])
		var lift := maxf(0,ground.y-Vector2(pose["leg_"+side][2]).y)
		var contact: float = snapshot.get("gait_contact_"+side,pose["foot_contact_"+side]) if gait else pose["foot_contact_"+side]
		var on_floor := contact>=CONTACT and lift<.12
		if on_floor:
			if not planted[side]: anchors[side]=ground
			grounds[side]=anchors[side]
			release_offsets[side]=Vector2.ZERO
		else:
			if planted[side]: release_offsets[side]=Vector2(anchors[side])-ground
			var fade := 0.0
			if gait:
				var phase := fposmod(float(snapshot["gait_phase"])+(.5 if side=="L" else 0),1)
				var stance := .46 if snapshot["gait_running"] else .60
				fade=1-smoothstep(stance,minf(1,stance+.20),phase)
			else:
				release_offsets[side]=Vector2(release_offsets[side]).lerp(Vector2.ZERO,1-exp(-24*delta))
				fade=1.0
			grounds[side]=ground+Vector2(release_offsets[side])*fade
			anchors[side]=grounds[side]
		planted[side]=on_floor
		feet[side]=Vector2(grounds[side])-Vector2(0,lift)
	# Recover a neutral stance with one small lifted step at a time. Dragging
	# both soles back toward idle was the visible slide at the end of a run.
	if idle_age>.10:
		if settle_side.is_empty():
			var largest := .18
			for side in ["L","R"]:
				var rest := GuConceptCharacterRig._joint_list(view,"leg_"+side)[2]
				var distance: float = Vector2(grounds[side]).distance_to(rest)
				if distance>largest:
					largest=distance
					settle_side=side
					settle_from=grounds[side]
					settle_to=rest
			if not settle_side.is_empty(): settle_age=0
		if not settle_side.is_empty():
			settle_age+=delta
			var t := clampf(settle_age/SETTLE_SECONDS,0,1)
			var arc := pow(sin(t*PI),2)
			grounds[settle_side]=settle_from.lerp(settle_to,t*t*(3-2*t))
			feet[settle_side]=Vector2(grounds[settle_side])-Vector2(0,arc*.65)
			pose["foot_contact_"+settle_side]=1-arc
			anchors[settle_side]=grounds[settle_side]
			planted[settle_side]=t>=1
			if t>=1: settle_side=""
	GuConceptCharacterRig._place_transition_feet(pose,view,feet,grounds)
	# Reach limits win over a floor anchor after interruptions or tight turns.
	# Keep subsequent frames on the actually displayed toe, not a hidden goal.
	for side in ["L","R"]:
		if planted[side]: anchors[side]=pose["foot_ground_"+side]
	snapshot["source_pose"]=pose
