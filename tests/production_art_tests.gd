extends RefCounted
## Data and integration gates for the art candidate. Native art review is separate:
## valid meshes and texture resources cannot establish a production art standard.


static func run(tree: SceneTree, check: Callable) -> void:
	var progress := {"checks":0}
	var tracked := func(condition: bool, label: String) -> void:
		progress["checks"] += 1
		check.call(condition, label)
	await _baked_assets(tree, tracked)
	await _character_data(tree, tracked)
	await _cosmetic_boundary(tree, tracked)
	await _world_art(tree, tracked)
	check.call(progress["checks"] == 19, "All nineteen independent art-data, runtime-content, authority and world-wiring gates completed without aborting")


static func _baked_assets(tree: SceneTree, check: Callable) -> void:
	var model := GuCharacterModel.new()
	tree.root.add_child(model)
	await tree.process_frame
	var actual_assets := true
	var rig_contract := true
	var variants := 0
	var paths: Dictionary = {}
	for body: String in ["male", "female"]:
		for outfit: String in ["jade", "crimson", "ivory"]:
			for hair: String in ["topknot", "ponytail"]:
				for weapon: String in ["sword", "spear", "unarmed"]:
					var look := {"body":body, "outfit":outfit, "hair":hair, "weapon":weapon}
					model.set_appearance(look)
					var asset: Resource = model.get("geometry_asset")
					var path := str(model.get("geometry_asset_path"))
					actual_assets = actual_assets and str(model.get("geometry_source")) == "baked" and asset != null and path.ends_with(".res") and ResourceLoader.exists(path)
					paths[path] = true
					if asset == null:
						continue
					var meshes: Array = asset.get("layer_meshes")
					actual_assets = actual_assets and meshes.size() == model.surfaces.get_child_count() and not meshes.is_empty()
					for index in range(mini(meshes.size(), model.surfaces.get_child_count())):
						var instance := model.surfaces.get_child(index) as MeshInstance3D
						actual_assets = actual_assets and instance != null and instance.mesh == meshes[index]
					var names: PackedStringArray = asset.get("rig_bones")
					var rests: Array = asset.get("rig_global_rests")
					var descriptor: Dictionary = asset.get("descriptor")
					rig_contract = rig_contract and str(asset.get("revision")) == "art10" and descriptor == look and names.size() == 22 and rests.size() == 22
					for index in range(mini(22, mini(names.size(), rests.size()))):
						rig_contract = rig_contract and names[index] == model.skeleton.get_bone_name(index) and model.skeleton.get_bone_global_rest(index).is_equal_approx(rests[index])
					variants += 1
	check.call(actual_assets and variants == 36 and paths.size() == 36, "All thirty-six runtime appearances draw the actual packaged mesh resources instead of merely naming baked files")
	check.call(rig_contract, "Packaged art revision, exact appearance descriptors and bone names/rests match the active animation rig")
	model.set("prefer_baked_assets", false)
	model.set_appearance({"body":"female", "outfit":"crimson", "hair":"topknot", "weapon":"spear"})
	model.blend_transitions = false
	model.set_motion("attack", GuCharacterAnimations.duration("attack", "spear") * 0.4, Vector2.DOWN, true)
	check.call(str(model.get("geometry_source")) == "generated" and model.get("geometry_asset") == null and model.surfaces.get_child_count() > 0 and model.skeleton.get_bone_count() == 22 and model.hand_position("L").is_finite() and model.motion_family == "spear", "Explicit authoring fallback still builds and animates on the same rig when baked geometry is disabled")
	model.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _character_data(tree: SceneTree, check: Callable) -> void:
	var model := GuCharacterModel.new()
	tree.root.add_child(model)
	await tree.process_frame
	model.blend_transitions = false
	var rig := model.skeleton
	var player := model.animator
	var geometry_ok := true
	var frames_ok := true
	var skin_ok := true
	var bindings_ok := true
	var material_ok := true
	var winding_ok := true
	var texture_data_ok := true
	var library_ok := true
	var measured_vertices := 0
	var measured_textures: Dictionary = {}
	for body: String in ["male", "female"]:
		for weapon: String in ["sword", "spear", "unarmed"]:
			var look := {"body":body, "outfit":"crimson" if weapon == "spear" else ("ivory" if weapon == "unarmed" else "jade"), "hair":"ponytail" if body == "female" else "topknot", "weapon":weapon}
			model.set_appearance(look)
			bindings_ok = bindings_ok and model.skeleton == rig and model.animator == player and rig.get_bone_count() == 22
			var library := player.get_animation_library("")
			library_ok = library_ok and library.get_animation_list().size() == 12 and model.motion_family == weapon
			for action: String in GuCharacterAnimations.clip_names():
				library_ok = library_ok and player.has_animation(action)
				if not player.has_animation(action):
					continue
				var animation := player.get_animation(action)
				library_ok = library_ok and str(animation.get_meta("weapon_family", "")) == weapon
				for track in range(animation.get_track_count()):
					library_ok = library_ok and animation.track_get_type(track) != Animation.TYPE_METHOD
				model.set_motion(action, animation.length * 0.43, Vector2.DOWN, true)
				library_ok = library_ok and model.hand_position("L").is_finite() and model.hand_position("R").is_finite()
			for node: Node in model.surfaces.get_children():
				if not node is MeshInstance3D:
					geometry_ok = false
					continue
				var instance := node as MeshInstance3D
				bindings_ok = bindings_ok and instance.skin != null and instance.get_node_or_null(instance.skeleton) == rig
				if instance.mesh == null:
					geometry_ok = false
					continue
				for surface in range(instance.mesh.get_surface_count()):
					var arrays := instance.mesh.surface_get_arrays(surface)
					var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
					var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
					var tangent: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
					var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
					var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
					var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
					var lengths_valid := not vertices.is_empty() and normals.size() == vertices.size() and uv.size() == vertices.size() and tangent.size() == vertices.size() * 4 and bones.size() == vertices.size() * 4 and weights.size() == bones.size()
					geometry_ok = geometry_ok and lengths_valid and indices.size() % 3 == 0
					if not lengths_valid:
						continue
					for index in indices:
						geometry_ok = geometry_ok and index >= 0 and index < vertices.size()
					for triangle in range(0, indices.size() - 2, 3):
						var a := indices[triangle]
						var b := indices[triangle + 1]
						var c := indices[triangle + 2]
						if a < 0 or b < 0 or c < 0 or a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
							winding_ok = false
							continue
						var face := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
						var outward := normals[a] + normals[b] + normals[c]
						if face.length_squared() < 0.00000000000001 or outward.length_squared() < 0.00000001:
							continue
						# Godot's front-face winding is clockwise. Geometry must
						# agree with its stored outward shading normals.
						winding_ok = winding_ok and face.normalized().dot(outward.normalized()) <= 0.0001
					for index in range(vertices.size()):
						geometry_ok = geometry_ok and vertices[index].is_finite() and normals[index].is_finite() and uv[index].is_finite() and absf(normals[index].length() - 1) < 0.005
						var axis := Vector3(tangent[index * 4], tangent[index * 4 + 1], tangent[index * 4 + 2])
						frames_ok = frames_ok and axis.is_finite() and absf(axis.length() - 1) < 0.02 and absf(axis.dot(normals[index])) < 0.025 and absf(absf(tangent[index * 4 + 3]) - 1) < 0.01
						var total := 0.0
						for influence in range(4):
							var offset := index * 4 + influence
							skin_ok = skin_ok and bones[offset] >= 0 and bones[offset] < 22 and is_finite(weights[offset]) and weights[offset] >= 0 and weights[offset] <= 1
							total += weights[offset]
						skin_ok = skin_ok and absf(total - 1) < 0.0001
					measured_vertices += vertices.size()
					var material := instance.mesh.surface_get_material(surface) as StandardMaterial3D
					material_ok = material_ok and material != null
					if material == null:
						continue
					material_ok = material_ok and is_finite(material.roughness) and material.roughness >= 0 and material.roughness <= 1 and _color_finite(material.albedo_color)
					for texture: Texture2D in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
						if texture == null or measured_textures.has(texture.get_instance_id()):
							continue
						measured_textures[texture.get_instance_id()] = true
						texture_data_ok = texture_data_ok and _image_has_variation(texture, false, 2)
	check.call(geometry_ok and measured_vertices > 0, "Six integrated body/weapon variants have finite normalized normals, finite UVs and valid triangle indices")
	check.call(winding_ok, "Nondegenerate integrated character triangles have front-face winding consistent with their outward normals")
	check.call(frames_ok, "Integrated material tangents remain finite, normalized and orthogonal with valid handedness")
	check.call(skin_ok, "Integrated mesh weights resolve all four bone influences and remain normalized after asset loading")
	check.call(bindings_ok, "Appearance replacement retains one live skeleton and AnimationPlayer and resolves every mesh skeleton path")
	check.call(library_ok, "Every integrated weapon family has all eleven finite sampled actions and no gameplay method tracks")
	check.call(material_ok and texture_data_ok and measured_textures.size() >= 6, "Integrated material maps contain readable varied pixels rather than empty texture resources")
	model.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _cosmetic_boundary(tree: SceneTree, check: Callable) -> void:
	var sim := LocalAuthority.new(74021)
	var before := sim.player.duplicate(true)
	var inventory_before := sim.inventory.to_data().duplicate(true)
	var progress_before := sim.progress.duplicate(true)
	var actor := ActorView.new()
	actor.bind(sim.player, true)
	tree.root.add_child(actor)
	await tree.process_frame
	actor.set_process(false)
	check.call(str(actor.character_view.model.get("geometry_source")) == "baked" and actor.character_view.model.get("geometry_asset") != null, "The actual gameplay player viewport starts from packaged art assets")
	var look := {"body":"female", "outfit":"ivory", "hair":"ponytail", "weapon":"spear"}
	actor.character_view.set_appearance(look)
	for action: String in GuCharacterAnimations.clip_names():
		actor.character_view.present(action, GuCharacterAnimations.duration(action, "spear") * 0.38, Vector2.RIGHT, true)
	check.call(sim.player == before and sim.inventory.to_data() == inventory_before and sim.progress == progress_before, "Previewing every new art action cannot mutate authority position, health, resources, inventory or progression")
	var changed := sim.set_appearance(look)
	actor._sync_character()
	var after := sim.player.duplicate(true)
	after["appearance"] = before["appearance"]
	check.call(bool(changed.get("ok", false)) and after == before and actor.character_view.model.get_appearance() == look, "Applying new art changes only cosmetic identity and reaches the actual player viewport")
	var saved := sim.to_profile()
	var restored := LocalAuthority.new(74021)
	var restored_ok := restored.load_profile(saved)
	look["weapon"] = "caller_mutation"
	saved["appearance_v2"]["hat"] = "caller_mutation"
	check.call(restored_ok and restored.player["appearance"] == sim.player["appearance"] and GuCharacterAppearance.validate(sim.player["appearance"]), "Art identity survives profile serialization independently of caller and serialized dictionaries")
	var legacy := sim.to_profile()
	legacy.erase("appearance")
	check.call(restored.load_profile(legacy) and restored.player["appearance"] == GuCharacterAppearance.default_data(), "Pre-customization profiles still load a valid default art identity")
	actor.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _world_art(tree: SceneTree, check: Callable) -> void:
	var sim := LocalAuthority.new(74021)
	var world := WorldView.new()
	tree.root.add_child(world)
	world.setup(sim)
	await tree.process_frame
	world.set_process(false)
	var ground: GroundView
	for child in world.get_children():
		if child is GroundView:
			ground = child
	var ground_texture := ground.get("art_atlas") as Texture2D if ground != null else null
	var ground_material := ground.get("ground_material") as ShaderMaterial if ground != null else null
	var terrain_node := ground.get_node_or_null("PaintedTerrain") as Polygon2D if ground != null else null
	check.call(ground_texture != null and _raster_source_valid(ground_texture) and _image_has_variation(ground_texture, false) and ground_material != null and terrain_node != null and terrain_node.material == ground_material and terrain_node.texture == ground_texture and ground_material.get_shader_parameter("terrain_art") == ground_texture, "Live ground draws varied imported PNG art through the actual continuous terrain polygon/material")
	var painted_props := 0
	var prop_data_ok := true
	var prop_sort_ok := world.y_sort_enabled and ground != null and ground.z_index < 0
	var sources: Dictionary = {}
	var atlas_pixels: Dictionary = {}
	var tree_prop: PropView
	for prop: PropView in world.props:
		prop_sort_ok = prop_sort_ok and prop.position.is_equal_approx(WorldGrid.project(prop.cell)) and prop.get_parent() == world
		if prop.kind == "tree" and tree_prop == null:
			tree_prop = prop
		if not prop.has_method("uses_painted_art") or not prop.call("uses_painted_art"):
			continue
		painted_props += 1
		var atlas := prop.get("art_atlas") as Texture2D
		var source: Rect2 = prop.get("art_source")
		var bounds: Rect2 = prop.get("art_bounds")
		prop_data_ok = prop_data_ok and atlas != null and _raster_source_valid(atlas) and source.has_area() and bounds.has_area()
		if atlas != null:
			prop_data_ok = prop_data_ok and Rect2(Vector2.ZERO, atlas.get_size()).encloses(source)
			var atlas_id := atlas.get_instance_id()
			if not atlas_pixels.has(atlas_id):
				var pixels := atlas.get_image()
				if pixels != null and pixels.is_compressed():
					pixels.decompress()
				atlas_pixels[atlas_id] = pixels
			var signature := str(atlas_id) + str(source)
			if not sources.has(signature):
				sources[signature] = true
				prop_data_ok = prop_data_ok and _atlas_region_valid(atlas_pixels[atlas_id], source)
	check.call(prop_data_ok and painted_props >= 6 and sources.size() >= 3, "Live trees and stone props select varied transparent atlas regions with nonempty draw bounds")
	check.call(prop_sort_ok, "New ground and prop art retains the isometric ground pivots and shared actor/prop Y-sort")
	var occlusion_ok := tree_prop != null
	if tree_prop != null:
		world.player_view.set_process(false)
		world.player_view.position = tree_prop.position + Vector2(0, -40)
		world._process(1)
		var faded := tree_prop.modulate.a
		world.player_view.position = tree_prop.position + Vector2(500, 500)
		world._process(1)
		occlusion_ok = faded < 0.4 and tree_prop.modulate.a > 0.9
	check.call(occlusion_ok, "Actual painted tree fades when it covers the player and restores opacity when the player leaves")
	world.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout


static func _image_has_variation(texture: Texture2D, transparent: bool, minimum_colors: int = 16) -> bool:
	if texture == null or texture.get_width() < 64 or texture.get_height() < 64:
		return false
	var pixels := texture.get_image()
	if pixels == null or pixels.is_empty():
		return false
	if pixels.is_compressed() and pixels.decompress() != OK:
		return false
	var colors: Dictionary = {}
	var opaque := 0
	var clear := 0
	# Relatively prime sample strides avoid accidentally sampling only one
	# phase of a regular weave/brush normal-map pattern.
	for sample in range(2048):
		var x := posmod(sample * 7919 + sample * sample * 17, pixels.get_width())
		var y := posmod(sample * 104729 + sample * sample * 41, pixels.get_height())
		var color := pixels.get_pixel(x, y)
		if color.a > 0.5:
			opaque += 1
			colors[color.to_rgba32()] = true
		if color.a < 0.1:
			clear += 1
	return opaque > 20 and colors.size() >= minimum_colors and (not transparent or clear > 20)


static func _color_finite(value: Color) -> bool:
	return is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)


static func _raster_source_valid(texture: Texture2D) -> bool:
	if texture == null:
		return false
	# Portable ImageTexture copies retain the imported PNG's provenance because
	# their runtime resource_path is empty. Pixel validation happens separately.
	var path := str(texture.get_meta("source_asset", texture.resource_path))
	if not path.ends_with(".png"):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and file.get_buffer(8).hex_encode() == "89504e470d0a1a0a"


static func _atlas_region_valid(pixels: Image, region: Rect2) -> bool:
	if pixels == null or pixels.is_empty() or not region.has_area():
		return false
	var colors: Dictionary = {}
	var opaque := 0
	var clear := 0
	for y in range(24):
		for x in range(24):
			var sample := region.position + region.size * Vector2((x + 0.5) / 24.0, (y + 0.5) / 24.0)
			var color := pixels.get_pixel(clampi(int(sample.x), 0, pixels.get_width() - 1), clampi(int(sample.y), 0, pixels.get_height() - 1))
			if color.a > 0.5:
				opaque += 1
				colors[color.to_rgba32()] = true
			if color.a < 0.1:
				clear += 1
	return opaque > 16 and clear > 16 and colors.size() > 16
