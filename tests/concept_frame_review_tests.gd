extends RefCounted
## Dense checks on the actual source rig/contours; each failure records the
## direction and phase. Artwork quality still needs the native frame review.

static func run(tree: SceneTree, check: Callable) -> void:
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256,48)
	view.set_active(false)
	var pants_valid := true
	var upright := true
	var channel_hands := true
	var cuffs := true
	var stance_soles := true
	var arm_follow := true
	var arm_partitions := true
	var phases := 0
	var failures := []
	var stance_samples := 0
	var max_drift := 0.0
	var motions := {}
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var facing := Vector2.DOWN.rotated(d*PI/4)
			var reference := GuConceptCharacterArt.view_for(look,d)
			for side in ["L","R"]:
				var key: String = "arm_"+side
				var upper := GuConceptCharacterArt.arm_bone_indices(reference,key,0)
				var lower := GuConceptCharacterArt.arm_bone_indices(reference,key,1)
				arm_partitions=arm_partitions and not upper.is_empty() and not lower.is_empty() and upper.size()+lower.size()==GuConceptCharacterArt.part_indices(reference,key).size()
				for point: Array in reference["parts"]["leg_"+side]["polygon"]:
					cuffs=cuffs and float(point[1])>=float(reference["ground"][1])-22-.001
			for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
				for frame in range(33):
					view.present(action,view.duration(action)*float(frame)/32,facing)
					var pose: Dictionary = view.capture_pose()["source_pose"]
					phases+=1
					if action=="channel":
						for side in ["L","R"]:
							var local := (Vector2(pose["arm_"+side][2])-Vector2(pose["torso"])).rotated(-float(pose["torso_rotation"]))
							channel_hands=channel_hands and local.y<-3.5 and absf(local.x)<3.0
					for side in ["L","R"]:
						if action in ["walk","run"] and float(pose["foot_contact_"+side])==1:
							stance_soles=stance_soles and absf(float(pose["foot_rotation_"+side]))<.000001
						var path := GuConceptCharacterArt.pants_contour(pose["leg_"+side])
						var triangulation := Geometry2D.triangulate_polygon(path)
						if triangulation.is_empty():
							pants_valid=false
							if failures.size()<24: failures.append({"body":body,"direction":d,"action":action,"frame":frame,"issue":"pants silhouette"})
						for point in path: pants_valid=pants_valid and point.is_finite()
						if d in [0,4]: upright=upright and absf(float(pose["foot_rotation_"+side]))<.000001
			for action in ["walk","run"]:
				var drift := 0.0
				var samples := 0
				for i in range(38):
					var phase := (float(i)+.25)/40
					var step := .0025
					view.present(action,view.duration(action)*phase,facing)
					var before: Dictionary = view.capture_pose()["source_pose"]
					view.present(action,view.duration(action)*(phase+step),facing)
					var after: Dictionary = view.capture_pose()["source_pose"]
					# ActorView advances phase from actual travelled screen distance
					# and retains the original WASD direction on diagonal movement.
					var travel := facing*GuConceptMotionFrames.stride(action,facing)*step
					for side in ["L","R"]:
						if before["foot_contact_"+side]!=1.0 or after["foot_contact_"+side]!=1.0: continue
						var error := (Vector2(after["foot_ground_"+side])+travel-Vector2(before["foot_ground_"+side])).length()
						drift=maxf(drift,error)
						samples+=1
				motions["%s_%d_%s" % [body,d,action]]={"samples":samples,"max_stance_drift":drift}
				max_drift=maxf(max_drift,drift)
				stance_samples+=samples
	check.call(cuffs,"Every source boot starts at the cuff, excluding standing-pose pants creases from the moving boot cutout")
	check.call(stance_soles,"Every planted walking/running boot keeps its sole angle fixed instead of pivoting through the floor")
	check.call(arm_partitions,"Separate rear upper-arm/forearm passes cover every original sleeve triangle once, preserving opacity without duplicated source areas")
	check.call(pants_valid,"Exposed pants silhouettes triangulate without crossing themselves in 5,808 poses across both bodies, eight directions and eleven actions")
	check.call(upright,"Frontal and rear boot artwork keeps its cuff upright in all eleven actions instead of using a sideways shoe roll")
	check.call(channel_hands,"Channeling brings both authored hands together above the belt near the chest in every body, direction and sampled phase")
	check.call(stance_samples>1200 and max_drift<.003,"Planted source feet cancel direction-specific actor travel on all eight views, including upward/downward walking and running")
	var keys_loop := true
	var keys_move := true
	for side in ["L","R"]:
		for running in [false,true]:
			for back in [false,true]:
				keys_loop=keys_loop and GuConceptMotionFrames.sleeve(.99999,side,running,back).distance_to(GuConceptMotionFrames.sleeve(.00001,side,running,back))<.0001
				keys_move=keys_move and GuConceptMotionFrames.sleeve(.25,side,running,back).distance_to(GuConceptMotionFrames.sleeve(.75,side,running,back))>.1
	check.call(keys_loop and keys_move,"Authored frontal/rear sleeve keys move visibly and interpolate continuously through the cycle seam")
	for d in range(8):
		var facing := Vector2.DOWN.rotated(d*PI/4)
		for running in [false,true]:
			for side in ["L","R"]:
				var minimum := INF
				var maximum := -INF
				for i in range(64):
					var angles := GuConceptMotionFrames.arm_angles(float(i)/64,side,running,facing)
					minimum=minf(minimum,angles.y-angles.x)
					maximum=maxf(maximum,angles.y-angles.x)
				arm_follow=arm_follow and maximum-minimum>.025 and GuConceptMotionFrames.arm_angles(.999999,side,running,facing).distance_to(GuConceptMotionFrames.arm_angles(.000001,side,running,facing))<.0001
	check.call(arm_follow,"All eight walking/running directions have changing elbow flexion and continuous shoulder/forearm follow-through at the loop seam")
	var stroke := GuConceptInkStroke.geometry(PackedVector2Array([Vector2.ZERO,Vector2(16,0),Vector2(16,12),Vector2.ZERO]),1.15,.38,Color.WHITE)
	var solid := true
	for i in range(stroke[Mesh.ARRAY_COLOR].size()):
		var color: Color = stroke[Mesh.ARRAY_COLOR][i]
		solid=solid and (is_equal_approx(color.a,0) if i%4 in [0,3] else is_equal_approx(color.a,1))
	check.call(solid and stroke[Mesh.ARRAY_VERTEX].size()==12 and stroke[Mesh.ARRAY_INDEX].size()==54,"Actual vector stroke meshes retain an opaque ink core with a separate narrow transparent fringe and closed joins")
	var output := FileAccess.open("res://artifacts/concept37_geometry_review.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"poses":phases,"pants_silhouettes":phases*2,"pants_valid":pants_valid,"upright_boots":upright,"stance_samples":stance_samples,"max_stance_drift":max_drift,"per_direction":motions,"failures":failures},"  "))
	output.close()
	print("CONCEPT_FRAME_REVIEW ",phases," poses; ",stance_samples," stance pairs; drift=",max_drift)
	view.queue_free()
	await tree.process_frame
	await _actor_stance(tree,check)

static func _actor_stance(tree: SceneTree, check: Callable) -> void:
	var state := {"cell":Vector2(15,20),"facing":Vector2.DOWN,"appearance":GuCharacterAppearance.default_data(),"dead":false,"running":false}
	var actor := ActorView.new()
	actor.bind(state,true)
	tree.root.add_child(actor)
	actor.set_process(false)
	actor.character_view.set_active(false)
	var report := {}
	var max_drift := 0.0
	var samples := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		state["appearance"]=look
		for d in range(8):
			var facing := Vector2.DOWN.rotated(d*PI/4)
			state["facing"]=facing
			for action in ["walk","run"]:
				state["running"]=action=="run"
				state["cell"]=Vector2(15,20)
				actor.position=WorldGrid.project(state["cell"])
				actor.move_blend=1
				actor.stride=0
				actor.character_view.set_appearance(look)
				actor.character_view.present(action,0,facing)
				var before := {}
				var drift := 0.0
				var pairs := 0
				for frame in range(360):
					state["cell"]+=facing*3.0/240
					actor._process(1.0/240)
					var pose: Dictionary = actor.character_view.capture_pose()["source_pose"]
					var factor := actor.character_view.display_height/actor.character_view.NATIVE_HEIGHT
					var points := {}
					for side in ["L","R"]:
						var point := actor.position+Vector2(pose["foot_ground_"+side])*factor
						points[side]={"at":point,"contact":pose["foot_contact_"+side]}
						if frame<120 or before.is_empty() or points[side]["contact"]!=1.0 or before[side]["contact"]!=1.0: continue
						drift=maxf(drift,point.distance_to(before[side]["at"]))
						pairs+=1
					before=points
				report["%s_%d_%s" % [body,d,action]]={"pairs":pairs,"max_world_foot_drift":drift}
				max_drift=maxf(max_drift,drift)
				samples+=pairs
	check.call(samples>6000 and max_drift<.01,"Actual ActorView root interpolation, source rig and distance-driven clock keep steady stance feet fixed in world space across both bodies and all eight walking/running directions")
	var output := FileAccess.open("res://artifacts/concept37_actor_stance.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"samples":samples,"max_world_foot_drift":max_drift,"per_case":report},"  "))
	output.close()
	print("ACTOR_STANCE_REVIEW ",samples," pairs; world drift=",max_drift)
	actor.queue_free()
	await tree.process_frame
