extends "res://tests/concept_character_visual_smoke.gd"
## Equal-size A/B evidence from the production renderer. Each native framebuffer
## contains both bodies; PNG rows are exact crops, never rescaled or repainted.

const ART_SIZE := Vector2i(960,760)
const ROW_SIZE := Vector2i(960,380)
const ACTIONS47 := ["attack","defend","gather","mine","walk","run"]
const POSES47 := [["idle",0.0],["attack",.16],["attack",.34],["attack",.56],["defend",.30],["gather",.50],["mine",.48],["walk",.18],["run",.18]]
const NAMES47 := ["Xuống","Xuống trái","Trái","Lên trái","Lên","Lên phải","Phải","Xuống phải"]
var directions47: Array[int] = [0,1,2,3,4,5,6,7]
var poses_only47 := false
var frames47 := 24
var baseline_shader47: Shader
var baseline_atlas47: Texture2D
var sources47: Dictionary = {}
var baseline47: Dictionary = {}
var actor_sets47: Array[Dictionary] = []
var equal_poses47 := 0
var rendered_frames47 := 0

func _hash_sources47() -> Dictionary:
	var paths := [
		"assets/shaders/concept_cutout.gdshader",
		"scripts/presentation/concept_character_rig.gd",
		"scripts/presentation/direction_action_fit.gd",
		"scripts/presentation/concept_joint_skin.gd",
		"scripts/presentation/concept_pose_fit.gd",
		"scripts/presentation/concept_character_art.gd",
		"scripts/presentation/concept_directional_parts.gd",
		"scripts/presentation/illustrated_character_view.gd",
		"scripts/presentation/illustrated_character_canvas.gd",
		"scripts/presentation/illustrated_character_art.gd",
		"scripts/presentation/pixel_character_view.gd",
		"scripts/presentation/concept_ink_stroke.gd",
		"scripts/presentation/character_held_prop.gd",
		"scripts/presentation/character_action_motion.gd",
		"scripts/core/character_appearance.gd",
		"tools/author_directional_character_parts.py",
		"tests/character47_art_review.gd",
		"assets/characters/concept-rig/manifest.json",
		"assets/characters/concept-rig/directional-atlas.svg",
		"assets/characters/concept-rig/directional-atlas.svg.import",
		"assets/characters/concept-rig/cloth-atlas.svg",
		"assets/characters/concept-rig/character-concept-01.png",
		"assets/characters/concept-rig/character-directions-02.png",
		"assets/characters/concept-rig/character-concept-01-matte.res",
		"assets/characters/concept-rig/character-concept-01-layers.res",
		"assets/characters/concept-rig/character-directions-02-matte.res",
		"assets/characters/concept-rig/character-directions-02-layers.res",
		"artifacts/concept47_baseline/manifest.json",
		"artifacts/concept47_baseline/directional-atlas.svg",
		"artifacts/concept47_baseline/concept_cutout.gdshader",
		"artifacts/concept47_baseline/author_directional_character_parts.py",
	]
	var result := {}
	for path: String in paths:
		assert(FileAccess.file_exists("res://"+path),"Missing capture source: "+path)
		result[path]=FileAccess.get_sha256("res://"+path)
	return result

func _validate_baseline47() -> void:
	baseline47=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/concept47_baseline/manifest.json"))
	var current := GuConceptCharacterArt.manifest()
	for key: String in baseline47["views"]:
		var before: Dictionary = baseline47["views"][key]
		var after: Dictionary = current["views"][key]
		for field in ["source","scale","ground","parts","eyes"]:
			assert(before.get(field)==after.get(field),"A/B source geometry changed: "+key+"/"+field)
		var before_art: Dictionary = before["directional_art"]
		var after_art: Dictionary = after["directional_art"]
		assert(before_art["atlas_size"]==after_art["atlas_size"],"Baseline atlas size mismatch")
		assert(before_art["rest_chains"]==after_art["rest_chains"],"Baseline rig changed")
		for part: String in before_art["parts"]:
			for field in ["bounds","atlas_rect","bone","side","anchors","stitch_length","pose_fit"]:
				assert(before_art["parts"][part].get(field)==after_art["parts"][part].get(field),"A/B asset contract changed: "+key+"/"+part+"/"+field)
	baseline_shader47=Shader.new()
	baseline_shader47.code=FileAccess.get_file_as_string("res://artifacts/concept47_baseline/concept_cutout.gdshader")
	var image := Image.new()
	assert(image.load_svg_from_string(FileAccess.get_file_as_string("res://artifacts/concept47_baseline/directional-atlas.svg"))==OK)
	# Match process/fix_alpha_border=true on the production SVG texture import.
	image.fix_alpha_edges()
	baseline_atlas47=ImageTexture.create_from_image(image)

func _stage47() -> void:
	root.content_scale_size=ART_SIZE
	root.size=ART_SIZE
	root.position=Vector2i(-1900,-1000)
	root.title="Cổ Sư · Nét vẽ nhân vật 0.47"
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("303a34")
	background.size=ART_SIZE
	review_root.add_child(background)
	for body in range(2):
		var row := body*ROW_SIZE.y
		for version in range(2):
			var column := version*480
			_review_label("TRƯỚC · 0.46" if version==0 else "SAU · 0.47",Vector2(column,row+10),480,15)
			_review_label("Cận cảnh · 200 px",Vector2(column+65,row+351),240,12)
			_review_label("Trong game · 48 px",Vector2(column+308,row+351),165,12)
			for height in [200.0,48.0]:
				var actor := GuIllustratedCharacterView.new()
				review_root.add_child(actor)
				actor.configure(256,height)
				actor.position=Vector2(column+(185 if height>100 else 390),row+337)
				actor.set_active(false)
				var look := GuCharacterAppearance.default_data()
				look["body"]="male" if body==0 else "female"
				actor.set_appearance(look)
				if version==0:
					var material := actor.illustration.material.duplicate() as ShaderMaterial
					material.shader=baseline_shader47
					material.set_shader_parameter("directional_atlas",baseline_atlas47)
					actor.illustration.material=material
				actor_sets47.append({"actor":actor,"body":body,"before":version==0,"height":height})
				review_views.append(actor)

func _capture47(folder: String,name: String) -> void:
	for body in range(2):
		for size_index in range(2):
			var before: GuIllustratedCharacterView = actor_sets47[body*4+size_index]["actor"]
			var after: GuIllustratedCharacterView = actor_sets47[body*4+2+size_index]["actor"]
			assert(before.capture_pose()==after.capture_pose(),"A/B pose mismatch")
			assert(before.illustration.material.shader==baseline_shader47,"Baseline material was replaced")
			assert(before.illustration.material.get_shader_parameter("directional_atlas")==baseline_atlas47,"Baseline atlas was replaced")
			equal_poses47+=1
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size()==ART_SIZE)
	for body in range(2):
		var body_name := "male" if body==0 else "female"
		var path := folder+"/"+body_name+"/"+name+".png"
		DirAccess.make_dir_recursive_absolute(("res://artifacts/"+path).get_base_dir())
		assert(image.get_region(Rect2i(Vector2i(0,body*ROW_SIZE.y),ROW_SIZE)).save_png("res://artifacts/"+path)==OK)
		captures.append(path)
	rendered_frames47+=1

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument=="--poses-only": poses_only47=true
		if argument.begins_with("--directions="):
			directions47.clear()
			for direction in argument.trim_prefix("--directions=").split(","):
				assert(int(direction)>=0 and int(direction)<8)
				directions47.append(int(direction))
	sources47=_hash_sources47()
	_validate_baseline47()
	_stage47()
	for direction in directions47:
		var first_capture := captures.size()
		var first_render := rendered_frames47
		var first_equal := equal_poses47
		var facing := Vector2.DOWN.rotated(direction*PI/4)
		var folder := "concept47/d%d" % direction
		for pose_index in range(POSES47.size()):
			var action: String = POSES47[pose_index][0]
			for actor in review_views: actor.present(action,float(POSES47[pose_index][1])*actor.duration(action),facing)
			await _capture47(folder,"pose%02d" % pose_index)
		var clips := {}
		if not poses_only47:
			for action in ACTIONS47:
				for actor in review_views: actor.present("idle",0,facing)
				var duration := review_views[0].duration(action)
				for frame in range(frames47):
					for substep in range(4):
						var age := (frame*4+substep)*duration/(frames47*4)
						for actor in review_views:
							actor.present_smooth(action,age,facing,false,duration/(frames47*4),1 if action in ["walk","run"] else 0)
					await _capture47(folder,action+"/frame%03d" % frame)
				clips[action]={"frames":frames47,"duration":duration,"sample_offset_frames":.75,"folder":folder+"/{body}/"+action}
		if sources47!=_hash_sources47():
			printerr("Sources changed during capture. Recapture after freeze.")
			quit(1)
			return
		var report := {"source":"Native Godot framebuffer, exact 960×380 row crops; production GuIllustratedCharacterView and present_smooth", "source_sha256":sources47,"direction":direction,"label":NAMES47[direction],"size":[ROW_SIZE.x,ROW_SIZE.y],"native_framebuffer_size":[ART_SIZE.x,ART_SIZE.y],"display_heights":[200,48],"bodies":["male","female"],"versions":["0.46","0.47"],"poses":POSES47,"clips":clips,"folder":folder,"captures":captures.slice(first_capture),"native_frames":rendered_frames47-first_render,"identical_pose_checks":equal_poses47-first_equal,"poses_only":poses_only47,"baseline_geometry_identical":true,"baseline_material_preserved":true}
		FileAccess.open("res://artifacts/concept47_d%d_native.json" % direction,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("CHARACTER47_DIRECTION_COMPLETE ",direction," native_frames=",report["native_frames"]," captures=",report["captures"].size()," equal_poses=",report["identical_pose_checks"])
	quit()
