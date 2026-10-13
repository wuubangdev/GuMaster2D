extends "res://tests/concept_character_visual_smoke.gd"
## Direction-by-direction evidence. All three stages share the exact snapshot
## produced by the live character; the browser only plays saved native frames.

const WORKSHOP_SIZE := Vector2i(960,640)
const ACTIONS := ["attack","defend","gather","mine","walk","run"]
const ACTION_NAMES := {"idle":"Đứng","attack":"Tấn công","defend":"Phòng thủ","gather":"Hái lượm","mine":"Khai khoáng","walk":"Đi bộ","run":"Chạy"}
const DIRECTION_NAMES := ["Xuống","Xuống trái","Trái","Lên trái","Lên","Lên phải","Phải","Xuống phải"]
const POSES := [["idle",0.0],["attack",.16],["attack",.34],["attack",.56],["defend",.30],["gather",.50],["mine",.30],["walk",.18],["run",.18]]
var workshop_prefix := "concept46"
var workshop_frames := 24
var workshop_directions: Array[int] = [0,1,2,3,4,5,6,7]
var poses_only := false
var baseline_only := false
var baseline_atlas: Texture2D
var workshop_clones: Array[GuIllustratedCharacterCanvas] = []
var workshop_bones: Array[BoneStage] = []
var workshop_title: Label
var workshop_caption: Label
var pose_records: Array[Dictionary] = []
var captured_sources: Dictionary = {}

func _source_hashes() -> Dictionary:
	var paths := ["scripts/presentation/concept_character_rig.gd","scripts/presentation/direction_action_fit.gd","scripts/presentation/concept_joint_skin.gd","scripts/presentation/concept_pose_fit.gd","scripts/presentation/concept_character_art.gd","scripts/presentation/concept_directional_parts.gd","assets/characters/concept-rig/manifest.json","assets/characters/concept-rig/directional-atlas.svg"]
	if baseline_only:
		paths=["tests/fixtures/concept46_baseline_rig.gd","artifacts/concept46_baseline/manifest.json","artifacts/concept46_baseline/directional-atlas.svg"]
	var result := {}
	for path in paths: result[path]=FileAccess.get_sha256("res://"+path)
	return result

class BoneStage extends Node2D:
	var actor: GuIllustratedCharacterView
	func _draw() -> void:
		var snapshot := actor.capture_pose()
		if snapshot.is_empty(): return
		var pose: Dictionary = snapshot["source_pose"]
		var scale_factor := float(snapshot["scale"])
		var shoulders := PackedVector2Array([pose["arm_L"][0],pose["arm_R"][0]])
		var hips := PackedVector2Array([pose["leg_L"][0],pose["leg_R"][0]])
		var pelvis: Vector2 = (hips[0]+hips[1])*.5
		var sternum: Vector2 = (shoulders[0]+shoulders[1])*.5
		_line(PackedVector2Array([pelvis,pose["torso"],sternum,pose["neck"],pose["head"]]),scale_factor,Color("f2d59c"))
		_line(shoulders,scale_factor,Color("f2d59c"))
		_line(hips,scale_factor,Color("f2d59c"))
		for side in ["L","R"]:
			var color := Color("83c2bb") if side=="L" else Color("f0ae74")
			for prefix in ["arm_","leg_"]:
				_line(pose[prefix+side],scale_factor,color)
			for key in ["wrist_","grip_","foot_ground_"]:
				var point: Vector2 = pose[key+side]*scale_factor
				draw_circle(point,3.0,color,false,1.0,true)
			var contact := float(pose.get("foot_contact_"+side,1.0))
			var foot: Vector2 = pose["foot_ground_"+side]*scale_factor
			draw_line(foot+Vector2(-9,4),foot+Vector2(9,4),Color(color,contact*.75),1.5,true)
	func _line(chain: PackedVector2Array, scale_factor: float, color: Color) -> void:
		var points := PackedVector2Array()
		for point in chain: points.append(point*scale_factor)
		draw_polyline(points,color,1.2,true)
		for point in points: draw_circle(point,2.0,color,true,-1,true)

func _workshop_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--prefix="): workshop_prefix=argument.trim_prefix("--prefix=")
		if argument.begins_with("--frames="): workshop_frames=maxi(8,int(argument.trim_prefix("--frames=")))
		if argument=="--poses-only": poses_only=true
		if argument=="--baseline-only":
			baseline_only=true
			poses_only=true
			workshop_prefix="concept46_before"
		if argument.begins_with("--directions="):
			workshop_directions.clear()
			for direction in argument.trim_prefix("--directions=").split(","):
				assert(int(direction)>=0 and int(direction)<8)
				workshop_directions.append(int(direction))

func _stage_scene() -> void:
	root.content_scale_size=WORKSHOP_SIZE
	root.size=WORKSHOP_SIZE
	root.position=Vector2i(-1900,-1000)
	root.title="Cổ Sư · Xưởng nhân vật theo hướng 0.46"
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("303a34")
	background.size=WORKSHOP_SIZE
	review_root.add_child(background)
	workshop_title=_review_label("0.46 · XƯỞNG NHÂN VẬT THEO HƯỚNG",Vector2(0,12),960,22)
	workshop_caption=_review_label("",Vector2(0,43),960,15)
	for column in range(3):
		_review_label(["01 · Xương và điểm bám","02 · Asset gắn vào xương","03 · Nhân vật hoàn chỉnh"][column],Vector2(column*320,74),320,16)
	for body in range(2):
		var actor := GuIllustratedCharacterView.new()
		review_root.add_child(actor)
		actor.configure(256,156)
		actor.position=Vector2(800,328+body*275)
		actor.set_active(false)
		var look := GuCharacterAppearance.default_data()
		look["body"]="male" if body==0 else "female"
		actor.set_appearance(look)
		review_views.append(actor)
		var clone := GuIllustratedCharacterCanvas.new()
		clone.position=Vector2(480,actor.position.y)
		review_root.add_child(clone)
		workshop_clones.append(clone)
		for column in range(2):
			var bones := BoneStage.new()
			bones.actor=actor
			bones.position=Vector2(160+column*320,actor.position.y)
			review_root.add_child(bones)
			workshop_bones.append(bones)
		_review_label("NAM" if body==0 else "NỮ",Vector2(10,336+body*275),940,13)

func _sync_workshop() -> void:
	for body in range(review_views.size()):
		if baseline_only:
			var snapshot := review_views[body].capture_pose()
			snapshot["source_pose"]=load("res://tests/fixtures/concept46_baseline_rig.gd").sample(snapshot)
			review_views[body]._publish(snapshot)
			review_views[body].illustration.material.set_shader_parameter("directional_atlas",baseline_atlas)
		workshop_clones[body].snapshot=review_views[body].capture_pose()
		workshop_clones[body].material=review_views[body].illustration.material
		workshop_clones[body].queue_redraw()
	for bones in workshop_bones: bones.queue_redraw()

func _set_weapon(weapon: String) -> void:
	for actor in review_views:
		var appearance := actor.appearance.duplicate(true)
		appearance["weapon"]=weapon
		actor.set_appearance(appearance)

func _record_pose(file: String) -> void:
	var bodies := []
	for actor in review_views:
		var snapshot := actor.capture_pose()
		var pose: Dictionary = snapshot["source_pose"]
		var points := {}
		for side in ["L","R"]:
			for prefix in ["arm_","leg_"]:
				points[prefix+side]=[]
				for point: Vector2 in pose[prefix+side]: points[prefix+side].append([point.x,point.y])
			for prefix in ["wrist_","grip_","foot_ground_"]:
				var point: Vector2 = pose[prefix+side]
				points[prefix+side]=[point.x,point.y]
		bodies.append({"body":actor.appearance["body"],"weapon":actor.appearance["weapon"],"phase":snapshot["phase"],"joints":points})
	pose_records.append({"file":file+".png","actors":bodies})

func _workshop_save(file: String) -> void:
	_sync_workshop()
	await _save(file)
	_record_pose(file)

func _run() -> void:
	_workshop_arguments()
	captured_sources=_source_hashes()
	if baseline_only:
		GuConceptCharacterArt._manifest=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/concept46_baseline/manifest.json"))
		var image := Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string("res://artifacts/concept46_baseline/directional-atlas.svg"))==OK)
		baseline_atlas=ImageTexture.create_from_image(image)
	_stage_scene()
	for direction in workshop_directions:
		var first_capture := captures.size()
		pose_records.clear()
		var facing := Vector2.DOWN.rotated(direction*PI/4)
		var folder := "%s/d%d" % [workshop_prefix,direction]
		DirAccess.make_dir_recursive_absolute("res://artifacts/"+folder)
		_set_weapon("sword")
		for i in range(POSES.size()):
			var action: String = POSES[i][0]
			workshop_title.text="%s · %s · %s" % ["0.44 trước sửa" if baseline_only else "0.46",DIRECTION_NAMES[direction],ACTION_NAMES[action]]
			workshop_caption.text="Tư thế %02d · pha %.2f · cùng một pose cho cả ba lớp" % [i+1,float(POSES[i][1])]
			for actor in review_views: actor.present(action,float(POSES[i][1])*actor.duration(action),facing)
			await _workshop_save(folder+"/pose%02d" % i)
		var clips := {}
		if not poses_only:
			for action in ACTIONS:
				var clip_folder: String = folder+"/"+action
				DirAccess.make_dir_recursive_absolute("res://artifacts/"+clip_folder)
				for actor in review_views: actor.present("idle",0,facing)
				var duration: float = review_views[0].duration(action)
				for frame in range(workshop_frames):
					workshop_title.text="0.46 · %s · %s" % [DIRECTION_NAMES[direction],ACTION_NAMES[action]]
					workshop_caption.text="Frame %02d / %02d · %.3f s · chân trụ thể hiện bằng vạch ngang" % [frame+1,workshop_frames,(frame+.75)*duration/workshop_frames]
					for substep in range(4):
						var age := (frame*4+substep)*duration/(workshop_frames*4)
						for actor in review_views:
							actor.present_smooth(action,age,facing,false,duration/(workshop_frames*4),1 if action in ["walk","run"] else 0)
					await _workshop_save(clip_folder+"/frame%03d" % frame)
				clips[action]={"frames":workshop_frames,"duration":duration,"folder":clip_folder,"sample_offset_frames":.75}
			for weapon in ["sword","spear","unarmed"]:
				_set_weapon(weapon)
				workshop_title.text="0.46 · %s · %s" % [DIRECTION_NAMES[direction],weapon]
				workshop_caption.text="Điểm bám vũ khí · tư thế tấn công ở pha 0.34"
				for actor in review_views: actor.present("attack",.34*actor.duration("attack",weapon),facing)
				await _workshop_save(folder+"/weapon_"+weapon)
		var fitting_revisions := {}
		for actor in review_views:
			fitting_revisions[actor.appearance["body"]]=GuConceptCharacterArt.view_for(actor.appearance,direction).get("directional_art",{}).get("fitting_revision",44)
		if captured_sources!=_source_hashes():
			printerr("Source files changed during native capture; recapture this direction after edits settle")
			quit(1)
			return
		var report := {"source":"Native Godot framebuffer; production GuIllustratedCharacterView snapshots","source_sha256":captured_sources,"direction":direction,"label":DIRECTION_NAMES[direction],"size":[WORKSHOP_SIZE.x,WORKSHOP_SIZE.y],"genders":["male","female"],"fitting_revisions":fitting_revisions,"stages":["skeleton","fitted_assets_with_bones","assembled"],"clips":clips,"poses":POSES,"records":pose_records,"captures":captures.slice(first_capture),"poses_only":poses_only}
		FileAccess.open("res://artifacts/%s_d%d_native.json" % [workshop_prefix,direction],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("DIRECTION_WORKSHOP_COMPLETE ",direction," captures=",captures.size()-first_capture)
	quit()
