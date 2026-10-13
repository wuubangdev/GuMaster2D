extends RefCounted
## Exercise native source geometry, not only the legacy control-pose metadata.
const LimbContract = preload("res://tests/character48_limb_contract.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256,48)
	view.set_active(false)
	var lengths := true
	var attachments := true
	var boots := true
	var neutral := true
	var limb_motion := false
	var projection_bounds := true
	var profile_rigid := true
	var stance_knees := true
	var projection_used := false
	var position := Vector2(12,9)
	view.position=position
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			var facing := Vector2.DOWN.rotated(d*PI/4)
			view.present("idle",0,facing,true)
			var before: Dictionary = view.capture_pose()["source_pose"]
			for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
				for i in range(17):
					view.present(action,view.duration(action)*float(i)/16,facing)
					var snapshot := view.capture_pose()
					var pose: Dictionary = snapshot["source_pose"]
					var source_head := GuConceptCharacterArt.source_position(reference,reference["parts"]["head"]["pivot"])
					var source_neck := GuConceptCharacterArt.source_position(reference,reference["neck"])
					var drawn_neck := Vector2(pose["head"])+(source_neck-source_head).rotated(float(pose["head_rotation"]))
					attachments = attachments and drawn_neck.distance_to(pose["neck"])<.0001 and view.position==position
					for side in ["L","R"]:
						for prefix in ["arm_","leg_"]:
							var key: String = prefix+side
							var authored: Array = reference["parts"][key]["joints"]
							var actual: PackedVector2Array = pose[key]
							for bone in range(2):
								var a := GuConceptCharacterArt.source_position(reference,authored[bone])
								var b := GuConceptCharacterArt.source_position(reference,authored[bone+1])
								if prefix=="arm_": lengths = lengths and absf(actual[bone].distance_to(actual[bone+1])-a.distance_to(b))<.0005
							if prefix=="leg_":
								var contract := LimbContract.inspect(pose,reference,side)
								lengths = lengths and contract["lengths"]
								projection_bounds = projection_bounds and contract["bounds"]
								profile_rigid = profile_rigid and contract["profile_rigid"]
								if action not in ["death","respawn","dash","hit"]: stance_knees = stance_knees and contract["stance_knee"]
								projection_used = projection_used or contract["projected"]
							var parent := GuConceptCharacterRig.body_point(pose,GuConceptCharacterArt.source_position(reference,authored[0]))
							attachments = attachments and actual[0].distance_to(parent)<.0001
						var key: String = "leg_"+side
						var points := GuConceptCharacterArt.part_vertices(reference,key,pose)
						var original: Array = reference["parts"][key]["polygon"]
						var expected := GuConceptCharacterArt.source_position(reference,original[0]).distance_to(GuConceptCharacterArt.source_position(reference,original[3]))
						boots = boots and absf(points[0].distance_to(points[3])-expected)<.0001
						limb_motion = limb_motion or (action=="walk" and Vector2(pose["leg_"+side][2]).distance_to(before["leg_"+side][2])>.5)
			for key in ["head","torso"]:
				neutral = neutral and Vector2(before[key]).distance_to(GuConceptCharacterArt.source_position(reference,reference["parts"][key]["pivot"]))<.0001
	check.call(lengths,"Actual source arms stay rigid and projected thighs/shins reconstruct unchanged physical lengths from XY plus depth in both bodies, eight views and eleven actions")
	check.call(projection_bounds and projection_used,"Leg projection is finite, never stretches its physical bones and stays within the 35-to-100 percent screen-length envelope")
	check.call(profile_rigid,"Left/right side views retain exact native two-dimensional thigh and shin lengths")
	check.call(stance_knees,"Frontal planted legs keep the knee above the upright sole in idle, movement and active standing actions")
	check.call(attachments,"Actual drawn shoulders and hips stay on the chest hierarchy, and the transformed head neck stays attached without moving the gameplay root")
	check.call(boots,"The rendered boot vertices preserve their original size through locomotion and combat instead of stretching an entire cutout")
	check.call(neutral and limb_motion,"The source rig preserves its approved neutral pivots and visibly articulates individual feet during locomotion")
	var planted := true
	view.set_appearance(GuCharacterAppearance.default_data())
	for d in [2,6]:
		var facing := Vector2.DOWN.rotated(d*PI/4)
		for action in ["walk","run"]:
			view.present(action,view.duration(action)*.10,facing)
			var first: Vector2 = view.capture_pose()["source_pose"]["leg_R"][2]
			view.present(action,view.duration(action)*.15,facing)
			var after: Vector2 = view.capture_pose()["source_pose"]["leg_R"][2]
			var travelled := (GuIllustratedCharacterArt.WALK_STRIDE if action=="walk" else GuIllustratedCharacterArt.RUN_STRIDE)*.05
			planted = planted and absf(after.x+facing.x*travelled-first.x)<.0001
	check.call(planted,"Actual source profile stance feet cancel the actor's distance-driven screen travel instead of sliding with the body")
	var owner_images := {}
	for source in ["original","directions"]:
		var file := "character-concept-01" if source=="original" else "character-directions-02"
		var texture: Texture2D = load("res://assets/characters/concept-rig/%s-layers.res" % file)
		owner_images[source]=texture.get_image()
	var isolated := true
	var grounded := true
	for reference: Dictionary in GuConceptCharacterArt.manifest()["views"].values():
		var owner: Image = owner_images[reference["source"]]
		var center: Array = reference["parts"]["head"]["pivot"]
		isolated = isolated and roundi(owner.get_pixel(int(center[0]),int(center[1])).r*255)==32
		var ground: Array = reference["ground"]
		for x in range(int(ground[0])-70,int(ground[0])+71):
			grounded = grounded and owner.get_pixel(x,int(ground[1])+3).r==0
	check.call(isolated,"Ownership textures give the face to its head layer rather than letting sleeves carry copies of adjacent facial pixels")
	var rear := GuConceptCharacterArt.view_for(GuCharacterAppearance.default_data(),4)
	var rear_grip: Array = rear["parts"]["arm_R"]["joints"][2]
	check.call(roundi(owner_images["original"].get_pixel(int(rear_grip[0]),int(rear_grip[1])).r*255)==128,"The rear male sword grip lies on visible authored hand pigment instead of the erased baked-weapon region")
	check.call(grounded,"All sixteen ownership masks reject the concept's drawn ground scratches below the soles")
	var source_owner: Image = owner_images["original"]
	var sword_isolated := true
	for point in [Vector2i(645,402),Vector2i(653,416),Vector2i(642,430)]:
		sword_isolated = sword_isolated and roundi(source_owner.get_pixelv(point).r*255)==7*32
	sword_isolated = sword_isolated and roundi(source_owner.get_pixel(665,399).r*255)==4*32
	check.call(sword_isolated,"The independent sword owns its complete guard and pale blade while the original gripping skin remains on the hand")
	check.call(source_owner.get_pixel(1066,425).r==0 and source_owner.get_pixel(1394,419).r==0,"Profile and rear body layers exclude the concept's baked guards so unarmed or swinging hands cannot carry a second weapon")
	var mirrored_strike := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in [2,6]:
			var facing := Vector2.DOWN.rotated(d*PI/4)
			view.present("attack",view.duration("attack")*.33,facing)
			var weapon := GuConceptCharacterArt.weapon_tip(view.capture_pose())-view.hand_position()
			mirrored_strike = mirrored_strike and weapon.x*facing.x>absf(weapon.y)*1.8
	check.call(mirrored_strike,"Both bodies' reflected source swords strike horizontally outward on left/right profiles instead of rotating down into the ground")
	view.set_appearance(GuCharacterAppearance.default_data())
	view.present("walk",.2,Vector2.RIGHT)
	var stable: Dictionary = view.capture_pose()["source_pose"]
	view.present_smooth("attack",0,Vector2.UP,false,0)
	check.call(Vector2(view.capture_pose()["source_pose"]["arm_R"][2]).is_equal_approx(stable["arm_R"][2]),"An accepted turn/cast at zero elapsed time preserves the exact already-drawn native hand")
	_transitions(view,check)
	_mesh(view,check)
	_body_panels(view,check,owner_images)
	_sleeves(view,check)
	_guard(view,check)
	_projected_contacts(view,check)
	view.queue_free()
	await tree.process_frame

static func _transitions(view: GuIllustratedCharacterView, check: Callable) -> void:
	var attached := true
	var fixed := true
	var stepped := true
	var planted := true
	var zero_stable := true
	var depth_fixed := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for from in range(8):
			for to in range(8):
				view.present("run",.19,Vector2.DOWN.rotated(from*PI/4))
				var before := view.capture_pose()
				var tip := GuConceptCharacterArt.weapon_tip(before)
				var action: String = ["walk","run","attack","defend","dash"][(from+to)%5]
				view.present_smooth(action,.21,Vector2.DOWN.rotated(to*PI/4),false,0)
				var event := view.capture_pose()
				zero_stable = zero_stable and event["direction_index"]==from and event["source_pose"]==before["source_pose"] and tip.is_equal_approx(GuConceptCharacterArt.weapon_tip(event))
				for frame in range(30):
					var last := int(view.capture_pose()["direction_index"])
					view.present_smooth(action,.21,Vector2.DOWN.rotated(to*PI/4),false,1.0/120)
					var snapshot := view.capture_pose()
					var d := int(snapshot["direction_index"])
					stepped = stepped and posmod(d-last,8) in [0,1,7]
					var reference := GuConceptCharacterArt.view_for(look,d)
					var pose: Dictionary = snapshot["source_pose"]
					var aim := Vector2.DOWN.rotated(d*PI/4)
					depth_fixed = depth_fixed and is_equal_approx(float(pose["arm_depth_L"]),-aim.x) and is_equal_approx(float(pose["arm_depth_R"]),aim.x)
					var source_head := GuConceptCharacterArt.source_position(reference,reference["parts"]["head"]["pivot"])
					var source_neck := GuConceptCharacterArt.source_position(reference,reference["neck"])
					var drawn_neck := Vector2(pose["head"])+(source_neck-source_head).rotated(float(pose["head_rotation"]))
					attached = attached and drawn_neck.distance_to(pose["neck"])<.0001 and Vector2(pose["neck"]).distance_to(GuConceptCharacterRig.body_point(pose,source_neck))<.0001
					for side in ["L","R"]:
						for prefix in ["arm_","leg_"]:
							var key: String = prefix+side
							var actual: PackedVector2Array = pose[key]
							var source := GuConceptCharacterRig._joint_list(reference,key)
							attached = attached and actual[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0]))<.0001
							for bone in range(2):
								if prefix=="arm_": fixed = fixed and absf(actual[bone].distance_to(actual[bone+1])-source[bone].distance_to(source[bone+1]))<.0005
							if prefix=="leg_":
								var contract := LimbContract.inspect(pose,reference,side)
								fixed = fixed and contract["lengths"] and contract["bounds"] and contract["profile_rigid"]
						var lift: Vector2 = Vector2(pose["foot_ground_"+side])-Vector2(pose["leg_"+side][2])
						planted = planted and absf(lift.x)<.0001 and lift.y>=-.0001
				stepped = stepped and int(view.capture_pose()["direction_index"])==to
	check.call(attached,"Nonzero native transitions keep both drawn neck seams and all shoulder/hip roots attached through every pair of facings")
	check.call(fixed,"Native turns retain the rendered view's rigid arms and reconstructible physical leg lengths with bounded view-specific projection")
	check.call(stepped,"Rapid turns traverse adjacent authored 45-degree views and reach the requested facing without skipping across the body")
	check.call(zero_stable,"A zero-time cast/turn preserves the entire rendered source pose, source view and sword tip across all 128 body/facing pairs")
	check.call(planted,"Turning transitions keep each contact shadow under its own ankle while blending the separate airborne lift")
	check.call(depth_fixed,"Native sleeve occlusion follows the source drawing currently rendered throughout turns instead of flipping halfway through a blend")

static func _projected_contacts(view: GuIllustratedCharacterView, check: Callable) -> void:
	var target_error := 0.0
	var knee_error := 0.0
	var samples := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for direction in range(8):
			var reference := GuConceptCharacterArt.view_for(look,direction)
			var facing := Vector2.DOWN.rotated(direction*PI/4)
			for action in ["walk","run"]:
				for frame in range(129):
					var phase := float(frame)/128
					view.present(action,view.duration(action)*phase,facing)
					var pose: Dictionary = view.capture_pose()["source_pose"]
					for side in ["L","R"]:
						var gait := GuIllustratedCharacterArt.gait_foot(phase+(.5 if side=="L" else 0),action=="run")
						if float(gait["contact"])<.999999: continue
						var source := GuConceptCharacterRig._joint_list(reference,"leg_"+side)
						var expected := source[2]+facing*float(gait["travel"])*GuConceptMotionFrames.projection(facing)
						var actual: PackedVector2Array = pose["leg_"+side]
						target_error=maxf(target_error,actual[2].distance_to(expected))
						if direction in [0,4]: knee_error=maxf(knee_error,actual[1].y-actual[2].y)
						samples+=1
	check.call(target_error<.002,"Projected leg solving preserves each original distance-driven stance target across 16 body/views and walk/run phases")
	check.call(knee_error<.0001,"Frontal walking/running stance never folds the visible knee below its sole")
	FileAccess.open("res://artifacts/concept48_projected_contacts.json",FileAccess.WRITE).store_string(JSON.stringify({"stance_samples":samples,"max_target_error":target_error,"max_knee_below_sole":knee_error},"  "))

static func _mesh(view: GuIllustratedCharacterView, check: Callable) -> void:
	var refined := true
	var neutral := true
	var topology := true
	var pinned := true
	var hem_moves := false
	var bad_triangles := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			view.present("idle",0,Vector2.DOWN.rotated(d*PI/4),true)
			var rest: Dictionary = view.capture_pose()["source_pose"]
			for key in ["torso","arm_L","arm_R"]:
				var points := GuConceptCharacterArt.part_vertices(reference,key,rest)
				var polygon: Array = reference["parts"][key]["polygon"]
				refined = refined and points.size()>polygon.size()*3
				for i in range(polygon.size()):
					neutral = neutral and points[i].distance_to(GuConceptCharacterArt.source_position(reference,polygon[i]))<.0001
			var rest_points := GuConceptCharacterArt.part_vertices(reference,"torso",rest)
			var indices := GuConceptCharacterArt.part_indices(reference,"torso")
			for action in ["walk","run","attack","cast","death"]:
				for frame in range(17):
					view.present(action,view.duration(action)*float(frame)/16,Vector2.DOWN.rotated(d*PI/4))
					var pose: Dictionary = view.capture_pose()["source_pose"]
					var points := GuConceptCharacterArt.part_vertices(reference,"torso",pose)
					for i in range(0,indices.size(),3):
						var a := indices[i]
						var b := indices[i+1]
						var c := indices[i+2]
						var before := (rest_points[b]-rest_points[a]).cross(rest_points[c]-rest_points[a])
						var after := (points[b]-points[a]).cross(points[c]-points[a])
						if before*after<=0 and bad_triangles.size()<8:
							bad_triangles.append({"body":body,"direction":d,"action":action,"frame":frame,"before":before,"after":after,"triangle":str(PackedVector2Array([rest_points[a],rest_points[b],rest_points[c]]))})
						topology = topology and before*after>0
					for i in range(rest_points.size()):
						var local := rest_points[i]-Vector2(rest["torso"])
						var attached_point := Vector2(pose["torso"])+local.rotated(float(pose["torso_rotation"]))
						if local.y<=3: pinned = pinned and points[i].distance_to(attached_point)<.0001
						elif action in ["walk","run"]: hem_moves = hem_moves or points[i].distance_to(attached_point)>.3
	check.call(refined and neutral,"Refined sleeve and coat meshes add internal deformation vertices while retaining every original neutral source landmark")
	check.call(topology,"Every actual rendered robe triangle keeps its winding through walking, running, attacks, casting and death")
	check.call(pinned and hem_moves,"The rendered source collar and belt remain pinned while internal hem vertices respond independently to steps")
	if not bad_triangles.is_empty(): print("NATIVE_MESH_DIAGNOSTICS ",JSON.stringify(bad_triangles))

static func _body_panels(view: GuIllustratedCharacterView, check: Callable, owner_images: Dictionary) -> void:
	var transferred := 0
	var missing := 0
	var kept_on_chest := 0
	var core_winding := true
	var neutral := true
	var independent := true
	var bounded := true
	var restored := 0
	var full_area := 0.0
	var complete_area := true
	var uncovered := 0
	var samples := 0
	var records := []
	var previous := {}
	for source: String in owner_images:
		var name := "character-concept-01" if source=="original" else "character-directions-02"
		previous[source]=(load("res://tests/fixtures/concept34_owners/%s-layers.res" % name) as Texture2D).get_image()
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			var owner: Image = owner_images[reference["source"]]
			var old: Image = previous[reference["source"]]
			var moved := 0
			# Include the removed resting palm below the elbow: the former
			# shoulder-only core left a visible hole through the E profile belt.
			var coat := PackedVector2Array()
			for point: Array in reference["body_core"]: coat.append(GuConceptCharacterArt._point(point))
			var coat_bounds := Rect2(coat[0],Vector2.ZERO)
			for point in coat: coat_bounds=coat_bounds.expand(point)
			var completed := GuConceptCharacterArt.source_contours(reference,"body_core")
			for y in range(floori(coat_bounds.position.y),ceili(coat_bounds.end.y)):
				for x in range(floori(coat_bounds.position.x),ceili(coat_bounds.end.x)):
					if roundi(owner.get_pixel(x,y).r*255)==64: continue
					var point := Vector2(x+.5,y+.5)
					var edge_distance := INF
					for i in range(coat.size()): edge_distance=minf(edge_distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,coat[i],coat[(i+1)%coat.size()])))
					# Ignore the outer two source pixels rounded by the silhouette;
					# every interior hole must have actual underpaint geometry.
					if edge_distance<2 or not Geometry2D.is_point_in_polygon(point,coat): continue
					var native := GuConceptCharacterArt.source_position(reference,[point.x,point.y])
					var covered := false
					for contour in completed: covered=covered or Geometry2D.is_point_in_polygon(native,contour)
					restored+=1
					uncovered+=0 if covered else 1
			for key: String in reference["sleeve_seams"]:
				var seam := PackedVector2Array()
				var outline := PackedVector2Array()
				for point: Array in reference["sleeve_seams"][key]: seam.append(GuConceptCharacterArt._point(point))
				for point: Array in reference["parts"][key]["polygon"]: outline.append(GuConceptCharacterArt._point(point))
				var bounds := Rect2(outline[0],Vector2.ZERO)
				for point in outline: bounds=bounds.expand(point)
				for y in range(floori(bounds.position.y),ceili(bounds.end.y)):
					for x in range(floori(bounds.position.x),ceili(bounds.end.x)):
						var point := Vector2(x+.5,y+.5)
						if not Geometry2D.is_point_in_polygon(point,seam) or not Geometry2D.is_point_in_polygon(point,outline): continue
						if roundi(old.get_pixel(x,y).r*255)!=64: continue
						var now := roundi(owner.get_pixel(x,y).r*255)
						kept_on_chest+=1 if now==64 else 0
						moved+=1 if now==int(GuConceptCharacterArt.manifest()["layer_ids"][key])*32 else 0
						missing+=1 if now==0 else 0
			transferred+=moved
			records.append({"body":body,"direction":d,"sleeve_pixels_reassigned":moved})
			var facing := Vector2.DOWN.rotated(d*PI/4)
			view.present("idle",0,facing,true)
			var rest: Dictionary = view.capture_pose()["source_pose"]
			var core := GuConceptCharacterArt._body_core_geometry(reference)
			var points := GuConceptCharacterArt.body_core_vertices(reference,rest)
			var contour_area := 0.0
			for contour in completed:
				var area := 0.0
				for i in range(contour.size()): area+=contour[i].cross(contour[(i+1)%contour.size()])
				contour_area+=absf(area)
			var mesh_area := 0.0
			for i in range(0,core["triangles"].size(),3):
				var a: int = core["triangles"][i]
				var b: int = core["triangles"][i+1]
				var c: int = core["triangles"][i+2]
				mesh_area+=absf((points[b]-points[a]).cross(points[c]-points[a]))
			complete_area=complete_area and absf(contour_area-mesh_area)<.01
			full_area+=mesh_area*.5
			for i in range(points.size()):
				neutral=neutral and points[i].distance_to((Vector2(core["vertices"][i])-GuConceptCharacterArt._point(reference["ground"]))*float(reference["scale"]))<.0001
			var isolated := rest.duplicate(true)
			isolated["cloth_sway"]=0.0
			isolated["cloth_lift_L"]=2.0
			isolated["cloth_lift_R"]=0.0
			for side in ["L","R"]:
				var hip := GuConceptCharacterRig._joint_list(reference,"leg_"+side)[0]-Vector2(rest["torso"])
				var point := Vector2(hip.x,15)
				var delta := GuConceptCharacterArt.coat_vertex(isolated,point,reference)-point
				independent=independent and absf(delta.y-(-2.0 if side=="L" else 0.0))<.0001
			for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
				for frame in range(33):
					view.present(action,view.duration(action)*float(frame)/32,facing)
					var pose: Dictionary = view.capture_pose()["source_pose"]
					var actual := GuConceptCharacterArt.body_core_vertices(reference,pose)
					var fields := GuConceptCharacterArt._coat_fields(pose,reference)
					for i in range(0,core["triangles"].size(),3):
						var a: int = core["triangles"][i]
						var b: int = core["triangles"][i+1]
						var c: int = core["triangles"][i+2]
						core_winding=core_winding and (points[b]-points[a]).cross(points[c]-points[a])*(actual[b]-actual[a]).cross(actual[c]-actual[a])>0
					for point: Vector2 in points:
						var local := point-Vector2(rest["torso"])
						var deformed := GuConceptCharacterArt.coat_vertex(pose,local,reference,fields)
						bounded=bounded and deformed.is_finite() and (local.y>3 or deformed.distance_to(local)<.0001)
					samples+=1
	check.call(transferred>500 and kept_on_chest==0,"Per-view sleeve seams transfer the original painted shoulder/cuff out of the standing torso, without leaving a second static sleeve")
	check.call(missing==0,"Separating the painted sleeves preserves every previously visible source pixel within the authored seam")
	check.call(neutral and core_winding,"The actual hidden-chest mesh retains neutral source coordinates and its winding in both bodies, all facings and eleven actions")
	check.call(independent,"Each robe side follows its own anatomical leg, including reversed rear views and asymmetric profile drawings")
	check.call(bounded,"Hidden chest and robe deformation keep the collar/belt pinned through 5808 action poses")
	check.call(complete_area and full_area>1000 and uncovered==0,"Independent coat mesh covers its entire clean silhouette, including all source holes, without keeping the old standing-limb outline")
	var report := {"passed":transferred>500 and kept_on_chest==0 and missing==0 and neutral and core_winding and independent and bounded and complete_area and full_area>1000 and uncovered==0,"neutral":neutral,"winding":core_winding,"full_coat_area_native":full_area,"complete_area":complete_area,"source_holes_covered":restored,"uncovered_interior_pixels":uncovered,"transferred_sleeve_pixels":transferred,"lost_sleeve_pixels":missing,"sleeve_pixels_left_on_torso":kept_on_chest,"poses":samples,"views":records}
	var file := FileAccess.open("res://artifacts/concept37_body_panels.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()

static func _sleeves(view: GuIllustratedCharacterView, check: Callable) -> void:
	var coverage := true
	var winding := true
	var shape := true
	var grip := true
	var cloth := true
	var native := true
	var min_cloth_edge := 1.0
	var max_cloth_edge := 1.0
	var max_cloth_displacement := 0.0
	var poses := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			var facing := Vector2.DOWN.rotated(d*PI/4)
			view.present("idle",0,facing,true)
			var rest: Dictionary = view.capture_pose()["source_pose"]
			for side in ["L","R"]:
				var key: String = "arm_"+side
				var original := GuConceptCharacterArt.part_vertices(reference,key,rest)
				var indices := GuConceptCharacterArt.part_indices(reference,key)
				var polygon := PackedVector2Array()
				for point: Array in reference["parts"][key]["polygon"]:
					polygon.append(GuConceptCharacterArt.source_position(reference,point))
				var outline_area := 0.0
				for contour in GuConceptCharacterArt.source_contours(reference,key):
					var area := 0.0
					for i in range(contour.size()): area+=contour[i].cross(contour[(i+1)%contour.size()])
					outline_area+=absf(area)
				var mesh_area := 0.0
				for i in range(0,indices.size(),3):
					mesh_area += absf((original[indices[i+1]]-original[indices[i]]).cross(original[indices[i+2]]-original[indices[i]]))
				coverage = coverage and absf(mesh_area-outline_area)<.003
				var source := GuConceptCharacterRig._joint_list(reference,key)
				var geometry := GuConceptCharacterArt._part_geometry(reference,key)
				for i in range(original.size()):
					native=native and original[i].distance_to(GuConceptCharacterArt.source_position(reference,[geometry["vertices"][i].x,geometry["vertices"][i].y]))<.0001
				for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
					for frame in range(33):
						view.present(action,view.duration(action)*float(frame)/32,facing)
						var snapshot := view.capture_pose()
						var pose: Dictionary = snapshot["source_pose"]
						var points := GuConceptCharacterArt.part_vertices(reference,key,pose)
						for i in range(0,indices.size(),3):
							var a := indices[i]
							var b := indices[i+1]
							var c := indices[i+2]
							var before := (original[b]-original[a]).cross(original[c]-original[a])
							var after := (points[b]-points[a]).cross(points[c]-points[a])
							winding = winding and before*after>0
							for edge in [[a,b],[b,c],[c,a]]:
								var rest_length := original[edge[0]].distance_to(original[edge[1]])
								var posed_length := points[edge[0]].distance_to(points[edge[1]])
								if int(geometry["bones"][a])==0:
									var ratio := posed_length/rest_length
									# Microscopic clipped edges lose relative precision in
									# float32. Check them with the same absolute tolerance;
									# winding remains strict for every triangle.
									if rest_length>=.01:
										min_cloth_edge=minf(min_cloth_edge,ratio)
										max_cloth_edge=maxf(max_cloth_edge,ratio)
									cloth=cloth and posed_length>.60*rest_length-.00002 and posed_length<1.40*rest_length+.00002
								else:
									shape=shape and absf(posed_length-rest_length)<.0002
						for i in range(points.size()):
							if int(geometry["bones"][i])!=0: continue
							var at := GuConceptCharacterArt.source_position(reference,[geometry["vertices"][i].x,geometry["vertices"][i].y])
							max_cloth_displacement=maxf(max_cloth_displacement,points[i].distance_to(GuConceptCharacterArt.arm_vertex(at,source,pose[key],0)))
						poses+=1
						var hand := GuConceptCharacterArt.arm_point(source[2],source,pose,key,2)
						grip = grip and hand.distance_to(GuConceptCharacterArt.hand_position(snapshot,side))<.0001
						# Check the actual lower-arm vertices, not only a helper's
						# endpoint: the nearest authored hand landmark stays rigid.
						var nearest := 0
						for i in range(1,polygon.size()):
							if polygon[i].distance_squared_to(source[2])<polygon[nearest].distance_squared_to(source[2]): nearest=i
						grip = grip and points[nearest].distance_to(GuConceptCharacterArt.arm_point(polygon[nearest],source,pose,key,int(geometry["bones"][nearest])))<.0001
	check.call(coverage,"Splitting source sleeves at the elbow and wrist covers their complete original UV outline without duplicating neutral area or dropping pixels")
	check.call(winding,"Every rendered upper-arm, forearm and palm triangle keeps its winding across both bodies, eight directions, eleven actions and 33 samples")
	check.call(shape,"Actual bracer and palm triangles retain their source lengths even at strongly folded combat poses")
	check.call(cloth and max_cloth_displacement>.10,"Rendered upper-cloth triangles deform near the elbow with bounded edge strain; no source sleeve triangle flips or exceeds 40 percent edge change")
	check.call(native,"The soft sleeve lattice preserves every source UV vertex at the approved neutral pose")
	check.call(grip,"The rendered source hand landmarks remain rigidly attached to the exact native grip used by weapons and skill effects")
	var report := {"arm_poses":poses,"bodies":2,"directions":8,"actions":11,"phases":33,"strain_measurement_min_edge_native":.01,"edge_float_tolerance_native":.00002,"minimum_cloth_edge_ratio":min_cloth_edge,"maximum_cloth_edge_ratio":max_cloth_edge,"max_cloth_displacement_native":max_cloth_displacement,"neutral_source_vertices":native,"all_triangles_keep_winding":winding,"source_uv_coverage":coverage,"bracer_and_palm_rigid":shape,"grip_attached":grip,"cloth_strain_bounded":cloth}
	var output := FileAccess.open("res://artifacts/concept37_sleeve_deformation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print("SLEEVE_DEFORMATION ",JSON.stringify(report))

static func _guard(view: GuIllustratedCharacterView, check: Callable) -> void:
	var compact := true
	var raised := true
	var source_lengths := true
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var look := GuCharacterAppearance.default_data()
			look["body"]=body
			look["weapon"]=weapon
			view.set_appearance(look)
			for d in range(8):
				var reference := GuConceptCharacterArt.view_for(look,d)
				var facing := Vector2.DOWN.rotated(d*PI/4)
				for frame in range(17):
					view.present("defend",view.duration("defend")*float(frame)/16,facing)
					var snapshot := view.capture_pose()
					var pose: Dictionary = snapshot["source_pose"]
					for side in ["L","R"]:
						var key: String = "arm_"+side
						var source := GuConceptCharacterRig._joint_list(reference,key)
						var hand_local := (Vector2(pose[key][2])-Vector2(pose["torso"])).rotated(-float(pose["torso_rotation"]))
						compact = compact and absf(hand_local.x)<=6 and hand_local.y<-4 and hand_local.y>-7
						for bone in range(2):
							source_lengths = source_lengths and absf(Vector2(pose[key][bone]).distance_to(pose[key][bone+1])-source[bone].distance_to(source[bone+1]))<.0001
					if weapon!="unarmed":
						var blade := GuConceptCharacterArt.weapon_tip(snapshot)-view.hand_position()
						# The 0.46 parry may lean outward up to 45 degrees to clear
						# the face without exceeding native elbow or palm limits.
						raised = raised and blade.y<-absf(blade.x)*.95
	check.call(compact and source_lengths,"Guard poses bring both hands above the belt near the chest with authored bone lengths in all source views and three weapon profiles")
	check.call(raised,"Both bodies hold swords and spears raised in a vertical or outward diagonal parry instead of dangling toward the ground")
