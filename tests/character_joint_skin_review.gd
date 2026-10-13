extends "res://tests/character_action_motion_review.gd"

const POSES := [["idle",0.0],["walk",.18],["walk",.75],["attack",.16],["attack",.34],["defend",.3],["mine",.30],["gather",.50]]
var joint_probes := 0
var joint_gaps: Array = []

func _probe_joints(tag: String, rendered: Image) -> void:
	for i in range(review_views.size()):
		var actor := review_views[i]
		var s := actor.capture_pose()
		for side in ["L","R"]:
			for key in ["arm_","leg_"]:
				var chain: PackedVector2Array = s["source_pose"][key+side]
				for joint in range(1,3):
					var center := chain[joint]
					if joint==2:
						# Arm endpoint 2 is the palm grip, leg endpoint 2 is the
						# ground sole. Probe the actual cuff/ankle above them.
						center=s["source_pose"]["wrist_"+side] if key=="arm_" else chain[2]+Vector2(0,-2).rotated(float(s["source_pose"]["foot_rotation_"+side]))
					for angle in range(8):
						var point := actor.position+(center+Vector2.from_angle(angle*PI/4)*.30)*float(s["scale"])
						var color := rendered.get_pixelv(Vector2i(point))
						if color.a<.95: joint_gaps.append({"pose":tag,"actor":i,"side":side,"part":key,"joint":joint,"point":str(point),"alpha":color.a})
						joint_probes+=1

func _run() -> void:
	capture_prefix="concept44"
	root.content_scale_size=Vector2i(2560,900)
	root.size=Vector2i(2560,900)
	root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(2560,900)
	review_root.add_child(background)
	var title := _review_label("0.44 · CHI TIẾT LIỀN KHỚP",Vector2(0,18),2560,26)
	_review_label("Nam / Nữ · 8 hướng · silhouette, khớp và nếp vải",Vector2(0,55),2560,17)
	var overlays := []
	for body in range(2):
		for d in range(8):
			var actor := GuIllustratedCharacterView.new()
			review_root.add_child(actor)
			actor.configure(256,176)
			actor.position=Vector2(160+d*320,345+body*370)
			actor.set_active(false)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if body==0 else "female"
			actor.set_appearance(look)
			review_views.append(actor)
			var layer := Layers.new()
			layer.actor=actor
			layer.position=actor.position
			layer.hide()
			review_root.add_child(layer)
			overlays.append(layer)
			_review_label(("Nam" if body==0 else "Nữ")+" · "+DIRECTION_LABELS[d],Vector2(d*320,410+body*370),320,17)
	# Same current rig pose, exact old/new art contracts and matching shader.
	# Only this isolated review process swaps the static manifest.
	var current := GuConceptCharacterArt.manifest()
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/concept44_baseline/manifest.json"))
	var old_image := Image.new()
	assert(old_image.load_svg_from_string(FileAccess.get_file_as_string("res://artifacts/concept44_baseline/directional-atlas.svg"))==OK)
	var old_atlas := ImageTexture.create_from_image(old_image)
	var new_atlas: Texture2D = load("res://assets/characters/concept-rig/directional-atlas.svg")
	for revision in ["before","after"]:
		GuConceptCharacterArt._manifest=before if revision=="before" else current
		for p in range(POSES.size()):
			var action: String = POSES[p][0]
			var phase: float = POSES[p][1]
			title.text=("0.43 · TRƯỚC" if revision=="before" else "0.44 · SAU")+" · "+action+" · "+str(phase)
			for i in range(review_views.size()):
				var actor := review_views[i]
				actor.present(action,phase*actor.duration(action),Vector2.DOWN.rotated((i%8)*PI/4))
				actor.illustration.material.set_shader_parameter("directional_atlas",old_atlas if revision=="before" else new_atlas)
			await _save("concept44_"+revision+"_%02d" % p)
	var actions := {}
	for action in ["walk","run","attack","defend","gather","mine"]:
		var folder: String = "concept44_"+action
		DirAccess.make_dir_recursive_absolute("res://artifacts/"+folder)
		for i in range(review_views.size()): review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4))
		var duration: float = review_views[0].duration(action)
		for frame in range(24):
			title.text="0.44 · %s · %02d / 24" % [action,frame+1]
			for substep in range(4):
				for i in range(review_views.size()):
					var actor := review_views[i]
					actor.present_smooth(action,(frame*4+substep)*duration/96,Vector2.DOWN.rotated((i%8)*PI/4),false,duration/96,1 if action in ["walk","run"] else 0)
			await _save(folder+"/frame%03d" % frame)
			if frame in [4,8,14,20]:
				for layer: Layers in overlays: layer.show(); layer.queue_redraw()
				await _save(folder+"_bones_%02d" % frame)
				for layer in overlays: layer.hide()
		actions[action]={"frames":24,"duration":duration}
	# Test real rendered alpha. Comparing dark cloth RGB to a green stage
	# gives false gaps, and sampling a ring below a sole tests empty floor.
	var probe_view := SubViewport.new()
	probe_view.size=Vector2i(2560,900)
	probe_view.transparent_bg=true
	probe_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(probe_view)
	review_root.reparent(probe_view)
	background.hide()
	for p in range(POSES.size()):
		for i in range(review_views.size()):
			var actor := review_views[i]
			actor.present(POSES[p][0],float(POSES[p][1])*actor.duration(POSES[p][0]),Vector2.DOWN.rotated((i%8)*PI/4))
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		_probe_joints(str(POSES[p]),probe_view.get_texture().get_image())
	FileAccess.open("res://artifacts/concept44_native.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":captures,"source":"native Godot / current rig, old and new atlas comparison","views":16,"actions":actions,"comparison_poses":POSES,"joint_pixel_samples":joint_probes,"joint_alpha_gaps":joint_gaps},"  "))
	quit()
