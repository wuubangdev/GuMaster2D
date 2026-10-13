extends SceneTree
## Exhaustive audit of source-space articulation, independent of raster art.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var rows := []
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var look := GuCharacterAppearance.default_data()
			look["body"]=body
			look["weapon"]=weapon
			actor.set_appearance(look)
			for direction in range(8):
				var view := GuConceptCharacterArt.view_for(look,direction)
				for action in ["idle","walk","run","attack","defend","gather","mine","cast","channel","dash","hit","death","respawn"]:
					var row := {"body":body,"weapon":weapon,"direction":direction,"action":action,"max_flex":0.0,"min_signed_L":INF,"max_signed_L":-INF,"min_signed_R":INF,"max_signed_R":-INF,"max_hand_step":0.0,"max_elbow_step":0.0,"max_blade_step":0.0,"opposite_rest_degrees":0.0,"hand_arc":0.0}
					var previous := {}
					for frame in range(121):
						actor.present(action,actor.duration(action,weapon)*float(frame)/120,Vector2.DOWN.rotated(direction*PI/4))
						var pose: Dictionary=actor.capture_pose()["source_pose"]
						for side in ["L","R"]:
							var source := GuConceptCharacterRig._joint_list(view,"arm_"+side)
							var chain: PackedVector2Array=pose["arm_"+side]
							var flex := rad_to_deg((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))
							var rest_flex := (source[1]-source[0]).angle_to(source[2]-source[1])
							row["max_flex"]=maxf(row["max_flex"],absf(flex))
							row["min_signed_"+side]=minf(row["min_signed_"+side],flex)
							row["max_signed_"+side]=maxf(row["max_signed_"+side],flex)
							row["opposite_rest_degrees"]=maxf(row["opposite_rest_degrees"],-flex*signf(rest_flex))
							if previous.has(side):
								row["max_hand_step"]=maxf(row["max_hand_step"],chain[2].distance_to(previous[side][2]))
								row["max_elbow_step"]=maxf(row["max_elbow_step"],chain[1].distance_to(previous[side][1]))
								if side=="R": row["hand_arc"]+=chain[2].distance_to(previous[side][2])
							previous[side]=chain
						var blade := (GuConceptCharacterArt.weapon_tip(actor.capture_pose())-actor.hand_position()).normalized()
						if previous.has("blade"): row["max_blade_step"]=maxf(row["max_blade_step"],absf(blade.angle_to(previous["blade"])))
						previous["blade"]=blade
					rows.append(row)
	var destination := "res://artifacts/character48_arm_audit.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): destination=argument.trim_prefix("--output=")
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	print("ARM48_AUDIT ",rows.size()," rows / ",rows.size()*121," poses saved ",destination)
	actor.queue_free()
	await process_frame
	quit()
