extends RefCounted
## Cross-check the real generated model, skin and appearance combinations.
## Separate from the motion-library tests: broken binds/geometry can still pass
## an AnimationPlayer test on a bare skeleton.

static func run(tree: SceneTree, check: Callable) -> void:
	var model := GuCharacterModel.new()
	tree.root.add_child(model)
	await tree.process_frame
	var skeleton := model.skeleton
	var rest_ok := skeleton.get_bone_count() == 22
	var hierarchy_ok := true
	var bind_ok := model.skin.get_bind_count() == skeleton.get_bone_count()
	var names: Dictionary = {}
	for index in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(index)
		names[bone_name] = true
		var parent := skeleton.get_bone_parent(index)
		hierarchy_ok = hierarchy_ok and (parent == -1 if index == 0 else parent >= 0 and parent < index)
		var rest := skeleton.get_bone_rest(index)
		rest_ok = rest_ok and rest.is_finite() and GuCharacterAnimations.BONE_RESTS.has(bone_name)
		if GuCharacterAnimations.BONE_RESTS.has(bone_name):
			rest_ok = rest_ok and rest.origin.is_equal_approx(GuCharacterAnimations.BONE_RESTS[bone_name])
		if index < model.skin.get_bind_count():
			var inverse_bind := model.skin.get_bind_pose(index)
			bind_ok = bind_ok and model.skin.get_bind_bone(index) == index and inverse_bind.is_finite()
			bind_ok = bind_ok and (skeleton.get_bone_global_rest(index) * inverse_bind).is_equal_approx(Transform3D.IDENTITY)
	check.call(rest_ok and names.size() == 22, "The actual model and animation library share twenty-two unique finite bone rests")
	check.call(hierarchy_ok, "Model bones have a single root and valid ordered parents without cycles")
	check.call(bind_ok, "Every skin inverse bind cancels its actual model bone global rest transform")
	check.call(_geometry_valid(model), "Generated character meshes have finite geometry, valid indices, normalized skin weights and resolvable skeleton paths")
	var original_library := model.animator.get_animation_library("")
	var variants_ok := true
	var skeleton_preserved := true
	var appearances_independent := true
	var count := 0
	var observed_weapons: Dictionary = {}
	var body_signature: Dictionary = {}
	var hair_signature: Dictionary = {}
	for body in ["male", "female"]:
		for outfit in ["jade", "crimson", "ivory"]:
			for hair in ["topknot", "ponytail"]:
				for weapon in ["sword", "spear", "unarmed"]:
					var appearance := {"body": body, "outfit": outfit, "hair": hair, "weapon": weapon}
					model.set_appearance(appearance)
					variants_ok = variants_ok and _geometry_valid(model)
					skeleton_preserved = skeleton_preserved and model.skeleton == skeleton and model.skin.get_bind_count() == 22
					skeleton_preserved = skeleton_preserved and model.animator.get_animation_library("").get_animation_list().size()==12 and model.motion_family==weapon
					appearance["body"] = "caller_mutation"
					appearances_independent = appearances_independent and model.get_appearance()["body"] == body
					var returned := model.get_appearance()
					returned["weapon"] = "caller_mutation"
					appearances_independent = appearances_independent and model.get_appearance()["weapon"] == weapon
					var has_steel := model.surfaces.has_node("Layer_steel")
					observed_weapons[weapon] = bool(observed_weapons.get(weapon, true)) and (not has_steel if weapon == "unarmed" else has_steel)
					if outfit == "jade" and weapon == "unarmed" and hair == "topknot":
						body_signature[body] = _geometry_signature(model)
					if body == "male" and outfit == "jade" and weapon == "unarmed":
						hair_signature[hair] = _geometry_signature(model)
					count += 1
	check.call(count == 36 and variants_ok, "All thirty-six cosmetic combinations build valid skinned meshes without stale or invalid surfaces")
	check.call(skeleton_preserved, "Changing wardrobe preserves the shared skeleton/skin and selects a complete motion family")
	check.call(appearances_independent, "Character model appearance data cannot be changed through caller or returned dictionaries")
	check.call(observed_weapons.size() == 3 and observed_weapons.values().all(func(value): return value), "Sword and spear build weapon geometry while unarmed removes the previous steel layer")
	check.call(body_signature.size() == 2 and not is_equal_approx(body_signature["male"], body_signature["female"]), "Male and female model choices change geometry rather than only material colors")
	check.call(hair_signature.size() == 2 and not is_equal_approx(hair_signature["topknot"], hair_signature["ponytail"]), "Topknot and ponytail choices change geometry rather than only labels")
	model.set_appearance({"body":"male", "outfit":"jade", "hair":"topknot", "weapon":"sword"})
	var poses_valid := true
	var planted_root := true
	for clip in GuCharacterAnimations.clip_names():
		for angle in range(8):
			for fraction in [0.0, 0.38, 0.75, 1.0]:
				model.set_motion(clip, GuCharacterAnimations.duration(clip) * fraction, Vector2.DOWN.rotated(angle * TAU / 8))
				poses_valid = poses_valid and model.transform.is_finite() and model.hand_position("R").is_finite() and model.hand_position("L").is_finite()
				planted_root = planted_root and model.position.is_equal_approx(Vector3.ZERO)
				for bone in range(skeleton.get_bone_count()):
					poses_valid = poses_valid and skeleton.get_bone_global_pose(bone).is_finite()
	check.call(poses_valid, "The real skinned model remains finite across eight directions and all eleven sampled action timelines")
	check.call(planted_root, "Sampling character clips never translates the model's gameplay ground pivot")
	model.set_motion("not_a_clip", 0.1, Vector2.ZERO)
	check.call(model.active_clip == "idle" and model.transform.is_finite(), "Unknown preview actions and zero-length facing safely fall back to finite idle")
	model.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _geometry_valid(model: GuCharacterModel) -> bool:
	if model.surfaces.get_child_count() <= 0:
		return false
	var triangles := 0
	for child in model.surfaces.get_children():
		if not child is MeshInstance3D:
			return false
		var instance: MeshInstance3D = child
		if instance.mesh == null or instance.skin != model.skin or instance.get_node_or_null(instance.skeleton) != model.skeleton:
			return false
		for surface in range(instance.mesh.get_surface_count()):
			if instance.mesh.surface_get_material(surface) == null:
				return false
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var texcoords: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or normals.size() != vertices.size() or texcoords.size() != vertices.size() or indices.size() % 3 != 0:
				return false
			if bones.size() != vertices.size() * 4 or weights.size() != bones.size():
				return false
			for index in indices:
				if index < 0 or index >= vertices.size():
					return false
			for index in range(vertices.size()):
				if not vertices[index].is_finite() or not normals[index].is_finite() or not texcoords[index].is_finite() or not is_equal_approx(normals[index].length(), 1.0):
					return false
				var total := 0.0
				for influence in range(4):
					var offset := index * 4 + influence
					if bones[offset] < 0 or bones[offset] >= model.skeleton.get_bone_count() or not is_finite(weights[offset]) or weights[offset] < 0.0 or weights[offset] > 1.0:
						return false
					total += weights[offset]
				# Native ArrayMesh round-trip perturbs two-influence weights
				# by about 1/65535 in this build; reject errors beyond packing.
				if absf(total - 1.0) > 2.0 / 65535.0:
					return false
			triangles += indices.size() / 3
	return triangles == model.triangle_count and triangles > 0


static func _geometry_signature(model: GuCharacterModel) -> float:
	var result := 0.0
	for instance in model.surfaces.get_children():
		for surface in range(instance.mesh.get_surface_count()):
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				result += point.length_squared()
	return result
