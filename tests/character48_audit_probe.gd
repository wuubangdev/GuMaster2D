extends SceneTree
## Read-only audit of displayed poses. Prints measurements, not aesthetic claims.
var rows := []

func _sources() -> Dictionary:
	var result := {}
	for path in ["scripts/presentation/concept_character_rig.gd","scripts/presentation/direction_action_fit.gd","scripts/presentation/concept_motion_frames.gd","scripts/presentation/illustrated_character_art.gd","scripts/presentation/illustrated_character_view.gd","scripts/presentation/actor_view.gd","scripts/presentation/character_foot_plant.gd"]:
		if FileAccess.file_exists("res://"+path): result[path]=FileAccess.get_sha256("res://"+path)
	return result

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source_hashes := _sources()
	var view := GuIllustratedCharacterView.new()
	root.add_child(view)
	view.configure(256,48)
	view.set_active(false)
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			for action in ["idle","walk","run","attack","cast","defend","channel","gather","mine","hit","dash","death","respawn"]:
				var previous := {}
				var worst := {"body":body,"d":d,"action":action,"max_joint_step":0.0,"max_elbow_step":0.0,"max_elbow_flex":0.0,"sign_changes":0}
				for i in range(241):
					view.present(action,view.duration(action)*float(i)/240,Vector2.DOWN.rotated(d*PI/4))
					var pose: Dictionary=view.capture_pose()["source_pose"]
					for side in ["L","R"]:
						var chain: PackedVector2Array=pose["arm_"+side]
						var flex: float=(chain[1]-chain[0]).angle_to(chain[2]-chain[1])
						worst["max_elbow_flex"]=maxf(float(worst["max_elbow_flex"]),absf(flex))
						if previous.is_empty(): continue
						var old: PackedVector2Array=previous["arm_"+side]
						var old_flex: float=(old[1]-old[0]).angle_to(old[2]-old[1])
						if flex*old_flex<0: worst["sign_changes"]+=1
						var change := absf(wrapf(flex-old_flex,-PI,PI))
						if change>float(worst["max_elbow_step"]):
							worst["max_elbow_step"]=change
							worst["elbow_phase"]=float(i)/240
							worst["elbow_side"]=side
						for prefix in ["arm_","leg_"]:
							for joint in range(3):
								var step: float=Vector2(pose[prefix+side][joint]).distance_to(previous[prefix+side][joint])
								if step>float(worst["max_joint_step"]):
									worst["max_joint_step"]=step
									worst["joint_phase"]=float(i)/240
									worst["joint_key"]=prefix+side+str(joint)
					previous=pose
				rows.append(worst)
	view.queue_free()
	var locomotion := []
	for d in range(8):
		var state := {"cell":Vector2(100,100),"facing":Vector2.DOWN.rotated(d*PI/4),"appearance":GuCharacterAppearance.default_data(),"running":false}
		var actor := ActorView.new()
		actor.bind(state,true)
		root.add_child(actor)
		actor.set_process(false)
		actor.character_view.set_active(false)
		# Settle the initial view turn before measuring locomotion itself.
		for settle in range(120): actor._process(1.0/120)
		var previous := {}
		var previous_world := {}
		var foot_slip := {}
		for stage in ["start","walk","run","stop","idle"]: foot_slip[stage]={"frames":0,"max_slip_px":0.0,"total_slip_px":0.0,"total_travel_px":0.0,"contact_jump_px":0.0}
		for i in range(720):
			var stage := "start" if i<60 else "walk" if i<240 else "run" if i<420 else "stop" if i<480 else "idle"
			state["running"]=stage=="run"
			if i<420: state["cell"]+=Vector2(state["facing"])*(3.0 if not state["running"] else 5.0)/120
			var before: Vector2=actor.position
			actor._process(1.0/120)
			var snapshot: Dictionary=actor.character_view.capture_pose()
			var pose: Dictionary=snapshot["source_pose"]
			for side in ["L","R"]:
				var world: Vector2=actor.position+Vector2(pose["foot_ground_"+side])*float(snapshot["scale"])
				if not previous.is_empty() and float(pose["foot_contact_"+side])>.995 and float(previous["foot_contact_"+side])>.995:
					var slip: float=world.distance_to(previous_world[side])
					var row: Dictionary=foot_slip[stage]
					row["frames"]+=1
					if slip>float(row["max_slip_px"]):
						row["max_frame"]=i
						row["max_side"]=side
						row["max_phase"]=snapshot["phase"]
						row["max_gait_weight"]=snapshot["gait_weight"]
					row["max_slip_px"]=maxf(float(row["max_slip_px"]),slip)
					row["total_slip_px"]+=slip
					row["total_travel_px"]+=actor.position.distance_to(before)
				previous_world[side]=world
			previous=pose
		locomotion.append({"d":d,"stages":foot_slip})
		actor.queue_free()
	var output := {"poses":rows,"actor_locomotion":locomotion,"source_sha256":source_hashes,"sources_stable":source_hashes==_sources()}
	FileAccess.open("res://artifacts/character48_audit_probe.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("CHARACTER48_AUDIT_PROBE ",rows.size()," pose tracks; ",locomotion.size()," actor directions")
	await process_frame
	quit()
