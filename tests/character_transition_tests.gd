extends RefCounted
## Observe final displayed chains, not just clip keys. Covers interrupted
## actions, view retargeting and prop handoffs at different render rates.
const LimbContract = preload("res://tests/character48_limb_contract.gd")

static func run(tree: SceneTree, check: Callable) -> void:
	var actor := GuIllustratedCharacterView.new()
	tree.root.add_child(actor)
	actor.configure(256,176)
	actor.set_active(false)
	var samples := 0
	var max_foot_error := 0.0
	var max_bone_error := 0.0
	var turn_error := 0.0
	var knee_poles := true
	var sockets := true
	var props := true
	var frozen := true
	var projection := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for d in range(8):
			var facing := Vector2.DOWN.rotated(d*PI/4)
			var view := GuConceptCharacterArt.view_for(look,d)
			for fps in [30,60,120]:
				var dt: float = 1.0/fps
				for action in ["attack","gather","mine"]:
					for phase in [.15,.35,.5,.65,.85]:
						actor.present(action,phase*actor.duration(action),facing)
						var start := actor.capture_pose()
						actor.present_smooth("idle",0,facing,false,0,0)
						frozen=frozen and actor.capture_pose()["source_pose"]==start["source_pose"] and actor.capture_pose()["held_prop"]==start["held_prop"]
						for frame in range(1,ceili(.15*fps)+1):
							actor.present_smooth("idle",frame*dt,facing,false,dt,0)
							var s := actor.capture_pose()
							var pose: Dictionary = s["source_pose"]
							for side in ["L","R"]:
								var foot := GuConceptCharacterRig._joint_list(view,"leg_"+side)[2]
								max_foot_error=maxf(max_foot_error,Vector2(pose["leg_"+side][2]).distance_to(foot))
								for prefix in ["arm_","leg_"]:
									var source := GuConceptCharacterRig._joint_list(view,prefix+side)
									var chain: PackedVector2Array = pose[prefix+side]
									var physical := LimbContract.physical_lengths(pose,side) if prefix=="leg_" else Vector2(chain[0].distance_to(chain[1]),chain[1].distance_to(chain[2]))
									for bone in range(2): max_bone_error=maxf(max_bone_error,absf(physical[bone]-source[bone].distance_to(source[bone+1])))
									if prefix=="leg_":
										var contract := LimbContract.inspect(pose,view,side)
										projection=projection and contract["lengths"] and contract["bounds"] and contract["profile_rigid"] and contract["stance_knee"]
									sockets=sockets and chain[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0]))<.0001
							props=props and float(s["held_prop"]["opacity"])>=0 and float(s["held_prop"]["opacity"])<=1
							samples+=1
						props=props and actor.capture_pose()["held_prop"]["kind"]=="sword" and float(actor.capture_pose()["held_prop"]["opacity"])>.99
				actor.present("mine",.5*actor.duration("mine"),facing)
				for frame in range(1,ceili(.2*fps)+1):
					actor.present_smooth("idle",frame*dt,-facing,false,dt,0)
					var s := actor.capture_pose()
					var turn_view := GuConceptCharacterArt.view_for(look,int(s["direction_index"]))
					for side in ["L","R"]:
						turn_error=maxf(turn_error,Vector2(s["source_pose"]["leg_"+side][2]).distance_to(GuConceptCharacterRig._joint_list(turn_view,"leg_"+side)[2]))
						var chain: PackedVector2Array = s["source_pose"]["leg_"+side]
						var source := GuConceptCharacterRig._joint_list(turn_view,"leg_"+side)
						var aim := Vector2.DOWN.rotated(int(s["direction_index"])*PI/4)
						var pole := -signf(aim.x) if absf(aim.x)>.1 else -signf(source[0].x-Vector2(s["source_pose"]["rest_torso"]).x)
						var projected: Vector2 = s["source_pose"]["leg_projection_"+side]
						var expected := GuConceptCharacterRig.solve_limb(chain[0],chain[2],source[0].distance_to(source[1])*projected.x,source[1].distance_to(source[2])*projected.y,pole)
						knee_poles=knee_poles and chain[1].distance_to(expected[1])<.002
	check.call(max_foot_error<.002,"Interrupted sword/gather/mine keeps both toes anchored at 30/60/120 FPS in all 16 body/views")
	check.call(max_bone_error<.0001 and sockets and projection,"Transition IK preserves rigid arms, reconstructible physical leg lengths, bounded leg projection and every shoulder/hip socket")
	check.call(turn_error<.002,"A half-turn remaps planted feet relative to each authored view without carrying the old view's leg arc")
	check.call(knee_poles,"Turning knees bend in the currently rendered view's plane rather than the previous facing")
	check.call(frozen,"Zero-delta event sync preserves the exact visible pose and prop")
	check.call(props,"Interrupted work restores the equipped weapon with bounded single-prop opacity")
	for equipped in ["sword","spear","unarmed"]:
		var expected: String = "none" if equipped=="unarmed" else equipped
		for action in ["mine","gather"]:
			var first := GuCharacterHeldProp.desired(action,0,equipped)
			var contact := GuCharacterHeldProp.desired(action,.5,equipped)
			var last := GuCharacterHeldProp.desired(action,1,equipped)
			check.call(first==last and first["kind"]==expected and first["opacity"]==1.0 and contact["kind"]==("pick" if action=="mine" else "none") and contact["opacity"]==1.0,"Tool appears during contact and returns equipment at clip endpoints: "+action+" / "+equipped)
	var boundaries := true
	var rates := []
	for fps in [30,60,120]:
		var holder := GuCharacterHeldProp.new()
		var current := holder.reset({"kind":"pick","opacity":1.0})
		for step in range(roundi(.1*fps)):
			var after := holder.advance({"kind":"sword","opacity":1.0},1.0/fps)
			if after["kind"]!=current["kind"]: boundaries=boundaries and float(current["opacity"])<=1.0/fps/GuCharacterHeldProp.HIDE_SECONDS+.00001
			current=after
		rates.append(current)
	check.call(boundaries,"An interrupted prop never changes identity while its outgoing image is still visible")
	check.call(absf(float(rates[0]["opacity"])-float(rates[2]["opacity"]))<.00001,"Single-prop handoff duration is independent of 30 versus 120 FPS")
	actor.present("mine",.4*actor.duration("mine"),Vector2.RIGHT)
	actor.present_smooth("walk",.1,Vector2.RIGHT,false,1.0/120)
	var interrupted := actor.capture_pose()
	check.call(interrupted["held_prop"]["kind"]=="pick" and interrupted["arms_behind_head"] and is_finite(float(interrupted["source_pose"]["tool_angle"])),"Mine-to-walk retains the pick socket and behind-head layer during the first interruption frame")
	actor.present("idle",0,Vector2.RIGHT,true)
	check.call(actor.capture_pose()["held_prop"]=={"kind":"sword","opacity":1.0} and not actor.capture_pose()["arms_behind_head"],"An explicit/reduced seek resets the prop and occlusion history")
	actor.queue_free()
	var report := {"samples":samples,"max_foot_drift":max_foot_error,"max_bone_error":max_bone_error,"max_turn_foot_drift":turn_error,"event_sync_frozen":frozen,"sockets":sockets,"props":props,"fps":[30,60,120]}
	FileAccess.open("res://artifacts/concept43_transitions.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CHARACTER_TRANSITIONS ",JSON.stringify(report))
