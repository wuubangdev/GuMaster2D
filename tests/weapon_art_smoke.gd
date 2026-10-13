extends SceneTree
## Native model/material/weapon review. No gameplay authority runs in this scene.
var views: Array[GuCharacterViewport] = []
func _initialize() -> void:
	if not "--test-mode" in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	_run.call_deferred()

func _label(text: String, at: Vector2, size: int, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("d9c391"))
	root.add_child(label)
	return label

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/"+name+".png")==OK)
	print("WEAPON_ART_CAPTURE ",name," 0")

func _run() -> void:
	root.size = Vector2i(1440,960)
	root.content_scale_size = root.size
	root.title = "GuMaster2D — Wardrobe & Weapon Art 0.9"
	var background := ColorRect.new()
	background.color = Color("142025")
	background.size = Vector2(1440,960)
	root.add_child(background)
	_label("CỔ SƯ  /  TẠO HÌNH & VÕ HỌC",Vector2(20,22),28,1400)
	_label("Trang phục có hình dáng riêng · Vải dệt / da / kim loại · Kiếm / thương hai tay / quyền pháp",Vector2(20,62),16,1400)
	var weapons := ["sword","spear","unarmed"]
	var outfits := ["jade","crimson","ivory"]
	for row in range(2):
		for col in range(3):
			var view := GuCharacterViewport.new()
			view.configure(640,290)
			view.model.blend_transitions = false
			root.add_child(view)
			view.position = Vector2(240+col*480,425+row*435)
			view.set_appearance({"body":"male" if row==0 else "female","outfit":outfits[col],"weapon":weapons[col],"hair":"topknot" if row==0 else "ponytail"})
			view.present("idle",.35,Vector2.DOWN)
			views.append(view)
			_label("%s · %s" % [GuCharacterAppearance.label("outfit",outfits[col]),GuCharacterAppearance.label("weapon",weapons[col])],Vector2(col*480,446+row*435),16,480)
	await _capture("wardrobe_weapon_idle")
	for i in range(views.size()):
		var weapon: String = views[i].model.appearance["weapon"]
		views[i].present("attack",GuCharacterAnimations.duration("attack",weapon)*.55,Vector2.DOWN.rotated(-PI/4))
	await _capture("wardrobe_weapon_attack")
	for i in range(views.size()):
		var weapon: String = views[i].model.appearance["weapon"]
		views[i].present("defend",GuCharacterAnimations.duration("defend",weapon)*.32,Vector2.DOWN)
	await _capture("wardrobe_weapon_defend")
	for view in views:
		view.present("idle",.35,Vector2.UP)
	await _capture("wardrobe_weapon_rear")
	var caption := _label("",Vector2(20,93),15,1400)
	DirAccess.make_dir_recursive_absolute("res://artifacts/weapon_frames")
	var samples: Array[Dictionary] = []
	var actions := ["walk","run","attack","defend"]
	for frame in range(96):
		var action: String = actions[frame/24]
		var fraction := float(frame%24)/24.0
		var facing := Vector2.DOWN.rotated(-PI/4 if action in ["run","attack"] else 0.0)
		caption.text = {"walk":"ĐI BỘ", "run":"CHẠY", "attack":"KIẾM CHÉM · THƯƠNG ĐÂM · QUYỀN ĐẤM", "defend":"TƯ THẾ PHÒNG THỦ"}[action]
		var times := {}
		for view in views:
			var weapon: String = view.model.appearance["weapon"]
			var time := GuCharacterAnimations.duration(action,weapon)*fraction
			view.present(action,time,facing)
			times[weapon] = time
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/weapon_frames/frame_%03d.png"%frame)==OK)
		samples.append({"frame":frame,"action":action,"fraction":fraction,"weapon_times":times})
	var manifest := FileAccess.open("res://artifacts/weapon_motion_capture.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"frames":96,"sample_rate":24,"bodies":2,"weapon_families":["sword","spear","unarmed"],"samples":samples},"  "))
	manifest.close()
	print("WEAPON_ART_COMPLETE 4 screenshots, 96 frames, 6 body/wardrobe/weapon examples")
	quit()
