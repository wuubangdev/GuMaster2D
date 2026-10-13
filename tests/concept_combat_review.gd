extends "res://tests/concept_character_visual_smoke.gd"
## Real renderer, all bodies/facings/weapons; optional joint overlay is review-only.

class Bones extends Node2D:
	var actor: GuIllustratedCharacterView
	func _draw() -> void:
		var snapshot := actor.capture_pose()
		var pose: Dictionary = snapshot["source_pose"]
		var factor := float(snapshot["scale"])
		for side in ["L","R"]:
			var chain: PackedVector2Array = pose["arm_"+side]
			var color := Color("edaf78") if side=="R" else Color("84cbd1")
			var points := PackedVector2Array([chain[0]*factor,chain[1]*factor,Vector2(pose["wrist_"+side])*factor])
			draw_polyline(points,color,1.4,true)
			for joint in points: draw_circle(joint,2.3,color,true,-1,true)
			if pose.has("cloth_guides"):
				for joint: Vector2 in pose["cloth_guides"][side]: draw_circle(joint*factor,1.4,Color("b4d289"),true,-1,true)
			var wrist := Vector2(pose["wrist_"+side])*factor
			var grip := GuConceptCharacterArt.hand_position(snapshot,side)
			draw_line(wrist,grip,Color("eae2c3"),2.0,true)
			draw_circle(wrist,2.1,Color("eae2c3"),true,-1,true)
			draw_circle(grip,3.0,color,false,1.2,true)
		if snapshot["appearance"]["weapon"]!="unarmed":
			draw_line(GuConceptCharacterArt.hand_position(snapshot),GuConceptCharacterArt.weapon_tip(snapshot),Color("e6db8d"),1.2,true)

func _run() -> void:
	capture_prefix="concept37"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="): capture_prefix=argument.trim_prefix("--capture-prefix=")
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1280,800)
	review_root.add_child(background)
	var title := _review_label("",Vector2(0,16),1280,24)
	_review_label("Nam / Nữ · 8 hướng · cùng rig và shader trong game · cam: tay cầm / xanh: tay đỡ",Vector2(0,54),1280,15)
	var actors := []
	var overlays := []
	for body in range(2):
		for d in range(8):
			var actor := GuIllustratedCharacterView.new()
			review_root.add_child(actor)
			actor.configure(256,128)
			actor.position=Vector2(80+d*160,335+body*320)
			actor.set_active(false)
			actors.append(actor)
			var bones := Bones.new()
			bones.actor=actor
			actor.add_child(bones)
			overlays.append(bones)
			_review_label(DIRECTION_LABELS[d],Vector2(d*160,349+body*320),160)
	var report := {"frames_per_weapon":48,"bodies":2,"directions":8,"weapons":{}}
	var bones_only := "--bones-only" in OS.get_cmdline_user_args()
	for weapon in ["sword","spear","unarmed"]:
		for i in range(actors.size()):
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if i<8 else "female"
			look["weapon"]=weapon
			actors[i].set_appearance(look)
		var folder := "res://artifacts/%s_combat/%s" % [capture_prefix,weapon]
		assert(DirAccess.make_dir_recursive_absolute(folder)==OK)
		var frames := []
		for frame in range(48):
			if bones_only and frame not in [0,8,12,16,23,32,47]: continue
			var phase := float(frame)/47
			title.text="KHỚP VÀ VŨ KHÍ · "+weapon.to_upper()+" · PHA %.3f" % phase
			var samples := []
			for i in range(actors.size()):
				var actor: GuIllustratedCharacterView=actors[i]
				actor.present("attack",actor.duration("attack",weapon)*phase,Vector2.DOWN.rotated((i%8)*PI/4))
				overlays[i].hide()
				var snapshot := actor.capture_pose()
				var pose: Dictionary = snapshot["source_pose"]
				samples.append({"body":actor.appearance["body"],"direction":i%8,"hands":[str(pose["grip_L"]),str(pose["grip_R"])],"wrists":[str(pose["wrist_L"]),str(pose["wrist_R"])],"hand_rotation":pose.get("hand_rotation_R",0),"support_rotation":pose.get("hand_rotation_L",0),"wrist":pose.get("weapon_wrist",0),"blade":str(GuConceptCharacterArt.weapon_tip(snapshot)-actor.hand_position())})
			await process_frame
			await RenderingServer.frame_post_draw
			if not bones_only: assert(root.get_texture().get_image().save_png(folder+"/frame%03d.png" % frame)==OK)
			if frame in [0,8,12,16,23,32,47]:
				for overlay in overlays:
					overlay.show()
					overlay.queue_redraw()
				await _save("%s_combat_%s_bones_%02d" % [capture_prefix,weapon,frame])
			frames.append({"frame":frame,"phase":phase,"samples":samples})
		report["weapons"][weapon]=frames
		print("COMBAT_CAPTURE ",weapon," ",7 if bones_only else 48," phases × 16 views")
	if not bones_only:
		var file := FileAccess.open("res://artifacts/%s_combat_review.json" % capture_prefix,FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		file.close()
	quit()
