extends RefCounted
## Acceptance observes displayed joints, event hand origins and authority.
## A timestamp change alone cannot satisfy smooth-motion checks.

const FACING := [Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1), Vector2.RIGHT, Vector2(1, 1)]

static func run(tree: SceneTree, check: Callable) -> bool:
	_gait(check)
	_profile(check)
	_directional_arms(check)
	_cloth_and_anatomy(check)
	await _playback(tree, check)
	await _live(tree, check)
	return true

static func _distance(a: Variant, b: Variant) -> float:
	if a is Vector2 and b is Vector2:
		return a.distance_to(b)
	if a is float and b is float:
		return absf(a - b)
	var largest := 0.0
	if a is Dictionary and b is Dictionary:
		for key in a:
			if not b.has(key):
				return INF
			var gap := absf(wrapf(float(a[key]) - float(b[key]), -PI, PI)) if "rotation" in str(key) or key == "weapon_angle" else _distance(a[key], b[key])
			largest = maxf(largest, gap)
	elif a is Array and b is Array:
		if a.size() != b.size():
			return INF
		for index in range(a.size()):
			largest = maxf(largest, _distance(a[index], b[index]))
	return largest

static func _gait(check: Callable) -> void:
	var planted := true
	var continuous := true
	var lifted := true
	var recovered := true
	var look := GuCharacterAppearance.default_data()
	for running in [false, true]:
		var stride := GuIllustratedCharacterArt.RUN_STRIDE if running else GuIllustratedCharacterArt.WALK_STRIDE
		var stance := .46 if running else .60
		for phase in [.07, .16, .30]:
			var first := GuIllustratedCharacterArt.gait_foot(phase, running)
			var after := GuIllustratedCharacterArt.gait_foot(phase + .05, running)
			planted = planted and absf(float(after["travel"]) + stride * .05 - float(first["travel"])) < .0001 and first["lift"] == 0.0 and first["contact"] == 1.0
		var epsilon := .00001
		for boundary in [stance, 1.0]:
			var before := GuIllustratedCharacterArt.gait_foot(boundary - epsilon, running)
			var center := GuIllustratedCharacterArt.gait_foot(boundary, running)
			var after := GuIllustratedCharacterArt.gait_foot(boundary + epsilon, running)
			var incoming := (float(center["travel"]) - float(before["travel"])) / epsilon
			var outgoing := (float(after["travel"]) - float(center["travel"])) / epsilon
			continuous = continuous and absf(incoming - outgoing) < .04 and absf(float(before["lift"]) - float(after["lift"])) / epsilon < .04
		for direction in range(8):
			var aim := Vector2.DOWN.rotated(direction * PI / 4)
			var first := GuIllustratedCharacterArt.sample("run" if running else "walk", .12, direction, look)
			var after := GuIllustratedCharacterArt.sample("run" if running else "walk", .22, direction, look)
			planted = planted and (Vector2(after["foot_R"]) + aim * stride * .10).distance_to(first["foot_R"]) < .0001
			var airborne := GuIllustratedCharacterArt.sample("run" if running else "walk", stance + (1 - stance) * .5, direction, look)
			var expected_lift := GuIllustratedCharacterArt.RUN_LIFT if running else GuIllustratedCharacterArt.WALK_LIFT
			lifted = lifted and is_equal_approx(float(airborne["foot_lift_R"]),expected_lift) and float(airborne["foot_contact_R"]) < .01 and (Vector2(airborne["foot_R"]) + Vector2(0, float(airborne["foot_lift_R"]))).is_equal_approx(airborne["foot_ground_R"])
	for weapon in ["sword", "spear", "unarmed"]:
		look["weapon"] = weapon
		for direction in range(8):
			recovered = recovered and _distance(GuIllustratedCharacterArt.sample("attack", 1.0, direction, look), GuIllustratedCharacterArt.sample("idle", 0.0, direction, look)) < .0001
	check.call(planted, "Walk and run stance feet cancel actual body travel in all eight facings instead of skating")
	check.call(continuous, "Foot takeoff and landing match horizontal velocity and have continuous zero vertical velocity")
	check.call(lifted, "Airborne feet lift visibly above their ground projections while their contact shadows fade")
	check.call(recovered, "Sword, spear and unarmed attack recovery return all joints and grip angles to the neutral pose")

static func _cloth_and_anatomy(check: Callable) -> void:
	var lengths_safe := true
	var profile_lengths := true
	var waist_attached := true
	var mesh_safe := true
	var cloth_moves := false
	var look := GuCharacterAppearance.default_data()
	for weapon in ["unarmed","sword","spear"]:
		look["weapon"] = weapon
		for d in range(8):
			for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
				for i in range(61):
					var pose := GuIllustratedCharacterArt.sample(action,float(i)/60,d,look)
					for side in ["L","R"]:
						var joints := GuIllustratedCharacterArt.leg_joints(pose,side)
						for segment in range(2):
							var length := joints[segment].distance_to(joints[segment+1])
							lengths_safe = lengths_safe and length<=GuIllustratedCharacterArt.LEG_SEGMENT+.001 and length>.01
							if d in [2,6]:
								profile_lengths = profile_lengths and absf(length-GuIllustratedCharacterArt.LEG_SEGMENT)<.001
					waist_attached = waist_attached and GuIllustratedCharacterArt.coat_vertex(pose,Vector2(-10,3)).is_equal_approx(Vector2(-10,3)) and GuIllustratedCharacterArt.coat_vertex(pose,Vector2(10,-9)).is_equal_approx(Vector2(10,-9))
					var hem := GuIllustratedCharacterArt.coat_vertex(pose,Vector2(10,15))
					cloth_moves = cloth_moves or (action in ["walk","run"] and hem.distance_to(Vector2(10,15))>.5)
					for row in range(8):
						for column in range(4):
							var cell := PackedVector2Array()
							for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
								var point: Vector2 = Vector2(-18,-13)+Vector2(36,30)*(Vector2(column,row)+corner)/Vector2(4,8)
								cell.append(GuIllustratedCharacterArt.coat_vertex(pose,point))
							mesh_safe = mesh_safe and Geometry2D.triangulate_polygon(cell).size()==6
							for j in range(4):
								mesh_safe = mesh_safe and (cell[(j+1)%4]-cell[j]).cross(cell[(j+2)%4]-cell[(j+1)%4])>0
	check.call(lengths_safe,"All projected thigh/shin segments remain within anatomical length across eight facings, eleven actions and three weapons")
	check.call(profile_lengths,"Both profile thighs and shins keep fixed eight-unit lengths through gait, guard, combat and recovery")
	check.call(waist_attached,"Coat deformation leaves the collar and belt attached to the original torso in every pose")
	check.call(mesh_safe,"Every cloth mesh cell stays convex and drawable through movement, combat, death and respawn")
	check.call(cloth_moves,"Returning knees and delayed side sway visibly deform the existing painted hem instead of translating a rigid coat")
	var reduced := GuIllustratedCharacterArt.sample("run",.72,6,look,true)
	check.call(GuIllustratedCharacterArt.coat_vertex(reduced,Vector2(10,15)).is_equal_approx(Vector2(10,15)),"Reduced motion restores the original neutral cloth shape together with planted feet")

static func _profile(check: Callable) -> void:
	var look := GuCharacterAppearance.default_data()
	var aligned := true
	var knees := true
	var stable_head := true
	for d in [2,6]:
		var neutral := GuIllustratedCharacterArt.sample("idle",0,d,look)
		aligned = aligned and absf(neutral["foot_L"].x-neutral["foot_R"].x)<3 and absf(neutral["hip_L"].x-neutral["hip_R"].x)<2
		for action in ["walk","run"]:
			var top := INF
			var bottom := -INF
			for i in range(60):
				var pose := GuIllustratedCharacterArt.sample(action,float(i)/60,d,look)
				top = minf(top,pose["head"].y)
				bottom = maxf(bottom,pose["head"].y)
				stable_head = stable_head and absf(pose["head_rotation"])<.015
				for side in ["L","R"]:
					var joints := GuIllustratedCharacterArt.leg_joints(pose,side)
					knees = knees and joints[0].is_equal_approx(pose["hip_"+side]) and joints[1].is_finite() and absf(joints[0].distance_to(joints[1])-GuIllustratedCharacterArt.LEG_SEGMENT)<.001 and absf(joints[1].distance_to(joints[2])-GuIllustratedCharacterArt.LEG_SEGMENT)<.001 and joints[2].distance_to(pose["foot_"+side])<5.1
			stable_head = stable_head and bottom-top<.5
	check.call(aligned,"Side-facing idle feet and hips share a narrow travel plane instead of the frontal wide stance")
	check.call(knees,"Both side walk/run legs have finite forward-flexing knees and boot-attached ankles throughout their real cycle")
	check.call(stable_head,"Side walk/run head rise remains under half a design unit and head roll under one degree")
	var original_pose := true
	for d in range(8):
		var neutral := GuIllustratedCharacterArt.sample("idle",0,d,look)
		original_pose = original_pose and neutral["head"].is_equal_approx(Vector2(0,-43)) and neutral["torso"].is_equal_approx(Vector2(0,-21))
	check.call(original_pose,"Material refinement keeps the original character head/body proportions and neutral landmarks in every direction")
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/character_v15_baseline.json"))["parts"]
	var unchanged := true
	var untouched_silhouettes := true
	var revised_robe_views := 0
	var revised_head_views := 0
	var improved := 0
	for key: String in baseline:
		var texture := GuIllustratedCharacterArt.part_texture(key)
		unchanged = unchanged and texture!=null
		if texture==null:
			continue
		var image := texture.get_image()
		image.convert(Image.FORMAT_RGBA8)
		var pixels := image.get_data()
		var alpha := PackedByteArray()
		alpha.resize(pixels.size()/4)
		for i in range(alpha.size()):
			alpha[i] = pixels[i*4+3]
		var alpha_hash := HashingContext.new()
		alpha_hash.start(HashingContext.HASH_SHA256)
		alpha_hash.update(alpha)
		var matches_approved_silhouette: bool = alpha_hash.finish().hex_encode()==baseline[key]["alpha_sha256"]
		unchanged = unchanged and Vector2(image.get_size())==Vector2(baseline[key]["size"][0],baseline[key]["size"][1])
		if key.begins_with("torso_"):
			revised_robe_views += int(not matches_approved_silhouette)
		elif key.begins_with("head_"):
			revised_head_views += int(not matches_approved_silhouette)
		else:
			untouched_silhouettes = untouched_silhouettes and matches_approved_silhouette
		var color_hash := HashingContext.new()
		color_hash.start(HashingContext.HASH_SHA256)
		color_hash.update(pixels)
		improved += int(color_hash.finish().hex_encode()!=baseline[key]["rgba_sha256"])
	check.call(unchanged and untouched_silhouettes and revised_robe_views==48 and revised_head_views==0 and baseline.size()==131 and GuIllustratedCharacterArt.manifest()["parts"].size()==155,"All legacy non-robe silhouettes remain exact; the 48 ink20 robe views use the wider hem; 24 modular accessory layers are added")
	check.call(improved>=120,"Imported color pixels change across the original character library while its silhouette remains unchanged")
	var paired := true
	var lids_local := true
	var mirror := true
	for body in ["male","female"]:
		for hair in ["topknot","ponytail"]:
			for d in [0,1,2,6,7]:
				var key := "head_%s_%s_%d" % [body,hair,d]
				var open := GuIllustratedCharacterArt.part_texture(key)
				var closed := GuIllustratedCharacterArt.part_texture(key+"_closed")
				paired = paired and open!=null and closed!=null and open.get_size()==closed.get_size()
				var a := open.get_image()
				var b := closed.get_image()
				var changed := 0
				for y in range(0,a.get_height(),4):
					for x in range(0,a.get_width(),4):
						if a.get_pixel(x,y)==b.get_pixel(x,y):
							continue
						changed += 1
						var model := Vector2(float(x)/8-20,float(y)/8-24)
						lids_local = lids_local and model.y> -3.5 and model.y<7 and absf(model.x)<10
				lids_local = lids_local and changed>8
			for suffix in ["","_closed"]:
				var left := GuIllustratedCharacterArt.part_texture("head_%s_%s_2%s" % [body,hair,suffix]).get_image()
				var right := GuIllustratedCharacterArt.part_texture("head_%s_%s_6%s" % [body,hair,suffix]).get_image()
				left.flip_x()
				var error := 0.0
				var count := 0
				for y in range(0,left.get_height(),8):
					for x in range(0,left.get_width(),8):
						var a := left.get_pixel(x,y)
						var b := right.get_pixel(x,y)
						error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a)
						count += 1
				mirror = mirror and error/count<.015
	check.call(paired,"All twenty face-facing body/hair views load matching authored open and closed head SVGs")
	check.call(lids_local,"Blink changes stay inside the eye region; the imported scalp, hair, ear and jaw remain unchanged")
	check.call(mirror,"Left and right profile artwork mirrors consistently for both genders, hairstyles and eyelid states")

static func _directional_arms(check: Callable) -> void:
	var look := GuCharacterAppearance.default_data()
	var forward := GuIllustratedCharacterArt.sample("idle",0,0,look)
	var backward := GuIllustratedCharacterArt.sample("idle",0,4,look)
	var anchors_rotate := true
	for side in ["L","R"]:
		anchors_rotate = anchors_rotate and signf(forward["arm_"+side][0].x)==-signf(backward["arm_"+side][0].x) and signf(forward["arm_"+side][2].x)==-signf(backward["arm_"+side][2].x)
	check.call(anchors_rotate,"Facing backward reverses anatomical shoulder and wrist projection together with the body")
	var mirrors := true
	var depth_swaps := true
	var profile_bends := true
	for d in [2,6]:
		var aim: Vector2 = FACING[d]
		var idle := GuIllustratedCharacterArt.sample("idle",0,d,look)
		depth_swaps = depth_swaps and (idle["arm_L"][0].y-idle["arm_R"][0].y)*aim.x< -2.5 and (idle["arm_depth_L"]-idle["arm_depth_R"])*aim.x< -1.9
		for action in ["idle","walk","run"]:
			for i in range(60):
				var pose := GuIllustratedCharacterArt.sample(action,float(i)/60,d,look)
				for side in ["L","R"]:
					var arm: Array = pose["arm_"+side]
					var chord: Vector2 = arm[0].lerp(arm[2],.54)
					profile_bends = profile_bends and (Vector2(arm[1])-chord).dot(aim)< -1.8
	var left := GuIllustratedCharacterArt.sample("idle",0,2,look)
	var right := GuIllustratedCharacterArt.sample("idle",0,6,look)
	for side in ["L","R"]:
		var other := "R" if side=="L" else "L"
		for i in range(3):
			mirrors = mirrors and (Vector2(left["arm_"+side][i])*Vector2(-1,1)).distance_to(right["arm_"+other][i])<.0001
	check.call(profile_bends,"Both profile elbows flex behind the wrist chord and reverse their bend throughout left/right idle, walk and run")
	check.call(mirrors,"Left/right resting arm silhouettes mirror after swapping anatomical near and far sides")
	for action in ["walk","run"]:
		for i in range(60):
			var pose := GuIllustratedCharacterArt.sample(action,float(i)/60,0,look)
			depth_swaps = depth_swaps and pose["arm_depth_L"]==forward["arm_depth_L"] and pose["arm_depth_R"]==forward["arm_depth_R"]
	check.call(depth_swaps,"Anatomical depth swaps near/far arms on left/right turns and remains stable through frontal body sway")
	var opposite_gait := true
	for d in range(8):
		var aim: Vector2 = FACING[d].normalized()
		var idle := GuIllustratedCharacterArt.sample("idle",0,d,look)
		for action in ["walk","run"]:
			for phase in [.08,.58]:
				var pose := GuIllustratedCharacterArt.sample(action,phase,d,look)
				for side in ["L","R"]:
					var wrist_travel := (Vector2(pose["arm_"+side][2])-Vector2(idle["arm_"+side][2])).dot(aim)
					var foot_travel := (Vector2(pose["foot_ground_"+side])-Vector2(idle["foot_ground_"+side])).dot(aim)
					opposite_gait = opposite_gait and absf(wrist_travel)>absf(foot_travel)*.15 and wrist_travel*foot_travel<0
	check.call(opposite_gait,"Walk/run arm swing follows all eight travel directions and counterbalances the same-side foot")
	var turns_safe := true
	var bends_change := true
	for d in range(8):
		var from := GuIllustratedCharacterArt.sample("run",.23,d,look)
		var to := GuIllustratedCharacterArt.sample("run",.23,(d+4)%8,look)
		for i in range(1,20):
			var pose := GuIllustratedCharacterArt.blend_poses(from,to,float(i)/20)
			for side in ["L","R"]:
				var arm: Array = pose["arm_"+side]
				turns_safe = turns_safe and Vector2(arm[1]).is_finite() and arm[0].distance_to(arm[1])>.4 and arm[1].distance_to(arm[2])>.4
		var early := GuIllustratedCharacterArt.blend_poses(from,to,.25)
		var late := GuIllustratedCharacterArt.blend_poses(from,to,.75)
		for side in ["L","R"]:
			bends_change = bends_change and early["arm_bend_"+side]*late["arm_bend_"+side]<0
	check.call(turns_safe,"Every opposite-facing run turn passes through finite connected elbows rather than collapsed sleeves")
	check.call(bends_change,"Interrupted turns carry the new elbow bend through the midpoint instead of rebuilding the old fixed bend")
	var drawable := true
	for weapon in ["sword","spear","unarmed"]:
		look["weapon"] = weapon
		for d in range(8):
			for action in ["idle","walk","run","attack","cast","defend","channel","dash","hit","death","respawn"]:
				for i in range(61):
					var pose := GuIllustratedCharacterArt.sample(action,float(i)/60,d,look)
					for side in ["L","R"]:
						var outline := GuIllustratedCharacterArt.ribbon_outline(GuIllustratedCharacterArt.forearm_curve(pose["arm_"+side]),2.45,1.55)
						drawable = drawable and Geometry2D.triangulate_polygon(outline).size()>0
	check.call(drawable,"Tapered forearms triangulate through every weapon, action and direction including tightly folded wrists")
	var visible_weapon := true
	look["weapon"] = "sword"
	for d in range(8):
		var pose := GuIllustratedCharacterArt.sample("idle",0,d,look)
		var hand: Vector2 = pose["arm_R"][2]
		var tip := hand+Vector2(0,-38).rotated(pose["weapon_angle"])
		visible_weapon = visible_weapon and hand.x*tip.x>0 and absf(tip.x)>19
	check.call(visible_weapon,"Resting sword tips remain outside the head silhouette in all facings including rear views")

static func _playback(tree: SceneTree, check: Callable) -> void:
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256, 80)
	var look := GuCharacterAppearance.default_data()
	view.present("walk", .23, Vector2.RIGHT)
	var before := view.capture_pose()
	var before_hand := view.hand_position("R")
	view.present_smooth("attack", .0, Vector2.LEFT, false, 0.0)
	var event_pose := view.capture_pose()
	check.call(event_pose["action"] == "attack" and _distance(before["pose"], event_pose["pose"]) == 0.0 and view.hand_position("R").is_equal_approx(before_hand), "Accepted zero-delta action sync keeps the exact displayed joints, source-art grip, spring angles and spell hand")
	view.present_smooth("attack", .0, Vector2.LEFT, false, .02)
	var target := GuIllustratedCharacterArt.sample("attack", 0.0, view.current_direction, look)
	var step := _distance(before["pose"], view.capture_pose()["pose"])
	check.call(step > .0001 and step < _distance(before["pose"], target) * .5, "The first action-transition frame advances toward the accepted pose without snapping every limb")
	for frame in range(30):
		view.present_smooth("attack", .0, Vector2.LEFT, false, 1.0 / 60.0)
	check.call(_distance(view.capture_pose()["pose"], target) < .003, "Interrupted action transitions settle at the complete target pose rather than retaining stale joints")
	var restart: Dictionary = view.capture_pose()["pose"]
	view.present_smooth("attack", .15, Vector2.LEFT, false, .04)
	restart = view.capture_pose()["pose"]
	view.present_smooth("attack", .0, Vector2.LEFT, false, .0)
	check.call(_distance(restart, view.capture_pose()["pose"]) == 0.0, "Restarting the same one-shot clip blends from the currently displayed pose")
	look["weapon"] = "spear"
	view.set_appearance(look)
	var crossed_seam := false
	var shortest_arc := true
	for direction in range(8):
		var next_direction := (direction + 1) % 8
		var a := GuIllustratedCharacterArt.sample("attack", .4, direction, look)
		var b := GuIllustratedCharacterArt.sample("attack", .4, next_direction, look)
		if absf(float(a["weapon_angle"]) - float(b["weapon_angle"])) <= PI:
			continue
		crossed_seam = true
		view.present("attack", view.duration("attack", "spear") * .4, Vector2.DOWN.rotated(direction * PI / 4))
		view.present_smooth("attack", view.duration("attack", "spear") * .4, Vector2.DOWN.rotated(next_direction * PI / 4), false, .02)
		var delta := wrapf(float(view.capture_pose()["pose"]["weapon_angle"]) - float(a["weapon_angle"]), -PI, PI)
		var goal := wrapf(float(b["weapon_angle"]) - float(a["weapon_angle"]), -PI, PI)
		shortest_arc = shortest_arc and delta * goal > 0.0 and absf(delta) < absf(goal) * .5
	check.call(crossed_seam and shortest_arc, "A spear turn across the angle seam takes the short arc without spinning around the body")
	look["weapon"] = "sword"
	view.set_appearance(look)
	var distances: Array[float] = []
	var neutral := GuIllustratedCharacterArt.sample("idle", 0.0, 6, look)
	for weight in [0.0, .2, 1.0]:
		view.present("idle", 0.0, Vector2.RIGHT)
		for frame in range(12):
			view.present_smooth("walk", view.duration("walk") * .25, Vector2.RIGHT, false, .04, weight)
		distances.append(Vector2(view.capture_pose()["pose"]["foot_R"]).distance_to(neutral["foot_R"]))
	check.call(distances[0] < .0001 and distances[1] > .1 and distances[1] < distances[2] * .5, "Locomotion weight fades actual foot displacement smoothly from a planted idle pose")
	view.present_smooth("run", .20, Vector2.UP, false, .02)
	view.present_smooth("run", .20, Vector2.UP, true, .01)
	var reduced: Dictionary = view.capture_pose()["pose"]
	check.call(_distance(reduced, GuIllustratedCharacterArt.sample("idle", 0.0, view.current_direction, look, true)) < .0001 and reduced["foot_lift_L"] == 0.0 and reduced["foot_lift_R"] == 0.0, "Reduced motion immediately exits an unfinished transition and restores a neutral planted locomotion pose")
	view.present("cast", .19, Vector2(1, -1))
	var seek := view.capture_pose()
	view.present_smooth("dash", .1, Vector2.DOWN, false, .02)
	view.present("cast", .19, Vector2(1, -1))
	check.call(view.capture_pose() == seek, "An explicit animation seek stays deterministic regardless of preceding smooth playback history")
	var other := GuIllustratedCharacterView.new()
	tree.root.add_child(other)
	other.configure(256, 80)
	view.present("walk", .17, Vector2.LEFT)
	other.present("walk", .17, Vector2.LEFT)
	for frame in range(30):
		view.present_smooth("cast", .21, Vector2.UP, false, 1.0 / 30.0)
	for frame in range(60):
		other.present_smooth("cast", .21, Vector2.UP, false, 1.0 / 60.0)
	check.call(_distance(view.capture_pose()["pose"], other.capture_pose()["pose"]) < .001, "A held target settles to the same displayed pose at 30Hz and 60Hz")
	var safe := true
	for weapon in ["sword", "spear", "unarmed"]:
		look["weapon"] = weapon
		view.set_appearance(look)
		for frame in range(64):
			view.present_smooth(["walk", "run", "attack", "cast", "dash", "hit", "defend", "idle"][frame % 8], .13, FACING[frame % 8], false, 1.0 / 60.0)
			var snapshot := view.capture_pose()
			for side in ["L", "R"]:
				var arm: Array = snapshot["pose"]["arm_" + side]
				safe = safe and Vector2(arm[0]).is_finite() and Vector2(arm[1]).is_finite() and Vector2(arm[2]).is_finite() and Vector2(arm[0]).distance_to(arm[1]) > .1 and Vector2(arm[1]).distance_to(arm[2]) > .1 and view.hand_position(side).is_equal_approx(Vector2(snapshot["source_pose"]["grip_"+side])*float(snapshot["scale"]))
	check.call(safe, "Rapid interruptions across every weapon and facing preserve connected limbs and exact displayed hand anchors")
	view.queue_free()
	other.queue_free()
	await tree.process_frame

static func _key(tree: SceneTree, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	tree.root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	tree.root.push_input(event, true)

static func _live(tree: SceneTree, check: Callable) -> void:
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	await tree.process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	var sim := game.simulation
	sim.player["cell"] = Vector2(15, 20)
	sim.player["appearance"] = GuCharacterAppearance.default_data()
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(18, 20), "spawn": Vector2(18, 20), "hp": 140.0}, true)
	var actor := game.world_view.player_view
	actor.position = WorldGrid.project(sim.player["cell"])
	actor.spawn_left = 0.0
	actor.action_left = 0.0
	var hero: GuIllustratedCharacterView = actor.character_view
	hero.set_appearance(sim.player["appearance"])
	hero.present("walk", .23, Vector2.RIGHT)
	var before: Dictionary = hero.capture_pose()["pose"]
	check.call(bool(sim.cast(0, "wolf_0", Vector2.ZERO)["ok"]), "Smooth release verification starts with an accepted real authoritative cast")
	game.flush_events()
	var moon: Dictionary = {}
	for effect in game.world_view.effects.effects:
		if effect["kind"] == "cast_moon":
			moon = effect
	check.call(not moon.is_empty() and _distance(before, hero.capture_pose()["pose"]) == 0.0 and moon.get("origin_offset", Vector2.INF).is_equal_approx(hero.hand_position("R")), "Real accepted cast sync preserves the displayed transition pose before capturing its exact spell origin")
	var profile := sim.to_profile().duplicate(true)
	var inventory := sim.inventory.to_data().duplicate(true)
	for frame in range(5):
		var dt := float(moon["release_time"])/5+.0000001
		actor._process(dt)
		game.world_view.effects._process(dt)
	var launch := WorldGrid.project(moon.get("at", Vector2.ZERO)) + Vector2(moon.get("launch_offset", Vector2.INF))
	check.call(launch.is_equal_approx(actor.position + hero.hand_position("R")) and sim.to_profile() == profile and sim.inventory.to_data() == inventory, "The smooth anticipation releases from its displayed hand without applying extra authoritative movement, mana or damage")
	var previous_stride := actor.stride
	sim.set_move_direction(Vector2.DOWN)
	sim.step(.08)
	profile = sim.to_profile().duplicate(true)
	inventory = sim.inventory.to_data().duplicate(true)
	actor._process(.08)
	var moving_cast := hero.capture_pose()
	var upper := GuIllustratedCharacterArt.sample("attack", float(moving_cast["phase"]), int(moving_cast["direction_index"]), sim.player["appearance"])
	var idle := GuIllustratedCharacterArt.sample("idle",0,int(moving_cast["direction_index"]),sim.player["appearance"],true)
	# Both feet can be planted during a walk's overlapping stance. A new
	# direction-specific stride changes the sampled phase; movement, not a
	# particular left-foot lift at one timestamp, is the gait contract.
	var stepped := Vector2(moving_cast["pose"]["foot_ground_L"]).distance_to(idle["foot_ground_L"])>.1 or Vector2(moving_cast["pose"]["foot_ground_R"]).distance_to(idle["foot_ground_R"])>.1
	check.call(actor.stride > previous_stride and actor.move_blend > .1 and stepped and Vector2(moving_cast["pose"]["arm_R"][2]).is_equal_approx(upper["arm_R"][2]) and sim.to_profile() == profile and sim.inventory.to_data() == inventory, "Walking during an accepted cast keeps the distance-driven foot gait while preserving its upper-body hand action and authoritative state")
	sim.set_move_direction(Vector2.ZERO)
	profile = sim.to_profile().duplicate(true)
	var camera := game.world_view.camera
	game.world_view.desired_zoom = 2.0
	game.world_view._camera_follow = Vector2(31.26, 72.74)
	game.world_view._process(0.0)
	var at_two := camera.position
	game.world_view._camera_follow.x += .26
	game.world_view._process(0.0)
	var display_delta := (camera.position - at_two) * camera.zoom
	check.call(at_two != at_two.round() and (at_two * camera.zoom).is_equal_approx((at_two * camera.zoom).round()) and display_delta.is_equal_approx(Vector2.ZERO), "At 2x zoom the camera permits fractional world positions while remaining registered to display pixels")
	game.world_view._camera_follow.x += .30
	game.world_view._process(0.0)
	check.call(((camera.position - at_two) * camera.zoom).is_equal_approx(Vector2(1, 0)), "A sub-world-pixel follow movement advances the 2x camera by one crisp display pixel")
	_key(tree, KEY_F6)
	await tree.process_frame
	var studio := game.hud.character_studio
	studio.set_process(false)
	studio._select_action(1)
	studio.playhead = studio.character_view.duration("walk") * .3
	studio._present()
	var stage_before: Dictionary = studio.character_view.capture_pose()["pose"]
	studio._select_action(3)
	check.call(studio.opened and _distance(stage_before, studio.character_view.capture_pose()["pose"]) == 0.0, "The real F6 workshop keeps its currently displayed pose when an action selector starts a new transition")
	studio._process(.02)
	check.call(_distance(stage_before, studio.character_view.capture_pose()["pose"]) > .0001 and sim.to_profile() == profile and sim.inventory.to_data() == inventory, "Workshop playback advances blended joints while leaving profile and inventory untouched")
	studio._toggle_play()
	var paused: Dictionary = studio.character_view.capture_pose()
	studio._process(.25)
	check.call(studio.character_view.capture_pose() == paused, "Pausing workshop playback holds the exact displayed smooth pose rather than seeking a different body pose")
	_key(tree, KEY_ESCAPE)
	game.queue_free()
	await tree.process_frame
