extends "res://tests/polish_visual_smoke.gd"
## Actual game and native cutout captures, with no substituted mockup frames.

var review_views: Array[GuIllustratedCharacterView] = []
var review_root: Node2D
var captures: Array[String] = []
var capture_prefix: String = "concept24"
var world_motion: Array[Dictionary] = []
var vertical_motion: Array[Dictionary] = []
var turn_motion: Array[Dictionary] = []
var direction_labels: Array[Label] = []
const DIRECTION_LABELS := ["S","SW","W","NW","N","NE","E","SE"]

class PigmentProbe extends Node2D:
	var source: Texture2D
	var uv: Vector2
	func _draw() -> void:
		draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(64,0),Vector2(64,64),Vector2(0,64)]),PackedColorArray([Color.WHITE]),PackedVector2Array([uv,uv,uv,uv]),source)

class InkProbe extends Node2D:
	var fraction := .5
	var opacity := 1.0
	func _draw() -> void:
		GuConceptInkStroke.draw(self,PackedVector2Array([Vector2(32+fraction,5),Vector2(32+fraction,59)]),.48,Color("332c24",opacity))

func _ink_probes() -> bool:
	var panel := ColorRect.new()
	panel.color=Color("354139")
	panel.size=Vector2(1280,800)
	review_root.add_child(panel)
	var probes := []
	for opacity in [1.0,.5]:
		for white in [false,true]:
			for fraction in [.25,.5,.75]:
				var at := Vector2(100+(probes.size()%6)*175,250+(probes.size()/6)*250)
				var background := ColorRect.new()
				background.color=Color.WHITE if white else Color.BLACK
				background.position=at
				background.size=Vector2(64,64)
				review_root.add_child(background)
				var probe := InkProbe.new()
				probe.position=at
				probe.fraction=fraction
				probe.opacity=opacity
				probe.material=GuConceptCharacterArt.material_for(GuCharacterAppearance.default_data())
				review_root.add_child(probe)
				var ink := Color("332c24")
				var expected := ink.lerp(background.color,1-opacity)
				probes.append({"at":at+Vector2(32,32),"expected":expected,"background":background.color,"opacity":opacity,"fraction":fraction})
	await _save(capture_prefix+"_ink_core")
	var framebuffer := root.get_texture().get_image()
	var measurements := []
	for probe: Dictionary in probes:
		var pixel := framebuffer.get_pixelv(Vector2i(probe["at"]))
		var expected: Color = probe["expected"]
		var error := Vector3(pixel.r-expected.r,pixel.g-expected.g,pixel.b-expected.b).length()
		var outside := framebuffer.get_pixelv(Vector2i(probe["at"])+Vector2i(3,0))
		var background: Color = probe["background"]
		var fringe_error := Vector3(outside.r-background.r,outside.g-background.g,outside.b-background.b).length()
		measurements.append({"opacity":probe["opacity"],"subpixel":probe["fraction"],"ink_core_rgb_error":error,"outside_rgb_error":fringe_error})
		if error>.012 or fringe_error>.012:
			printerr("INK_CORE_MISMATCH ",measurements[-1])
			return false
	var output := FileAccess.open("res://artifacts/%s_ink_core.json" % capture_prefix,FileAccess.WRITE)
	output.store_string(JSON.stringify(measurements,"  "))
	output.close()
	print("CONCEPT_INK_CORE ",measurements.size()," GPU samples")
	return true

func _edge_probes() -> bool:
	var panel := ColorRect.new()
	panel.color=Color("354139")
	panel.size=Vector2(1280,800)
	review_root.add_child(panel)
	var probes := []
	for source_name in ["original","directions"]:
		var texture := GuConceptCharacterArt._texture(source_name)
		var pixels := texture.get_image()
		if pixels.is_compressed(): pixels.decompress()
		var file := "character-concept-01" if source_name=="original" else "character-directions-02"
		var resource: Texture2D = load("res://assets/characters/concept-rig/%s-layers.res" % file)
		var owners := resource.get_image()
		var best := {}
		var contrast := 0.0
		for y in range(150,320):
			for x in range(660,790) if source_name=="original" else range(370,500):
				if roundi(owners.get_pixel(x,y).r*255)!=32: continue
				var ink := pixels.get_pixel(x,y)
				for offset: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next := Vector2i(x,y)+offset
					if owners.get_pixelv(next).r!=0: continue
					var paper := pixels.get_pixelv(next)
					var distance := Vector3(ink.r-paper.r,ink.g-paper.g,ink.b-paper.b).length()
					if distance>contrast:
						contrast=distance
						best={"ink":ink,"pixel":Vector2(x+.5,y+.5)+Vector2(offset)*.5}
		if contrast<.12:
			printerr("EDGE_PROBE_NO_SAMPLE ",source_name," contrast=",contrast)
			return false
		for white in [false,true]:
			var at := Vector2(100+probes.size()*250,300)
			var background := ColorRect.new()
			background.color=Color.WHITE if white else Color.BLACK
			background.position=at
			background.size=Vector2(64,64)
			review_root.add_child(background)
			var probe := PigmentProbe.new()
			probe.source=texture
			probe.uv=Vector2(best["pixel"])/Vector2(texture.get_size())+Vector2(2,0)
			probe.position=at
			probe.material=GuConceptCharacterArt.material_for(GuCharacterAppearance.default_data())
			review_root.add_child(probe)
			var ink: Color = best["ink"]
			probes.append({"source":source_name,"at":at+Vector2(32,32),"expected":Color(ink.r*.5+(.5 if white else 0),ink.g*.5+(.5 if white else 0),ink.b*.5+(.5 if white else 0)),"background":"white" if white else "black"})
	await _save(capture_prefix+"_edge_filter")
	var actual := root.get_texture().get_image()
	var measurements := []
	for probe: Dictionary in probes:
		var pixel := actual.get_pixelv(Vector2i(probe["at"]))
		var expected: Color = probe["expected"]
		var error := Vector3(pixel.r-expected.r,pixel.g-expected.g,pixel.b-expected.b).length()
		measurements.append({"source":probe["source"],"background":probe["background"],"rgb_error":error})
		if error>=.025:
			printerr("EDGE_FILTER_MISMATCH ",probe["source"]," ",probe["background"]," expected=",expected," actual=",pixel," error=",error)
			return false
	var output := FileAccess.open("res://artifacts/%s_edge_filter.json" % capture_prefix,FileAccess.WRITE)
	output.store_string(JSON.stringify(measurements,"  "))
	output.close()
	print("CONCEPT_EDGE_FILTER ",JSON.stringify(measurements))
	return true

func _hold(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code
	event.pressed=pressed
	root.push_input(event,true)

func _save(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/%s.png" % name)==OK)
	captures.append(name+".png")
	print("CONCEPT_CAPTURE ",name)

func _review_label(text: String, at: Vector2, width: float, font_size: int=18) -> Label:
	var label := Label.new()
	label.text=text
	label.position=at
	label.size.x=width
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("efe2c6"))
	review_root.add_child(label)
	return label

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="):
			capture_prefix=argument.trim_prefix("--capture-prefix=")
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position=Vector2i(-1800,-1200)
	root.title="GuMaster2D — Source concept character review"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro=false
	game.simulation.player["appearance"]=GuCharacterAppearance.default_data()
	_fixture()
	game.simulation.player["facing"]=WorldGrid.unproject(Vector2.DOWN)
	game.world_view.player_view._sync_character()
	await _save(capture_prefix+"_world_front")
	game.simulation.player["facing"]=WorldGrid.unproject(Vector2(1,1).normalized())
	game.world_view.player_view._sync_character()
	await _save(capture_prefix+"_world_quarter")
	for slot in range(4):
		_fixture()
		_accept(slot)
		_step(0.30 if slot==0 else 0.08 if slot==2 else 0.25)
		await _save(capture_prefix+"_world_skill_%d" % (slot+1))
	if capture_prefix!="concept24":
		_fixture()
		for mob in game.simulation.mobs.values(): mob["dead"]=true
		game.world_view.player_view.character_view.present("idle",0,Vector2.RIGHT,true)
		assert(DirAccess.make_dir_recursive_absolute("res://artifacts/%s_gameplay" % capture_prefix)==OK)
		for frame in range(64):
			if frame==0: _hold(KEY_D,true)
			if frame==24:
				_hold(KEY_D,false)
				_hold(KEY_S,true)
				_hold(KEY_SHIFT,true)
			if frame==48:
				_hold(KEY_S,false)
				_hold(KEY_SHIFT,false)
			game.input_controller.update_movement()
			_step(1.0/24)
			await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://artifacts/%s_gameplay/frame%03d.png" % [capture_prefix,frame])==OK)
			var native_pose: Dictionary = game.world_view.player_view.character_view.capture_pose()["source_pose"]
			world_motion.append({"frame":frame,"cell":str(game.simulation.player["cell"]),"displayed_root":str(game.world_view.player_view.position),"action":game.world_view.player_view.character_view.current_action,"left_foot":str(native_pose["leg_L"][2]),"right_foot":str(native_pose["leg_R"][2])})
		await _save(capture_prefix+"_world_after_stop")
		if capture_prefix in ["concept29","concept30","concept31","concept32","concept33","concept34","concept35","concept36","concept37"]:
			_fixture()
			for mob in game.simulation.mobs.values(): mob["dead"]=true
			assert(DirAccess.make_dir_recursive_absolute("res://artifacts/%s_vertical" % capture_prefix)==OK)
			for frame in range(96):
				if frame==0: _hold(KEY_W,true)
				if frame==24: _hold(KEY_SHIFT,true)
				if frame==48:
					_hold(KEY_W,false)
					_hold(KEY_S,true)
				if frame==72:
					_hold(KEY_S,false)
					_hold(KEY_SHIFT,false)
				game.input_controller.update_movement()
				_step(1.0/24)
				await process_frame
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_png("res://artifacts/%s_vertical/frame%03d.png" % [capture_prefix,frame])==OK)
				var view := game.world_view.player_view.character_view
				var native_pose: Dictionary = view.capture_pose()["source_pose"]
				vertical_motion.append({"frame":frame,"cell":str(game.simulation.player["cell"]),"direction":view.current_direction,"action":view.current_action,"contacts":[native_pose["foot_contact_L"],native_pose["foot_contact_R"]]})
	game.hide()
	game.hud.root.hide()
	var overlay := CanvasLayer.new()
	overlay.layer=100
	root.add_child(overlay)
	review_root=Node2D.new()
	overlay.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1280,800)
	review_root.add_child(background)
	_review_label("NHÂN VẬT TỪ CONCEPT GỐC · 8 HƯỚNG",Vector2(0,18),1280,26)
	_review_label("Bản vẽ nguồn được hiển thị qua mask · cùng renderer với nhân vật ngoài bản đồ",Vector2(0,56),1280,16)
	for row in range(2):
		for d in range(8):
			var view := GuIllustratedCharacterView.new()
			review_root.add_child(view)
			view.configure(256,128)
			view.position=Vector2(80+d*160,340+row*320)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if row==0 else "female"
			view.set_appearance(look)
			view.set_active(false)
			view.present("idle",0.0,Vector2.DOWN.rotated(d*PI/4),true)
			review_views.append(view)
			direction_labels.append(_review_label(DIRECTION_LABELS[d],Vector2(d*160,352+row*320),160))
	await _save(capture_prefix+"_directions")
	if capture_prefix not in ["concept24","concept25"]:
		for view in review_views:
			var meshes: Array = view.illustration.get_meta("concept_draw_meshes",[])
			var source := GuConceptCharacterArt.view_for(view.appearance,int(view.capture_pose()["direction_index"]))
			var expected: int = source["parts"].size()+(1 if source.has("body_core") else 0)
			# Neutral cloth adds two passes per arm: opaque wash and the
			# transparent extension fold. Flex crease is zero at neutral.
			if source.has("modular_art"): expected+=4
			assert(meshes.size()==expected,"Source parts and independent SVG cloth submit bounded indexed meshes, independently of subdivision")
			for mesh: ArrayMesh in meshes: assert(mesh.get_surface_count()==1)
	for action in ["walk","run","attack","defend","cast","channel"]:
		for i in range(review_views.size()):
			var view := review_views[i]
			view.present(action,view.duration(action)*0.33,Vector2.DOWN.rotated((i%8)*PI/4))
		await _save(capture_prefix+"_"+action)
	assert(DirAccess.make_dir_recursive_absolute("res://artifacts/%s_motion" % capture_prefix)==OK)
	for frame in range(48):
		for i in range(review_views.size()):
			var view := review_views[i]
			var action := "walk" if i<8 else "run"
			view.present_smooth(action,float(frame)/24,Vector2.DOWN.rotated((i%8)*PI/4),false,1.0/24)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/%s_motion/frame%03d.png" % [capture_prefix,frame])==OK)
	if capture_prefix not in ["concept24","concept25"]:
		assert(DirAccess.make_dir_recursive_absolute("res://artifacts/%s_turn" % capture_prefix)==OK)
		for i in range(review_views.size()):
			review_views[i].present("walk",.19,Vector2.DOWN.rotated((i%8)*PI/4))
		for frame in range(48):
			var poses := []
			for i in range(review_views.size()):
				var d := i%8
				var turn := 0 if frame<8 else 4 if frame<20 else 6 if frame<30 else 1
				var action := "run" if frame<30 else "attack" if frame<44 else "idle"
				var time := float(frame)/24 if frame<30 else float(frame-30)/24 if frame<44 else float(frame-44)/24
				var view := review_views[i]
				view.present_smooth(action,time,Vector2.DOWN.rotated(((d+turn)%8)*PI/4),false,1.0/24)
				var pose := view.capture_pose()
				direction_labels[i].text=DIRECTION_LABELS[int(pose["direction_index"])]+" · "+action
				poses.append({"body":pose["appearance"]["body"],"source_direction":pose["direction_index"],"target_direction":pose["control_direction_index"],"action":action})
			await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://artifacts/%s_turn/frame%03d.png" % [capture_prefix,frame])==OK)
			turn_motion.append({"frame":frame,"poses":poses})
		for i in range(direction_labels.size()): direction_labels[i].text=DIRECTION_LABELS[i%8]
		for i in range(review_views.size()):
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if i<8 else "female"
			look["weapon"]="unarmed"
			review_views[i].set_appearance(look)
			review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4),true)
		await _save(capture_prefix+"_unarmed")
	for i in range(review_views.size()):
		var look := GuCharacterAppearance.default_data()
		look["body"]="male" if i<8 else "female"
		look["outfit"]="crimson" if i<8 else "ivory"
		look["hair"]="topknot" if i<8 else "ponytail"
		look["weapon"]="sword" if i<8 else "spear"
		look["boots"]="leather"
		look["hat"]="bamboo" if i<8 else "sect"
		review_views[i].set_appearance(look)
		review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4),true)
	await _save(capture_prefix+"_equipment")
	if capture_prefix!="concept24":
		for i in range(review_views.size()):
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if i<8 else "female"
			review_views[i].set_appearance(look)
			review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4),true)
		await _save(capture_prefix+"_opacity_base")
		var opaque := root.get_texture().get_image()
		for view in review_views: view.modulate.a=.5
		await _save(capture_prefix+"_opacity_half")
		var faded := root.get_texture().get_image()
		var background_color := faded.get_pixel(4,400)
		for view in review_views:
			var point := view.position+Vector2(view.capture_pose()["source_pose"]["head"])*view.display_height/view.NATIVE_HEIGHT
			var a := opaque.get_pixel(roundi(point.x),roundi(point.y))
			var b := faded.get_pixel(roundi(point.x),roundi(point.y))
			var before := Vector3(a.r-background_color.r,a.g-background_color.g,a.b-background_color.b).length()
			var after := Vector3(b.r-background_color.r,b.g-background_color.g,b.b-background_color.b).length()
			assert(before>.025 and after>before*.15 and after<before*.90,"Fading must retain the same head ownership and source pixels")
	if capture_prefix in ["concept28","concept29","concept30","concept31","concept32","concept33","concept34","concept35","concept36","concept37"]:
		for i in range(review_views.size()):
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if i<8 else "female"
			review_views[i].set_appearance(look)
			review_views[i].modulate=Color.WHITE
			review_views[i].present("run",review_views[i].duration("run")*.33,Vector2.DOWN.rotated((i%8)*PI/4))
		background.color=Color.WHITE
		for child in review_root.get_children():
			if child is Label: child.add_theme_color_override("font_color",Color("332c24"))
		await _save(capture_prefix+"_outline_light")
		background.color=Color("354139")
		for child in review_root.get_children():
			if child is Label: child.add_theme_color_override("font_color",Color("efe2c6"))
		await _save(capture_prefix+"_outline_dark")
		if not await _edge_probes():
			quit(1)
			return
		if capture_prefix in ["concept29","concept30","concept31","concept32","concept33","concept34","concept35","concept36","concept37"] and not await _ink_probes():
			quit(1)
			return
	var output := FileAccess.open("res://artifacts/%s_capture.json" % capture_prefix,FileAccess.WRITE)
	output.store_string(JSON.stringify({"renderer":"source-concept cutouts","native_renderer":DisplayServer.get_name(),"captures":captures,"directions":8,"bodies":2,"accepted_skills":4,"motion_frames":48,"motion_sample_rate":24,"gameplay_frames":world_motion.size(),"gameplay_input":"D, Shift+S, release to stop","world_motion":world_motion,"vertical_frames":vertical_motion.size(),"vertical_input":"W, Shift+W, Shift+S, release to stop","vertical_motion":vertical_motion,"turn_frames":turn_motion.size(),"turn_motion":turn_motion},"  "))
	output.close()
	print("CONCEPT_SMOKE_COMPLETE ",captures.size()," native screenshots; 48 walk/run frames")
	quit()
