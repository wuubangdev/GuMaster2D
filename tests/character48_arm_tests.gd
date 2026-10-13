extends SceneTree
## Dense motion regressions for the specific channel, cast and spear branch
## failures found in 0.47. Includes real native bone/palm attachment contracts.
var passed := 0
var failed := 0
var findings := []
var metrics := {}

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: passed+=1
	else:
		failed+=1
		findings.append(label)
		push_error(label)

func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var samples := 0
	var bone_error := 0.0
	var root_error := 0.0
	var grip_error := 0.0
	var flex_max := 0.0
	var cast_elbow := 0.0
	var cast_hand := 0.0
	var cast_blade := 0.0
	var spear_blade := 0.0
	var cast_endpoint := 0.0
	var foot_knee_margin := INF
	var frontal_knee_margin := INF
	var stance_knee_margin := INF
	var leg_physical_error := 0.0
	var leg_projection_min := 1.0
	var leg_profile_error := 0.0
	var leg_projection_metadata_error := 0.0
	var max_gait_joint_step := 0.0
	var worst_knee := {}
	var preparation_flex := 0.0
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var look := GuCharacterAppearance.default_data()
			look["body"]=body
			look["weapon"]=weapon
			actor.set_appearance(look)
			for direction in range(8):
				var facing := Vector2.DOWN.rotated(direction*PI/4)
				var view := GuConceptCharacterArt.view_for(look,direction)
				actor.present("idle",0,facing)
				var neutral: Dictionary = actor.capture_pose()["source_pose"]
				for action in ["idle","walk","run","attack","defend","gather","mine","cast","channel","dash","hit","death","respawn"]:
					var previous := {}
					var previous_blade := Vector2.ZERO
					for frame in range(121):
						actor.present(action,actor.duration(action,weapon)*float(frame)/120,facing)
						var snapshot := actor.capture_pose()
						var pose: Dictionary = snapshot["source_pose"]
						for side in ["L","R"]:
							var source := GuConceptCharacterRig._joint_list(view,"arm_"+side)
							var chain: PackedVector2Array = pose["arm_"+side]
							root_error=maxf(root_error,chain[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0])))
							for bone in range(2): bone_error=maxf(bone_error,absf(chain[bone].distance_to(chain[bone+1])-source[bone].distance_to(source[bone+1])))
							flex_max=maxf(flex_max,absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1])))
							var socket := GuConceptCharacterRig.hand_vertex(source[2],source,chain,float(pose["hand_rotation_"+side]))
							grip_error=maxf(grip_error,socket.distance_to(GuConceptCharacterArt.hand_position(snapshot,side)/float(snapshot["scale"])))
							var leg: PackedVector2Array = pose["leg_"+side]
							var leg_source := GuConceptCharacterRig._joint_list(view,"leg_"+side)
							var depth: PackedFloat32Array = pose.get("leg_depth_"+side,PackedFloat32Array([0,0,0]))
							var projection: Vector2 = pose.get("leg_projection_"+side,Vector2.ONE)
							for bone in range(2):
								var physical := leg_source[bone].distance_to(leg_source[bone+1])
								var drawn := leg[bone].distance_to(leg[bone+1])
								var measured := drawn/physical
								leg_projection_min=minf(leg_projection_min,measured)
								leg_physical_error=maxf(leg_physical_error,absf(sqrt(drawn*drawn+pow(depth[bone+1]-depth[bone],2))-physical))
								leg_projection_metadata_error=maxf(leg_projection_metadata_error,absf(measured-projection[bone]))
								if direction in [2,6]: leg_profile_error=maxf(leg_profile_error,absf(drawn-physical))
							if action=="cast":
								if frame in [0,120]: cast_endpoint=maxf(cast_endpoint,chain[2].distance_to(neutral["arm_"+side][2]))
								if not previous.is_empty():
									cast_elbow=maxf(cast_elbow,chain[1].distance_to(previous["arm_"+side][1]))
									cast_hand=maxf(cast_hand,chain[2].distance_to(previous["arm_"+side][2]))
							if action in ["walk","run"]:
								var margin := leg[2].y-leg[1].y
								if direction in [0,4]: frontal_knee_margin=minf(frontal_knee_margin,margin)
								if float(pose["foot_contact_"+side])>.999: stance_knee_margin=minf(stance_knee_margin,margin)
								if margin<foot_knee_margin:
									foot_knee_margin=margin
									worst_knee={"body":body,"direction":direction,"action":action,"side":side,"phase":float(frame)/120,"knee":str(leg[1]),"sole":str(leg[2])}
								if not previous.is_empty():
									for joint in range(3): max_gait_joint_step=maxf(max_gait_joint_step,leg[joint].distance_to(previous["leg_"+side][joint]))
						var blade := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
						if frame>0:
							if action=="cast": cast_blade=maxf(cast_blade,absf(blade.angle_to(previous_blade)))
							if action=="attack" and weapon=="spear": spear_blade=maxf(spear_blade,absf(blade.angle_to(previous_blade)))
						previous=pose
						previous_blade=blade
						samples+=1
					if action=="mine" or action=="attack" and weapon=="sword":
						var prepared_at := .28 if action=="mine" else .16
						actor.present(action,actor.duration(action,weapon)*prepared_at,facing)
						var prepared: PackedVector2Array = actor.capture_pose()["source_pose"]["arm_R"]
						preparation_flex=maxf(preparation_flex,absf((prepared[1]-prepared[0]).angle_to(prepared[2]-prepared[1])))
	check(bone_error<.0001 and root_error<.0001,"Every source arm keeps its two bone lengths and exact torso attachment across all thirteen actions")
	check(grip_error<.0001,"Every sword/tool palm socket follows the actual articulated visible hand")
	check(flex_max<=GuConceptCharacterRig.ARM_MAX_FLEX+.0001,"Channel and every other action obey the same 135 degree elbow limit in every view")
	check(cast_elbow<1.3 and cast_hand<1.7,"Native casting cannot teleport through the shoulder when a legacy control wrist crosses its angular branch")
	check(cast_blade<.20,"Casting has a continuous carried weapon angle through charge, release and recovery")
	check(cast_endpoint<.0001,"Both casting hands return exactly to their authored neutral at entry and recovery")
	check(spear_blade<.25,"The spear shaft does not flip its shortest-angle branch in SE preparation or recovery")
	check(preparation_flex<deg_to_rad(125),"Sword and mining preparation open the elbow instead of pinning every load to the hard 135 degree stop")
	check(frontal_knee_margin>.20,"Front and back walking/running never place a knee below its sole, including the airborne return")
	check(stance_knee_margin>.05,"A grounded walking/running sole remains below its knee in every drawing")
	check(leg_physical_error<.0001 and leg_projection_metadata_error<.00001,"Every projected edge plus its actual depth reconstructs the unchanged physical source bone length")
	check(leg_projection_min>=GuConceptCharacterRig.LEG_MIN_PROJECTION-.00001 and leg_profile_error<.0001,"Foreshortening stays bounded and E/W profile bones remain rigid at original length")
	metrics={"samples":samples,"max_bone_error":bone_error,"max_root_error":root_error,"max_grip_error":grip_error,"max_elbow_flex_degrees":rad_to_deg(flex_max),"cast_elbow_step_per_120":cast_elbow,"cast_hand_step_per_120":cast_hand,"cast_blade_radians_per_120":cast_blade,"cast_endpoint_error":cast_endpoint,"spear_blade_radians_per_120":spear_blade,"minimum_gait_knee_above_sole":foot_knee_margin,"worst_knee":worst_knee,"max_gait_joint_step_per_120":max_gait_joint_step}
	metrics["max_preparation_flex_degrees"]=rad_to_deg(preparation_flex)
	metrics.merge({"frontal_knee_above_sole":frontal_knee_margin,"stance_knee_above_sole":stance_knee_margin,"leg_physical_length_error":leg_physical_error,"leg_projection_metadata_error":leg_projection_metadata_error,"minimum_leg_projection":leg_projection_min,"profile_leg_length_error":leg_profile_error})
	FileAccess.open("res://artifacts/character48_arm_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"findings":findings,"metrics":metrics},"  "))
	print("CHARACTER48_ARM ",passed,"/",passed+failed," ",JSON.stringify(metrics))
	actor.queue_free()
	await process_frame
	quit(1 if failed else 0)
