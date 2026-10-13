extends RefCounted
## Pixel runtime acceptance. Tests imported assets, authored frame data and live
## views independently of the obsolete 3D authoring pipeline.

const ENVIRONMENT_MANIFEST := "res://assets/pixel/environment/manifest.json"
const ACTIONS := ["idle", "walk", "run", "attack", "defend", "cast", "channel", "dash", "hit", "death", "respawn"]

static func run(tree: SceneTree, check: Callable) -> bool:
	check.call(WorldGrid.CELL_SIZE == Vector2(32, 32) and WorldGrid.project(Vector2.RIGHT) == Vector2(32, 0) and WorldGrid.project(Vector2.DOWN) == Vector2(0, 32), "The live world uses 32px square tiles with orthogonal screen directions")
	var projections_ok := true
	for point in [Vector2.ZERO, Vector2(12, 20), Vector2(7.35, 16.72), Vector2(-3.25, 40.5)]:
		projections_ok = projections_ok and WorldGrid.unproject(WorldGrid.project(point)).is_equal_approx(point)
	check.call(projections_ok, "Pixel world projection round trips both whole and fractional authority cells")
	var manifest := GuPixelCharacterView.atlas_manifest()
	# Godot JSON numbers are floats; array equality preserves element types.
	check.call(manifest.get("cell_size", []) == [80.0, 80.0] and manifest.get("pivot", []) == [40.0, 68.0] and float(manifest.get("native_height", 0)) == 48.0, "Character atlases share an 80px padded cell and a fixed ground pivot for a 48px figure")
	check.call(manifest.get("directions", []).size() == 8 and manifest.get("clips", {}).size() == ACTIONS.size() and manifest.get("appearances", {}).size() == 36, "The packaged sprite library contains eight directions, eleven actions and all 36 cosmetic combinations")
	if not manifest.has("appearances") or not manifest.has("clips"):
		return false
	var indices_valid := true
	var anchors_valid := true
	var assets_exist := true
	var counts_valid := true
	var sampled_binary_alpha := true
	var no_mipmaps := true
	var frame_margins := true
	var full_atlas_hashes := {}
	var clips: Dictionary = manifest["clips"]
	var records: Dictionary = manifest["appearances"]
	for key: String in records:
		var record: Dictionary = records[key]
		var path := str(record.get("path", ""))
		assets_exist = assets_exist and FileAccess.file_exists(path) and ResourceLoader.exists(path)
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if texture == null:
			indices_valid = false
			continue
		var image := texture.get_image()
		no_mipmaps = no_mipmaps and image != null and not image.has_mipmaps()
		if image == null:
			indices_valid = false
			continue
		full_atlas_hashes[_image_hash(image)] = true
		var columns := int(record.get("columns", 0))
		var max_frames := (image.get_width() / 80) * (image.get_height() / 80)
		indices_valid = indices_valid and columns > 0 and image.get_width() == columns * 80 and image.get_height() % 80 == 0
		for action: String in ACTIONS:
			var directions: Array = record.get("frames", {}).get(action, [])
			var hands: Array = record.get("hands", {}).get(action, [])
			counts_valid = counts_valid and directions.size() == 8 and hands.size() == 8 and int(clips.get(action, {}).get("frames", 0)) >= 4
			for direction in range(directions.size()):
				var frames: Array = directions[direction]
				counts_valid = counts_valid and frames.size() == int(clips.get(action, {}).get("frames", 0))
				for frame in range(frames.size()):
					indices_valid = indices_valid and int(frames[frame]) >= 0 and int(frames[frame]) < max_frames
					if direction >= hands.size() or frame >= hands[direction].size():
						anchors_valid = false
						continue
					for side in ["R", "L"]:
						var point: Array = hands[direction][frame].get(side, [])
						anchors_valid = anchors_valid and point.size() == 2
						if point.size() == 2:
							anchors_valid = anchors_valid and is_finite(float(point[0])) and is_finite(float(point[1])) and float(point[0]) >= 0 and float(point[0]) < 80 and float(point[1]) >= 0 and float(point[1]) < 80 and is_equal_approx(float(point[0]), roundf(float(point[0]))) and is_equal_approx(float(point[1]), roundf(float(point[1])))
		# Every frame in one atlas is inspected, plus separate body/weapon variants.
		# Hashes and indices above cover all 36 imported atlas resources.
		if key in ["male_jade_topknot_sword", "female_ivory_ponytail_spear", "female_crimson_topknot_unarmed"]:
			sampled_binary_alpha = sampled_binary_alpha and _binary_alpha(image)
			for action: String in ACTIONS:
				for directions: Array in record["frames"][action]:
					for frame_id in directions:
						var origin := Vector2i(int(frame_id) % columns, int(frame_id) / columns) * 80
						var bounds := image.get_region(Rect2i(origin, Vector2i(80, 80))).get_used_rect()
						frame_margins = frame_margins and bounds.has_area() and bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 80 and bounds.end.y < 80
	check.call(assets_exist and indices_valid and full_atlas_hashes.size() == 36, "All 36 imported character PNGs exist, have valid frame indices and contain distinct actual pixels")
	check.call(counts_valid, "Every cosmetic combination has at least four frames for every action in each of eight directions")
	check.call(anchors_valid, "Every authored frame has finite integer left/right hand anchors inside its padded cell")
	check.call(sampled_binary_alpha and no_mipmaps, "Representative full character atlases use only 0/255 alpha and imported textures have no smoothing mipmaps")
	check.call(frame_margins, "Complete action and direction silhouettes retain transparent cell margins for body and weapon without clipping")
	var view := GuPixelCharacterView.new()
	tree.root.add_child(view)
	view.configure(256, 48)
	await tree.process_frame
	check.call(view.sprite != null and view.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and view.sprite.scale == view.sprite.scale.round() and view.rotation == 0, "Live character sprites use nearest filtering, integer scale and no synthetic rotation")
	check.call(not _contains_3d_or_viewport(view), "The live character renderer contains no Node3D, camera or SubViewport")
	var direction_pixels := {}
	var direction_indices := {}
	for direction in range(8):
		view.present("idle", 0.0, Vector2.DOWN.rotated(direction * TAU / 8.0))
		direction_pixels[_image_hash(view.current_frame_texture().get_image())] = true
		direction_indices[view.current_direction] = true
	check.call(direction_pixels.size() == 8 and direction_indices.size() == 8, "All eight facing inputs select distinct authored frame pixels rather than renamed or rotated duplicates")
	var poses_change := true
	var actions_distinct := {}
	var anchors_fit := true
	for action: String in ACTIONS:
		var phases := {}
		for sample in range(16):
			view.present(action, GuCharacterAnimations.duration(action) * float(sample) / 15.0, Vector2.RIGHT)
			var texture := view.current_frame_texture()
			phases[_image_hash(texture.get_image())] = true
			actions_distinct[_image_hash(texture.get_image())] = true
			for side in ["R", "L"]:
				var anchor := view.hand_position(side)
				anchors_fit = anchors_fit and anchor.is_finite() and view.visual_rect().grow(0.001).has_point(anchor)
		poses_change = poses_change and phases.size() >= 2
	check.call(poses_change and actions_distinct.size() >= 22, "Idle, walking, running, attacks, guard, casting, channel, dash, hit, death and respawn animate with different authored pixels")
	check.call(anchors_fit, "Runtime spell anchors remain finite and inside the displayed atlas frame across all actions")
	var cosmetic_pixels := {}
	for body in GuCharacterAppearance.catalog("body"):
		for outfit in GuCharacterAppearance.catalog("outfit"):
			for weapon in GuCharacterAppearance.catalog("weapon"):
				for hair in GuCharacterAppearance.catalog("hair"):
					view.set_appearance({"body": body["id"], "outfit": outfit["id"], "weapon": weapon["id"], "hair": hair["id"]})
					view.present("idle", 0.0, Vector2.DOWN)
					cosmetic_pixels[_image_hash(view.current_frame_texture().get_image())] = true
	check.call(cosmetic_pixels.size() == 36, "Each selectable body, outfit, weapon and hair combination changes the visible front-facing sprite")
	view.set_appearance(GuCharacterAppearance.default_data())
	view.present("walk", 0.0, Vector2.RIGHT, true)
	var reduced := _image_hash(view.current_frame_texture().get_image())
	view.present("walk", 0.8, Vector2.RIGHT, true)
	check.call(_image_hash(view.current_frame_texture().get_image()) == reduced, "Reduced motion freezes locomotion frames while preserving a readable facing pose")
	view.present("death", 1.15, Vector2.DOWN)
	var fallen := view.current_frame
	view.present("death", 5.0, Vector2.DOWN)
	check.call(view.current_frame == fallen, "Death clamps to its final authored frame instead of looping back to standing")
	view.queue_free()
	_wolves(check)
	await _environment(tree, check)
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	await tree.process_frame
	game.set_physics_process(false)
	check.call(game.world_view.player_view.character_view is GuPixelCharacterView and game.hud.portrait_doll.avatar is GuPixelCharacterView and game.hud.character_doll.avatar is GuPixelCharacterView, "Gameplay, compact HUD and character sheet all use the same actual pixel renderer")
	check.call(not _contains_3d_or_viewport(game), "The complete live game scene contains no hidden 3D renderer or SubViewport")
	check.call(game.world_view.camera.zoom.x == game.world_view.camera.zoom.y and is_equal_approx(game.world_view.camera.zoom.x, roundf(game.world_view.camera.zoom.x)), "The world camera uses uniform integer magnification for crisp map and character pixels")
	var old_zoom := game.world_view.desired_zoom
	var wheel := InputEventMouseButton.new()
	wheel.position = tree.root.get_visible_rect().get_center()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	tree.root.push_input(wheel, true)
	game.world_view._process(0.03)
	var zoomed := game.world_view.desired_zoom == minf(old_zoom + 1, 3) and game.world_view.camera.zoom == Vector2.ONE * game.world_view.desired_zoom
	wheel = wheel.duplicate() as InputEventMouseButton
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	tree.root.push_input(wheel, true)
	game.world_view._process(0.03)
	var camera_pixels := game.world_view.camera.position*game.world_view.camera.zoom
	var shake_pixels := game.world_view.camera.offset*game.world_view.camera.zoom
	check.call(zoomed and game.world_view.desired_zoom == old_zoom and camera_pixels == camera_pixels.round() and shake_pixels == shake_pixels.round(), "Real wheel input changes zoom by one whole scale and camera movement stays registered to display pixels")
	game.world_view.set_reduced_motion(true)
	var ground_frozen := false
	for child in game.world_view.get_children():
		if child is GroundView:
			var ground_phase: float = child.phase
			child._process(0.4)
			ground_frozen = child.reduced_motion and child.phase == ground_phase
	check.call(ground_frozen, "Reduced motion also freezes animated water in the actual gameplay ground")
	game.world_view.set_reduced_motion(false)
	var authority_before := game.simulation.to_profile().duplicate(true)
	var inventory_before := game.simulation.inventory.to_data().duplicate(true)
	game.world_view.player_view.character_view.present("attack", 0.45, Vector2.UP)
	check.call(game.simulation.to_profile() == authority_before and game.simulation.inventory.to_data() == inventory_before, "Rendering an attack frame cannot change authority position, resources, equipment or save data")
	game.world_view.player_view.character_view.present("idle", 0.0, Vector2.LEFT)
	var origin: Vector2 = game.simulation.player["cell"]
	var event := {"kind": "cast_moon", "at": origin, "to": origin + Vector2.RIGHT * 2.0}
	var event_before := event.duplicate(true)
	game.world_view.receive(event)
	var effect: Dictionary = game.world_view.effects.effects.back()
	var live_view: GuPixelCharacterView = game.world_view.player_view.character_view
	check.call(effect["origin_offset"] == live_view.hand_position("R") and effect["character_texture"] == live_view.current_frame_texture() and live_view.current_action == "attack" and event == event_before, "Reversing facing for an accepted cast captures the new sprite hand and texture without modifying its source event")
	game.queue_free()
	await tree.process_frame
	return true

static func _wolves(check: Callable) -> void:
	var texture := GuPixelWolfArt.texture()
	check.call(texture != null and texture.get_size() == Vector2(2048, 384), "Enemies consume the original packaged 192-frame wolf pixel atlas")
	if texture == null:
		return
	var image := texture.get_image()
	check.call(_binary_alpha(image) and not image.has_mipmaps(), "Every wolf animation frame retains exact binary pixel alpha without mipmaps")
	var directions_ok := true
	var pixels := {}
	for direction in range(8):
		directions_ok = directions_ok and GuPixelWolfArt.direction_index(Vector2.DOWN.rotated(direction * TAU / 8.0)) == direction
		pixels[_image_hash(image.get_region(Rect2i(direction * 4 * 64, 0, 64, 64)))] = true
	check.call(directions_ok and pixels.size() == 8, "The wolf's eight authored facings match actual movement directions and have distinct silhouettes")
	var locomotion := {}
	var fallen := {}
	for frame in range(4):
		locomotion[_image_hash(image.get_region(Rect2i(frame * 64, 64, 64, 64)))] = true
		fallen[_image_hash(image.get_region(Rect2i(frame * 64, 5 * 64, 64, 64)))] = true
	check.call(locomotion.size() >= 3 and fallen.size() == 4, "Wolf locomotion alternates limbs and its four collapse frames remain visually distinct")

static func _environment(tree: SceneTree, check: Callable) -> void:
	var manifest_value = JSON.parse_string(FileAccess.get_file_as_string(ENVIRONMENT_MANIFEST))
	check.call(manifest_value is Dictionary, "The pixel environment has a packaged readable atlas manifest")
	if not manifest_value is Dictionary:
		return
	var manifest: Dictionary = manifest_value
	check.call(int(manifest.get("tile_size", 0)) == 32 and int(manifest.get("pixel_scale", 0)) == 1, "Environment assets are authored at the same native 32px grid as gameplay")
	var terrain: Dictionary = manifest.get("terrain", {})
	var props: Dictionary = manifest.get("props", {})
	var terrain_texture: Texture2D = load(str(terrain.get("path", "")))
	var prop_texture: Texture2D = load(str(props.get("path", "")))
	check.call(terrain_texture != null and prop_texture != null and terrain_texture.get_size() == Vector2(256, 192) and prop_texture.get_size() == Vector2(768, 384), "Native terrain and prop PNG atlases import at their specified pixel dimensions")
	if terrain_texture == null or prop_texture == null:
		return
	var terrain_image := terrain_texture.get_image()
	var prop_image := prop_texture.get_image()
	check.call(_binary_alpha(terrain_image) and _binary_alpha(prop_image) and not terrain_image.has_mipmaps() and not prop_image.has_mipmaps(), "Full environment atlases retain binary alpha and no filtering mipmaps")
	var tile_pixels := {}
	for tile in range(int(terrain.get("tile_count", 0))):
		var origin := Vector2i(tile % 8, tile / 8) * 32
		tile_pixels[_image_hash(terrain_image.get_region(Rect2i(origin, Vector2i(32, 32))))] = true
	var groups: Dictionary = terrain.get("groups", {})
	check.call(tile_pixels.size() >= 40 and ["grass", "dirt", "stone", "water", "flowers", "farm"].all(func(group: String) -> bool: return groups.has(group)), "Grass, road edges, stone paths, animated water, flowers and farm plots have genuinely distinct tile artwork")
	var prop_regions_valid := true
	var prop_pixels := {}
	for record: Dictionary in props.get("frames", []):
		var coordinates: Array = record.get("region", [])
		prop_regions_valid = prop_regions_valid and coordinates.size() == 4
		if coordinates.size() == 4:
			var region := Rect2i(int(coordinates[0]), int(coordinates[1]), int(coordinates[2]), int(coordinates[3]))
			prop_regions_valid = prop_regions_valid and Rect2i(Vector2i.ZERO, prop_image.get_size()).encloses(region) and region.size == Vector2i(96, 96)
			prop_pixels[_image_hash(prop_image.get_region(region))] = true
	check.call(prop_regions_valid and prop_pixels.size() >= 24, "Trees, rocks, roof segments, pillars, shrine and ambient animation occupy distinct valid prop cells")
	var world := WorldGrid.new()
	var blocked_before := world.blocked.duplicate(true)
	var definitions_before := world.props.duplicate(true)
	var ground := GroundView.new()
	ground.world = world
	tree.root.add_child(ground)
	await tree.process_frame
	check.call(ground.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and not _contains_3d_or_viewport(ground), "Ground draws native pixel tiles with nearest filtering directly in the 2D world")
	var sources := {}
	var bounds_valid := true
	var views: Array[PropView] = []
	for data: Dictionary in world.props:
		var view := PropView.new()
		view.configure(data)
		tree.root.add_child(view)
		views.append(view)
		sources[hash(view.art_source)] = true
		var appropriate_art := (view.art_source == Rect2() and view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR) if view.kind in ["bamboo","ruin_column"] else (view.uses_pixel_art() and view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
		bounds_valid = bounds_valid and appropriate_art and view.art_bounds.has_area() and view.position == WorldGrid.project(data["cell"]) and view.position == view.position.round() and view.scale == Vector2.ONE
	check.call(bounds_valid and sources.size() >= 12, "World props use their intended atlas or vector renderer with valid grounded bounds and the correct logical cell")
	check.call(world.blocked == blocked_before and world.props == definitions_before and world.is_walkable(WorldGrid.SPAWN) and world.is_safe(WorldGrid.SPAWN), "Constructing pixel terrain and props preserves obstacles, navigation and safe-camp authority")
	for view in views:
		view.queue_free()
	ground.queue_free()
	await tree.process_frame

static func _binary_alpha(image: Image) -> bool:
	if image == null:
		return false
	var copy := image.duplicate() as Image
	copy.clear_mipmaps()
	copy.convert(Image.FORMAT_RGBA8)
	var bytes := copy.get_data()
	for index in range(3, bytes.size(), 4):
		if bytes[index] != 0 and bytes[index] != 255:
			return false
	return true

static func _image_hash(image: Image) -> String:
	if image == null:
		return "missing"
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(image.get_data())
	return digest.finish().hex_encode()

static func _contains_3d_or_viewport(node: Node) -> bool:
	if node is Node3D or node is SubViewport:
		return true
	for child in node.get_children():
		if _contains_3d_or_viewport(child):
			return true
	return false
