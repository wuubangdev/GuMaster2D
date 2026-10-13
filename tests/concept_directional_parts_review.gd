extends "res://tests/concept_character_visual_smoke.gd"
## All review frames use the production CanvasItem renderer and shader.

class Layers extends Node2D:
	var actor: GuIllustratedCharacterView
	var mode := "bones"
	func _draw() -> void:
		var s := actor.capture_pose()
		var view := GuConceptCharacterArt.view_for(s["appearance"],int(s["direction_index"]))
		var pose: Dictionary = s["source_pose"]
		var factor := float(s["scale"])
		if mode=="bones":
			for side in ["L","R"]:
				for prefix in ["arm_","leg_"]:
					var joints: PackedVector2Array = pose[prefix+side]
					var points := PackedVector2Array()
					for point in joints: points.append(point*factor)
					draw_polyline(points,Color("e6b954"),1.25,true)
					for point in points: draw_circle(point,2,Color("e6b954"))
			return
		GuConceptCharacterArt._draw_body_core(self,view,pose,Vector2.ZERO,factor,Color.WHITE)
		GuConceptCharacterArt._draw_part(self,view,"torso",pose,Vector2.ZERO,factor,Color.WHITE)
		if mode=="body": return
		GuConceptCharacterArt._draw_part(self,view,"head",pose,Vector2(0,-7)*factor,factor,Color.WHITE)
		for side in ["L","R"]:
			var shift := Vector2(-23 if side=="L" else 23,0)*factor
			GuConceptDirectionalParts.draw_arm(self,s,view,side,pose,{},shift,factor,Color.WHITE)
			GuConceptDirectionalParts.draw_leg(self,view,side,pose,Vector2(0,10)*factor,factor,Color.WHITE)

func _run() -> void:
	capture_prefix="concept41"
	root.content_scale_size=Vector2i(1600,900)
	root.size=Vector2i(1600,900)
	root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1600,900)
	review_root.add_child(background)
	if not await _gpu_parts_probe():
		quit(1)
		return
	var title := _review_label("0.41 · CHI TIẾT THEO HƯỚNG / GHÉP XƯƠNG",Vector2(0,18),1600,26)
	_review_label("Nam / Nữ · 8 hướng · render trực tiếp bằng Godot",Vector2(0,55),1600,17)
	var overlays := []
	for body in range(2):
		for d in range(8):
			var actor := GuIllustratedCharacterView.new()
			review_root.add_child(actor)
			actor.configure(256,176)
			actor.position=Vector2(100+d*200,345+body*370)
			actor.set_active(false)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if body==0 else "female"
			look["weapon"]="unarmed"
			actor.set_appearance(look)
			actor.present("idle",0,Vector2.DOWN.rotated(d*PI/4),true)
			review_views.append(actor)
			var layer := Layers.new()
			layer.actor=actor
			layer.position=actor.position
			layer.hide()
			review_root.add_child(layer)
			overlays.append(layer)
			_review_label(("Nam" if body==0 else "Nữ")+" · "+DIRECTION_LABELS[d],Vector2(d*200,410+body*370),200,17)
	await _save("concept41_idle")
	for mode in ["body","exploded"]:
		for i in range(review_views.size()):
			var layer: Layers = overlays[i]
			layer.mode=mode
			layer.material=GuConceptCharacterArt.material_for(review_views[i].appearance)
			layer.show()
			layer.queue_redraw()
			review_views[i].illustration.hide()
		title.text="0.41 · "+("THÂN RIÊNG / KHÔNG VẼ LẠI TAY CHÂN CŨ" if mode=="body" else "TÁCH CÁC BỘ PHẬN KHỎI THÂN")
		await _save("concept41_"+mode)
	for i in range(review_views.size()):
		review_views[i].illustration.show()
		overlays[i].hide()
	for action in ["walk","run","attack","defend","cast","channel","hit","dash","death"]:
		var weapons := ["sword","spear","unarmed"] if action=="attack" else ["sword"]
		for weapon in weapons:
			var folder: String = "concept41_"+action+"_"+weapon
			DirAccess.make_dir_recursive_absolute("res://artifacts/"+folder)
			var frames := 24 if action in ["walk","run","attack"] else 8
			for frame in range(frames):
				var phase := float(frame)/frames
				title.text="0.41 · %s / %s · frame %02d / %02d" % [action,weapon,frame+1,frames]
				for i in range(review_views.size()):
					var actor := review_views[i]
					var look := actor.appearance.duplicate()
					look["weapon"]=weapon
					actor.set_appearance(look)
					actor.present(action,phase*actor.duration(action,weapon),Vector2.DOWN.rotated((i%8)*PI/4),false)
				await _save(folder+"/frame%03d" % frame)
				if frame in [0,frames/2]:
					for layer: Layers in overlays:
						layer.mode="bones"
						layer.material=null
						layer.show()
						layer.queue_redraw()
					await _save(folder+"_bones_%02d" % frame)
					for layer in overlays: layer.hide()
	var report := FileAccess.open("res://artifacts/concept41_native.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"captures":captures,"source":"native Godot live renderer","views":16},"  "))
	report.close()
	quit()

func _gpu_parts_probe() -> bool:
	var panel := Node2D.new()
	review_root.add_child(panel)
	var probes := []
	var background := Color("354139")
	for view: Dictionary in GuConceptCharacterArt.manifest()["views"].values():
		var kit: Dictionary = view["directional_art"]
		for key: String in kit["parts"]:
			var asset: Dictionary = kit["parts"][key]
			var texture := load(asset["path"]) as Texture2D
			var pixels := texture.get_image()
			if pixels.is_compressed(): pixels.decompress()
			var b: Array = asset["bounds"]
			var native := Vector2(0,-2 if str(asset["bone"])=="foot" else .7)
			var uv := (native-Vector2(b[0],b[1]))/Vector2(b[2],b[3])
			var sample_at := Vector2i(uv*Vector2(pixels.get_size()))
			uv=(Vector2(sample_at)+Vector2.ONE*.5)/Vector2(pixels.get_size())
			var expected := pixels.get_pixelv(sample_at)
			expected=Color(expected.r*expected.a+background.r*(1-expected.a),expected.g*expected.a+background.g*(1-expected.a),expected.b*expected.a+background.b*(1-expected.a))
			var probe := PigmentProbe.new()
			var rect: Array = asset["atlas_rect"]
			probe.uv=Vector2(18,0)+(Vector2(rect[0],rect[1])+uv*Vector2(rect[2],rect[3]))/Vector2(kit["atlas_size"][0],kit["atlas_size"][1])
			probe.source=GuConceptCharacterArt._texture("original")
			probe.position=Vector2(90+(probes.size()%22)*64,150+(probes.size()/22)*40)
			probe.scale=Vector2(.75,.5)
			probe.material=GuConceptCharacterArt.material_for(GuCharacterAppearance.default_data())
			panel.add_child(probe)
			probes.append({"view":kit["view"],"part":key,"at":probe.position+Vector2(20,12),"expected":expected})
	await _save("concept41_gpu_parts")
	var framebuffer := root.get_texture().get_image()
	var worst := 0.0
	for probe: Dictionary in probes:
		var actual := framebuffer.get_pixelv(Vector2i(probe["at"]))
		var expected: Color = probe["expected"]
		var error := Vector3(actual.r-expected.r,actual.g-expected.g,actual.b-expected.b).length()
		worst=maxf(worst,error)
		if error>.045: printerr("GPU_PART_MISMATCH ",probe["view"]," ",probe["part"]," ",error)
	var report := FileAccess.open("res://artifacts/concept41_gpu.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"parts":probes.size(),"max_rgb_error":worst,"passed":worst<.045},"  "))
	report.close()
	panel.queue_free()
	await process_frame
	return worst<.045
