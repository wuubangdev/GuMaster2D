extends SceneTree
## Focused side-view review from the exact live renderer at native 60Hz.
## Timelines sample real clip durations. This is visual evidence, not FPS.

const FRAMES := 180
const CLIPS := [
	{"body":"male","outfit":"jade","hair":"topknot","weapon":"sword","action":"walk","facing":Vector2.RIGHT,"label":"Nam · Đi phải · Kiếm"},
	{"body":"female","outfit":"ivory","hair":"ponytail","weapon":"spear","action":"walk","facing":Vector2.LEFT,"label":"Nữ · Đi trái · Thương"},
	{"body":"female","outfit":"crimson","hair":"ponytail","weapon":"unarmed","action":"run","facing":Vector2.RIGHT,"label":"Nữ · Chạy phải"},
	{"body":"male","outfit":"jade","hair":"topknot","weapon":"unarmed","action":"run","facing":Vector2.LEFT,"label":"Nam · Chạy trái"}
]
var views: Array[GuIllustratedCharacterView] = []
var samples: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	_run.call_deferred()

func _label(text: String, at: Vector2, width: float, font_size: int = 18) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("302b25"))
	root.add_child(label)

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
	root.title = "GuMaster2D — Side profile 0.19 review"
	assert(DirAccess.make_dir_recursive_absolute("res://artifacts/profile_motion")==OK)
	var background := ColorRect.new()
	background.color = Color("b8aa84")
	background.size = Vector2(1280,800)
	root.add_child(background)
	_label("GÓC NGANG / ĐI VÀ CHẠY",Vector2(0,25),1280,28)
	_label("Rig dùng trong game và F6 · Nhịp clip thực · Đầu ổn định, chân gập gối",Vector2(0,69),1280,16)
	for i in range(CLIPS.size()):
		var clip: Dictionary = CLIPS[i]
		var look := {"body":clip["body"],"outfit":clip["outfit"],"hair":clip["hair"],"weapon":clip["weapon"]}
		var at := Vector2(160+i*320,425)
		views.append(_view(look,at,104))
		_label(clip["label"],Vector2(i*320,462),320)
		for closed in [false,true]:
			var small := _view(look,Vector2(i*320+(220 if closed else 100),711),48)
			small.present("idle",small.duration("idle")*(.896 if closed else 0.0),clip["facing"])
		_label("Mắt mở             Chớp mắt",Vector2(i*320,730),320,14)
	await process_frame
	for frame in range(FRAMES):
		var time := float(frame)/60
		var poses: Array[Dictionary] = []
		for i in range(views.size()):
			var clip: Dictionary = CLIPS[i]
			views[i].present_smooth(clip["action"],time,clip["facing"],false,1.0/60)
			poses.append(views[i].capture_pose())
		await process_frame
		await RenderingServer.frame_post_draw
		var framebuffer := root.get_texture().get_image()
		assert(framebuffer.get_size()==Vector2i(1280,800))
		assert(framebuffer.save_png("res://artifacts/profile_motion/frame%03d.png" % frame)==OK)
		samples.append({"frame":frame,"time":time,"poses":str(poses)})
	var file := FileAccess.open("res://artifacts/ink19_side_motion_capture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"revision":"ink19","frames":FRAMES,"sample_rate":60,"renderer":"GuIllustratedCharacterView","source":"Native framebuffer / live rig / actual clip durations / isolated presentation","profiles":4,"samples":samples},"  "))
	file.close()
	print("PROFILE_MOTION_SMOKE_COMPLETE 180 native frames; four side walk/run clips; open/closed eyes")
	quit()
