extends SceneTree
## Transparent native framebuffer probes during real smooth playback. Checking
## alpha catches holes independently of the background and cloth color.
var samples := 0
var holes: Array = []
var actors: Array[GuIllustratedCharacterView] = []
var seam_prefix := "concept46"
const ACTIONS := ["idle","attack","defend","gather","mine","walk","run","cast","channel","idle"]
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()
func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="): seam_prefix=argument.trim_prefix("--capture-prefix=")
	root.size=Vector2i(960,640)
	root.content_scale_size=root.size
	var viewport := SubViewport.new()
	viewport.size=Vector2i(960,640)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for body in ["male","female"]:
		var actor := GuIllustratedCharacterView.new()
		viewport.add_child(actor)
		actor.configure(256,280)
		actor.position=Vector2(240+actors.size()*480,500)
		actor.set_active(false)
		var look := GuCharacterAppearance.default_data();look["body"]=body
		actor.set_appearance(look)
		actors.append(actor)
	var directions := [0] if "--south-only" in OS.get_cmdline_user_args() else [0,1,2,3,4,5,6,7]
	for direction in directions:
		for actor in actors: actor.present("idle",0,Vector2.DOWN.rotated(direction*PI/4))
		for action in ACTIONS:
			var duration := actors[0].duration(action)
			for frame in range(24):
				for substep in range(4):
					for actor in actors:
						actor.present_smooth(action,(frame*4+substep)*duration/96,Vector2.DOWN.rotated(direction*PI/4),false,duration/96,1 if action in ["walk","run"] else 0)
				if frame%4!=0: continue
				await process_frame
				await RenderingServer.frame_post_draw
				var rendered := viewport.get_texture().get_image()
				for actor in actors: probe(actor,rendered,direction,action,frame)
				if direction==0 and action=="defend" and frame==8: rendered.save_png("res://artifacts/%s_seam_guard.png" % seam_prefix)
	var report := {"directions":directions,"actions":ACTIONS,"alpha_samples":samples,"holes":holes,"passed":holes.is_empty(),"source":"Native transparent framebuffer / present_smooth transitions and real fitting renderer"}
	report["source_sha256"]={}
	for path in ["assets/shaders/concept_cutout.gdshader","assets/characters/concept-rig/manifest.json","assets/characters/concept-rig/directional-atlas.svg"]:
		report["source_sha256"][path]=FileAccess.get_sha256("res://"+path)
	FileAccess.open("res://artifacts/%s_seams.json" % seam_prefix,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CHARACTER46_SEAMS ",samples," samples; ",holes.size()," gaps")
	viewport.queue_free()
	await process_frame
	quit(1 if not holes.is_empty() else 0)
func probe(actor: GuIllustratedCharacterView, rendered: Image, direction: int, action: String, frame: int) -> void:
	var snapshot := actor.capture_pose()
	var pose: Dictionary = snapshot["source_pose"]
	var points := {}
	for side in ["L","R"]:
		points["shoulder_"+side]=pose["arm_"+side][0]
		points["elbow_"+side]=pose["arm_"+side][1]
		points["wrist_"+side]=pose["wrist_"+side]
		points["knee_"+side]=pose["leg_"+side][1]
		points["ankle_"+side]=pose["leg_"+side][2]+Vector2(0,-.16)
	for key in points:
		for i in range(8):
			var p: Vector2 = points[key]+Vector2.from_angle(i*TAU/8)*.14
			var pixel := Vector2i(actor.position+p*float(snapshot["scale"]))
			var opacity := rendered.get_pixelv(pixel).a if Rect2i(Vector2i.ZERO,rendered.get_size()).has_point(pixel) else 0.0
			if opacity<.95: holes.append({"body":actor.appearance["body"],"direction":direction,"action":action,"frame":frame,"joint":key,"alpha":opacity})
			samples+=1
