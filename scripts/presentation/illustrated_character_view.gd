class_name GuIllustratedCharacterView
extends GuPixelCharacterView
## Compatible character API with the approved source art and a continuous rig.
## The old atlas remains available for saved tooling and regression snapshots.

var illustration: GuIllustratedCharacterCanvas
var _snapshot: Dictionary = {}
var _transition_from: Dictionary = {}
var _transition_source_offsets: Dictionary = {}
var _transition_source_pose: Dictionary = {}
var _transition_source_direction := -1
var _source_transition_age := 0.0
var _source_transition_length := .09
var _turn_age := 0.0
var _turn_goal := -1
var _turn_sign := 1
const TURN_STEP_SECONDS := .026
var _transition_age := 0.0
var _transition_length := .12
var _smooth_action := ""
var _smooth_direction := -1
var _smooth_time := 0.0
var _secondary: Dictionary = {}
var _source_secondary: Dictionary = {}
var _held_prop := GuCharacterHeldProp.new()
var _transition_from_overhead := false
var _foot_plant := preload("res://scripts/presentation/character_foot_plant.gd").new()

func _init() -> void:
	name = "IllustratedCharacterView"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func configure(pixel_size: int = 256, height: float = 48.0) -> void:
	super.configure(pixel_size,height)
	display_height = maxf(1.0,height)
	sprite.visible = false
	if illustration == null:
		illustration = GuIllustratedCharacterCanvas.new()
		add_child(illustration)
	present(current_action,_time,_facing,_reduced)

func present(action: String, time: float, facing: Vector2, reduced: bool = false) -> void:
	# Explicit sampling/seek stays deterministic for portraits, tooling and
	# screenshots. Playback alone owns transition and secondary-motion history.
	super.present(action,time,facing,reduced)
	# Harvest clips are native rig animations; the archived pixel atlas stays idle.
	if GuCharacterActionMotion.harvesting(action): current_action=action
	if illustration == null:
		return
	_transition_from.clear()
	_transition_source_offsets.clear()
	_transition_source_pose.clear()
	_foot_plant.reset()
	_turn_age = 0
	_turn_goal = current_direction
	_smooth_action = current_action
	_smooth_direction = current_direction
	_smooth_time = time
	var snapshot := _make_snapshot(time,reduced,1.0)
	snapshot["held_prop"]=_held_prop.reset(snapshot["held_prop"])
	_publish(snapshot)
	_reset_secondary(_snapshot["pose"])

func _control_pose(phase: float, direction: int, reduced: bool, locomotion_weight: float, gait_phase: float, running: bool, gait_direction: int) -> Dictionary:
	var pose := GuIllustratedCharacterArt.sample(current_action,phase,direction,appearance,reduced)
	if current_action in ["walk","run"] and not reduced:
		var neutral := GuIllustratedCharacterArt.sample("idle",0,direction,appearance)
		pose = GuIllustratedCharacterArt.blend_poses(neutral,pose,locomotion_weight)
	elif current_action in ["attack","cast","defend"] and gait_phase >= 0 and locomotion_weight > 0 and not reduced:
		# The upper-body facing and the travelled gait can differ during a cast.
		var gait := GuIllustratedCharacterArt.sample("run" if running else "walk",fposmod(gait_phase,1.0),gait_direction if gait_direction >= 0 else direction,appearance)
		for key: String in gait:
			if key.begins_with("foot_") or key.begins_with("hip_") or key.begins_with("cloth_") or key=="leg_forward":
				pose[key] = Vector2(pose[key]).lerp(gait[key],locomotion_weight) if gait[key] is Vector2 else lerpf(float(pose[key]),float(gait[key]),locomotion_weight)
	return pose

func _make_snapshot(time: float, reduced: bool, locomotion_weight: float, gait_phase: float = -1.0, running: bool = false, gait_direction: int = -1, render_direction: int = -1) -> Dictionary:
	var length := maxf(.01,duration(current_action,str(appearance["weapon"])))
	var loops := current_action in ["idle","walk","run","defend","channel"]
	var phase := fposmod(maxf(time,0),length)/length if loops else clampf(time/length,0,1)
	var direction := current_direction if render_direction<0 else render_direction
	var pose := _control_pose(phase,current_direction,reduced,locomotion_weight,gait_phase,running,gait_direction)
	var gait_clip := current_action in ["walk","run"]
	var gait_overlay := current_action in ["attack","cast","defend"] and gait_phase>=0
	var gait_weight := locomotion_weight if gait_clip or gait_overlay else 0.0
	var value := {"appearance":appearance.duplicate(true),"action":current_action,"direction_index":direction,"control_direction_index":current_direction,"phase":phase,"reduced":reduced,"scale":display_height/NATIVE_HEIGHT,"pose":pose,"source_offsets":GuConceptCharacterArt.joint_offsets(appearance,current_direction),"gait_weight":gait_weight,"gait_active":gait_weight>.001 and not reduced,"gait_phase":phase if gait_clip else gait_phase,"gait_running":current_action=="run" if gait_clip else running}
	if value["gait_active"]:
		for side in ["L","R"]:
			value["gait_contact_"+side]=GuIllustratedCharacterArt.gait_foot(float(value["gait_phase"])+(.5 if side=="L" else 0),bool(value["gait_running"]))["contact"]
	var source_control := value.duplicate(false)
	source_control["pose"] = pose if direction==current_direction else _control_pose(phase,direction,reduced,locomotion_weight,gait_phase,running,gait_direction)
	value["source_pose"] = GuConceptCharacterRig.sample(source_control)
	value["held_prop"]=GuCharacterHeldProp.desired(current_action,phase,str(appearance["weapon"]))
	value["arms_behind_head"]=current_action=="mine" or current_action=="attack" and str(appearance["weapon"])=="sword"
	return value

func _render_direction(previous: Dictionary, delta: float) -> int:
	if _turn_goal!=current_direction:
		_turn_goal=current_direction
		_turn_age=0
	var direction := int(previous["direction_index"])
	if direction==current_direction:
		_turn_age=0
		return direction
	_turn_age += maxf(0,delta)
	var steps := floori(_turn_age/TURN_STEP_SECONDS)
	_turn_age -= steps*TURN_STEP_SECONDS
	for step in range(mini(steps,4)):
		var clockwise := posmod(current_direction-direction,8)
		if clockwise==0: break
		if clockwise!=4: _turn_sign=1 if clockwise<4 else -1
		direction=posmod(direction+_turn_sign,8)
	return direction

func _publish(value: Dictionary) -> void:
	_snapshot = value
	var outfit := str(appearance["outfit"])
	if illustration.get_meta("source_outfit", "")!=outfit:
		illustration.material = GuConceptCharacterArt.material_for(appearance).duplicate()
		illustration.set_meta("source_outfit",outfit)
	var source_view := GuConceptCharacterArt.view_for(appearance,int(value["direction_index"]))
	var source_size: Array = GuConceptCharacterArt.manifest()["sources"][source_view["source"]]["size"]
	for eye in range(2):
		var region: Array = source_view.get("eyes",[[0,0,0,0],[0,0,0,0]])[eye]
		illustration.material.set_shader_parameter("eye_left" if eye==0 else "eye_right",Vector4(float(region[0])/source_size[0],float(region[1])/source_size[1],float(region[2])/source_size[0],float(region[3])/source_size[1]))
	illustration.material.set_shader_parameter("blink",float(value["source_pose"].get("blink",0)))
	illustration.snapshot = _snapshot
	illustration.queue_redraw()

func _reset_secondary(pose: Dictionary) -> void:
	_secondary.clear()
	for key in ["tail_rotation","weapon_angle","head_rotation"]:
		_secondary[key] = Vector2(float(pose[key]),0)
	_source_secondary.clear()
	for key in ["tail_rotation","weapon_wrist","head_rotation"]:
		_source_secondary[key] = Vector2(float(_snapshot["source_pose"][key]),0)

func _spring_angle(key: String, target: float, delta: float, frequency: float, damping: float, source: bool = false) -> float:
	# Exact damped spring for a held target. No Euler substeps or dependence on
	# draw frequency, and wrap angles around the shortest arc at every step.
	var store: Dictionary = _source_secondary if source else _secondary
	var spring: Vector2 = store.get(key,Vector2(target,0))
	var displacement := wrapf(spring.x-target,-PI,PI)
	var decay := exp(-damping*frequency*delta)
	var damped := frequency*sqrt(1-damping*damping)
	var c := cos(damped*delta)
	var s := sin(damped*delta)
	var next := decay*(displacement*c+(spring.y+damping*frequency*displacement)/damped*s)
	var velocity := decay*(spring.y*c-(damping*frequency*spring.y+frequency*frequency*displacement)/damped*s)
	store[key] = Vector2(target+next,velocity)
	return target+next

func present_smooth(action: String, time: float, facing: Vector2, reduced: bool, delta: float, locomotion_weight: float = 1.0, gait_phase: float = -1.0, running: bool = false, movement_facing: Vector2 = Vector2.ZERO, root_travel: Vector2 = Vector2.INF) -> void:
	var previous := _snapshot
	super.present(action,time,facing,reduced)
	# Harvest clips are native rig animations; the archived pixel atlas stays idle.
	if GuCharacterActionMotion.harvesting(action): current_action=action
	if illustration == null:
		return
	var gait_direction := direction_for(movement_facing) if movement_facing.length_squared() > .001 else current_direction
	var reset: bool = previous.is_empty() or reduced or bool(previous.get("reduced",false)) or previous["appearance"] != appearance
	var render_direction := current_direction if reset else _render_direction(previous,delta)
	var target := _make_snapshot(time,reduced,clampf(locomotion_weight,0,1),gait_phase,running,gait_direction,render_direction)
	if reset:
		_foot_plant.reset()
		_transition_from.clear()
		_transition_source_pose.clear()
		_turn_goal=current_direction
		_turn_age=0
		target["held_prop"]=_held_prop.reset(target["held_prop"])
		_publish(target)
		_reset_secondary(target["pose"])
	else:
		var loops := current_action in ["idle","walk","run","defend","channel"]
		var restarted := not loops and time < _smooth_time-.001
		var changed := current_action != _smooth_action or current_direction != _smooth_direction or restarted
		if changed:
			_transition_from = previous["pose"].duplicate(true)
			_transition_source_offsets = previous.get("source_offsets",{}).duplicate(true)
			_transition_age = 0
			_transition_length = .12 if current_action in ["idle","walk","run","channel","defend"] else .07
			if current_action in ["hit","dash"]:
				_transition_length = .045
		if changed or render_direction!=int(previous["direction_index"]):
			_transition_from_overhead=bool(previous.get("arms_behind_head",false))
			_transition_source_pose=previous["source_pose"].duplicate(true)
			_transition_source_direction=int(previous["direction_index"])
			_source_transition_age=0
			_source_transition_length=.09 if current_action in ["idle","walk","run","channel","defend"] else .06
			if current_action in ["hit","dash"]: _source_transition_length=.045
		var dt := maxf(0,delta)
		target["held_prop"]=_held_prop.advance(target["held_prop"],dt)
		var pose: Dictionary = target["pose"]
		if not _transition_from.is_empty():
			_transition_age += dt
			var t := clampf(_transition_age/_transition_length,0,1)
			pose = GuIllustratedCharacterArt.blend_poses(_transition_from,pose,t*t*(3-2*t))
			target["source_offsets"] = GuConceptCharacterArt.blend_offsets(_transition_source_offsets,target["source_offsets"],t*t*(3-2*t))
			if t >= 1:
				_transition_from.clear()
		if dt > 0:
			pose["tail_rotation"] = _spring_angle("tail_rotation",float(pose["tail_rotation"]),dt,17,.68)
			pose["weapon_angle"] = _spring_angle("weapon_angle",float(pose["weapon_angle"]),dt,36 if current_action in ["attack","cast","dash"] else 24,.86)
			pose["head_rotation"] = _spring_angle("head_rotation",float(pose["head_rotation"]),dt,24,.90)
		elif not previous.is_empty():
			# Accepted events may sync at delta zero before VFX snapshots. Keep
			# the actual displayed spring angles as well as the blended hand.
			for key in ["tail_rotation","weapon_angle","head_rotation"]:
				pose[key] = previous["pose"][key]
		target["pose"] = pose
		var source_pose: Dictionary = target["source_pose"]
		var source_view := GuConceptCharacterArt.view_for(appearance,render_direction)
		if not _transition_source_pose.is_empty():
			target["arms_behind_head"]=bool(target["arms_behind_head"]) or _transition_from_overhead
			_source_transition_age+=dt
			var t := clampf(_source_transition_age/_source_transition_length,0,1)
			var from_pose := _transition_source_pose
			if _transition_source_direction!=render_direction:
				from_pose=GuConceptCharacterRig.retarget(from_pose,GuConceptCharacterArt.view_for(appearance,_transition_source_direction),source_view)
			source_pose=GuConceptCharacterRig.blend(from_pose,source_pose,t*t*(3-2*t),source_view)
			if t>=1: _transition_source_pose.clear()
		for key in ["head_rotation","tail_rotation","weapon_wrist"]:
			if dt>0 and key=="weapon_wrist" and (current_action=="attack" or GuCharacterActionMotion.harvesting(current_action)):
				_source_secondary[key]=Vector2(float(source_pose[key]),0)
			elif dt>0:
				source_pose[key]=_spring_angle(key,float(source_pose[key]),dt,24 if key=="head_rotation" else 17 if key=="tail_rotation" else 36,.90 if key=="head_rotation" else .68 if key=="tail_rotation" else .86,true)
			else:
				source_pose[key]=previous["source_pose"][key]
		source_pose["held_prop"]=target["held_prop"]["kind"]
		GuConceptCharacterRig.attach(source_pose,source_view)
		target["source_pose"]=source_pose
		_foot_plant.advance(target,previous,root_travel/maxf(.001,float(target["scale"])),dt)
		source_pose=target["source_pose"]
		GuConceptCharacterRig.bind_weapon(source_pose,source_view,appearance,render_direction)
		# Event sync owns no elapsed animation time. Preserve the complete
		# rendered pose bit-for-bit, including view-dependent weapon baselines.
		target["source_pose"]=source_pose if dt>0 else previous["source_pose"].duplicate(true)
		_publish(target)
	_smooth_action = current_action
	_smooth_direction = current_direction
	_smooth_time = time

func capture_pose() -> Dictionary:
	return _snapshot.duplicate(true)

func hand_position(side: String = "R") -> Vector2:
	if _snapshot.is_empty():
		return super.hand_position(side)
	return GuConceptCharacterArt.hand_position(_snapshot,side)

func visual_rect() -> Rect2:
	# Includes the curved knot/ponytail, fully raised hands and spear tip.
	var factor := display_height/NATIVE_HEIGHT
	return Rect2(Vector2(-90,-105)*factor,Vector2(180,165)*factor)
