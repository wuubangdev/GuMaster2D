extends SceneTree
## Direction-first fixture. Taste is reviewed from native captures; these
## contracts catch detached grips, sliding soles and unreadable action targets.
const LimbContract = preload("res://tests/character48_limb_contract.gd")
var passed := 0
var failed := 0
var findings := []
var metrics := {}

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if condition: passed+=1
	else:
		failed+=1
		findings.append(label)
		push_error(label)

func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var bone_error := 0.0
	var root_error := 0.0
	var foot_error := 0.0
	var grip_error := 0.0
	var hand_step := 0.0
	var samples := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		var view := GuConceptCharacterArt.view_for(look,0)
		actor.present("idle",0,Vector2.DOWN)
		var rest: Dictionary = actor.capture_pose()["source_pose"]
		for action in ["attack","gather","mine","defend"]:
			var previous := Vector2.ZERO
			for frame in range(121):
				var phase := float(frame)/120
				actor.present(action,actor.duration(action)*phase,Vector2.DOWN)
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				for key in ["arm_L","arm_R","leg_L","leg_R"]:
					var source := GuConceptCharacterRig._joint_list(view,key)
					var chain: PackedVector2Array = pose[key]
					root_error=maxf(root_error,chain[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0])))
					var physical := LimbContract.physical_lengths(pose,key.right(1)) if key.begins_with("leg") else Vector2(chain[0].distance_to(chain[1]),chain[1].distance_to(chain[2]))
					for bone in range(2): bone_error=maxf(bone_error,absf(physical[bone]-source[bone].distance_to(source[bone+1])))
					if key.begins_with("leg") and action!="defend": foot_error=maxf(foot_error,chain[2].distance_to(rest[key][2]))
				var hand := GuConceptCharacterArt.hand_position(snapshot)/float(snapshot["scale"])
				var palm := GuConceptCharacterRig.hand_vertex(GuConceptCharacterRig._joint_list(view,"arm_R")[2],GuConceptCharacterRig._joint_list(view,"arm_R"),pose["arm_R"],float(pose["hand_rotation_R"]))
				grip_error=maxf(grip_error,hand.distance_to(palm))
				if frame>0: hand_step=maxf(hand_step,hand.distance_to(previous))
				previous=hand
				if frame in [0,120] and action!="defend":
					check(Vector2(pose["arm_R"][2]).distance_to(rest["arm_R"][2])<.0001,body+" "+action+" returns authored neutral grip at endpoint "+str(frame))
				samples+=1
		actor.present("attack",actor.duration("attack")*.34,Vector2.DOWN)
		var strike := actor.capture_pose()
		var strike_pose: Dictionary = strike["source_pose"]
		var arm: PackedVector2Array = strike_pose["arm_R"]
		var blade := (GuConceptCharacterArt.weapon_tip(strike)-actor.hand_position()).normalized()
		var flex := absf((arm[1]-arm[0]).angle_to(arm[2]-arm[1]))
		check(flex<.40 and (arm[2]-arm[1]).normalized().y>.94,body+" south sword contact opens elbow and reaches down toward target")
		check(blade.y>.85,body+" south sword blade follows the downward stroke")
		var support: PackedVector2Array = strike_pose["arm_L"]
		check(absf(support[1].x-support[0].x)<3.0,body+" south free elbow stays beside ribs at contact")
		actor.present("gather",actor.duration("gather")*.50,Vector2.DOWN)
		var gather: Dictionary = actor.capture_pose()["source_pose"]
		var hand_y := float(gather["grip_R"].y)
		check(hand_y>float(rest["grip_R"].y)+4.0 and float(gather["torso"].y)>float(rest["torso"].y)+3.8,body+" gather lowers hips before extending hand below resting palm")
		for side in ["L","R"]:
			var chain: PackedVector2Array = gather["leg_"+side]
			check(chain[1].y<chain[2].y-.1,body+" gather knee remains above sole "+side)
		actor.present("mine",actor.duration("mine")*.48,Vector2.DOWN)
		var mine: Dictionary = actor.capture_pose()["source_pose"]
		var pick_axis := Vector2.UP.rotated(float(mine["tool_angle"]))
		var pick_contact := Vector2(mine["grip_R"])+pick_axis*11.0
		check(pick_axis.y>.85 and pick_contact.y>float(mine["grip_R"].y)+9.0,body+" mine pick head extends down from palm toward rock at contact")
		metrics[body]={"sword_contact_flex_degrees":rad_to_deg(flex),"gather_grip_y":hand_y,"gather_hip_drop":float(gather["torso"].y)-float(rest["torso"].y),"pick_contact":str(pick_contact)}
	check(bone_error<.0001,"All south actions preserve rigid arm and reconstructed physical leg lengths")
	check(root_error<.0001,"All south shoulders and hips remain attached to torso")
	check(foot_error<.0002,"South sword/gather/mine keep both planted feet fixed")
	check(grip_error<.0001,"All south action props use the actual articulated palm socket")
	check(hand_step<3.0,"All south action hand paths are continuous over 120 intervals")
	# Guard is a shared attachment correction, so cover every body/view here.
	var raised := true
	var guard_bound := true
	var guard_attached := true
	var guard_elbow := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for direction in range(8):
			actor.present("defend",actor.duration("defend")*.4,Vector2.DOWN.rotated(direction*PI/4))
			var snap := actor.capture_pose()
			var pose: Dictionary = snap["source_pose"]
			var source_view := GuConceptCharacterArt.view_for(look,direction)
			var blade := (GuConceptCharacterArt.weapon_tip(snap)-actor.hand_position()).normalized()
			var palm_axis := GuConceptCharacterRig._weapon_source_axis(source_view,look).rotated(GuConceptCharacterRig.forearm_delta(pose,source_view)+float(pose["hand_rotation_R"])).normalized()
			raised=raised and blade.y<-absf(blade.x)*.95
			guard_bound=guard_bound and absf(float(pose["weapon_wrist"]))<=GuConceptCharacterRig.WRIST_LIMIT+.0001
			guard_attached=guard_attached and blade.distance_to(palm_axis)<.0001
			for side in ["L","R"]:
				var chain: PackedVector2Array = pose["arm_"+side]
				guard_elbow=guard_elbow and absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))<=GuConceptCharacterRig.ARM_MAX_FLEX+.0001
			var hand_local := (Vector2(pose["arm_R"][2])-Vector2(pose["torso"])).rotated(-float(pose["torso_rotation"]))
			print("GUARD46 ",body," ",direction," ",hand_local," wrist ",pose["weapon_wrist"])
	check(raised,"Every sword guard remains raised within the outward 45-degree parry cone")
	check(guard_bound and guard_attached,"All sixteen sword guards share one bounded visible palm/blade roll")
	check(guard_elbow,"Both elbows in all sixteen sword guards remain inside the same 135 degree articulation limit")
	GuConceptCharacterRig._guard_fit_cache.clear()
	var fits_before := GuConceptCharacterRig._guard_fit_evaluations
	var cold_start := Time.get_ticks_usec()
	actor.present("defend",0,Vector2.DOWN)
	metrics["guard_cold_fit_ms"]=(Time.get_ticks_usec()-cold_start)/1000.0
	var warm_start := Time.get_ticks_usec()
	for frame in range(121): actor.present("defend",actor.duration("defend")*float(frame)/120,Vector2.DOWN)
	metrics["guard_warm_pose_mean_ms"]=(Time.get_ticks_usec()-warm_start)/121000.0
	var fit_count := GuConceptCharacterRig._guard_fit_evaluations-fits_before
	check(fit_count==2,"Breathing guard playback computes its two local arm fits once and reuses them for 121 frames")
	metrics["guard_fits_for_121_frames"]=fit_count
	check(absf(GuCharacterActionMotion.release_seconds("sword")-.2176)<.000001,"Sword authority release remains .2176 seconds")
	_all_direction_targets(actor)
	_northwest_contact_visibility(actor)
	await load("res://tests/concept_combat_tests.gd").run(self,check)
	load("res://tests/concept_articulation_tests.gd")._guard(actor,check)
	metrics.merge({"samples":samples,"max_bone_error":bone_error,"max_attachment_error":root_error,"max_planted_foot_error":foot_error,"max_palm_error":grip_error,"max_hand_step_per_120":hand_step})
	FileAccess.open("res://artifacts/character46_motion_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"findings":findings,"metrics":metrics},"  "))
	print("CHARACTER46_MOTION ",passed,"/",passed+failed," ",JSON.stringify(metrics))
	actor.queue_free()
	await process_frame
	quit(1 if failed else 0)

func _all_direction_targets(actor: GuIllustratedCharacterView) -> void:
	var rows := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for direction in range(8):
			var aim := Vector2.DOWN.rotated(direction*PI/4)
			var row := {"body":body,"direction":direction}
			actor.present("idle",0,aim)
			var rest: Dictionary = actor.capture_pose()["source_pose"]
			var guard_clearance := INF
			for frame in range(121):
				actor.present("defend",actor.duration("defend")*float(frame)/120,aim)
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				var face_center := Vector2(pose["head"])+Vector2(0,2)
				var hand := actor.hand_position()/float(snapshot["scale"])
				var tip := GuConceptCharacterArt.weapon_tip(snapshot)/float(snapshot["scale"])
				var face_a := (hand-face_center)/Vector2(7.2,5.7)
				var face_b := (tip-face_center)/Vector2(7.2,5.7)
				guard_clearance=minf(guard_clearance,Geometry2D.get_closest_point_to_segment(Vector2.ZERO,face_a,face_b).length())
			row["minimum_guard_face_radius"]=guard_clearance
			check(guard_clearance>=1.0,"Guard blade clears face over 121 frames: "+body+"/"+str(direction))
			for action in ["attack","gather","mine"]:
				var phase: float = {"attack":.34,"gather":.50,"mine":.48}[action]
				actor.present(action,actor.duration(action)*phase,aim)
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				if action=="attack":
					var axis := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
					row["sword_contact_facing_dot"]=axis.dot(aim)
					check(axis.dot(aim)>.50,"Sword contact points into its authored direction: "+body+"/"+str(direction))
				elif action=="mine":
					var axis := Vector2.UP.rotated(float(pose["tool_angle"]))
					row["pick_contact_facing_dot"]=axis.dot(aim)
					check(axis.dot(aim)>.50,"Pick contact points toward resource direction: "+body+"/"+str(direction))
				else:
					var travel := Vector2(pose["grip_R"])-Vector2(rest["grip_R"])
					row["gather_reach_toward_target"]=travel.dot(aim)
					check(travel.dot(aim)>2.0,"Gather contact extends toward stem instead of staying at belt: "+body+"/"+str(direction))
			rows.append(row)
	metrics["direction_targets"]=rows

func _northwest_contact_visibility(actor: GuIllustratedCharacterView) -> void:
	# Far hands are genuinely behind head/coat in NW. A correct IK solution
	# still fails visually when its contact disappears inside those polygons.
	var rows := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		var view := GuConceptCharacterArt.view_for(look,3)
		for action in ["attack","gather"]:
			actor.present(action,actor.duration(action)*(.34 if action=="attack" else .50),Vector2.DOWN.rotated(3*PI/4))
			var snapshot := actor.capture_pose()
			var pose: Dictionary = snapshot["source_pose"]
			var palm := actor.hand_position()/float(snapshot["scale"])
			var clearance := INF
			for part in ["head","torso"]:
				for contour: PackedVector2Array in GuConceptCharacterArt.outline_paths(view,part,pose):
					var distance := INF
					for index in range(contour.size()-1):
						distance=minf(distance,palm.distance_to(Geometry2D.get_closest_point_to_segment(palm,contour[index],contour[index+1])))
					if Geometry2D.is_point_in_polygon(palm,contour): distance=-distance
					clearance=minf(clearance,distance)
			check(clearance>.5,"NW "+body+" "+action+" contact palm clears actual head/coat contours without changing rear occlusion")
			rows.append({"body":body,"action":action,"contact_palm":str(palm),"head_coat_clearance":clearance})
	metrics["northwest_contact_visibility"]=rows
