extends SceneTree
## Measure world-space soles on the actual ActorView, at multiple render rates.
## A pose-only test cannot detect sliding caused by root interpolation.
var failures := 0
var checks := []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures+=1; printerr("FAIL: ",label)

func _run() -> void:
	var tracks := []
	var max_slip := 0.0
	var max_idle_error := 0.0
	var sockets := true
	var frozen := true
	var finite := true
	var contacts := 0
	for body in ["male","female"]:
		for direction in range(8):
			for fps in [30,60,120]:
				var dt: float = 1.0/fps
				var look := GuCharacterAppearance.default_data()
				look["body"]=body
				var facing := Vector2.DOWN.rotated(direction*PI/4)
				var state := {"cell":Vector2(100,100),"facing":facing,"appearance":look,"running":false}
				var actor := ActorView.new()
				actor.bind(state,true)
				root.add_child(actor)
				actor.set_process(false)
				actor.character_view.set_active(false)
				for step in range(fps): actor._process(dt)
				var previous := {}
				var world_feet := {}
				var worst := 0.0
				var total := 0.0
				var rows := 0
				for frame in range(6*fps):
					var t: float = frame*dt
					state["running"]=t>=1.5 and t<3.0
					if t<3: state["cell"]+=facing*(5 if state["running"] else 3)*dt
					actor._process(dt)
					var s: Dictionary = actor.character_view.capture_pose()
					var pose: Dictionary=s["source_pose"]
					var view := GuConceptCharacterArt.view_for(look,int(s["direction_index"]))
					for side in ["L","R"]:
						var chain: PackedVector2Array=pose["leg_"+side]
						var source := GuConceptCharacterRig._joint_list(view,"leg_"+side)
						sockets=sockets and chain[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0]))<.0001
						for joint in chain: finite=finite and joint.is_finite()
						var world: Vector2=actor.position+Vector2(pose["foot_ground_"+side])*float(s["scale"])
						if not previous.is_empty() and float(pose["foot_contact_"+side])>.995 and float(previous["foot_contact_"+side])>.995:
							var slip := world.distance_to(world_feet[side])
							worst=maxf(worst,slip)
							total+=slip
							rows+=1
						world_feet[side]=world
						if t>5: max_idle_error=maxf(max_idle_error,chain[2].distance_to(source[2]))
					previous=pose
					if frame%fps==0:
						actor._sync_character(0)
						frozen=frozen and actor.character_view.capture_pose()["source_pose"]==pose
				contacts+=rows
				max_slip=maxf(max_slip,worst)
				tracks.append({"body":body,"direction":direction,"fps":fps,"contacts":rows,"max_slip_px":worst,"total_slip_px":total})
				actor.queue_free()
	check(finite and sockets,"Real movement keeps both hips attached and every displayed joint finite at 30/60/120 FPS")
	check(contacts>10000,"World-space foot checks cover both bodies, eight directions and three render rates")
	check(max_slip<.65,"Start/pace/stop planted soles have no jump above .65 native pixel")
	check(max_idle_error<.20,"After stopping, feet settle individually back to neutral instead of dragging together")
	check(frozen,"Zero-delta accepted-event sync cannot consume root travel twice or change the visible pose")
	var report := {"passed":checks.size()-failures,"failed":failures,"checks":checks,"tracks":tracks,"contacts":contacts,"max_slip_px":max_slip,"max_idle_error_px":max_idle_error}
	FileAccess.open("res://artifacts/character48_locomotion_tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CHARACTER48_LOCOMOTION ",checks.size()-failures,"/",checks.size()," max_slip=",max_slip," idle=",max_idle_error)
	await process_frame
	quit(1 if failures else 0)
