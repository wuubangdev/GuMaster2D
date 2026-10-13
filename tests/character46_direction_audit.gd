extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var rows := []
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for direction in range(8):
			var source := GuConceptCharacterArt.view_for(look,direction)
			var torso := GuConceptCharacterArt.source_position(source,source["parts"]["torso"]["pivot"])
			var facing := Vector2.DOWN.rotated(direction*PI/4)
			var row := {"body":body,"direction":direction,"source":{}}
			for key in ["arm_L","arm_R","leg_L","leg_R"]:
				var chain := GuConceptCharacterRig._joint_list(source,key)
				row["source"][key]={"joints":str(chain),"outward":signf(chain[0].x-torso.x),"length":chain[0].distance_to(chain[1])+chain[1].distance_to(chain[2])}
			for action in ["attack","gather","mine"]:
				row[action]=[]
				for phase in ([.16,.34,.56] if action=="attack" else [.16,.50,.64] if action=="gather" else [.28,.48,.64]):
					actor.present(action,actor.duration(action)*phase,facing)
					var snapshot := actor.capture_pose()
					var pose: Dictionary = snapshot["source_pose"]
					var entry := {"phase":phase,"R":str(pose["arm_R"]),"L":str(pose["arm_L"]),"tip":str(GuConceptCharacterArt.weapon_tip(snapshot)),"pick_axis":str(Vector2.UP.rotated(float(pose["tool_angle"]))),"body":str(Vector2(pose["torso"])-Vector2(pose["rest_torso"])),"rotation":pose["torso_rotation"]}
					row[action].append(entry)
			rows.append(row)
	FileAccess.open("res://artifacts/character46_direction_audit.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	quit()
