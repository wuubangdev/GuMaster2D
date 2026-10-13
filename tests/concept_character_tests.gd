extends RefCounted
## Source fidelity, transparent silhouettes and actual presentation ownership.

static func _digest(path: String) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(path))
	return context.finish()

static func run(tree: SceneTree, check: Callable) -> void:
	var manifest := GuConceptCharacterArt.manifest()
	var views: Dictionary = manifest.get("views",{})
	check.call(views.size()==16,"The live source-art library contains eight authored views for each of the two bodies")
	check.call(_digest("res://assets/characters/concept-rig/character-concept-01.png")==_digest("res://docs/game-studio/concepts/ink20/character-concept-01.png") and _digest("res://assets/characters/concept-rig/character-directions-02.png")==_digest("res://docs/game-studio/concepts/ink20/detail-02/character-directions-02.png"),"Runtime color images are byte-identical to the approved original concept and direction drawings")
	var masks_valid := true
	var grips_valid := true
	for entry: Dictionary in views.values():
		masks_valid = masks_valid and entry.get("parts",{}).size()==6 and float(entry.get("scale",0))>0
		var size: Array = manifest["sources"][entry["source"]]["size"]
		for part: Dictionary in entry["parts"].values():
			var polygon := PackedVector2Array()
			for point: Array in part["polygon"]:
				var vertex := Vector2(float(point[0]),float(point[1]))
				polygon.append(vertex)
				masks_valid = masks_valid and vertex.is_finite() and vertex.x>=0 and vertex.y>=0 and vertex.x<size[0] and vertex.y<size[1]
			masks_valid = masks_valid and Geometry2D.triangulate_polygon(polygon).size()>0
		for side in ["L","R"]:
			var joints: Array = entry["parts"]["arm_"+side]["joints"]
			grips_valid = grips_valid and joints.size()==3 and GuConceptCharacterArt.source_position(entry,joints[0]).distance_to(GuConceptCharacterArt.source_position(entry,joints[2]))>1
	check.call(masks_valid,"Every head, coat, arm and leg source mask is bounded and triangulates independently of moving poses")
	check.call(grips_valid,"Each direction keeps independent source shoulders, elbows and visible hand grips")
	var matte: Texture2D = load("res://assets/characters/concept-rig/character-concept-01-matte.res")
	var direction_matte: Texture2D = load("res://assets/characters/concept-rig/character-directions-02-matte.res")
	check.call(matte.get_size()==Vector2(1586,992) and direction_matte.get_size()==Vector2(1774,887),"Opacity resources match their unmodified color atlases exactly")
	var mask := matte.get_image()
	var directional_mask := direction_matte.get_image()
	check.call(mask.get_pixel(725,292).r>.95 and mask.get_pixel(288,554).r>.95 and mask.get_pixel(778,410).r>.95 and mask.get_pixel(810,270).r<.05 and directional_mask.get_pixel(236,240).r>.95 and directional_mask.get_pixel(331,210).r<.05,"Paper removal preserves enclosed faces, ivory lapels and fists while exposing the map around the silhouette")
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256,48)
	view.set_active(false)
	view.present("idle",0,Vector2.DOWN,true)
	await tree.process_frame
	var snapshot := view.capture_pose()
	var reference: Dictionary = views["male_0"]
	var expected := GuConceptCharacterArt.source_position(reference,reference["parts"]["arm_R"]["joints"][2])
	check.call(view.illustration.material.shader==GuConceptCharacterArt.SHADER and not view.sprite.visible and view.hand_position().is_equal_approx(expected),"The actual live character canvas uses source opacity and its original visible grip instead of the compatibility sprite")
	var position := view.position
	view.present("attack",view.duration("attack")*.12,Vector2.DOWN)
	check.call(float(view.illustration.material.get_shader_parameter("blink"))>.5 and view.position==position,"The source face receives the real windup expression without changing the gameplay pivot")
	var contours_valid := true
	var neutral_contours := true
	var boots_clean := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var entry := GuConceptCharacterArt.view_for(look,d)
			view.present("idle",0,Vector2.DOWN.rotated(d*PI/4),true)
			var pose: Dictionary = view.capture_pose()["source_pose"]
			for key: String in entry["parts"]:
				var source_paths := GuConceptCharacterArt._body_source_edges(entry) if key=="torso" else GuConceptCharacterArt.source_contours(entry,key)
				contours_valid = contours_valid and not source_paths.is_empty()
				if key.begins_with("leg_"): boots_clean = boots_clean and source_paths.size()==1
				var rendered := GuConceptCharacterArt.outline_paths(entry,key,pose)
				var drawn_points := {}
				for path in rendered:
					contours_valid = contours_valid and path.size()>=2
					for point in path:
						contours_valid = contours_valid and point.is_finite()
						drawn_points[Vector2i(roundi(point.x*1000),roundi(point.y*1000))]=true
				for path in source_paths:
					contours_valid = contours_valid and path.size()>=(2 if key=="torso" else 12)
					for point in path:
						# The fully straight leg solver reserves 0.0001 native
						# units of reach. Allow that subpixel numerical margin.
						var matched := false
						var bin := Vector2i(roundi(point.x*1000),roundi(point.y*1000))
						for dy in [-1,0,1]:
							for dx in [-1,0,1]: matched = matched or drawn_points.has(bin+Vector2i(dx,dy))
						neutral_contours = neutral_contours and matched
	check.call(contours_valid and neutral_contours,"All 96 source parts retain finite neutral external ink contours; hidden torso/sleeve compositing cuts carry no extra black outline")
	check.call(boots_clean,"Each of the 32 boot outlines is one connected silhouette without detached source fragments")
	var ownership := {}
	for source in ["original","directions"]:
		var file := "character-concept-01" if source=="original" else "character-directions-02"
		var texture: Texture2D = load("res://assets/characters/concept-rig/%s-layers.res" % file)
		ownership[source]=texture.get_image()
	var fingers_follow := true
	for probe in [{"source":"directions","pixel":Vector2i(668,352)},{"source":"directions","pixel":Vector2i(657,736)},{"source":"directions","pixel":Vector2i(1419,736)},{"source":"original","pixel":Vector2i(1007,422)}]:
		fingers_follow = fingers_follow and roundi(ownership[probe["source"]].get_pixelv(probe["pixel"]).r*255)==3*32
	check.call(fingers_follow,"Actual profile fingertips in both bodies belong to their moving hand instead of remaining on the coat")
	check.call(roundi(ownership["directions"].get_pixel(225,785).r*255)!=2*32,"The female front hem excludes the exposed pants pixels previously baked into the moving coat")
	view.queue_free()
	await tree.process_frame
