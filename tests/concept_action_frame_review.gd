extends "res://tests/concept_character_visual_smoke.gd"
## Each PNG is the complete native framebuffer. Review every action at 32
## phases, plus front/rear contact sheets; no mockup or interpolated images.

const ACTIONS := ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]
const FRAMES := 32
var dense := []
var sheets := []

func _character(body: String, at: Vector2, height: float) -> GuIllustratedCharacterView:
	var view := GuIllustratedCharacterView.new()
	review_root.add_child(view)
	view.configure(256,height)
	view.position=at
	var look := GuCharacterAppearance.default_data()
	look["body"]=body
	view.set_appearance(look)
	view.set_active(false)
	return view

func _run() -> void:
	capture_prefix="concept29"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="): capture_prefix=argument.trim_prefix("--capture-prefix=")
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position=Vector2i(-1800,-1200)
	root.title="GuMaster2D · individual action frame review"
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1280,800)
	review_root.add_child(background)
	var title := _review_label("",Vector2(0,16),1280,24)
	var note := _review_label("",Vector2(0,54),1280,15)
	var frame_group := Node2D.new()
	review_root.add_child(frame_group)
	for row in range(2):
		for d in range(8):
			var view := _character("male" if row==0 else "female",Vector2(80+d*160,335+row*320),128)
			view.reparent(frame_group)
			dense.append(view)
			var label := _review_label(DIRECTION_LABELS[d],Vector2(d*160,349+row*320),160)
			label.reparent(frame_group)
	frame_group.hide()
	var sheet_group := Node2D.new()
	review_root.add_child(sheet_group)
	for row in range(4):
		for phase in range(8):
			var view := _character("male" if row<2 else "female",Vector2(80+phase*160,222+row*180),96)
			view.reparent(sheet_group)
			sheets.append(view)
			var label := _review_label(("Nam" if row<2 else "Nữ")+" · "+("S" if row%2==0 else "N")+" · %d/8" % phase,Vector2(phase*160,229+row*180),160,14)
			label.reparent(sheet_group)
	var metadata := {"renderer":DisplayServer.get_name(),"bodies":2,"directions":8,"frames_per_action":FRAMES,"actions":{},"front_rear_sheets":[],"native_png_frames":0,"new_bitmap_artwork":false}
	for action: String in ACTIONS:
		title.text="LÊN / XUỐNG · "+action.to_upper()+" · 8 PHA"
		note.text="Cùng renderer trong game · hai body · kiểm hình giày, quần, cổ tay và nét viền theo tư thế"
		for i in range(sheets.size()):
			var row := i/8
			var phase := float(i%8)/8
			sheets[i].present(action,sheets[i].duration(action)*phase,Vector2.DOWN if row%2==0 else Vector2.UP)
		await _save(capture_prefix+"_phases_"+action)
		metadata["front_rear_sheets"].append(capture_prefix+"_phases_"+action+".png")
		print("ACTION_PHASE_SHEET ",action)
	if not "--phases-only" in OS.get_cmdline_user_args():
		sheet_group.hide()
		frame_group.show()
		for action: String in ACTIONS:
			var folder := "res://artifacts/%s_actions/%s" % [capture_prefix,action]
			assert(DirAccess.make_dir_recursive_absolute(folder)==OK)
			var records := []
			for frame in range(FRAMES):
				var phase := float(frame)/(FRAMES if action in ["idle","walk","run","defend","channel"] else FRAMES-1)
				title.text="TỪNG FRAME · "+action.to_upper()+" · %02d/%02d" % [frame,FRAMES-1]
				note.text="Nam: hàng trên · Nữ: hàng dưới · S/SW/W/NW/N/NE/E/SE · pha %.4f" % phase
				var samples := []
				for i in range(dense.size()):
					var view: GuIllustratedCharacterView = dense[i]
					view.present(action,view.duration(action)*phase,Vector2.DOWN.rotated((i%8)*PI/4))
					var pose: Dictionary = view.capture_pose()["source_pose"]
					samples.append({"body":view.appearance["body"],"direction":i%8,"feet":[str(pose["leg_L"][2]),str(pose["leg_R"][2])],"contacts":[pose["foot_contact_L"],pose["foot_contact_R"]]})
				await process_frame
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_png(folder+"/frame%03d.png" % frame)==OK)
				records.append({"frame":frame,"phase":phase,"poses":samples})
			metadata["actions"][action]=records
			metadata["native_png_frames"]+=FRAMES
			print("ACTION_FRAMES_COMPLETE ",action," ",FRAMES," frames × 16 views")
	var output := FileAccess.open("res://artifacts/%s_action_review.json" % capture_prefix,FileAccess.WRITE)
	output.store_string(JSON.stringify(metadata,"  "))
	output.close()
	print("ACTION_REVIEW_COMPLETE ",metadata["native_png_frames"]," native frames; ",metadata["front_rear_sheets"].size()," front/rear sheets")
	quit()
