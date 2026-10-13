extends SceneTree
## Live-rendered turns expose shoulder depth, elbow flex and weapon grip.
## No fabricated frames: the same view is used by world, portraits and F6.

const FRAMES := 240
const DIRECTIONS := [6,7,0,1,2,3,4,5]
const NAMES := ["Nam","Tây nam","Tây","Tây bắc","Bắc","Đông bắc","Đông","Đông nam"]
const CLIPS := [
	{"body":"male","outfit":"jade","hair":"topknot","weapon":"unarmed","action":"walk","label":"Đi · Tay không"},
	{"body":"female","outfit":"crimson","hair":"ponytail","weapon":"unarmed","action":"run","label":"Chạy · Tay không"},
	{"body":"male","outfit":"jade","hair":"topknot","weapon":"sword","action":"defend","label":"Phòng thủ · Kiếm"},
	{"body":"female","outfit":"ivory","hair":"ponytail","weapon":"spear","action":"attack","label":"Tấn công · Thương"}
]
var views: Array[GuIllustratedCharacterView] = []
var small_views: Array[GuIllustratedCharacterView] = []
var samples: Array[Dictionary] = []
var heading: Label

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	_run.call_deferred()

func _label(text: String, at: Vector2, width: float, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("302b25"))
	root.add_child(label)
	return label

func _view(look: Dictionary, at: Vector2, height: float) -> GuIllustratedCharacterView:
	var view := GuIllustratedCharacterView.new()
	root.add_child(view)
	view.configure(256,height)
	view.position = at
	view.set_appearance(look)
	view.set_active(false)
	return view

func _run() -> void:
	root.content_scale_size = Vector2i(1280,800)
	root.size = Vector2i(1280,800)
	root.title = "GuMaster2D — Ink motion 0.19"
	assert(DirAccess.make_dir_recursive_absolute("res://artifacts/directional_motion")==OK)
	var background := ColorRect.new()
	background.color = Color("b8aa84")
	background.size = Vector2(1280,800)
	root.add_child(background)
	_label("NÉT MỰC / CHUYỂN ĐỘNG",Vector2(0,24),1280,28)
	_label("Nhân vật cũ · Màu giấy / nét gạch · Nhịp lấy đà / ra đòn",Vector2(0,67),1280,16)
	heading = _label("",Vector2(0,102),1280,18)
	for i in range(CLIPS.size()):
		var clip: Dictionary = CLIPS[i]
		var look := {"body":clip["body"],"outfit":clip["outfit"],"hair":clip["hair"],"weapon":clip["weapon"]}
		views.append(_view(look,Vector2(160+i*320,465),128))
		small_views.append(_view(look,Vector2(160+i*320,720),48))
		_label(clip["label"],Vector2(i*320,494),320)
	_label("Cùng rig ở kích thước chơi 48 px",Vector2(0,750),1280,16)
	await process_frame
	for frame in range(FRAMES):
		var direction := int(DIRECTIONS[frame/30])
		var facing := Vector2.DOWN.rotated(direction*PI/4)
		heading.text = "Hướng: "+NAMES[direction]
		var time := float(frame)/60
		var poses: Array[Dictionary] = []
		for i in range(views.size()):
			var action: String = CLIPS[i]["action"]
			var clip_time := fposmod(time,views[i].duration(action))
			views[i].present_smooth(action,clip_time,facing,false,1.0/60)
			small_views[i].present_smooth(action,clip_time,facing,false,1.0/60)
			var pose: Dictionary = views[i].capture_pose()["pose"]
			poses.append({"arm_L":str(pose["arm_L"]),"arm_R":str(pose["arm_R"]),"bend_L":pose["arm_bend_L"],"bend_R":pose["arm_bend_R"]})
		await process_frame
		await RenderingServer.frame_post_draw
		var framebuffer := root.get_texture().get_image()
		assert(framebuffer.get_size()==Vector2i(1280,800))
		assert(framebuffer.save_png("res://artifacts/directional_motion/frame%03d.png" % frame)==OK)
		samples.append({"frame":frame,"time":time,"direction":direction,"arms":poses})
	var file := FileAccess.open("res://artifacts/ink19_turn_capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"revision":"ink19","frames":FRAMES,"sample_rate":60,"renderer":"GuIllustratedCharacterView","directions":DIRECTIONS,"actions":["walk","run","defend","attack"],"samples":samples},"  "))
	file.close()
	print("DIRECTIONAL_MOTION_SMOKE_COMPLETE 240 native frames; eight facings; walk/run/guard/spear")
	quit()
