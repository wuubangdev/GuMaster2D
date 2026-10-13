extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var maximum := 0.0
	var worst := {}
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		for direction in range(8):
			var actor := GuIllustratedCharacterView.new()
			root.add_child(actor)
			actor.configure(256,176)
			actor.set_active(false)
			actor.set_appearance(look)
			var facing := Vector2.DOWN.rotated(direction*PI/4)
			actor.present("idle",0,facing,true)
			var rest: Dictionary = actor.capture_pose()["source_pose"]
			for action in ["attack","gather","mine"]:
				for phase in [.15,.35,.5,.65,.85]:
					actor.present(action,phase*actor.duration(action),facing,false)
					for frame in range(1,7):
						actor.present_smooth("idle",frame/60.0,facing,false,1.0/60,0)
						var pose: Dictionary = actor.capture_pose()["source_pose"]
						for side in ["L","R"]:
							var error := Vector2(pose["leg_"+side][2]).distance_to(rest["leg_"+side][2])
							if error>maximum:
								maximum=error
								worst={"body":body,"direction":direction,"action":action,"phase":phase,"frame":frame,"side":side}
			actor.free()
	print(JSON.stringify({"max_foot_drift":maximum,"worst":worst}))
	quit()
