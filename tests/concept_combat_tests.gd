extends RefCounted
## Native constraints and real View playback. Pose tests cannot certify taste;
## concept_combat_review.gd captures the same renderer for visual review.

static func run(tree: SceneTree, check: Callable) -> void:
	var actor := GuIllustratedCharacterView.new()
	tree.root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var fixed := true
	var elbow := true
	var wrist := true
	var shaft := true
	var neutral := true
	var attached := true
	var continuous := true
	var forward := true
	var upper_fill := true
	var profile_contact := true
	var max_contact_flex := 0.0
	var cloth_bridges := true
	var bridge_samples := 0
	var max_support_step := 0.0
	var max_flex := 0.0
	var max_shaft_error := 0.0
	var max_frame_hand := 0.0
	var max_blade_turn := 0.0
	var largest_hand := {}
	var largest_blade := {}
	var samples := 0
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var look := GuCharacterAppearance.default_data()
			look["body"]=body
			look["weapon"]=weapon
			actor.set_appearance(look)
			for d in range(8):
				var facing := Vector2.DOWN.rotated(d*PI/4)
				var source := GuConceptCharacterArt.view_for(look,d)
				actor.present("idle",0,facing,true)
				var rest: Dictionary = actor.capture_pose()["source_pose"]
				var rest_tip := GuConceptCharacterArt.weapon_tip(actor.capture_pose())
				if weapon=="sword" and d in [2,6]:
					actor.present("attack",actor.duration("attack",weapon)*.34,facing)
					var contact: Dictionary = actor.capture_pose()["source_pose"]
					var chain: PackedVector2Array = contact["arm_R"]
					var flex := absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))
					max_contact_flex=maxf(max_contact_flex,flex)
					profile_contact=profile_contact and flex<deg_to_rad(23) and (chain[2]-chain[1]).normalized().dot(facing)>.94
				var previous := Vector2.ZERO
				var previous_support := Vector2.ZERO
				var previous_blade := Vector2.ZERO
				for frame in range(97):
					var phase := float(frame)/96
					actor.present("attack",actor.duration("attack",weapon)*phase,facing)
					var snapshot := actor.capture_pose()
					var pose: Dictionary = snapshot["source_pose"]
					var grip := actor.hand_position()
					var support := GuConceptCharacterArt.hand_position(snapshot,"L")
					if frame>0:
						max_support_step=maxf(max_support_step,support.distance_to(previous_support))
						continuous=continuous and support.distance_to(previous_support)<2.5
						if grip.distance_to(previous)>max_frame_hand:
							max_frame_hand=grip.distance_to(previous)
							largest_hand={"body":body,"weapon":weapon,"direction":d,"frame":frame}
						continuous=continuous and grip.distance_to(previous)<2.5
					previous=grip
					previous_support=support
					if weapon!="unarmed" and frame in [0,96]: neutral=neutral and GuConceptCharacterArt.weapon_tip(snapshot).distance_to(rest_tip)<.0001
					for side in ["L","R"]:
						var key: String = "arm_"+side
						var original := GuConceptCharacterRig._joint_list(source,key)
						var chain: PackedVector2Array = pose[key]
						var flex := absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))
						max_flex=maxf(max_flex,flex)
						elbow=elbow and flex<=GuConceptCharacterRig.ARM_MAX_FLEX+.0001
						for bone in range(2): fixed=fixed and absf(chain[bone].distance_to(chain[bone+1])-original[bone].distance_to(original[bone+1]))<.0001
						attached=attached and chain[0].distance_to(GuConceptCharacterRig.body_point(pose,original[0]))<.0001
						var sleeve := GuConceptCharacterArt.exposed_upper_sleeve(source,key,pose)
						upper_fill=upper_fill and Geometry2D.triangulate_polygon(sleeve).size()>0
						for bridge in GuConceptCharacterArt.elbow_cloth_bridges(source,key,chain):
							bridge_samples+=1
							var cut: Vector2 = bridge["cut"]
							var outline: PackedVector2Array = bridge["outline"]
							var axis := (original[2]-original[0]).normalized()
							cloth_bridges=cloth_bridges and cut.cross(axis)*float(bridge["turn"])>0 and Geometry2D.triangulate_polygon(bridge["polygon"]).size()>0
							var deformation := GuConceptCharacterArt.sleeve_deformation(original,chain)
							var upper_edge := GuConceptCharacterArt.sleeve_point(original[1]+cut,original,chain,0,deformation)
							var lower_edge := GuConceptCharacterArt.sleeve_point(original[1]+cut,original,chain,1,deformation)
							cloth_bridges=cloth_bridges and outline[0].distance_to(upper_edge)<.0001 and outline[-1].distance_to(lower_edge)<.0001
							var bound := maxf(upper_edge.distance_to(chain[1]),lower_edge.distance_to(chain[1]))
							cloth_bridges=cloth_bridges and bound<=cut.length()+.1601
							for point in outline: cloth_bridges=cloth_bridges and point.distance_to(chain[1])<=bound+.0001
						if frame in [0,96]: neutral=neutral and chain[2].distance_to(rest[key][2])<.0001
					if weapon=="sword":
						wrist=wrist and absf(float(pose["weapon_wrist"]))<=GuConceptCharacterRig.WRIST_LIMIT+.0001
						var blade := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
						if frame>0:
							var turn := absf(previous_blade.angle_to(blade))
							if turn>max_blade_turn:
								max_blade_turn=turn
								largest_blade={"body":body,"direction":d,"frame":frame}
							continuous=continuous and turn<.30
						previous_blade=blade
						var relative := GuConceptCharacterRig._weapon_source_axis(source,look).rotated(GuConceptCharacterRig.forearm_delta(pose,source)+float(pose["weapon_wrist"])).normalized()
						attached=attached and blade.distance_to(relative)<.00001
						var binding := GuConceptCharacterArt.sword_attachment(snapshot)
						attached=attached and Vector2(binding["grip"]).distance_to(actor.hand_position())<.00001
					if weapon=="spear" and phase>=.18 and phase<=.58:
						var axis := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
						var error := Vector2(pose["arm_L"][2]).distance_to(grip+axis*5.5)
						max_shaft_error=maxf(max_shaft_error,error)
						shaft=shaft and error<.001
					if d in [2,6] and phase>=.33 and phase<=.36 and weapon=="sword":
						var blade := GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()
						forward=forward and blade.x*facing.x>absf(blade.y)*1.8
					samples+=1
	check.call(fixed and attached,"Native combat keeps source bone lengths and torso shoulder roots for 4,656 sword/spear/unarmed poses; the drawn grip and sword tip share one forearm/wrist attachment")
	check.call(elbow,"Native attacks stay below 135 degrees of elbow flexion in both arms, all bodies and facings, including entry and recovery")
	check.call(wrist,"Sword attacks bound local wrist deviation to 0.85 radians instead of rotating a disconnected blade")
	check.call(shaft,"Both spear hands stay on one rigid shaft throughout load, thrust and follow-through with less than 0.001 native-unit grip error")
	check.call(neutral,"Each weapon's attack starts and ends at the actual authored neutral hand positions")
	check.call(continuous and forward,"Native attacks have continuous hand paths through all 96 phase intervals and an outward horizontal left/right contact window")
	check.call(profile_contact,"Both bodies extend the actual weapon elbow below 23 degrees and point the forearm toward the target at left/right sword contact")
	check.call(upper_fill,"Exposed combat upper sleeves have valid tapered contours in every pose without a detached forearm tube")
	check.call(cloth_bridges and bridge_samples>100,"Elbow cloth fills only the opening sector, meets both source cutout edges exactly and stays within source width; closing folds have no duplicate cap outline")
	var playback := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for d in range(8):
			var facing := Vector2.DOWN.rotated(d*PI/4)
			actor.present("idle",0,facing)
			for frame in range(61):
				actor.present_smooth("attack",actor.duration("attack")*float(frame)/60,facing,false,1.0/120)
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				var source := GuConceptCharacterArt.view_for(look,d)
				var relative := GuConceptCharacterRig._weapon_source_axis(source,look).rotated(GuConceptCharacterRig.forearm_delta(pose,source)+float(pose["weapon_wrist"])).normalized()
				var blade := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
				playback=playback and relative.distance_to(blade)<.00001
	check.call(playback,"Actual smooth View playback, including native transition and spring history, keeps the sword parented to its displayed forearm")
	_palms(actor,check)
	_attack_curves(check)
	_source_gaps(actor,check)
	_support_arm(actor,check)
	var report := {"profile_contact_max_elbow_degrees":rad_to_deg(max_contact_flex),"profile_contact_passed":profile_contact,"native_poses":samples,"smooth_playback_poses":976,"elbow_cloth_bridge_samples":bridge_samples,"max_support_hand_step_per_96_phase_intervals":max_support_step,"max_elbow_degrees":rad_to_deg(max_flex),"max_spear_grip_error":max_shaft_error,"max_hand_step_per_96_phase_intervals":max_frame_hand,"largest_hand_interval":largest_hand,"max_blade_turn_degrees_per_96_phase_intervals":rad_to_deg(max_blade_turn),"largest_blade_interval":largest_blade,"rig_checks_passed":fixed and attached and elbow and wrist and shaft and neutral and continuous and forward and upper_fill and cloth_bridges and playback and profile_contact}
	var output := FileAccess.open("res://artifacts/concept37_combat_constraints.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print("COMBAT_CONSTRAINTS ",JSON.stringify(report))
	actor.queue_free()
	await tree.process_frame

static func _palms(actor: GuIllustratedCharacterView, check: Callable) -> void:
	var rotates := true
	var attached := true
	var geometry_bound := true
	var shaft_bound := true
	var max_grip_error := 0.0
	var wrist_views := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			var source := GuConceptCharacterRig._joint_list(reference,"arm_R")
			var geometry := GuConceptCharacterArt._part_geometry(reference,"arm_R")
			var palm := GuConceptCharacterArt.arm_bone_indices(reference,"arm_R",2)
			geometry_bound=geometry_bound and palm.size()>0
			var moved := false
			var max_turn := 0.0
			for frame in range(49):
				actor.present("attack",actor.duration("attack")*float(frame)/48,Vector2.DOWN.rotated(d*PI/4))
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				var chain: PackedVector2Array = pose["arm_R"]
				var turn := float(pose["hand_rotation_R"])
				max_turn=maxf(max_turn,absf(turn))
				attached=attached and absf(turn-float(pose["weapon_wrist"]))<.0001
				var grip := GuConceptCharacterRig.hand_vertex(source[2],source,chain,turn)
				var wrist := Vector2(pose["wrist_R"])
				var source_wrist := GuConceptCharacterRig.source_wrist(source)
				attached=attached and absf(chain[1].distance_to(wrist)-source[1].distance_to(source_wrist))<.0001 and absf(wrist.distance_to(grip)-source_wrist.distance_to(source[2]))<.0001
				max_grip_error=maxf(max_grip_error,grip.distance_to(actor.hand_position()))
				attached=attached and grip.distance_to(actor.hand_position())<.0001
				var vertices := GuConceptCharacterArt.part_vertices(reference,"arm_R",pose)
				var delta := GuConceptCharacterRig.forearm_delta(pose,reference)+turn
				for i in range(0,palm.size(),3):
					var a := palm[i]
					var b := palm[i+1]
					var original_a := GuConceptCharacterArt.source_position(reference,[geometry["vertices"][a].x,geometry["vertices"][a].y])
					var original_b := GuConceptCharacterArt.source_position(reference,[geometry["vertices"][b].x,geometry["vertices"][b].y])
					geometry_bound=geometry_bound and (vertices[b]-vertices[a]).distance_to((original_b-original_a).rotated(delta))<.0002
				moved=moved or grip.distance_to(chain[2])>.025
				var blade := (GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position()).normalized()
				shaft_bound=shaft_bound and blade.distance_to(GuConceptCharacterRig._weapon_source_axis(reference,look).rotated(delta).normalized())<.0001
			rotates=rotates and moved
			wrist_views.append({"body":body,"direction":d,"max_turn":max_turn,"moves":moved})
	check.call(rotates and geometry_bound,"Source palm mesh rotates independently at a cuff pivot in every body/view; actual palm triangle edges inherit the same local wrist angle as the blade")
	check.call(attached and shaft_bound,"Drawn palm centre, weapon root and skill grip share the articulated wrist attachment through 784 attack samples; no bitmap hand remains fixed to the forearm")
	var report := {"poses":784,"max_grip_error":max_grip_error,"rotates":rotates,"geometry_bound":geometry_bound,"shaft_bound":shaft_bound,"wrist_views":wrist_views,"passed":rotates and attached and geometry_bound and shaft_bound}
	var output := FileAccess.open("res://artifacts/concept37_palm_constraints.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print("PALM_CONSTRAINTS ",JSON.stringify(report))

static func _attack_curves(check: Callable) -> void:
	var continuous := true
	var monotone := true
	for keys in [[Vector2.ZERO,Vector2(1,2),Vector2(3,1),Vector2(4,-1)],[Vector2.ONE,Vector2(-2,2),Vector2(2,3),Vector2(-3,1)]]:
		for seam in [.16,.18,.34,GuConceptCharacterRig.ATTACK_RECOVERY]:
			var h := .00005
			var before := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam-h)
			var at := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam)
			var after := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam+h)
			continuous=continuous and ((at-before)/h).distance_to((after-at)/h)<.20
		for segment in [[.18,.34,keys[1],keys[2]],[.34,GuConceptCharacterRig.ATTACK_RECOVERY,keys[2],keys[3]]]:
			for frame in range(65):
				var point := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],lerpf(segment[0],segment[1],float(frame)/64))
				for axis in range(2): monotone=monotone and point[axis]>=minf(segment[2][axis],segment[3][axis])-.00001 and point[axis]<=maxf(segment[2][axis],segment[3][axis])+.00001
	check.call(continuous and monotone,"Attack curves carry continuous velocity through load/contact/recovery without overshooting local shoulder, elbow or wrist keys")

static func _source_gaps(actor: GuIllustratedCharacterView, check: Callable) -> void:
	var bounded := true
	var repaired := true
	var fills := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			for side in ["L","R"]:
				var key: String = "arm_"+side
				var gap := GuConceptCharacterArt.source_forearm_gap(reference,key)
				if gap>0: fills+=1
				if body=="male" and d in [2,4] and side=="R": repaired=repaired and gap>0
				if body=="male" and d in [0,6] and side=="R": repaired=repaired and gap==0
				for frame in range(33):
					actor.present("attack",actor.duration("attack")*float(frame)/32,Vector2.DOWN.rotated(d*PI/4))
					var pose: Dictionary = actor.capture_pose()["source_pose"]
					var polygon := GuConceptCharacterArt.missing_forearm_contour(reference,key,pose)
					if polygon.is_empty(): continue
					var elbow: Vector2 = pose[key][1]
					var wrist: Vector2 = pose["wrist_"+side]
					var axis := (wrist-elbow).normalized()
					bounded=bounded and Geometry2D.triangulate_polygon(polygon).size()>0
					for point in polygon: bounded=bounded and absf((point-elbow).cross(axis))<=.84 and (point-elbow).dot(axis)<=elbow.distance_to(wrist)*gap+.23
	check.call(repaired and bounded,"Only sustained missing source forearm intervals receive a narrow cuff bridge; male W/N gaps connect to the wrist without a full arm tube or palm cap")
	print("SOURCE_FOREARM_GAPS ",fills," / 32 authored arms")

static func _support_arm(actor: GuIllustratedCharacterView, check: Callable) -> void:
	var articulated := true
	var counterbalance := true
	var neutral := true
	var palettes := true
	var rows := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		look["weapon"]="sword"
		actor.set_appearance(look)
		for d in range(8):
			var view := GuConceptCharacterArt.view_for(look,d)
			var source := GuConceptCharacterRig._joint_list(view,"arm_L")
			var geometry := GuConceptCharacterArt._part_geometry(view,"arm_L")
			var triangles := GuConceptCharacterArt.arm_bone_indices(view,"arm_L",2)
			var max_roll := 0.0
			var min_flex := INF
			var max_flex := -INF
			for frame in range(97):
				actor.present("attack",actor.duration("attack")*float(frame)/96,Vector2.DOWN.rotated(d*PI/4))
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				var chain: PackedVector2Array = pose["arm_L"]
				var turn := float(pose["hand_rotation_L"])
				max_roll=maxf(max_roll,absf(turn))
				var flex := (chain[1]-chain[0]).angle_to(chain[2]-chain[1])
				min_flex=minf(min_flex,flex)
				max_flex=maxf(max_flex,flex)
				var grip := GuConceptCharacterArt.hand_position(snapshot,"L")/float(snapshot["scale"])
				articulated=articulated and absf(turn)<=GuConceptCharacterRig.SUPPORT_WRIST_LIMIT+.00001 and grip.distance_to(GuConceptCharacterRig.hand_vertex(source[2],source,chain,turn))<.0001
				var vertices := GuConceptCharacterArt.part_vertices(view,"arm_L",pose)
				for i in triangles:
					var original := GuConceptCharacterArt.source_position(view,[geometry["vertices"][i].x,geometry["vertices"][i].y])
					articulated=articulated and vertices[i].distance_to(GuConceptCharacterRig.hand_vertex(original,source,chain,turn))<.0001
				if frame in [0,96]: neutral=neutral and grip.distance_to(source[2])<.0001 and absf(turn)<.0001
				if d in [2,6] and frame==36:
					var aim := Vector2.DOWN.rotated(d*PI/4)
					counterbalance=counterbalance and (grip.x-chain[0].x)*aim.x<-.5
			articulated=articulated and max_roll>.10 and max_flex-min_flex>.05
			for side in ["L","R"]:
				var pigment := GuConceptCharacterArt.sleeve_pigment(view,"arm_"+side)
				palettes=palettes and pigment.a==1 and pigment.r>=.19 and pigment.r<=.67 and pigment.g>=pigment.b
			rows.append({"body":body,"direction":d,"max_palm_roll":max_roll,"elbow_excursion":max_flex-min_flex})
	check.call(articulated and counterbalance,"Free sword arm counterbalances profile contact; its source palm really rolls at the cuff, with bounded elbow motion in all 16 views")
	check.call(neutral,"Support palm and arm return exactly to their authored neutral pose at both attack endpoints")
	check.call(palettes,"All 32 sleeve bridge palettes are opaque source cloth colors, excluding skin, ivory and dark ink")
	var smooth_settle := true
	var keys := [Vector2.ZERO,Vector2(1,2),Vector2(3,1),Vector2(4,-1)]
	for seam in [.16,.18,GuConceptCharacterRig.SUPPORT_CONTACT,GuConceptCharacterRig.SUPPORT_RECOVERY]:
		var h := .00005
		var before := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam-h,GuConceptCharacterRig.SUPPORT_CONTACT,GuConceptCharacterRig.SUPPORT_RECOVERY)
		var at := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam,GuConceptCharacterRig.SUPPORT_CONTACT,GuConceptCharacterRig.SUPPORT_RECOVERY)
		var after := GuConceptCharacterRig.attack_track(keys[0],keys[1],keys[2],keys[3],seam+h,GuConceptCharacterRig.SUPPORT_CONTACT,GuConceptCharacterRig.SUPPORT_RECOVERY)
		smooth_settle=smooth_settle and ((at-before)/h).distance_to((after-at)/h)<.20
	check.call(smooth_settle,"Delayed support-arm contact and settle preserve velocity through all key boundaries, independently of sword contact timing")
	var output := FileAccess.open("res://artifacts/concept37_support_arm.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"poses":1552,"views":rows,"articulated":articulated,"counterbalance":counterbalance,"neutral":neutral,"source_palettes":palettes,"smooth_settle":smooth_settle},"  "))
	output.close()
