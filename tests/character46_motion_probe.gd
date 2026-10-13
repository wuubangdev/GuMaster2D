extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		var view := GuConceptCharacterArt.view_for(look,0)
		var source := {}
		for key in ["arm_L","arm_R","leg_L","leg_R"]: source[key]=str(GuConceptCharacterRig._joint_list(view,key))
		print("SOURCE ",body," ",JSON.stringify(source))
		for direction in range(8):
			for weapon in ["sword","spear","unarmed"]:
				look["weapon"]=weapon
				actor.set_appearance(look)
				actor.present("defend",.1,Vector2.DOWN.rotated(direction*PI/4))
				var pose: Dictionary = actor.capture_pose()["source_pose"]
				for side in ["L","R"]:
					var local := (Vector2(pose["arm_"+side][2])-Vector2(pose["torso"])).rotated(-float(pose["torso_rotation"]))
					if absf(local.x)>6 or local.y>=-4 or local.y<=-7: print("GUARD_BOX ",body," ",weapon," ",direction," ",side," ",local)
		look["weapon"]="sword"
		actor.set_appearance(look)
		for action in ["idle","attack","gather","mine","defend"]:
			for phase in ([0.0] if action=="idle" else [.16,.34,.50,.64]):
				actor.present(action,actor.duration(action)*phase,Vector2.DOWN)
				var shot := actor.capture_pose()
				var pose: Dictionary = shot["source_pose"]
				print("POSE ",body," ",action," ",phase," ",JSON.stringify({"torso":str(pose["torso"]),"rotation":pose["torso_rotation"],"R":str(pose["arm_R"]),"L":str(pose["arm_L"]),"legR":str(pose["leg_R"]),"tip":str(GuConceptCharacterArt.weapon_tip(shot))}))
	quit()
