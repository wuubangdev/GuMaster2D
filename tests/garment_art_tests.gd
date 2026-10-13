extends RefCounted
## Tests the authored cloth's skin envelopes and rest-space surface orientation.
## The mesh is inspected independently of a studio camera or a palette change.

static func run(tree: SceneTree, check: Callable) -> void:
	var model := GuCharacterModel.new()
	tree.root.add_child(model)
	await tree.process_frame
	model.blend_transitions = false
	var normalized := true
	var valid_bones := true
	var budget := true
	var rest_normals := true
	var sleeve_joints := true
	var leg_driven := true
	var pose_finite := true
	var hem_motion := true
	var maximum_triangles := 0
	var maximum_weight_error := 0.0
	var folded_hems := true
	for body: String in ["male","female"]:
		for outfit: String in ["jade","crimson","ivory"]:
			model.set_appearance({"body":body,"outfit":outfit,"hair":"topknot","weapon":"sword"})
			model.buckets.clear()
			GuCharacterGarments.build(model)
			var triangles := 0
			var chest_arm := 0
			var arm_fore := 0
			var hip_leg := 0
			var lower_left := 0
			var lower_right := 0
			var maximum_hem_radius := 0.0
			var minimum_hem_radius := INF
			var arrays: Array[Dictionary] = []
			for material in model.buckets:
				var bucket: Dictionary = model.buckets[material]
				triangles += bucket.i.size()/3
				arrays.append(bucket.duplicate(true))
				for i in range(bucket.v.size()):
					var total := 0.0
					var bone_weights: Dictionary = {}
					for j in range(4):
						var bone: int = bucket.b[i*4+j]
						var weight: float = bucket.w[i*4+j]
						valid_bones = valid_bones and bone>=0 and bone<22 and weight>=0 and weight<=1
						total += weight
						if weight>0:
							bone_weights[model.skeleton.get_bone_name(bone)] = weight
					maximum_weight_error = maxf(maximum_weight_error,absf(total-1))
					for side: String in ["L","R"]:
						if bone_weights.get("Chest",0)>.01 and bone_weights.get("UpperArm_"+side,0)>.01:
							chest_arm += 1
						if bone_weights.get("UpperArm_"+side,0)>.01 and bone_weights.get("Forearm_"+side,0)>.01:
							arm_fore += 1
						if bone_weights.get("Hips",0)>.01 and bone_weights.get("Thigh_"+side,0)>.01:
							hip_leg += 1
						if bucket.v[i].y<.78 and bone_weights.get("Thigh_"+side,0)>.4:
							if side=="L":
								lower_left += 1
							else:
								lower_right += 1
					if material=="cloth" and bucket.v[i].y>1.15 and absf(bucket.v[i].x)<.14:
						var p: Vector3 = bucket.v[i]
						var n: Vector3 = bucket.n[i]
						if absf(p.z)>.1:
							rest_normals = rest_normals and n.z*p.z>0 and n.is_finite()
					if material=="cloth" and bucket.v[i].y<.8:
						var radius := Vector2(bucket.v[i].x,bucket.v[i].z).length()
						maximum_hem_radius = maxf(maximum_hem_radius,radius)
						minimum_hem_radius = minf(minimum_hem_radius,radius)
				maximum_triangles = maxi(maximum_triangles,triangles)
			budget = budget and triangles<=11000
			sleeve_joints = sleeve_joints and chest_arm>50 and arm_fore>30
			leg_driven = leg_driven and hip_leg>100 and lower_left>50 and lower_right>50
			folded_hems = folded_hems and maximum_hem_radius-minimum_hem_radius>.035
			model.set_motion("idle",0,Vector2.DOWN,true)
			var baseline := _skin(model,arrays)
			for clip: String in ["run","attack","defend","dash"]:
				var duration := model.animator.get_animation(clip).length
				model.set_motion(clip,duration*.45,Vector2.DOWN,true)
				var points := _skin(model,arrays)
				var leg_displacement := 0.0
				for i in range(points.size()):
					pose_finite = pose_finite and points[i].is_finite() and points[i].length()<4
					if baseline[i].y<.76:
						leg_displacement = maxf(leg_displacement,points[i].distance_to(baseline[i]))
				if clip=="run":
					hem_motion = hem_motion and leg_displacement>.07
	check.call(budget,"Subdivided wardrobe remains within 11,000 garment triangles (maximum %d)" % maximum_triangles)
	normalized = maximum_weight_error<.00001
	check.call(normalized and valid_bones,"Every garment vertex has four valid normalized rig influences (maximum error %.8f)" % maximum_weight_error)
	check.call(rest_normals,"Tailored torso's front and rear geometric normals face outward without camera correction")
	check.call(sleeve_joints,"Both continuous sleeves blend Chest to UpperArm and UpperArm to Forearm in every wardrobe")
	check.call(leg_driven,"Wrapped split hems have mixed waist weights and follow both legs independently")
	check.call(folded_hems,"Draped skirt sections have real curved rest-space volume in every wardrobe")
	check.call(pose_finite,"Weighted garment vertices remain finite through run, attack, defence and dash on both body types")
	check.call(hem_motion,"Run animates the actual weighted robe hem rather than a rigid waist-attached board")
	model.free()
	await tree.process_frame

static func _skin(model: GuCharacterModel, arrays: Array[Dictionary]) -> PackedVector3Array:
	var transforms: Array[Transform3D] = []
	for bone in range(model.skeleton.get_bone_count()):
		transforms.append(model.skeleton.get_bone_global_pose(bone)*model.skeleton.get_bone_global_rest(bone).affine_inverse())
	var points := PackedVector3Array()
	for bucket: Dictionary in arrays:
		for vertex in range(bucket.v.size()):
			var p := Vector3.ZERO
			for influence in range(4):
				var i := vertex*4+influence
				p += (transforms[bucket.b[i]]*bucket.v[vertex])*bucket.w[i]
			points.append(p)
	return points
