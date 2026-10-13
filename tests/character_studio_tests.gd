extends RefCounted
## Called by test_runner after its existing suites. Uses test mode and temporary fixtures.

static func run(tree: SceneTree, check: Callable) -> void:
	var initial := GuCharacterAppearance.default_data()
	check.call(GuCharacterAppearance.validate(initial), "Default character look is a complete valid descriptor")
	var legacy_look := {"body": "male", "outfit": "jade", "weapon": "sword", "hair": "topknot"}
	check.call(GuCharacterAppearance.validate(legacy_look) and GuCharacterAppearance.sanitize(legacy_look) == initial, "Legacy four-slot looks migrate to the new accessory defaults")
	initial["outfit"] = "crimson"
	check.call(GuCharacterAppearance.DEFAULT["outfit"] == "jade", "Changing a returned appearance cannot mutate catalog defaults")
	var variants_ok := true
	var combinations := 0
	for body in GuCharacterAppearance.catalog("body"):
		for outfit in GuCharacterAppearance.catalog("outfit"):
			for weapon in GuCharacterAppearance.catalog("weapon"):
				for hair in GuCharacterAppearance.catalog("hair"):
					variants_ok = variants_ok and GuCharacterAppearance.validate({"body": body["id"], "outfit": outfit["id"], "weapon": weapon["id"], "hair": hair["id"]})
					combinations += 1
	check.call(variants_ok and combinations == 36, "All 36 supported body, wardrobe, weapon and hair combinations validate")
	var expanded_count := 0
	var expanded_valid := true
	for body in GuCharacterAppearance.catalog("body"):
		for outfit in GuCharacterAppearance.catalog("outfit"):
			for weapon in GuCharacterAppearance.catalog("weapon"):
				for hair in GuCharacterAppearance.catalog("hair"):
					for boots in GuCharacterAppearance.catalog("boots"):
						for hat in GuCharacterAppearance.catalog("hat"):
							var look := {"body": body["id"], "outfit": outfit["id"], "weapon": weapon["id"], "hair": hair["id"], "boots": boots["id"], "hat": hat["id"]}
							expanded_valid = expanded_valid and GuCharacterAppearance.validate(look)
							expanded_count += 1
	check.call(expanded_valid and expanded_count == 216 and GuIllustratedCharacterArt.manifest()["cosmetic_combinations"] == expanded_count, "The modular character catalog composes 216 valid appearances")
	var accessory_parts := true
	for direction in range(8):
		for key in ["boot_%d" % direction, "boot_leather_%d" % direction, "hat_bamboo_%d" % direction, "hat_sect_%d" % direction]:
			accessory_parts = accessory_parts and GuIllustratedCharacterArt.part_texture(key) != null
	check.call(accessory_parts, "Both footwear styles and both hats have authored assets in all eight directions")
	var invalid := GuCharacterAppearance.default_data()
	invalid["weapon"] = "missing_item"
	check.call(not GuCharacterAppearance.validate(invalid) and not GuCharacterAppearance.validate([]), "Unknown cosmetic IDs and non-dictionary descriptors are rejected")
	invalid = GuCharacterAppearance.default_data()
	invalid.erase("hair")
	check.call(not GuCharacterAppearance.validate(invalid), "Incomplete appearance descriptors are rejected instead of partially applying")
	var sim := LocalAuthority.new()
	var inventory_before := sim.inventory.to_data()
	var authority_before := sim.player.duplicate(true)
	check.call(not sim.set_appearance(invalid)["ok"] and sim.player == authority_before, "Invalid appearance application is atomic")
	var selected := {"body": "female", "outfit": "ivory", "weapon": "spear", "hair": "ponytail", "boots": "leather", "hat": "bamboo"}
	check.call(sim.set_appearance(selected)["ok"] and sim.inventory.to_data() == inventory_before, "Applying cosmetics preserves equipped Gu and inventory")
	selected["body"] = "male"
	check.call(sim.player["appearance"]["body"] == "female", "Authority keeps an independent copy of the applied look")
	var profile := sim.to_profile()
	check.call(profile["appearance"].size() == 4 and profile["appearance_v2"] == {"boots": "leather", "hat": "bamboo"}, "New accessories serialize beside the original four-field profile for older builds")
	var restored := LocalAuthority.new()
	check.call(restored.load_profile(profile) and restored.player["appearance"] == sim.player["appearance"], "A saved character look survives a validated profile round trip")
	var partial_accessories := profile.duplicate(true)
	partial_accessories["appearance_v2"].erase("boots")
	check.call(restored.load_profile(partial_accessories) and restored.player["appearance"]["boots"] == "cloth" and restored.player["appearance"]["hat"] == "bamboo", "A missing v2 accessory receives its default while the other slot is preserved")
	profile.erase("appearance")
	check.call(restored.load_profile(profile) and restored.player["appearance"] == GuCharacterAppearance.default_data(), "Older schema 1 profiles receive the default appearance")
	profile["appearance"] = legacy_look
	profile.erase("appearance_v2")
	check.call(restored.load_profile(profile) and restored.player["appearance"] == GuCharacterAppearance.default_data(), "Saved four-slot appearances migrate without losing the existing look")
	profile["appearance"] = {"body": "male", "outfit": "missing_catalog_id", "weapon": "sword", "hair": "topknot"}
	profile["appearance_v2"] = {"boots": "unknown_boot", "hat": "sect"}
	check.call(restored.load_profile(profile) and restored.player["appearance"]["outfit"] == "jade" and restored.player["appearance"]["boots"] == "cloth" and restored.player["appearance"]["hat"] == "sect", "Unknown saved cosmetic IDs fall back only in their own slots")
	var snapshot := restored.to_profile()
	profile["appearance"] = "invalid"
	check.call(not restored.load_profile(profile) and restored.to_profile() == snapshot, "A saved appearance with the wrong data type rejects the whole load without changing live state")
	sim.player["cell"] = Vector2(12, 20)
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	var origin: Vector2 = sim.player["cell"]
	sim.set_move_direction(Vector2(1, -1), true)
	sim.step(0.1)
	check.call(is_equal_approx(origin.distance_to(sim.player["cell"]), LocalAuthority.PLAYER_RUN_SPEED * 0.1) and sim.player["running"], "Sprint uses an authoritative normalized 4.8-cell-per-second speed")
	sim.set_move_direction(Vector2.ZERO, true)
	check.call(not sim.player["running"], "Stopping movement clears sprint even if the modifier remains held")
	sim.set_move_direction(Vector2.RIGHT, true)
	sim.move_to(Vector2(13, 20))
	check.call(not sim.player["running"] and sim.movement_direction == Vector2.ZERO, "An accepted click path takes ownership from sprinting keyboard movement")
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	await tree.process_frame
	game.set_physics_process(false)
	var hud := game.hud
	var studio := hud.character_studio
	_hold_key(tree, KEY_SHIFT, true)
	_hold_key(tree, KEY_D, true)
	check.call(game.simulation.player["running"] and game.input_controller.sprint_held, "Shift plus real WASD input requests the run state")
	_key(tree, KEY_F6)
	await tree.process_frame
	check.call(hud.studio_open and hud.has_open_window() and studio.visible and game.input_controller.held_movement.is_empty() and not game.input_controller.sprint_held and game.simulation.movement_direction == Vector2.ZERO, "F6 opens the character studio and clears held movement and sprint")
	var mana_before := float(game.simulation.player["mana"])
	_key(tree, KEY_2)
	_hold_key(tree, KEY_W, true)
	_hold_key(tree, KEY_ALT, true)
	check.call(game.simulation.player["mana"] == mana_before and game.simulation.movement_direction == Vector2.ZERO and not game.preview_held, "The character modal gates skills, movement and dash preview")
	var scene_inventory := game.simulation.inventory.to_data()
	var hp_before := float(game.simulation.player["hp"])
	studio.appearance = {"body": "female", "outfit": "crimson", "weapon": "spear", "hair": "ponytail", "boots": "leather", "hat": "sect"}
	studio._sync_controls()
	check.call(studio.selectors.size() == 6 and studio.appearance["hat"] == "sect" and studio.appearance["boots"] == "leather", "The F6 workshop exposes hat and footwear slots and preserves the selected variants")
	_click(tree, studio.apply_button.get_global_rect().get_center())
	await tree.process_frame
	check.call(game.simulation.player["appearance"] == studio.appearance and game.simulation.inventory.to_data() == scene_inventory and game.simulation.player["hp"] == hp_before, "Applying from the workshop updates appearance without changing gameplay stats or equipment")
	check.call(hud.portrait_doll.appearance_signature == str(game.simulation.player["appearance"]) and hud.character_doll.appearance_signature == str(game.simulation.player["appearance"]), "Both HUD and character-sheet portraits reflect the applied appearance")
	var face_before: Vector2 = game.simulation.player["facing"]
	studio._select_direction(7)
	studio._select_action(3)
	check.call(studio.direction_index == 7 and studio.action == "attack" and game.simulation.player["facing"] == face_before, "Preview direction and attack choice never rotate the authoritative character")
	studio.yaw_slider.value = 123.0
	check.call(studio.direction_index == 3 and studio.direction_vector().is_equal_approx(Vector2.UP.rotated(deg_to_rad(135.0))) and game.simulation.player["facing"] == face_before, "The rotation slider snaps to one of eight authored directions without changing authority facing")
	studio._select_direction(2)
	check.call(studio.facing_angle == 90.0 and studio.yaw_slider.value == 90.0 and studio.direction_vector().is_equal_approx(Vector2.RIGHT), "Compass buttons synchronize the eight-direction rotation slider")
	check.call(studio.character_view is GuPixelCharacterView and not _contains_3d_or_viewport(studio.character_view), "The workshop uses a sprite renderer with no 3D scene or SubViewport")
	var authored_directions := {}
	for direction in range(8):
		studio._select_direction(direction)
		studio._present()
		authored_directions[studio.character_view.current_direction] = true
	check.call(authored_directions.size() == 8, "Every compass button selects a distinct authored sprite direction")
	studio._toggle_play()
	var time_before := studio.playhead
	studio._process(0.2)
	check.call(not studio.playing and studio.playhead == time_before and not studio.character_view.active, "Pausing the workshop freezes its local playhead and continuous render updates")
	studio._toggle_play()
	studio.playback_rate = 2.0
	time_before = studio.playhead
	studio._process(0.2)
	check.call(is_equal_approx(studio.playhead - time_before, 0.4), "Workshop playback rate scales only the presentation clock")
	var previous_size := tree.root.size
	var previous_content_scale := tree.root.content_scale_size
	var sizes_fit := true
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		tree.root.content_scale_size = dimensions
		tree.root.size = dimensions
		await tree.process_frame
		await tree.process_frame
		var room := hud.root.get_global_rect()
		sizes_fit = sizes_fit and room.encloses(studio.get_global_rect()) and studio.get_global_rect().encloses(studio.apply_button.get_global_rect()) and studio.stage.size.y >= 250
		print("STUDIO_LAYOUT ", dimensions, " room=", room, " modal=", studio.get_global_rect(), " stage=", studio.stage.size)
	check.call(sizes_fit, "The character workshop fits 960x640, 1280x800 and 1920x1080 viewports")
	tree.root.content_scale_size = previous_content_scale
	tree.root.size = previous_size
	await tree.process_frame
	_key(tree, KEY_ESCAPE)
	await tree.process_frame
	check.call(not hud.studio_open and not hud.has_open_window() and not studio.character_view.active and game.simulation.movement_direction == Vector2.ZERO, "Escape closes the workshop, suspends rendering and does not resume old movement")
	_hold_key(tree, KEY_ALT, false)
	_hold_key(tree, KEY_W, false)
	_hold_key(tree, KEY_SHIFT, false)
	_hold_key(tree, KEY_D, false)
	_hold_key(tree, KEY_ALT, true)
	check.call(game.preview_held and not game.simulation.player["running"], "Alt previews the dash without setting sprint")
	_hold_key(tree, KEY_ALT, false)
	_key(tree, KEY_F6)
	_key(tree, KEY_TAB)
	check.call(not hud.studio_open and hud.bag_open and not studio.character_view.active, "Opening the bag replaces the studio and suspends its renderer")
	_key(tree, KEY_ESCAPE)
	game.queue_free()
	await tree.process_frame
	await tree.create_timer(0.08).timeout

static func _contains_3d_or_viewport(node: Node) -> bool:
	if node is Node3D or node is SubViewport:
		return true
	for child in node.get_children():
		if _contains_3d_or_viewport(child):
			return true
	return false

static func _key(tree: SceneTree, code: int) -> void:
	_hold_key(tree, code, true)
	_hold_key(tree, code, false)

static func _hold_key(tree: SceneTree, code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	tree.root.push_input(event, true)

static func _click(tree: SceneTree, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	tree.root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	tree.root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	tree.root.push_input(event, true)
