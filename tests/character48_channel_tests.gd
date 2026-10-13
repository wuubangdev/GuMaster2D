extends SceneTree
var passed := 0
var failed := 0
var findings := []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		findings.append(label)
		push_error(label)
func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var max_x := 0.0
	var max_y := -INF
	var max_flex := 0.0
	var max_step := 0.0
	var rows := []
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var look := GuCharacterAppearance.default_data()
			look["body"]=body
			look["weapon"]=weapon
			actor.set_appearance(look)
			for direction in range(8):
				var previous := {}
				var fit := true
				for frame in range(241):
					actor.present("channel",actor.duration("channel")*float(frame)/240,Vector2.DOWN.rotated(direction*PI/4))
					var pose: Dictionary = actor.capture_pose()["source_pose"]
					for side in ["L","R"]:
						var chain: PackedVector2Array = pose["arm_"+side]
						var local := (chain[2]-Vector2(pose["torso"])).rotated(-float(pose["torso_rotation"]))
						var flex := absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))
						max_x=maxf(max_x,absf(local.x))
						max_y=maxf(max_y,local.y)
						max_flex=maxf(max_flex,flex)
						fit=fit and absf(local.x)<3.0 and local.y<-3.5 and flex<=GuConceptCharacterRig.ARM_MAX_FLEX+.0001
						if previous.has(side): max_step=maxf(max_step,chain[2].distance_to(previous[side]))
						previous[side]=chain[2]
				check(fit,"Bounded chest channel "+body+"/"+weapon+"/"+str(direction))
	check(max_step<.02,"Channel breathing stays continuous through the reach-fit threshold and loop seam")
	await load("res://tests/concept_frame_review_tests.gd").run(self,check)
	var report := {"passed":passed,"failed":failed,"findings":findings,"metrics":{"channel_poses":48*241,"max_chest_x":max_x,"lowest_hand_y":max_y,"max_flex_degrees":rad_to_deg(max_flex),"max_step_per_240":max_step}}
	FileAccess.open("res://artifacts/character48_channel_tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CHARACTER48_CHANNEL ",JSON.stringify(report))
	actor.queue_free()
	await process_frame
	quit(1 if failed else 0)
