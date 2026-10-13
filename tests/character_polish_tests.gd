extends RefCounted
## Independent polish gates exercise the actual generated meshes and sampled FK.
## Cosmetics and animation remain presentation data; no authority is involved.

const WEAPONS: Array[String] = ["sword", "spear", "unarmed"]
const GRIP_ACTIONS: Array[String] = ["idle", "walk", "run", "attack", "defend"]
const REQUIRED_TEXTURES: Array[String] = ["cloth", "cloth_dark", "cloth_light", "ivory", "leather", "hair", "hair_light"]


static func run(tree: SceneTree, check: Callable) -> void:
	var view := GuCharacterViewport.new()
	view.configure(480, 140)
	tree.root.add_child(view)
	view.set_active(false)
	await tree.process_frame
	var model: GuCharacterModel = view.model
	model.blend_transitions = false
	var skeleton := model.skeleton
	var player := model.animator
	var geometry: Dictionary = {}
	var textured_uvs := true
	var textures_present := true
	var texture_variation := true
	var normal_maps := true
	for outfit: String in ["jade", "crimson", "ivory"]:
		view.set_appearance({"body":"male", "outfit":outfit, "hair":"topknot", "weapon":"unarmed"})
		geometry[outfit] = _geometry_fingerprint(model)
		for key: String in REQUIRED_TEXTURES:
			var material: StandardMaterial3D = model.materials.get(key)
			textures_present = textures_present and material != null and material.albedo_texture != null
			if material != null and material.albedo_texture != null:
				var texture := material.albedo_texture
				texture_variation = texture_variation and texture.get_width() >= 64 and texture.get_height() >= 64
				texture_variation = texture_variation and material.texture_repeat and material.uv1_scale.is_finite() and material.uv1_scale.x > 0 and material.uv1_scale.y > 0
		for key: String in ["cloth", "leather", "hair", "steel"]:
			var material: StandardMaterial3D = model.materials.get(key)
			normal_maps = normal_maps and material != null and material.normal_enabled and material.normal_texture != null
		textured_uvs = textured_uvs and _textured_surfaces_valid(model)
	check.call(geometry["jade"] != geometry["crimson"] and geometry["jade"] != geometry["ivory"] and geometry["crimson"] != geometry["ivory"], "Three wardrobe options have different actual geometry independently of palette colors")
	check.call(textures_present and texture_variation, "Fabric, lining, leather and hair have valid repeating albedo textures across all three garments")
	check.call(textured_uvs, "Textured character surfaces have finite nondegenerate UVs and real tangent frames")
	check.call(normal_maps, "Cloth, leather, hair and steel use actual normal map resources")
	check.call(model.skeleton == skeleton and model.animator == player and skeleton.get_bone_count() == 22, "Changing garment meshes preserves the existing twenty-two-bone skeleton and AnimationPlayer")
	view.set_appearance({"body":"male", "outfit":"jade", "hair":"topknot", "weapon":"unarmed"})
	var male_face := _face_fingerprint(model)
	view.set_appearance({"body":"female", "outfit":"jade", "hair":"topknot", "weapon":"unarmed"})
	check.call(male_face != _face_fingerprint(model), "Male and female faces have different actual head geometry independently of skin colors")

	var trajectories: Dictionary = {}
	var family_metadata := true
	var complete_libraries := true
	var no_method_tracks := true
	for weapon: String in WEAPONS:
		view.set_appearance({"body":"male", "outfit":"jade", "hair":"topknot", "weapon":weapon})
		var library := model.animator.get_animation_library("")
		complete_libraries = complete_libraries and library.get_animation_list().size() == 12
		trajectories[weapon] = {}
		for clip: StringName in library.get_animation_list():
			var animation := library.get_animation(clip)
			family_metadata = family_metadata and str(animation.get_meta("weapon_family", "")) == weapon
			for track in range(animation.get_track_count()):
				no_method_tracks = no_method_tracks and animation.track_get_type(track) != Animation.TYPE_METHOD
		for action: String in ["attack", "defend", "run"]:
			trajectories[weapon][action] = _trajectory(model, action)
	check.call(complete_libraries and family_metadata, "Sword, spear and unarmed select separate complete motion libraries with explicit weapon family metadata")
	check.call(no_method_tracks, "Weapon animation libraries contain no gameplay method tracks or damage callbacks")
	for action: String in ["attack", "defend", "run"]:
		var distinct := true
		for pair: Vector2i in [Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)]:
			distinct = distinct and _trajectory_difference(trajectories[WEAPONS[pair.x]][action], trajectories[WEAPONS[pair.y]][action]) > 0.05
		check.call(distinct, "%s has different actual FK hand/body trajectories for sword, spear and unarmed" % action)

	var grip_script := load("res://scripts/presentation/weapon_rig.gd")
	var grip_ok := grip_script != null
	var maximum_grip_error := 0.0
	view.set_appearance({"body":"female", "outfit":"ivory", "hair":"ponytail", "weapon":"spear"})
	if grip_script != null:
		var target: Vector3 = grip_script.support_grip("spear")
		var right_index := skeleton.find_bone("Hand_R")
		for action: String in GRIP_ACTIONS:
			var length := model.animator.get_animation(action).length
			for sample in range(41):
				view.present(action, length * float(sample) / 40.0, Vector2.DOWN)
				var expected := skeleton.get_bone_global_pose(right_index) * target
				var error := expected.distance_to(model.hand_position("L"))
				maximum_grip_error = maxf(maximum_grip_error, error)
				grip_ok = grip_ok and is_finite(error) and error < 0.008
	check.call(grip_ok, "Spear support hand stays within 8 mm of its shaft grip through idle, gait, strike and defence (max %.1f mm)" % (maximum_grip_error * 1000))

	var finite_geometry := true
	var ground_pivot := true
	var camera_fit := true
	var sampled_frames := 0
	var crop_detail := ""
	var envelopes: Dictionary = {}
	# Representative cases exercise every weapon and all three distinct garments;
	# the existing geometry suite covers every one of the 36 cosmetic combinations.
	var cases: Array[Dictionary] = [
		{"body":"male", "outfit":"jade", "hair":"topknot", "weapon":"sword"},
		{"body":"female", "outfit":"ivory", "hair":"ponytail", "weapon":"spear"},
		{"body":"male", "outfit":"crimson", "hair":"ponytail", "weapon":"unarmed"},
	]
	for appearance: Dictionary in cases:
		view.set_appearance(appearance)
		var arrays := _mesh_arrays(model)
		for action: String in GuCharacterAnimations.clip_names():
			var length := model.animator.get_animation(action).length
			for fraction: float in [0.0, 0.19, 0.38, 0.65, 0.90, 1.0]:
				view.present(action, length * fraction, Vector2.DOWN)
				var points := _skin_vertices(model, arrays)
				for point: Vector3 in points:
					finite_geometry = finite_geometry and point.is_finite() and point.length() < 4.0
				for angle in range(8):
					view.present(action, length * fraction, Vector2.DOWN.rotated(float(angle) * TAU / 8))
					ground_pivot = ground_pivot and model.position.is_zero_approx() and model.scale.is_equal_approx(Vector3.ONE)
					var screen_bounds := _camera_bounds(view.camera, model.transform, points)
					var weapon: String = appearance["weapon"]
					envelopes[weapon] = Rect2(envelopes[weapon]).merge(screen_bounds) if envelopes.has(weapon) else screen_bounds
					var fits := screen_bounds.position.x >= 0.005 and screen_bounds.position.y >= 0.005 and screen_bounds.end.x <= 0.995 and screen_bounds.end.y <= 0.995
					if not fits and crop_detail.is_empty():
						crop_detail = "%s %s %.2f direction %d bounds %s" % [appearance["weapon"], action, fraction, angle, screen_bounds]
					camera_fit = camera_fit and fits
					sampled_frames += 1
	check.call(finite_geometry, "CPU-skinned garment, body, hair and weapon vertices stay finite and bounded in every sampled action")
	check.call(ground_pivot, "All eight directions and eleven actions preserve the gameplay ground pivot and model scale")
	check.call(camera_fit, "Character render keeps complete body and weapon inside the texture for %d sampled views%s" % [sampled_frames, "" if crop_detail.is_empty() else " — " + crop_detail])
	print("CHARACTER_POLISH_ENVELOPES ", envelopes)
	view.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _geometry_fingerprint(model: GuCharacterModel) -> int:
	# Commutative accumulation does not treat material regrouping or vertex order
	# as a new outfit: coordinates and their multiplicities must actually differ.
	var digest := 0
	var xor_digest := 0
	var count := 0
	for instance: MeshInstance3D in model.surfaces.get_children():
		for surface in range(instance.mesh.get_surface_count()):
			var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point: Vector3 in vertices:
				var quantized := Vector3i(roundi(point.x * 100000), roundi(point.y * 100000), roundi(point.z * 100000))
				var value := hash(quantized)
				digest += value
				xor_digest ^= value
				count += 1
	return hash([count, digest, xor_digest])


static func _textured_surfaces_valid(model: GuCharacterModel) -> bool:
	var checked := 0
	for instance: MeshInstance3D in model.surfaces.get_children():
		for surface in range(instance.mesh.get_surface_count()):
			var material: StandardMaterial3D = instance.mesh.surface_get_material(surface)
			if material == null:
				return false
			if material.albedo_texture == null:
				continue
			var arrays := instance.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_TANGENT] == null or arrays[Mesh.ARRAY_TEX_UV] == null:
				return false
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			if uv.size() != vertices.size() or tangents.size() != vertices.size() * 4:
				return false
			var minimum := Vector2(INF, INF)
			var maximum := Vector2(-INF, -INF)
			for index in range(uv.size()):
				if not uv[index].is_finite():
					return false
				minimum = minimum.min(uv[index])
				maximum = maximum.max(uv[index])
				var tangent := Vector3(tangents[index * 4], tangents[index * 4 + 1], tangents[index * 4 + 2])
				if not tangent.is_finite() or tangent.length_squared() < 0.25 or absf(tangents[index * 4 + 3]) < 0.5:
					return false
				if absf(tangent.normalized().dot(normals[index])) > 0.02:
					return false
			if (maximum - minimum).length_squared() < 0.1:
				return false
			checked += 1
	return checked >= 5


static func _face_fingerprint(model: GuCharacterModel) -> int:
	var head := model.skeleton.find_bone("Head")
	var count := 0
	var digest := 0
	var xor_digest := 0
	for instance: MeshInstance3D in model.surfaces.get_children():
		for surface in range(instance.mesh.get_surface_count()):
			if instance.mesh.surface_get_material(surface) != model.materials["face_skin"]:
				continue
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for index in range(vertices.size()):
				if bones[index * 4] != head or weights[index * 4] < 0.5:
					continue
				var point := vertices[index]
				var value := hash(Vector3i(roundi(point.x * 100000), roundi(point.y * 100000), roundi(point.z * 100000)))
				digest += value
				xor_digest ^= value
				count += 1
	return hash([count, digest, xor_digest])


static func _trajectory(model: GuCharacterModel, action: String) -> PackedVector3Array:
	var result := PackedVector3Array()
	var length := model.animator.get_animation(action).length
	for fraction: float in [0.0, 0.14, 0.29, 0.42, 0.59, 0.76, 0.91]:
		model.set_motion(action, length * fraction, Vector2.DOWN)
		result.append(model.hand_position("L"))
		result.append(model.hand_position("R"))
		result.append(model.skeleton.get_bone_global_pose(model.skeleton.find_bone("Head")).origin)
	return result


static func _trajectory_difference(first: PackedVector3Array, second: PackedVector3Array) -> float:
	var difference := 0.0
	for index in range(mini(first.size(), second.size())):
		difference += first[index].distance_to(second[index])
	return difference


static func _mesh_arrays(model: GuCharacterModel) -> Array[Array]:
	var result: Array[Array] = []
	for instance: MeshInstance3D in model.surfaces.get_children():
		for surface in range(instance.mesh.get_surface_count()):
			result.append(instance.mesh.surface_get_arrays(surface))
	return result


static func _skin_vertices(model: GuCharacterModel, arrays: Array[Array]) -> PackedVector3Array:
	var transforms: Array[Transform3D] = []
	for bone in range(model.skeleton.get_bone_count()):
		transforms.append(model.skeleton.get_bone_global_pose(bone) * model.skin.get_bind_pose(bone))
	var result := PackedVector3Array()
	for surface: Array in arrays:
		var vertices: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = surface[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = surface[Mesh.ARRAY_WEIGHTS]
		for index in range(vertices.size()):
			var point := Vector3.ZERO
			for influence in range(4):
				var offset := index * 4 + influence
				if weights[offset] > 0.00001:
					point += transforms[bones[offset]] * vertices[index] * weights[offset]
			result.append(point)
	return result


static func _camera_bounds(camera: Camera3D, transform: Transform3D, points: PackedVector3Array) -> Rect2:
	var inverse := camera.get_camera_transform().affine_inverse() * transform
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point: Vector3 in points:
		var projected := inverse * point
		var uv := Vector2(0.5 + projected.x / camera.size, 0.5 - projected.y / camera.size)
		minimum = minimum.min(uv)
		maximum = maximum.max(uv)
	return Rect2(minimum, maximum - minimum)
