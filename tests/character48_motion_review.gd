extends SceneTree
## Genuine before/after playback from the production view. No pose substitution.
const SIZE := Vector2i(960,640)
const NAMES := ["Xuống","Xuống trái","Trái","Lên trái","Lên","Lên phải","Phải","Xuống phải"]
const CORE := ["attack","defend","gather","mine","walk","run"]
const SECONDARY := ["cast","channel","dash","hit","death","respawn"]
const TRANSITIONS := ["walk_run_stop","move_attack_move","harvest_interrupt","turn_90","turn_180"]
const POSES := [["idle",0.0],["attack",.16],["attack",.34],["attack",.56],["defend",.3],["gather",.5],["mine",.48],["walk",.18],["run",.18],["cast",.55],["channel",.3],["dash",.4],["hit",.4],["death",.8],["respawn",.5]]
var output := ""
var label := "0.48"
var dirs: Array[int] = [0,1,2,3,4,5,6,7]
var clips_filter: Array[String] = []
var quick := false
var frames_per_second := 24.0
var actors: Array[GuIllustratedCharacterView] = []
var small_actors: Array[GuIllustratedCharacterView] = []
var title: Label
var caption: Label
var sources: Dictionary
var records: Array[Dictionary] = []
var gait_phase := 0.0
var gait_time := 0.0
var previous_action := ""
var action_age := 0.0
var actor_drivers: Array[ActorView] = []
var ground_grids: Array[TravelGrid] = []
var actor_mode := false

class TravelGrid extends Node2D:
	var camera_offset := Vector2.ZERO
	func _draw() -> void:
		for y in range(-2,3):
			for x in range(-5,6):
				var p := Vector2(x*32,y*20)-Vector2(fposmod(camera_offset.x,32),fposmod(camera_offset.y,20))
				draw_circle(p,1.2,Color("91a48d",.26))

func _initialize() -> void:
	call_deferred("_run")

func _hash_sources() -> Dictionary:
	var paths := ["scripts/presentation/concept_character_rig.gd","scripts/presentation/direction_action_fit.gd","scripts/presentation/concept_pose_fit.gd","scripts/presentation/concept_joint_skin.gd","scripts/presentation/concept_character_art.gd","scripts/presentation/concept_directional_parts.gd","scripts/presentation/illustrated_character_view.gd","scripts/presentation/illustrated_character_art.gd","scripts/presentation/illustrated_character_canvas.gd","scripts/presentation/character_action_motion.gd","scripts/presentation/concept_motion_frames.gd","scripts/presentation/character_held_prop.gd","scripts/presentation/pixel_character_view.gd","scripts/presentation/actor_view.gd","assets/shaders/concept_cutout.gdshader","assets/characters/concept-rig/manifest.json","assets/characters/concept-rig/directional-atlas.svg","assets/characters/concept-rig/cloth-atlas.svg","assets/characters/concept-rig/character-concept-01.png","assets/characters/concept-rig/character-directions-02.png","tests/character48_motion_review.gd"]
	if FileAccess.file_exists("res://scripts/presentation/character_foot_plant.gd"):
		paths.append("scripts/presentation/character_foot_plant.gd")
	var result := {}
	for path: String in paths:
		assert(FileAccess.file_exists("res://"+path),path)
		result[path]=FileAccess.get_sha256("res://"+path)
	return result

func _label(text: String,position: Vector2,size: int=16) -> Label:
	var value := Label.new()
	value.position=position
	value.size=Vector2(960,30)
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.text=text
	value.add_theme_color_override("font_color",Color("e5dac0"))
	value.add_theme_font_size_override("font_size",size)
	root.add_child(value)
	return value

func _stage() -> void:
	root.content_scale_size=SIZE
	root.size=SIZE
	root.position=Vector2i(-1900,-1000)
	root.title="Cổ Sư · Kiểm tra chuyển động 0.48"
	var background := ColorRect.new()
	background.color=Color("303a34")
	background.size=SIZE
	background.z_index=-2
	root.add_child(background)
	title=_label(label+" · Kiểm tra chuyển động",Vector2(0,12),21)
	caption=_label("",Vector2(0,44),13)
	for body_index in range(2):
		var actor := GuIllustratedCharacterView.new()
		root.add_child(actor)
		actor.configure(256,256)
		actor.position=Vector2(220+body_index*480,548)
		actor.set_active(false)
		var appearance := GuCharacterAppearance.default_data()
		appearance["body"]="male" if body_index==0 else "female"
		actor.set_appearance(appearance)
		actors.append(actor)
		var grid := TravelGrid.new()
		grid.position=actor.position
		grid.z_index=-1
		grid.visible=false
		root.add_child(grid)
		ground_grids.append(grid)
		var small := GuIllustratedCharacterView.new()
		root.add_child(small)
		small.configure(256,48)
		small.position=Vector2(404+body_index*480,548)
		small.set_active(false)
		small.set_appearance(appearance)
		small_actors.append(small)
		var body_label := _label("NAM · cận cảnh 256 px" if body_index==0 else "NỮ · cận cảnh 256 px",Vector2(body_index*480,586),14)
		body_label.size.x=480
		var floor_line := Line2D.new()
		floor_line.points=PackedVector2Array([Vector2(70+body_index*480,549),Vector2(449+body_index*480,549)])
		floor_line.width=1
		floor_line.default_color=Color("728271",.45)
		root.add_child(floor_line)
	_label("Điểm bám chân và khớp được ghi từ chính pose đang hiển thị · Nhân vật nhỏ: cỡ game 48 px",Vector2(0,616),11)

func _arguments() -> void:
	output=ProjectSettings.globalize_path("res://artifacts/concept48")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
		if argument.begins_with("--label="): label=argument.trim_prefix("--label=")
		if argument.begins_with("--directions="):
			dirs.clear()
			for direction in argument.trim_prefix("--directions=").split(","): dirs.append(int(direction))
		if argument.begins_with("--clips="):
			clips_filter.assign(argument.trim_prefix("--clips=").split(","))
		if argument=="--quick": quick=true
	DirAccess.make_dir_recursive_absolute(output)

func _json_point(point: Vector2) -> Array:
	return [point.x,point.y]

func _record(file: String,time: float) -> Dictionary:
	var bodies := []
	for actor in actors:
		var snapshot := actor.capture_pose()
		var pose: Dictionary = snapshot["source_pose"]
		var joints := {}
		for side in ["L","R"]:
			for prefix in ["arm_","leg_"]:
				var chain := []
				for point: Vector2 in pose[prefix+side]: chain.append(_json_point(point))
				joints[prefix+side]=chain
			for prefix in ["grip_","wrist_","foot_ground_"]: joints[prefix+side]=_json_point(pose[prefix+side])
		bodies.append({"body":actor.appearance["body"],"origin":_json_point(actor.position),"scale":snapshot["scale"],"action":snapshot["action"],"direction":snapshot["direction_index"],"phase":snapshot["phase"],"gait_weight":snapshot.get("gait_weight",0),"contacts":[pose.get("foot_contact_L",1),pose.get("foot_contact_R",1)],"joints":joints})
	if actor_mode:
		for i in range(2):
			var driver := actor_drivers[i]
			var source: Dictionary = driver.character_view.capture_pose()["source_pose"]
			bodies[i]["actor_root"]=_json_point(driver.position)
			bodies[i]["world_feet"]=[_json_point(driver.position+source["foot_ground_L"]*float(driver.character_view.capture_pose()["scale"])),_json_point(driver.position+source["foot_ground_R"]*float(driver.character_view.capture_pose()["scale"]))]
	return {"file":file,"time":time,"actors":bodies}

func _save(file: String,time: float) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output+"/"+file
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var image := root.get_texture().get_image()
	assert(image.get_size()==SIZE)
	assert(image.save_png(path)==OK)
	records.append(_record(file,time))

func _all_actors() -> Array[GuIllustratedCharacterView]:
	var result: Array[GuIllustratedCharacterView] = []
	result.append_array(actors)
	result.append_array(small_actors)
	return result

func _transition_duration(clip: String) -> float:
	return {"walk_run_stop":1.8,"move_attack_move":1.6,"harvest_interrupt":1.65,"turn_90":1.35,"turn_180":1.2}[clip]

func _transition_state(clip: String,t: float,direction: int) -> Dictionary:
	var action := "idle"
	var weight := 0.0
	var facing := direction
	match clip:
		"walk_run_stop":
			if t<.6:
				action="walk"
				weight=smoothstep(0,.16,t)
			elif t<1.2:
				action="run"
				weight=1
			elif t<1.48:
				action="run"
				weight=1-smoothstep(1.2,1.48,t)
		"move_attack_move":
			if t<.35: action="walk"; weight=1
			elif t<.99: action="attack"; weight=.65
			else: action="walk"; weight=1
		"harvest_interrupt":
			if t<.45: action="gather"
			elif t<.75: action="walk"; weight=1
			elif t<1.2: action="mine"
			elif t<1.5: action="defend"
		"turn_90":
			action="walk"
			weight=1
			facing=posmod(direction+(2 if t>=.45 else 0)+(2 if t>=.90 else 0),8)
		"turn_180":
			action="run" if t<1.0 else "idle"
			weight=1 if t<1.0 else 0
			facing=posmod(direction+(4 if t>=.5 else 0),8)
	return {"action":action,"weight":weight,"direction":facing}

func _advance(clip: String,t: float,direction: int,dt: float) -> void:
	if clip=="actor_walk_run_stop":
		_advance_actor(t,direction,dt)
	elif clip in TRANSITIONS:
		var state := _transition_state(clip,t,direction)
		var action: String = state["action"]
		if action!=previous_action: action_age=0; previous_action=action
		else: action_age+=dt
		var running := action=="run"
		if state["weight"]>0: gait_phase+=dt/actors[0].duration("run" if running else "walk")
		var facing := Vector2.DOWN.rotated(float(state["direction"])*PI/4)
		for actor in _all_actors():
			var age: float = gait_phase*actor.duration(action) if action in ["walk","run"] else action_age
			actor.present_smooth(action,age,facing,false,dt,state["weight"],gait_phase if state["weight"]>0 else -1,running,facing)
	else:
		var facing := Vector2.DOWN.rotated(direction*PI/4)
		for actor in _all_actors(): actor.present_smooth(clip,t,facing,false,dt,1 if clip in ["walk","run"] else 0)


func _start_actor(direction: int) -> void:
	for body_index in range(2):
		var look := GuCharacterAppearance.default_data()
		look["body"]="male" if body_index==0 else "female"
		var driver := ActorView.new()
		driver.bind({"cell":Vector2.ZERO,"facing":WorldGrid.unproject(Vector2.DOWN.rotated(direction*PI/4)).normalized(),"appearance":look,"dead":false,"running":false},true)
		root.add_child(driver)
		driver.set_process(false)
		driver.hide()
		driver.character_view.set_active(false)
		actor_drivers.append(driver)

func _advance_actor(t: float,direction: int,dt: float) -> void:
	var speed := 0.0 if t<.2 or t>=1.4 else 2.0 if t<.8 else 3.5
	for i in range(2):
		var driver := actor_drivers[i]
		driver.state["running"]=t>=.8 and t<1.4
		driver.state["cell"]+=Vector2(driver.state["facing"])*speed*dt
		driver._process(dt)
		driver.hide()
		var snapshot: Dictionary = driver.character_view.capture_pose()
		var large: Dictionary = snapshot.duplicate(true)
		large["scale"]=actors[i].display_height/GuPixelCharacterView.NATIVE_HEIGHT
		actors[i]._publish(large)
		small_actors[i]._publish(snapshot)
		ground_grids[i].camera_offset=driver.position*(256.0/48.0)
		ground_grids[i].queue_redraw()

func _capture_clip(clip: String,direction: int) -> Dictionary:
	var duration: float = 2.2 if clip=="actor_walk_run_stop" else _transition_duration(clip) if clip in TRANSITIONS else actors[0].duration(clip)
	if clip in ["defend","channel"]: duration=.9
	var count := ceili(duration*frames_per_second)
	var step := duration/count
	var facing := Vector2.DOWN.rotated(direction*PI/4)
	for actor in _all_actors(): actor.present("idle",0,facing)
	gait_phase=0
	previous_action=""
	action_age=0
	actor_mode=clip=="actor_walk_run_stop"
	for grid in ground_grids: grid.visible=actor_mode
	if actor_mode: _start_actor(direction)
	var start := records.size()
	for frame in range(count):
		for substep in range(4):
			_advance(clip,(frame*4+substep)*step/4,direction,step/4)
		title.text=label+" · "+NAMES[direction]+" · "+clip
		caption.text="Frame %02d/%02d · %.3f s · %.2f FPS · Nam và nữ cùng thời điểm" % [frame+1,count,(frame+.75)*step,1/step]
		await _save("d%d/%s/frame%03d.png" % [direction,clip,frame],(frame+.75)*step)
	for driver in actor_drivers: driver.queue_free()
	actor_drivers.clear()
	actor_mode=false
	for grid in ground_grids: grid.visible=false
	return {"folder":"d%d/%s" % [direction,clip],"frames":count,"duration":duration,"fps":1/step,"records":records.slice(start)}

func _run() -> void:
	_arguments()
	sources=_hash_sources()
	_stage()
	for direction in dirs:
		records.clear()
		var clips := {}
		var pose_records := []
		if not quick:
			for index in range(POSES.size()):
				var action: String = POSES[index][0]
				for actor in _all_actors(): actor.present(action,float(POSES[index][1])*actor.duration(action),Vector2.DOWN.rotated(direction*PI/4))
				title.text=label+" · "+NAMES[direction]+" · "+action
				caption.text="Tư thế mẫu · pha %.2f" % float(POSES[index][1])
				await _save("d%d/pose%02d.png" % [direction,index],float(POSES[index][1])*actors[0].duration(action))
			pose_records=records.duplicate(true)
		var selected := CORE.duplicate()
		selected.append_array(["cast","channel"])
		if direction in [0,2,4,6]: selected.append_array(["dash","hit","death","respawn"])
		if direction in [0,4,6]:
			selected.append_array(TRANSITIONS)
			selected.append("actor_walk_run_stop")
		if not clips_filter.is_empty(): selected=clips_filter.duplicate()
		for clip: String in selected:
			clips[clip]=await _capture_clip(clip,direction)
		assert(sources==_hash_sources(),"Source changed during capture; evidence is stale")
		var report := {"version":label,"source":"Native Godot framebuffer via production GuIllustratedCharacterView.present_smooth; 4 substeps per captured frame","project":ProjectSettings.globalize_path("res://"),"source_sha256":sources,"direction":direction,"label":NAMES[direction],"size":[SIZE.x,SIZE.y],"poses":POSES if not quick else [],"pose_records":pose_records,"clips":clips,"capture_count":records.size(),"records":records}
		FileAccess.open(output+"/d%d_native.json" % direction,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("CHARACTER48_NATIVE direction=",direction," captures=",records.size()," output=",output)
	quit()
