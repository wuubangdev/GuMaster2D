extends RefCounted
## Presentation acceptance uses the imported art and the live scene. Authority
## remains immediate; readable combat beats and HUD tails may lag visually.

const FX_NAMES := ["moon_blade", "moon_impact", "ice_shard", "ice_impact", "shield_cast", "shield_loop", "dash_wake", "dash_feather", "cast_spark", "hit_spark", "dust", "seal", "reward"]

static func run(tree: SceneTree, check: Callable) -> bool:
	if not _fx_assets(check):
		return false
	await _vital_bar(tree, check)
	await _live_presentation(tree, check)
	return true

static func _hash(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()

static func _fx_assets(check: Callable) -> bool:
	var manifest := GuPixelEffectsArt.manifest()
	var clips: Dictionary = manifest.get("clips", {})
	var texture := GuPixelEffectsArt.texture()
	check.call(texture != null and FX_NAMES.all(func(kind: String) -> bool: return clips.has(kind)), "The imported pixel spell library supplies distinct projectile, impact, shield, dash, seal and reward artwork")
	if texture == null or not FX_NAMES.all(func(kind: String) -> bool: return clips.has(kind)):
		return false
	var image := texture.get_image()
	var alpha_ok := image != null and not image.has_mipmaps()
	if image == null:
		check.call(false, "Pixel spell textures expose their imported pixels for frame validation")
		return false
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	for index in range(3, data.size(), 4):
		if data[index] != 0 and data[index] != 255:
			alpha_ok = false
			break
	check.call(alpha_ok, "The complete pixel spell atlas uses exact binary alpha and no filtering mipmaps")
	var regions_valid := true
	var visible_frames := true
	var animated_clips := true
	var directional_frames := true
	var unique_frames := {}
	var atlas_bounds := Rect2(Vector2.ZERO, image.get_size())
	for kind: String in FX_NAMES:
		var clip: Dictionary = clips[kind]
		var clip_hashes := {}
		var facing_regions := {}
		for direction in range(int(clip["directions"])):
			for frame in range(int(clip["frames"])):
				var region := GuPixelEffectsArt.region(kind, frame, Vector2.RIGHT.rotated(direction * TAU / 8.0))
				regions_valid = regions_valid and region.size == Vector2(96, 96) and region.position == region.position.round() and atlas_bounds.encloses(region)
				if not atlas_bounds.encloses(region):
					continue
				var pixels := image.get_region(Rect2i(region))
				var bounds := pixels.get_used_rect()
				visible_frames = visible_frames and bounds.has_area() and bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 96 and bounds.end.y < 96
				clip_hashes[_hash(pixels)] = true
				unique_frames[str(region.position)] = true
				if frame == 3:
					facing_regions[str(region.position)] = true
		animated_clips = animated_clips and clip_hashes.size() >= 4
		directional_frames = directional_frames and facing_regions.size() == int(clip["directions"])
	check.call(regions_valid and unique_frames.size() == 328, "All 328 spell frames resolve to separate integral 96px cells within the actual imported atlas")
	check.call(visible_frames, "Every spell frame has visible art and transparent margins without clipping its silhouette")
	check.call(animated_clips and directional_frames, "Every spell has changing authored pixels and every directional projectile selects its own atlas cells")
	check.call(GuPixelEffectsArt.region("unknown", 0) == Rect2() and GuPixelEffectsArt.region("moon_blade", -1) == GuPixelEffectsArt.region("moon_blade", 0) and GuPixelEffectsArt.region("moon_blade", 999) == GuPixelEffectsArt.region("moon_blade", 7), "Missing art is safely rejected and frame requests clamp inside the valid authored sequence")
	var view := GuPixelCharacterView.new()
	view.configure(256, 48)
	view.present("idle", 0.0, Vector2.DOWN)
	var face := view.current_frame_texture().get_image().get_region(Rect2i(34, 30, 13, 8))
	var dark_eye := false
	var catchlight := false
	for y in range(face.get_height()):
		for x in range(face.get_width()):
			var pixel := face.get_pixel(x, y)
			dark_eye = dark_eye or pixel.is_equal_approx(Color("192837"))
			catchlight = catchlight or pixel.is_equal_approx(Color("fff8da"))
	check.call(dark_eye and catchlight, "The front-facing live hero has visible dark eyes and contrasting catchlights below its hair fringe")
	view.free()
	return true

static func _vital_bar(tree: SceneTree, check: Callable) -> void:
	var bar := GuVitalBar.new()
	bar.size = Vector2(160, 18)
	bar.max_value = 100
	bar.value = 100
	tree.root.add_child(bar)
	await tree.process_frame
	bar.set_process(false)
	bar.value = 60
	check.call(bar.value == 60 and bar.damage_tail == 100 and bar.hold_left > 0.0, "A lost-health edge holds the previous amount while the actual HP bar immediately reflects damage")
	bar._process(0.10)
	check.call(bar.value == 60 and bar.damage_tail == 100, "The brief held health edge acknowledges damage without changing the actual bar value")
	bar._process(0.10)
	bar._process(0.30)
	check.call(bar.damage_tail == 60 and bar.value == 60, "The held health edge settles at the actual current HP without lingering indefinitely")
	bar.reduced_motion = true
	bar.value = 25
	bar._process(0.0)
	check.call(bar.damage_tail == 25 and bar.value == 25, "Reduced motion immediately settles health feedback at the true amount")
	bar.queue_free()
	await tree.process_frame

static func _live_presentation(tree: SceneTree, check: Callable) -> void:
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
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(18, 20), "spawn": Vector2(18, 20), "hp": 140.0}, true)
	game.world_view.player_view.position = WorldGrid.project(sim.player["cell"])
	game.world_view.player_view.spawn_left = 0.0
	game.world_view.actors["wolf_0"].was_dead = false
	game.world_view.actors["wolf_0"].flash = 0.0
	game.world_view.actors["wolf_0"].position = WorldGrid.project(sim.mobs["wolf_0"]["cell"])
	check.call(bool(sim.cast(0, "wolf_0", Vector2.ZERO)["ok"]), "The polished projectile scenario starts with an accepted authoritative cast")
	game.flush_events()
	var profile := sim.to_profile().duplicate(true)
	var inventory := sim.inventory.to_data().duplicate(true)
	var moon: Dictionary = {}
	for effect in game.world_view.effects.effects:
		if effect["kind"] == "cast_moon":
			moon = effect
	var hero := game.world_view.player_view.character_view
	check.call(not moon.is_empty() and moon.get("origin_offset", Vector2.INF) == hero.hand_position("R") and float(moon.get("life", 0.0)) > GuPixelEffectsArt.CONTACT_TIME, "Accepted projectile art captures the current authored hand and retains time for travel followed by impact")
	var victim: ActorView = game.world_view.actors["wolf_0"]
	check.call(sim.mobs["wolf_0"]["hp"] < 140 and sim.player["mana"] == 92 and victim.flash == 0.0, "Damage and mana commit immediately while the victim's visual hit reaction waits for projectile contact")
	# The displayed caster may have moved during anticipation. Launch must
	# use its current world-space hand rather than the command's older cell.
	var rendered_player := game.world_view.player_view
	var old_position := rendered_player.position
	rendered_player.position += Vector2(11, -5)
	rendered_player._sync_character()
	game.world_view.effects._process(float(moon["release_time"])-.001)
	check.call(not moon.has("launch_offset"), "Sword projectile remains in the hand throughout its windup")
	game.world_view.effects._process(.002)
	var launch: Vector2 = WorldGrid.project(moon["at"]) + Vector2(moon["launch_offset"])
	check.call(launch.is_equal_approx(rendered_player.position + hero.hand_position("R")) and sim.to_profile() == profile, "A moving caster releases the spell from its current rendered hand without moving authority or charging resources again")
	rendered_player.position = old_position
	victim._process(GuPixelEffectsArt.CONTACT_TIME - 0.03)
	check.call(victim.flash == 0.0, "The victim cannot flash before the accepted projectile reaches its visual contact beat")
	victim._process(0.04)
	check.call(victim.flash > 0.0, "The victim's hit flash starts when the accepted projectile reaches visual contact")
	game.world_view.effects._process(0.35)
	game.world_view.player_view._process(0.35)
	check.call(sim.to_profile() == profile and sim.inventory.to_data() == inventory, "Advancing delayed impact, spell art and actor clocks cannot apply extra damage, charge mana or alter the saved profile")
	sim.cooldowns[0] = 0.0
	sim.player["mana"] = 100.0
	sim.mobs["wolf_0"]["hp"] = 20.0
	victim.flash = 0.0
	check.call(bool(sim.cast(0, "wolf_0", Vector2.ZERO)["ok"]), "The contact-death scenario starts with an accepted lethal cast")
	game.flush_events()
	profile = sim.to_profile().duplicate(true)
	victim._process(GuPixelEffectsArt.CONTACT_TIME - 0.03)
	check.call(bool(sim.mobs["wolf_0"]["dead"]) and not victim.presentation_dead and victim.visible, "An authoritative defeat commits immediately while the enemy remains visible until projectile contact")
	victim._process(0.04)
	check.call(victim.presentation_dead and victim.death_age > 0.0 and sim.to_profile() == profile, "Projectile contact starts the enemy's death animation without repeating rewards or changing authoritative state")
	game.world_view.set_reduced_motion(true)
	check.call(game.world_view.effects.reduced_motion and game.world_view.camera.offset == Vector2.ZERO, "Reduced motion preserves accepted effect state while suppressing camera shake")
	game.world_view.set_reduced_motion(false)
	check.call(game.hud.hp_bar is GuVitalBar and game.hud.target_bar is GuVitalBar, "Both player and selected-target HP use the same readable damage feedback component")
	var original_size := tree.root.size
	var original_scale := tree.root.content_scale_size
	game.hud.toggle_bag()
	await tree.create_timer(0.24).timeout
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		tree.root.content_scale_size = dimensions
		tree.root.size = dimensions
		await tree.process_frame
		await tree.process_frame
		var browser := game.hud.inventory_browser
		var controls: Array[Button] = browser.filter_buttons.duplicate()
		controls.append(browser.sort_button)
		var filters_fit := true
		for button in controls:
			filters_fit = filters_fit and button.size.x + 0.1 >= button.get_combined_minimum_size().x and browser.get_global_rect().encloses(button.get_global_rect())
		check.call(filters_fit, "Every inventory filter and sorting label fits its native button at %dx%d" % [dimensions.x, dimensions.y])
		var row: GuInventoryRow = browser.rows["gu_1"]
		check.call(row.visible and game.hud.bag.get_global_rect().encloses(row.feed_button.get_global_rect()), "The selected Gu's feeding action is visible above the inventory grid at %dx%d" % [dimensions.x, dimensions.y])
		var belt := game.hud.action_belt.get_global_rect()
		check.call(belt.size.x < dimensions.x * 0.5 and belt.encloses(game.hud.hotbar.get_global_rect()), "The skill dock consumes its own area while freeing the bottom playfield corners at %dx%d" % [dimensions.x, dimensions.y])
	tree.root.content_scale_size = original_scale
	tree.root.size = original_size
	game.queue_free()
	await tree.process_frame
