extends SceneTree
## Scenario tests for local gameplay invariants and real scene/input wiring.
## Uses --test-mode and a separate save path; never touches the player's profile.

var results: Array[Dictionary] = []
var failures: int = 0
var scene_completed: bool = false
var presentation_completed: bool = false
var targeting_completed: bool = false
var classic_ui_completed: bool = false
var rpg_windows_completed: bool = false
var character_completed: bool = false
var keyboard_completed: bool = false
var pixel_completed: bool = false
var polish_completed: bool = false
var vector_completed: bool = false
var smooth_completed: bool = false

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		printerr("Tests require -- --test-mode to isolate the player's save.")
		quit(2)
		return
	# The dummy headless display starts at 64x64 when stretch is disabled.
	# Exercise the same native viewport as the PC build before constructing HUD.
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	results.append({"name": label, "passed": condition})
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func fixture(seed_value: int = 74021) -> LocalAuthority:
	var sim := LocalAuthority.new(seed_value)
	sim.player["cell"] = Vector2(15, 20)
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	var target: Dictionary = sim.mobs["wolf_0"]
	target.merge({"dead": false, "cell": Vector2(18, 20), "spawn": Vector2(18, 20), "hp": 140.0}, true)
	return sim

func advance(sim: LocalAuthority, seconds: float) -> void:
	for i in range(ceili(seconds / 0.05)):
		sim.step(0.05)

func _run() -> void:
	# Window initialization may restore the dummy display's 64x64 extent after
	# _initialize. Establish the native fixture once the SceneTree is running.
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1280, 800)
	await process_frame
	print("TEST_VIEWPORT ", OS.get_name(), " ", root.get_visible_rect(), " window=", root.size)
	check(root.get_visible_rect().size == Vector2(1280, 800), "The test fixture starts at the actual native 1280x800 PC viewport")
	preload("res://tests/character_animation_tests.gd").run(check,root)
	preload("res://tests/weapon_animation_tests.gd").run(check,root)
	# The live game now uses authored 2D frames. Archived mesh/export suites
	# exercise the previous authoring backend and are not runtime acceptance.
	pixel_completed = await preload("res://tests/pixel_art_tests.gd").run(self,check)
	_test_character_rig()
	_test_navigation()
	_test_manual_movement()
	_test_combat()
	_test_cast_preview()
	_test_capture()
	_test_inventory()
	_test_save()
	await _test_scene()
	await _test_presentation()
	await _test_targeting()
	await _test_classic_ui()
	await _test_rpg_windows()
	await _test_keyboard_controls()
	await preload("res://tests/character_studio_tests.gd").run(self,check)
	polish_completed = await preload("res://tests/polish_feature_tests.gd").run(self,check)
	vector_completed = await preload("res://tests/vector_presentation_tests.gd").run(self,check)
	smooth_completed = await preload("res://tests/smooth_motion_tests.gd").run(self,check)
	preload("res://tests/ink_style_tests.gd").run(check)
	await preload("res://tests/concept_character_tests.gd").run(self,check)
	await preload("res://tests/concept_frame_review_tests.gd").run(self,check)
	await preload("res://tests/concept_combat_tests.gd").run(self,check)
	await preload("res://tests/concept_articulation_tests.gd").run(self,check)
	await preload("res://tests/concept_modular_parts_tests.gd").run(self,check)
	await preload("res://tests/concept_directional_parts_tests.gd").run(self,check)
	await preload("res://tests/character_action_motion_tests.gd").run(self,check)
	await preload("res://tests/character_transition_tests.gd").run(self,check)
	await preload("res://tests/character_joint_skin_tests.gd").run(self,check)
	check(pixel_completed and polish_completed and vector_completed and smooth_completed and scene_completed and presentation_completed and targeting_completed and classic_ui_completed and rpg_windows_completed and character_completed and keyboard_completed, "Legacy assets, illustrated smooth motion, polish, scene, targeting, character, keyboard and classic UI suites complete without aborting")
	# Last fixture has stopped/freed its voices. Give the asynchronous audio
	# mixer time to retire WAV playbacks before the headless process exits.
	await create_timer(.12).timeout
	var report := {"engine": Engine.get_version_info()["string"], "platform": OS.get_name(), "total": results.size(), "passed": results.size() - failures, "failed": failures, "results": results}
	var file := FileAccess.open("res://artifacts/test_results_%s.json" % OS.get_name().to_lower(), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("TEST_RESULTS ", results.size() - failures, "/", results.size(), " passed; ", failures, " failed")
	quit(1 if failures > 0 else 0)

func _test_character_rig() -> void:
	var joints := ["belt", "chest", "neck", "head", "hip_l", "hip_r", "knee_l", "knee_r", "foot_l", "foot_r", "shoulder_l", "shoulder_r", "elbow_l", "elbow_r", "hand_l", "hand_r"]
	var finite_and_bounded := true
	var limbs_connected := true
	for i in range(8):
		for action in ["", "cast_moon", "shield", "dash", "cast_frost"]:
			for frame in range(25):
				var pose := GuHumanoidRig.sample(Vector2.UP.rotated(i * TAU / 8), frame * 0.26, 1, frame / 24.0, action, frame / 24.0)
				for joint in joints:
					var point: Vector2 = pose[joint]
					finite_and_bounded = finite_and_bounded and point.is_finite() and absf(point.x) < 60 and point.y >= -90 and point.y <= 12
				for side in ["l", "r"]:
					var forearm := Vector2(pose["elbow_" + side]).distance_to(pose["hand_" + side])
					limbs_connected = limbs_connected and forearm > 0.5 and forearm < 27
	check(finite_and_bounded, "All eight directions and full cast/walk timelines keep the rig finite and inside its visual envelope")
	check(limbs_connected, "Animated forearms retain nonzero bounded length across direction and action transitions")
	var forward := GuHumanoidRig.sample(Vector2.DOWN, 0, 0, 0)
	var backward := GuHumanoidRig.sample(Vector2.UP, 0, 0, 0)
	var profile := GuHumanoidRig.sample(Vector2.RIGHT, 0, 0, 0)
	check(not forward["back"] and backward["back"] and profile["profile"] and not forward["profile"], "Front, rear and side use the correct face/hair and arm layers")
	var mirrored := GuHumanoidRig.sample(Vector2.LEFT, 0, 0, 0)
	check(is_equal_approx(profile["hand_r"].x, -mirrored["hand_r"].x) and is_equal_approx(profile["hand_r"].y, mirrored["hand_r"].y), "Mirroring preserves hand height and flips casting side")
	var first := GuHumanoidRig.sample(Vector2.RIGHT, PI * 0.5, 1, 0)
	var opposite := GuHumanoidRig.sample(Vector2.RIGHT, PI * 1.5, 1, 0)
	check(first["foot_l"].y < first["foot_r"].y and opposite["foot_r"].y < opposite["foot_l"].y, "Walking alternates planted and lifted feet every half cycle")
	var planted := GuHumanoidRig.sample(Vector2.RIGHT, TAU * 0.1, 1, 0)
	var after_step := GuHumanoidRig.sample(Vector2.RIGHT, TAU * 0.35, 1, 0)
	var body_travel := Vector2(GuHumanoidRig.STRIDE_DISTANCE * 0.25, 0)
	check(Vector2(after_step["foot_r"]).is_equal_approx(Vector2(planted["foot_r"]) - body_travel), "A planted foot cancels body travel exactly during the stance phase instead of skating")
	var idle := GuHumanoidRig.sample(Vector2.DOWN, 2, 0, 2)
	check(idle["foot_l"].is_equal_approx(forward["foot_l"]) and idle["foot_r"].is_equal_approx(forward["foot_r"]), "Idle breathing leaves both feet at their ground anchors")
	var still := GuHumanoidRig.sample(Vector2.RIGHT, 0, 1, 0, "shield", 0.3, true, 0.12, true)
	var later := GuHumanoidRig.sample(Vector2.RIGHT, 4, 1, 5, "shield", 0.3, true, 0.12, true)
	check(still == later, "Reduced motion suppresses gait, breath, ribbon, channel hover and recoil while preserving the active pose")
	var moon := GuHumanoidRig.sample(Vector2.RIGHT, 0, 0, 0, "cast_moon", 0.35)
	var shield := GuHumanoidRig.sample(Vector2.RIGHT, 0, 0, 0, "shield", 0.35)
	var frost := GuHumanoidRig.sample(Vector2.RIGHT, 0, 0, 0, "cast_frost", 0.35)
	check(moon["hand_r"].x > profile["hand_r"].x + 10 and shield["hand_r"].y < profile["hand_r"].y - 15 and frost["hand_l"].x < profile["hand_l"].x - 10, "Moon projects forward, shield raises the hands and frost opens both arms")
	var recovered := GuHumanoidRig.sample(Vector2.RIGHT, 0, 0, 0, "cast_moon", 1.0)
	check(recovered["hand_r"].is_equal_approx(profile["hand_r"]) and recovered["chest"].is_equal_approx(profile["chest"]), "Cast recovery returns to the idle pose at the event timer endpoint")
	var zero := GuHumanoidRig.sample(Vector2.ZERO, 0, 0, 0)
	check(zero["head"].is_finite() and zero["direction"] == Vector2.DOWN, "Zero-length facing safely falls back to a readable front pose")
	var actor := ActorView.new()
	var state := {"cell": Vector2(15, 20), "facing": Vector2.RIGHT, "dead": false}
	actor.bind(state, true)
	var original := state.duplicate(true)
	actor.channeling = true
	actor.channel_facing = Vector2.LEFT
	check(actor.current_pose()["direction"] == Vector2.LEFT and state == original, "Capture can visually face its target without writing authoritative facing")
	actor.channeling = false
	actor.receive({"kind": "cast_moon", "at": state["cell"], "to": Vector2(13, 22)})
	check(actor.current_pose()["direction"].is_equal_approx(WorldGrid.project(Vector2(13, 22) - state["cell"]).normalized()) and state == original, "Casting keeps its accepted visual direction while movement can change authoritative facing")
	actor._process(actor.action_duration)
	check(actor.current_pose()["direction"].is_equal_approx(WorldGrid.project(state["facing"]).normalized()), "Cast recovery returns to the current walking direction")
	var effects := WorldEffects.new()
	var event := {"kind": "cast_moon", "at": Vector2(15, 20), "to": Vector2(13, 22)}
	var event_before := event.duplicate(true)
	effects.receive(event)
	check(effects.effects[0]["origin_offset"].x < 0 and event == event_before, "Leftward spell VFX originates on the casting side without modifying its source event")
	effects.free()
	actor.receive({"kind": "cast_frost"})
	actor._process(actor.action_duration)
	check(actor.action_left == 0 and state == original, "Finishing a cast animation never changes authority state")
	actor.receive({"kind": "cast_moon"})
	actor.channeling = true
	state["dead"] = true
	actor._process(0.05)
	check(actor.action_left == 0 and not actor.channeling and actor.death_age > 0, "Death interrupts casting and channel presentation before drawing the fallen body")
	state["dead"] = false
	state["cell"] = WorldGrid.SPAWN
	actor._process(0.02)
	check(actor.position.is_equal_approx(WorldGrid.project(WorldGrid.SPAWN)) and actor.spawn_left > 0 and actor.flash == 0, "Respawn places a clean standing rig at the authoritative spawn point")
	actor.free()
	character_completed = true

func _test_classic_ui() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	var hud := game.hud
	var expanded_height := hud.quest_panel.size.y
	var progress_text := hud.quest_text.text
	click(hud.quest_toggle.get_global_rect().get_center())
	await process_frame
	await process_frame
	check(hud.quest_collapsed and not hud.quest_content.visible and hud.quest_panel.size.y < expanded_height, "Quest collapse frees playfield space through real mouse input")
	check(game.simulation.player["path"].is_empty() and hud.quest_text.text == progress_text, "Collapsing a quest neither moves the player nor discards progress")
	click(hud.quest_toggle.get_global_rect().get_center())
	await process_frame
	await process_frame
	check(not hud.quest_collapsed and hud.quest_content.visible and hud.quest_panel.size.y >= expanded_height, "Quest expand restores its visible objectives")
	click(hud.settings_button.get_global_rect().get_center())
	await process_frame
	check(game.paused and hud.pause_panel.visible and game.simulation.player["path"].is_empty(), "Settings button opens a paused menu without issuing a movement command")
	key(KEY_ESCAPE)
	await process_frame
	click(hud.bag_button.get_global_rect().get_center())
	await create_timer(0.24).timeout
	check(hud.bag_open and hud.bag_rows.size() == 4, "Inventory menu button opens the equipped Gu and material sockets")
	var meat_before := int(game.simulation.inventory.materials["meat"])
	click(hud.bag_rows["gu_1"].feed_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	check(int(_displayed_materials(hud.inventory_browser)["meat"]) == meat_before - 1, "Material socket count updates after an actual feed transaction")
	game.simulation.inventory.reward_material("seal", 2)
	await process_frame
	await process_frame
	check(_displayed_materials(hud.inventory_browser) == game.simulation.inventory.materials, "Open inventory material sockets track new loot without reopening")
	game.world_view.select_target("wolf_0")
	hud.update_hud(0.0)
	var original_window_size := root.size
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = dimensions
		await process_frame
		await process_frame
		var bounds := hud.root.get_global_rect()
		var inside := bounds.encloses(hud.bag.get_global_rect()) and bounds.encloses(hud.status_panel.get_global_rect()) and bounds.encloses(hud.settings_button.get_global_rect())
		for skill in hud.skill_buttons:
			inside = inside and bounds.encloses(skill.get_global_rect())
		check(inside, "Inventory, vitals and action controls remain on screen at %dx%d" % [dimensions.x, dimensions.y])
		var skills_clear := true
		for skill in hud.skill_buttons:
			for shortcut in [hud.bag_button, hud.settings_button, hud.character_button, hud.journal_button]:
				skills_clear = skills_clear and not skill.get_global_rect().intersects(shortcut.get_global_rect())
		check(skills_clear, "All skill buttons remain clear of menu shortcuts at %dx%d" % [dimensions.x, dimensions.y])
		check(not hud.status_panel.get_global_rect().intersects(hud.target_panel.get_global_rect()), "Player and selected-target vitals remain separate at %dx%d" % [dimensions.x, dimensions.y])
		var bag_clear := true
		for shortcut in [hud.bag_button, hud.settings_button, hud.character_button, hud.journal_button]:
			bag_clear = bag_clear and not hud.bag.get_global_rect().intersects(shortcut.get_global_rect())
		check(bag_clear, "Menu shortcuts cannot cover inventory contents at %dx%d" % [dimensions.x, dimensions.y])
	root.size = original_window_size
	await process_frame
	await process_frame
	hud.toggle_bag()
	await create_timer(0.24).timeout
	click(hud.action_belt.get_global_rect().get_center() + Vector2(0, 48))
	await process_frame
	check(game.simulation.player["path"].is_empty(), "Empty action-belt space consumes clicks instead of sending world movement")
	var world_center := hud.root.get_global_rect().get_center()
	check(not hud.status_panel.get_global_rect().has_point(world_center) and not hud.quest_panel.get_global_rect().has_point(world_center) and not hud.action_belt.get_global_rect().has_point(world_center), "Peripheral HUD leaves the center of the playfield unobscured")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	classic_ui_completed = true

func _displayed_materials(browser: GuInventoryBrowser) -> Dictionary:
	var quantities := {}
	for slot in browser.slots:
		var entry := slot.entry
		if entry.get("type", "") == "material":
			var kind := str(entry["material"])
			quantities[kind] = int(quantities.get(kind, 0)) + int(entry["quantity"])
	return quantities

func _test_rpg_windows() -> void:
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	var hud := game.hud
	key(KEY_F3)
	await process_frame
	check(hud.character_open and hud.character_panel.visible, "F3 opens the live character sheet")
	check(not game.world_view.targeting.visible and not hud.skill_detail.visible, "Character sheet suppresses world aiming overlays")
	game.simulation.player["hp"] = 123.0
	game.simulation.player["currency"] = 275
	await process_frame
	check(hud.character_values["Sinh lực"].text == "123 / 200" and hud.character_values["Ngân lượng"].text == "275", "Character attributes reflect current authority values")
	var mana := float(game.simulation.player["mana"])
	key(KEY_2)
	game.use_skill(1)
	await process_frame
	check(float(game.simulation.player["mana"]) == mana and game.simulation.cooldowns[1] == 0, "Character sheet blocks both keyboard and hotbar casts")
	key(KEY_F4)
	await create_timer(0.24).timeout
	check(hud.character_open and hud.bag_open and not hud.character_panel.get_global_rect().intersects(hud.bag.get_global_rect()), "F3 and F4 windows coexist on opposite sides without overlap")
	var browser := hud.inventory_browser
	check(browser.slots.size() == 30 and browser.entries.size() == game.simulation.inventory.occupied_slots(), "Thirty-slot inventory shows exactly the occupied Gu and material stacks")
	click(hud.character_doll.slots[2].get_global_rect().get_center())
	await process_frame
	check(browser.selected_key == "gu:gu_3" and hud.bag_rows["gu_3"].visible and not hud.bag_rows["gu_1"].visible, "Clicking an equipped Gu selects its own inventory details")
	check(float(game.simulation.player["mana"]) == mana, "Inspecting a character Gu never casts it")
	click(browser.filter_buttons[2].get_global_rect().get_center())
	await process_frame
	var materials_only := true
	for slot in browser.slots:
		materials_only = materials_only and (slot.entry.is_empty() or slot.entry.get("type") == "material")
	check(materials_only and browser.material_detail.visible and not browser.details.visible, "Material filter shows stacks and hides Gu feeding controls")
	game.simulation.inventory.reward_material("meat", 120)
	await process_frame
	await process_frame
	var meat_stacks: Array[int] = []
	for slot in browser.slots:
		if slot.entry.get("material", "") == "meat":
			meat_stacks.append(int(slot.entry["quantity"]))
	meat_stacks.sort()
	check(meat_stacks == [24, 99], "Inventory splits 123 materials into visible stacks of 99 and 24")
	var selected_before := browser.selected_key
	var inventory_before := game.simulation.inventory.materials.duplicate()
	click(browser.sort_button.get_global_rect().get_center())
	await process_frame
	check(browser.selected_key == selected_before and game.simulation.inventory.materials == inventory_before, "Sorting retains selection and never changes inventory quantities")
	var captured := game.simulation.inventory.add_gu("GU-01")
	await process_frame
	await process_frame
	browser.select_gu(str(captured["instance_id"]))
	check(hud.bag_rows[str(captured["instance_id"])].visible and hud.bag_rows[str(captured["instance_id"])].feed_button.disabled, "Newly captured Gu appears in the grid with its full-hunger disabled state")
	key(KEY_ESCAPE)
	await create_timer(0.24).timeout
	check(not hud.bag_open and hud.character_open and not game.paused, "Escape closes the latest side window and preserves the other one")
	key(KEY_ESCAPE)
	await process_frame
	check(not hud.has_open_window() and not game.paused, "Second Escape closes the remaining window before opening pause")
	key(KEY_F11)
	await process_frame
	check(hud.journal_open and hud.journal_panel.visible, "F11 opens the quest journal")
	check(not game.world_view.targeting.visible and not hud.skill_detail.visible, "Journal suppresses world aiming overlays")
	game.simulation.progress["kills"] = 2
	await process_frame
	check(hud.journal_objectives[0].text.contains("2 / 3") and hud.journal_bars[0].value == 2, "Journal objectives update from actual quest progress")
	click(hud.journal_track.get_global_rect().get_center())
	await process_frame
	check(not hud.quest_panel.visible and not hud.quest_tracked, "Quest tracking can be hidden from the journal")
	click(hud.journal_track.get_global_rect().get_center())
	await process_frame
	check(hud.quest_panel.visible and hud.quest_tracked, "Quest tracking can be restored without losing progress")
	game.simulation.progress.merge({"kills": 3, "captures": 1, "feeds": 1, "claimed": true}, true)
	await process_frame
	check(hud.journal_reward.text.contains("Đã nhận") and hud.journal_bars[2].value == 1, "Completed quest shows the already-claimed reward rather than a duplicate claim action")
	key(KEY_F3)
	await process_frame
	check(hud.character_open and not hud.journal_open, "Opening a side window closes the central journal")
	click(hud.bag_button.get_global_rect().get_center())
	await create_timer(0.24).timeout
	check(hud.bag_open and hud.character_open, "Bottom inventory shortcut remains clickable above the window backdrop")
	key(KEY_F11)
	await create_timer(0.24).timeout
	check(hud.journal_open and not hud.bag.visible and not hud.character_panel.visible, "Journal replaces both side windows without a lingering panel")
	for dimensions in [Vector2i(960, 640), Vector2i(1920, 1080)]:
		var original := root.size
		root.size = dimensions
		await process_frame
		await process_frame
		check(hud.root.get_global_rect().encloses(hud.journal_panel.get_global_rect()), "Quest journal stays on screen at %dx%d" % [dimensions.x, dimensions.y])
		root.size = original
		await process_frame
	key(KEY_ESCAPE)
	await process_frame
	key(KEY_ESCAPE)
	await process_frame
	check(game.paused and hud.bag_button.disabled and hud.character_button.disabled, "Pause disables window shortcuts and leaves no gameplay windows active")
	key(KEY_ESCAPE)
	await process_frame
	check(not game.paused and not hud.bag_button.disabled, "Resume restores the UI shortcuts")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	rpg_windows_completed = true

func _test_navigation() -> void:
	var world := WorldGrid.new()
	var point := Vector2(12.75, 17.25)
	check(WorldGrid.unproject(WorldGrid.project(point)).is_equal_approx(point), "Square pixel projection round trip")
	check(not world.is_walkable(Vector2(9, 18)) and not world.is_walkable(Vector2(-1, 8)), "Rock and map boundary block navigation")
	var path := world.path(Vector2(8, 18), Vector2(10, 18))
	var previous := Vector2(8, 18)
	var valid: bool = not path.is_empty() and path.back() == Vector2(10, 18)
	for cell in path:
		valid = valid and world.is_walkable(cell) and world.clear_segment(previous, cell)
		previous = cell
	check(valid, "AStar route goes around rock without cutting corners")
	check(world.sweep(Vector2(8, 18), Vector2(11, 18)).x < 8.51, "Swept dash stops before obstacle")
	var sim := fixture()
	check(bool(sim.move_to(Vector2(14, 18))["ok"]), "Movement accepts reachable target")
	advance(sim, 4.0)
	check(Vector2(sim.player["cell"]).distance_to(Vector2(14, 18)) < 0.05, "Continuous movement reaches route destination")
	check(not bool(sim.move_to(Vector2(NAN, 10))["ok"]), "Nonfinite movement is rejected")

func _test_manual_movement() -> void:
	var sim := fixture()
	for mob in sim.mobs.values():
		mob["dead"] = true
	var origin: Vector2 = sim.player["cell"]
	sim.set_move_direction(Vector2(10, 0))
	sim.step(0.1)
	check(is_equal_approx(Vector2(sim.player["cell"]).distance_to(origin), 0.3), "Held movement clamps oversized direction to the configured player speed")
	sim.player["cell"] = origin
	sim.set_move_direction(Vector2(1, 1))
	sim.step(0.1)
	check(is_equal_approx(Vector2(sim.player["cell"]).distance_to(origin), 0.3), "Diagonal keyboard travel uses the same world speed as cardinal travel")
	sim.set_move_direction(Vector2.ZERO)
	var stopped: Vector2 = sim.player["cell"]
	sim.step(0.2)
	check(sim.player["cell"] == stopped, "Releasing the final movement key stops authoritative displacement")
	sim.set_move_direction(Vector2.RIGHT)
	var direction := sim.movement_direction
	check(sim.set_move_direction(Vector2(NAN, 0)).get("error") == "BAD_PATH" and sim.movement_direction == direction and sim.player["cell"] == stopped, "Invalid held-movement input cannot corrupt direction or position")
	sim.player["cell"] = Vector2(8, 18)
	sim.set_move_direction(Vector2.RIGHT)
	for i in range(10):
		sim.step(0.5)
	check(Vector2(sim.player["cell"]).x < 8.501 and sim.world.is_walkable(sim.player["cell"]), "Repeated keyboard motion into a rock stays on its walkable side")
	sim.player["cell"] = Vector2(8.48, 17.6)
	sim.set_move_direction(Vector2(1, 1))
	var slide_start: Vector2 = sim.player["cell"]
	sim.step(0.2)
	check(Vector2(sim.player["cell"]).x < 8.501 and Vector2(sim.player["cell"]).y > 17.8 and slide_start.distance_to(sim.player["cell"]) <= 0.6001, "Blocked diagonal motion slides along the clear wall axis without exceeding its movement budget")
	check(not sim.events.any(func(event: Dictionary): return event["kind"] == "move"), "Held motion does not flood the event queue with click markers")
	sim.player["cell"] = origin
	sim.move_to(Vector2(14, 20))
	var route: Array = sim.player["path"].duplicate()
	sim.set_move_direction(Vector2.ZERO)
	check(sim.movement_direction == Vector2.ZERO and not route.is_empty() and sim.player["path"] == route, "A successful ground click owns its route and zero keyboard intent preserves it")
	sim.set_move_direction(Vector2.UP)
	check(sim.player["path"].is_empty(), "A fresh keyboard direction takes over from the click route")
	sim.set_move_direction(Vector2.ZERO)
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(18, 20), "hp": 32.0, "owned": true}, true)
	sim.begin_capture("wolf_0")
	var seals: int = sim.inventory.materials["seal"]
	sim.drain_events()
	sim.set_move_direction(Vector2.RIGHT)
	sim.set_move_direction(Vector2.RIGHT)
	check(sim.capture.is_empty() and sim.inventory.materials["seal"] == seals and sim.events.size() == 1, "Held movement cancels capture once and never refunds or recharges the consumed seal")
	sim._damage_player(1000)
	check(sim.movement_direction == Vector2.ZERO and bool(sim.player["dead"]), "Death clears the authoritative held movement intent")
	check(sim.set_move_direction(Vector2.RIGHT).get("error") == "DEAD" and sim.movement_direction == Vector2.ZERO, "Dead actors reject keyboard movement")
	advance(sim, 5.1)
	check(sim.movement_direction == Vector2.ZERO and sim.player["cell"] == WorldGrid.SPAWN, "Respawn cannot restore a stale keyboard direction")
	sim.set_move_direction(Vector2.RIGHT)
	check(sim.load_profile(sim.to_profile()) and sim.movement_direction == Vector2.ZERO, "Loading a profile restores position without restoring held keys")

func _test_keyboard_controls() -> void:
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	for mob in game.simulation.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	var sim := game.simulation
	var origin := Vector2(15, 20)
	var controller := game.input_controller
	var directions_ok := true
	for code in [KEY_W, KEY_A, KEY_S, KEY_D]:
		controller.clear_movement()
		sim.player["cell"] = origin
		game.accumulator = 0
		hold_key(code, true)
		game._physics_process(0.1)
		var displacement := WorldGrid.project(Vector2(sim.player["cell"]) - origin).normalized()
		directions_ok = directions_ok and displacement.is_equal_approx(GameBindings.MOVE_KEYS[code])
		hold_key(code, false)
	check(directions_ok, "Live WASD input moves up, left, down and right in screen space on the square pixel map")
	check(sim.player["shield"] == 0 and sim.cooldowns[1] == 0 and sim.player["mana"] == 100.0, "W is movement only and never spends mana on the former shield binding")
	sim.player["cell"] = origin
	game.accumulator = 0
	hold_key(KEY_W, true)
	hold_key(KEY_D, true)
	game._physics_process(0.1)
	check(is_equal_approx(Vector2(sim.player["cell"]).distance_to(origin), 0.3) and WorldGrid.project(Vector2(sim.player["cell"]) - origin).x > 0 and WorldGrid.project(Vector2(sim.player["cell"]) - origin).y < 0, "W+D moves diagonally through the scene at the normalized world speed")
	hold_key(KEY_W, false)
	hold_key(KEY_D, false)
	var stopped: Vector2 = sim.player["cell"]
	game._physics_process(0.1)
	check(sim.player["cell"] == stopped and controller.held_movement.is_empty(), "Real key releases stop movement with no residual route")
	hold_key(KEY_W, true)
	hold_key(KEY_S, true)
	game._physics_process(0.1)
	check(sim.player["cell"] == stopped and sim.movement_direction == Vector2.ZERO, "Opposite movement keys cancel instead of choosing an arbitrary direction")
	hold_key(KEY_W, false)
	game._physics_process(0.1)
	check(WorldGrid.project(Vector2(sim.player["cell"]) - stopped).y > 0, "Releasing one opposite key immediately restores the remaining direction")
	hold_key(KEY_S, false)
	var mana := float(sim.player["mana"])
	for code in [KEY_Q, KEY_E, KEY_R, KEY_5, KEY_7, KEY_0, KEY_KP_0]:
		key(code)
	check(float(sim.player["mana"]) == mana and sim.cooldowns.all(func(value: float): return value == 0), "Former letter skills and empty number slots never cast or charge resources")
	key(KEY_2)
	check(sim.player["shield"] > 0 and is_equal_approx(float(sim.player["mana"]), mana - 12), "Number 2 casts the shield through real keyboard input")
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_2
	echo.pressed = true
	echo.echo = true
	root.push_input(echo, true)
	check(is_equal_approx(float(sim.player["mana"]), mana - 12), "OS key repeat does not recast a held skill number")
	sim.cooldowns[1] = 0
	sim.player["mana"] = 100.0
	key(KEY_KP_2)
	check(sim.player["mana"] == 88.0 and sim.cooldowns[1] > 0, "Number-pad keys use the same skill slots as the top-row numbers")
	var labels: Array[String] = []
	for button in game.hud.skill_buttons:
		labels.append(button.hotkey)
	check(labels == ["1", "2", "3", "4"], "All four hotbar buttons display the active numeric bindings")
	controller.clear_movement()
	sim.player["cell"] = origin
	sim.cooldowns[1] = 0
	sim.player["mana"] = 100.0
	hold_key(KEY_D, true)
	key(KEY_2)
	game.accumulator = 0
	game._physics_process(0.1)
	check(Vector2(sim.player["cell"]).distance_to(origin) > 0.25 and sim.player["shield"] > 0, "Holding WASD while pressing a skill number preserves both movement and the accepted skill")
	controller.clear_movement()
	hold_key(KEY_D, true)
	sim.player["cell"] = origin
	game.world_view.player_view.position = WorldGrid.project(origin)
	# Move the camera owner as well as its node before queuing window input.
	# Otherwise its next process tick restores the previous follow position.
	game.world_view._camera_follow = game.world_view.player_view.position + Vector2(0, -24)
	game.world_view.camera.position = game.world_view._camera_follow
	game.world_view.camera.force_update_scroll()
	await process_frame
	click(game.world_view.cell_to_screen(Vector2(15, 22)))
	await process_frame
	check(sim.movement_direction == Vector2.ZERO and controller.held_movement.is_empty() and not sim.player["path"].is_empty(), "A ground click takes over from held keyboard movement")
	hold_key(KEY_D, false)
	check(not sim.player["path"].is_empty(), "Releasing the old keyboard key does not discard a new click route")
	hold_key(KEY_A, true)
	check(sim.player["path"].is_empty() and sim.movement_direction != Vector2.ZERO, "A fresh WASD press takes over from mouse pathfinding")
	controller.clear_movement()
	for window in ["bag", "character", "journal"]:
		hold_key(KEY_D, true)
		match window:
			"bag": game.hud.toggle_bag()
			"character": game.hud.toggle_character()
			"journal": game.hud.toggle_journal()
		check(controller.held_movement.is_empty() and sim.movement_direction == Vector2.ZERO, "Opening %s immediately stops and disarms held movement" % window)
		hold_key(KEY_W, true)
		var before: Vector2 = sim.player["cell"]
		game._physics_process(0.1)
		key(KEY_ESCAPE)
		game._physics_process(0.1)
		check(sim.player["cell"] == before and controller.held_movement.is_empty(), "Blocked key presses do not resume after closing %s" % window)
		hold_key(KEY_W, false)
	hold_key(KEY_D, true)
	game.toggle_pause()
	var before_pause: Vector2 = sim.player["cell"]
	var before_clock := sim.clock
	game._physics_process(0.2)
	game.toggle_pause()
	game._physics_process(0.1)
	check(sim.player["cell"] == before_pause and is_equal_approx(sim.clock, before_clock + 0.1) and controller.held_movement.is_empty(), "Pause disarms movement and resume never restarts an old held key")
	hold_key(KEY_D, false)
	hold_key(KEY_W, true)
	controller._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var before_focus: Vector2 = sim.player["cell"]
	game._physics_process(0.1)
	check(sim.player["cell"] == before_focus and controller.held_movement.is_empty() and sim.movement_direction == Vector2.ZERO, "Switching away from the game clears held keys and prevents stuck walking")
	hold_key(KEY_W, false)
	sim.player["cell"] = origin
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(18, 20), "hp": 32.0, "owned": true}, true)
	game.world_view.selected_id = "wolf_0"
	key(KEY_C)
	check(not sim.capture.is_empty(), "Capture C remains available after numeric skill remapping")
	hold_key(KEY_D, true)
	check(sim.capture.is_empty(), "A WASD press interrupts capture immediately through live input")
	sim._damage_player(1000)
	game._physics_process(0.05)
	check(bool(sim.player["dead"]) and controller.held_movement.is_empty() and sim.movement_direction == Vector2.ZERO, "Death disarms the keyboard controller as well as authority movement")
	advance(sim, 5.1)
	game._physics_process(0.1)
	check(sim.player["cell"] == WorldGrid.SPAWN, "Respawn stands still until a new movement key press")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	keyboard_completed = true

func _test_combat() -> void:
	var sim := fixture()
	var result := sim.cast(0, "wolf_0", Vector2.ZERO)
	check(bool(result["ok"]) and sim.player["mana"] == 92.0 and sim.mobs["wolf_0"]["hp"] == 99.0, "Moon cast applies configured damage and mana once")
	check(not bool(sim.cast(0, "wolf_0", Vector2.ZERO)["ok"]) and sim.player["mana"] == 92.0, "Cooldown rejects repeated cast without charging")
	sim.cooldowns[0] = 0.0
	sim.player["mana"] = 0.0
	check(sim.cast(0, "wolf_0", Vector2.ZERO).get("error") == "NO_MANA" and sim.cooldowns[0] == 0.0, "Insufficient mana leaves cooldown unchanged")
	sim = fixture()
	sim.player["cell"] = WorldGrid.SPAWN
	check(sim.cast(0, "wolf_0", Vector2.ZERO).get("error") == "SAFE_ZONE", "Safe camp disallows offensive casts")
	sim = fixture()
	sim.player["cell"] = Vector2(8.48, 18)
	check(not bool(sim.cast(2, "", Vector2(11, 18))["ok"]) and sim.player["mana"] == 100.0, "Blocked dash is rejected without resource loss")
	sim = fixture()
	check(bool(sim.cast(2, "", Vector2(18, 20))["ok"]) and Vector2(sim.player["cell"]).distance_to(Vector2(18, 20)) < 0.01, "Valid dash reaches cursor within three tiles")
	sim = fixture()
	sim.player["cell"] = Vector2(8, 18)
	sim.mobs["wolf_0"]["cell"] = Vector2(10, 18)
	check(sim.cast(0, "wolf_0", Vector2.ZERO).get("error") == "NO_LOS", "Projectile respects obstacle line of sight")
	sim = fixture()
	sim.inventory.slot_gu(0)["hunger"] = 0.0
	check(sim.cast(0, "wolf_0", Vector2.ZERO).get("error") == "HUNGRY", "Dormant Gu cannot cast")
	sim.inventory.slot_gu(0)["hunger"] = 19.0
	sim.cast(0, "wolf_0", Vector2.ZERO)
	check(sim.mobs["wolf_0"]["hp"] == 107.0, "Low hunger reduces offensive output by twenty percent")
	sim = fixture()
	sim.cast(3, "wolf_0", Vector2.ZERO)
	check(sim.mobs["wolf_0"]["slow_left"] == 3.0 and sim.mobs["wolf_0"]["hp"] == 114.0, "Frost applies damage and timed slow")
	sim.cast(1, "", Vector2.ZERO)
	sim._damage_player(20)
	check(sim.player["hp"] == 200.0 and sim.player["shield"] == 55.0, "Shield absorbs damage before HP")
	advance(sim, 5.1)
	check(sim.player["shield"] == 0.0, "Shield expires after five seconds")
	sim = fixture()
	sim.mobs["wolf_0"]["cell"] = Vector2(15.8, 20)
	sim.step(0.05)
	check(sim.mobs["wolf_0"]["state"] == "windup" and sim.player["hp"] == 200.0, "Wolf telegraphs before damage")
	sim.player["cell"] = Vector2(15, 22)
	advance(sim, 0.7)
	check(sim.player["hp"] == 200.0, "Moving out of telegraph evades attack")
	sim = fixture()
	sim.mobs["wolf_0"].merge({"cell": Vector2(20, 20), "state": "chase", "owned": true, "hp": 40.0}, true)
	sim.player["cell"] = Vector2(12, 23)
	sim.step(0.05)
	var retreat_x: float = sim.mobs["wolf_0"]["cell"].x
	sim.player["cell"] = Vector2(21, 20)
	sim.step(0.05)
	check(sim.mobs["wolf_0"]["state"] == "leash" and sim.mobs["wolf_0"]["cell"].x < retreat_x, "Leashing mob commits to return even if player re-enters aggro range")
	advance(sim, 1.1)
	check(sim.mobs["wolf_0"]["hp"] == 140.0 and not bool(sim.mobs["wolf_0"]["owned"]), "Returning mob resets health and encounter ownership")
	sim = fixture()
	sim._damage_mob("wolf_0", 1000)
	sim._damage_mob("wolf_0", 1000)
	check(sim.player["xp"] == 35 and sim.player["currency"] == 112 and sim.progress["kills"] == 1, "Death grants XP and loot exactly once")
	advance(sim, 20.1)
	check(not bool(sim.mobs["wolf_0"]["dead"]) and sim.mobs["wolf_0"]["hp"] == 140.0, "Killed mob respawns after twenty seconds")
	sim = fixture()
	sim._damage_player(1000)
	sim._damage_player(1000)
	check(bool(sim.player["dead"]) and sim.player["currency"] == 95, "Player death penalty applies once")
	advance(sim, 5.1)
	check(not bool(sim.player["dead"]) and sim.player["cell"] == WorldGrid.SPAWN and sim.player["hp"] == 200.0, "Player respawns safely with full resources")
	sim = fixture()
	sim.player["xp"] = 105
	sim._check_level()
	check(sim.player["level"] == 2 and sim.player["max_hp"] == 220.0, "Cumulative XP grants level and new max HP")
	sim.progress = {"kills": 3, "captures": 1, "feeds": 1, "claimed": false}
	sim._check_quest()
	sim._check_quest()
	check(sim.player["currency"] == 300 and bool(sim.progress["claimed"]), "Teaching quest reward is granted once")

func _test_cast_preview() -> void:
	var sim := fixture()
	var before_player := sim.player.duplicate(true)
	var before_mobs := sim.mobs.duplicate(true)
	var before_inventory := sim.inventory.to_data().duplicate(true)
	var before_events := sim.events.duplicate(true)
	var before_cooldowns := sim.cooldowns.duplicate()
	for slot in range(4):
		var preview := sim.preview_cast(slot, "wolf_0", Vector2(15, 23))
		check(bool(preview["ok"]) and int(preview["cost"]) > 0, "Cast preview %d accepts a usable skill without executing it" % slot)
	check(sim.player == before_player and sim.mobs == before_mobs and sim.inventory.to_data() == before_inventory and sim.events == before_events and sim.cooldowns == before_cooldowns, "All cast previews leave resources, paths, mobs, inventory, events and cooldowns untouched")
	sim.mobs["wolf_0"]["cell"] = Vector2(22, 20)
	check(sim.preview_cast(0, "wolf_0", Vector2.ZERO).get("error") == sim.cast(0, "wolf_0", Vector2.ZERO).get("error"), "Out-of-range preview and cast return the same denial")
	sim.player["cell"] = Vector2(8, 18)
	sim.mobs["wolf_0"]["cell"] = Vector2(10, 18)
	check(sim.preview_cast(0, "wolf_0", Vector2.ZERO).get("error") == "NO_LOS", "Preview identifies an in-range target behind a rock")
	var dash := sim.preview_cast(2, "", Vector2(11, 18))
	check(bool(dash["ok"]) and bool(dash["clipped"]) and Vector2(dash["destination"]).x < 8.51, "Dash preview marks a clipped path and stops before its obstacle")
	sim.cast(2, "", Vector2(11, 18))
	check(Vector2(sim.player["cell"]).is_equal_approx(dash["destination"]), "Actual dash lands at exactly its displayed preview endpoint")
	sim.cooldowns[2] = 0.0
	check(sim.preview_cast(2, "", Vector2(11, 18)).get("error") == "BAD_PATH", "Preview rejects a dash with too little space before a wall")
	sim = fixture()
	sim.player["max_mana"] = 105.0
	sim.player["mana"] = 12.8
	var mana_preview := sim.preview_cast(1, "", Vector2.ZERO)
	check(mana_preview.get("error") == "NO_MANA" and mana_preview["cost"] == 13, "Preview uses rounded-up mana cost at a nonstandard maximum")
	var button := SkillButton.new()
	button.definition = sim.catalog.slot(1)
	button.update_state(0.0, 100.0, 12.8, 105.0, false)
	check(button.unavailable and button.status == "Thiếu khí", "Hotbar availability uses the same rounded-up cost as the authority")
	button.free()
	sim.inventory.gu[0]["hunger"] = 0.0
	sim.cooldowns[0] = 2.0
	check(sim.preview_cast(0, "wolf_0", Vector2.ZERO).get("error") == "HUNGRY", "Preview preserves the cast's hunger-before-cooldown denial priority")
	check(sim.preview_cast(99, "", Vector2.ZERO).get("error") == "BAD_SLOT", "Preview handles an invalid slot without indexing the catalog")
	check(sim.preview_cast(2, "", Vector2(NAN, 1)).get("error") == "BAD_PATH", "Preview rejects a non-finite dash aim")

func _test_capture() -> void:
	var sim := fixture()
	check(sim.begin_capture("wolf_0").get("error") == "HP_TOO_HIGH" and sim.inventory.materials["seal"] == 5, "Ineligible capture does not consume seal")
	sim._damage_mob("wolf_0", 108)
	sim.player["cell"] = Vector2(14, 20)
	check(sim.begin_capture("wolf_0").get("error") == "OUT_OF_RANGE", "Capture enforces range")
	sim.player["cell"] = Vector2(15.1, 20)
	check(bool(sim.begin_capture("wolf_0")["ok"]) and sim.inventory.materials["seal"] == 4, "Eligible capture reserves seal and starts channel")
	sim.move_to(Vector2(15, 21))
	check(sim.capture.is_empty() and sim.inventory.materials["seal"] == 4, "Movement cancels channel without refund")
	sim = fixture()
	sim._damage_mob("wolf_0", 108)
	sim.begin_capture("wolf_0")
	sim._damage_player(1)
	check(sim.capture.is_empty(), "Taking damage interrupts capture")
	sim = fixture()
	sim.inventory.materials = {"seal": 5}
	for i in range(25):
		sim.inventory.add_gu("GU-01")
	sim._damage_mob("wolf_0", 108)
	check(sim.begin_capture("wolf_0").get("error") == "BAG_FULL" and sim.inventory.materials["seal"] == 5, "Full bag blocks capture before consuming seal")
	# Pin RNG immediately before channel completion; AI cannot reach attack range in two seconds.
	sim = fixture()
	sim._damage_mob("wolf_0", 108)
	sim.mobs["wolf_0"]["slow_left"] = 3.0
	var seed_value := 1
	var probe := RandomNumberGenerator.new()
	probe.seed = seed_value
	while probe.randf() >= 0.7:
		seed_value += 1
		probe.seed = seed_value
	sim.rng.seed = seed_value
	sim.begin_capture("wolf_0")
	advance(sim, 2.05)
	check(sim.progress["captures"] == 1 and sim.inventory.gu.size() == 5 and bool(sim.mobs["wolf_0"]["dead"]), "Completed successful capture creates one Gu and removes target")
	check(float(sim.inventory.gu.back()["hunger"]) == 100.0, "Captured Gu starts at full hunger")
	sim = fixture()
	sim._damage_mob("wolf_0", 108)
	sim.mobs["wolf_0"]["slow_left"] = 3.0
	seed_value = 1
	probe.seed = seed_value
	while probe.randf() < 0.7:
		seed_value += 1
		probe.seed = seed_value
	sim.rng.seed = seed_value
	sim.begin_capture("wolf_0")
	advance(sim, 2.05)
	check(sim.inventory.gu.size() == 4 and sim.inventory.materials["seal"] == 4 and not bool(sim.mobs["wolf_0"]["dead"]), "Failed capture consumes seal but creates no Gu")

func _test_inventory() -> void:
	var sim := fixture()
	var inv := sim.inventory
	inv.gu[0]["hunger"] = 20.0
	check(inv.feed("wrong", "gu_1", "stone", inv.version, sim.catalog).get("error") == "WRONG_FOOD" and inv.materials["stone"] == 2, "Wrong food is rejected without consuming")
	check(inv.feed("stale", "gu_1", "meat", -1, sim.catalog).get("error") == "VERSION_CONFLICT", "Stale inventory version is rejected")
	var version := inv.version
	var result := sim.feed_gu("repeat", "gu_1", "meat", version)
	for i in range(20):
		check(sim.feed_gu("repeat", "gu_1", "meat", version) == result, "Feed retry %02d returns identical receipt" % i)
	check(inv.materials["meat"] == 2 and inv.gu[0]["hunger"] == 60.0 and sim.progress["feeds"] == 1, "Feed retries consume one food and count one quest action")
	check(inv.feed("repeat", "gu_2", "stone", version, sim.catalog).get("error") == "REQUEST_CONFLICT", "Reused request ID cannot change payload")
	inv.gu[0]["hunger"] = 82.0
	sim.feed_gu("clamp", "gu_1", "meat", inv.version)
	check(inv.gu[0]["hunger"] == 100.0, "Feed caps hunger at one hundred")
	check(inv.feed("full", "gu_1", "meat", inv.version, sim.catalog).get("error") == "FULL_HUNGER", "Full hunger rejects food consumption")
	inv.advance_hunger(300.0)
	check(inv.gu[0]["hunger"] == 99.0, "Equipped hunger decays one point in five online minutes")
	inv = InventoryModel.new()
	inv.materials = {"meat": 99}
	for i in range(25):
		inv.add_gu("GU-01")
	check(inv.occupied_slots() == 30, "Unique Gu and ninety-nine material stacks share capacity")
	inv.reward_material("meat", 1)
	check(inv.materials["meat"] == 99 and inv.pending_materials["meat"] == 1, "Full-bag reward is retained in pending storage")
	inv.gu[0]["hunger"] = 50.0
	inv.feed("space", "gu_1", "meat", inv.version, sim.catalog)
	inv.recover_rewards()
	check(inv.materials["meat"] == 99 and inv.pending_materials.is_empty(), "Pending reward recovers when stack has space")
	var data := inv.to_data()
	var reloaded := InventoryModel.new()
	check(reloaded.load_data(data, sim.catalog), "Valid inventory profile loads")
	data["gu"][1]["instance_id"] = data["gu"][0]["instance_id"]
	check(not reloaded.load_data(data, sim.catalog), "Duplicate instance IDs are rejected")
	data = inv.to_data()
	data["gu"][0]["slot"] = "broken"
	check(not reloaded.load_data(data, sim.catalog), "Malformed numeric fields are rejected without crash")

func _test_save() -> void:
	var store := SaveStore.new("user://automated_tests/profile.json")
	store.clear_profile()
	var sim := fixture()
	sim.inventory.gu[0]["hunger"] = 50.0
	var version := sim.inventory.version
	sim.feed_gu("persisted", "gu_1", "meat", version)
	check(store.save_profile(sim.to_profile()), "Local save writes profile")
	var other := fixture()
	check(other.load_profile(store.load_profile()) and other.inventory.gu[0]["hunger"] == 90.0 and other.player["cell"] == sim.player["cell"], "Save round trip restores inventory and position")
	other.feed_gu("persisted", "gu_1", "meat", version)
	check(other.inventory.materials["meat"] == 2 and other.progress["feeds"] == 1, "Receipt survives restart and prevents duplicate consumption")
	sim.player["currency"] = 222
	store.save_profile(sim.to_profile())
	var corrupt := FileAccess.open(store.path, FileAccess.WRITE)
	corrupt.store_string("{ broken json")
	corrupt.close()
	check(store.load_profile().get("currency") == 100, "Corrupt main save falls back to prior backup")
	var invalid := sim.to_profile()
	invalid["inventory"]["gu"][0]["hunger"] = "invalid"
	corrupt = FileAccess.open(store.path, FileAccess.WRITE)
	corrupt.store_string(JSON.stringify(invalid))
	corrupt.close()
	check(store.load_profile().get("currency") == 100, "Semantically invalid main save falls back to backup")
	invalid = sim.to_profile()
	invalid["cell"] = [{}, []]
	check(not other.load_profile(invalid), "Malformed saved position cannot crash loader")
	store.clear_profile()

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	root.push_input(event, true)

func click(point: Vector2) -> void:
	# Input.parse_input_event consumes window pixels; our view helpers return canvas pixels.
	point = root.get_final_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	Input.parse_input_event(event)

func _test_scene() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	check(game.test_mode and game.hud.skill_buttons.size() == 4 and game.world_view.actors.size() == game.simulation.mobs.size() and game.simulation.mobs.size() == Bestiary.population("forest").size()+6, "Main scene boots with HUD and expanded authority population in isolated test mode")
	var destination := Vector2(15, 21)
	click(game.world_view.cell_to_screen(destination))
	await process_frame
	check(not game.simulation.player["path"].is_empty(), "Real mouse input routes ground click into movement")
	game.simulation.player["path"] = []
	key(KEY_TAB)
	await create_timer(0.24).timeout
	check(game.hud.bag_open and game.hud.bag_list.get_child_count() == 4, "Tab opens inventory with four equipped Gu")
	var feed_button: Button = game.hud.bag_list.get_child(0).feed_button
	click(feed_button.get_global_rect().get_center())
	await process_frame
	check(game.simulation.progress["feeds"] == 1 and game.simulation.player["path"].is_empty(), "Inventory feed button consumes food without moving player")
	key(KEY_TAB)
	# Closing inventory keeps consuming mouse input during its exit transition.
	# The cursor-driven world casts below begin after the panel has fully hidden.
	await create_timer(0.24).timeout
	game.simulation.player["cell"] = Vector2(15, 20)
	game.simulation.mobs["wolf_0"]["cell"] = Vector2(18, 20)
	game.world_view.selected_id = "wolf_0"
	key(KEY_1)
	await process_frame
	check(game.simulation.mobs["wolf_0"]["hp"] == 99.0, "1 key casts through live input controller")
	key(KEY_4)
	await process_frame
	check(game.simulation.mobs["wolf_0"]["hp"] == 73.0 and game.simulation.mobs["wolf_0"]["slow_left"] == 3.0, "4 key casts frost through live input controller")
	var motion := InputEventMouseMotion.new()
	motion.position = game.world_view.cell_to_screen(Vector2(15, 23))
	root.push_input(motion, true)
	await process_frame
	# Viewport injection dispatches synchronously; resolve aim after the camera's preceding frame.
	var cast_origin: Vector2 = game.simulation.player["cell"]
	var cast_aim := game.world_view.screen_to_cell(game.cursor_screen)
	# Camera interpolation can put this real viewport ray across a tree.
	# The authority's navigation trace clips dash travel at obstacles; a
	# straight three-cell expectation incorrectly demands moving through one.
	var dash_preview := game.simulation.preview_cast(2,game.world_view.selected_id,cast_aim)
	var expected_dash: Vector2 = dash_preview.get("destination",cast_origin)
	var cursor_in_world := game.pointer_in_world
	key(KEY_3)
	await process_frame
	if Vector2(game.simulation.player["cell"]).distance_to(expected_dash) >= 0.05:
		print("DASH_CURSOR_FIXTURE screen=", game.cursor_screen, " origin=", cast_origin, " aim=", cast_aim, " pointer_world=", cursor_in_world, " expected=", expected_dash, " actual=", game.simulation.player["cell"], " belt=", game.hud.action_belt.get_global_rect())
	check(bool(dash_preview.get("ok",false)) and expected_dash.distance_to(cast_origin)>.1 and Vector2(game.simulation.player["cell"]).distance_to(expected_dash) < 0.05, "3 key dashes toward actual viewport cursor and respects the authority's obstacle trace")
	var mana: float = game.simulation.player["mana"]
	click(game.hud.skill_buttons[1].get_global_rect().get_center())
	await process_frame
	check(game.simulation.player["shield"] > 0 and game.simulation.player["mana"] < mana and game.simulation.player["path"].is_empty(), "Skill button casts shield without sending ground movement")
	key(KEY_ESCAPE)
	await process_frame
	var clock: float = game.simulation.clock
	game._physics_process(1.0)
	check(game.paused and game.hud.pause_panel.visible and game.simulation.clock == clock, "Escape pauses simulation and reveals help")
	key(KEY_ESCAPE)
	await process_frame
	check(not game.paused, "Escape resumes gameplay")
	game.simulation._damage_player(1000)
	game.hud.update_hud(0)
	check(game.hud.death_text.visible, "Death countdown appears in live HUD")
	advance(game.simulation, 5.1)
	game.hud.update_hud(0)
	check(not game.hud.death_text.visible, "HUD recovers after player respawn")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	scene_completed = true

func _test_presentation() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	game.hud.toggle_bag()
	await create_timer(0.24).timeout
	var row: GuInventoryRow = game.hud.bag_rows["gu_1"]
	var row_id := row.get_instance_id()
	var button_id := row.feed_button.get_instance_id()
	click(row.feed_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	check(game.hud.bag_rows["gu_1"].get_instance_id() == row_id and row.feed_button.get_instance_id() == button_id and row.feed_button.disabled, "Feed refresh keeps row/button identity and reflects full hunger")
	game.simulation.inventory.gu[0]["hunger"] = 10.0
	game.simulation.inventory.materials["meat"] = 0
	game.hud.update_hud(0.6)
	check(row.feed_button.disabled and row.feed_button.text == "Hết thức ăn", "Bag shows why feeding is unavailable without rebuilding")
	click(Vector2(650, 300))
	await process_frame
	check(not game.hud.bag_open and game.simulation.player["path"].is_empty(), "Backdrop click closes bag and is consumed before world movement")
	await create_timer(0.22).timeout
	# Chained hide callbacks can run on the next process tick after timeout.
	await process_frame
	check(not game.hud.bag.visible and not game.hud.backdrop.visible, "Bag close animation hides both panel and backdrop")
	var feeds_before := int(game.simulation.progress["feeds"])
	game.feed("gu_1", "meat")
	check(int(game.simulation.progress["feeds"]) == feeds_before, "Closing-bag controls cannot trigger a delayed feed transaction")
	game.hud.toggle_bag()
	game.hud.toggle_bag()
	game.hud.toggle_bag()
	await create_timer(0.24).timeout
	# Timer and tween completion can share a long headless frame. Inspect
	# the final UI state after the completion tick, as the close check above.
	await process_frame
	check(game.hud.bag_open and game.hud.bag.visible and is_equal_approx(game.hud.bag.modulate.a, 1.0) and is_equal_approx(game.hud.bag.offset_left, GameHUD.BAG_LEFT), "Rapid bag toggles finish in the latest requested state")
	game.hud.toggle_bag()
	var p := game.simulation.player
	p["mana"] = 0.0
	game.simulation.inventory.gu[0]["hunger"] = 100.0
	game.hud.update_hud(0)
	check(game.hud.skill_buttons[0].unavailable and game.hud.skill_buttons[0].status == "Thiếu khí", "Hotbar identifies insufficient mana before a cast")
	p["mana"] = 100.0
	game.simulation.inventory.gu[0]["hunger"] = 0.0
	game.hud.update_hud(0)
	check(game.hud.skill_buttons[0].status == "Cổ đói", "Hotbar distinguishes empty hunger from mana and cooldown")
	game.simulation.inventory.gu[0]["hunger"] = 100.0
	game.simulation.cooldowns[0] = 1.2
	game.hud.update_hud(0)
	check(game.hud.skill_buttons[0].status == "Hồi 1.2s", "Cooldown status keeps the skill name independent of its timer")
	game.simulation.cooldowns[0] = 0.0
	game.hud.update_hud(0)
	check(game.hud.skill_buttons[0].status == "Sẵn sàng" and game.hud.skill_buttons[0].pulse_left > 0.0, "Ready transition triggers a bounded hotbar pulse")
	p["cell"] = Vector2(15, 20)
	var target: Dictionary = game.simulation.mobs["wolf_0"]
	target.merge({"cell": Vector2(18, 20), "hp": 32.0, "owned": true}, true)
	game.world_view.selected_id = "wolf_0"
	game.hud.update_hud(0)
	check(game.hud.target_hint.text.contains("70%"), "Capture hint identifies a valid low-health target in range")
	target["cell"] = Vector2(22, 20)
	game.hud.update_hud(0)
	check(game.hud.target_hint.text.contains("Lại gần"), "Capture hint updates when a weakened target leaves range")
	target["cell"] = Vector2(18, 20)
	game.simulation.inventory.materials["seal"] = 0
	game.hud.update_hud(0)
	check(game.hud.target_hint.text.contains("Hết phong ấn"), "Capture hint reflects exhausted seals")
	p["level"] = 2
	p["xp"] = 150
	game.hud.update_hud(0)
	check(game.hud.xp_bar.value == 50 and game.hud.xp_bar.max_value == 200, "XP bar shows progress within the current cumulative level threshold")
	game.toggle_pause()
	await process_frame
	var actor_phase := game.world_view.player_view.phase
	var effects_phase := game.world_view.effects.phase
	await create_timer(0.12).timeout
	check(game.world_view.player_view.phase == actor_phase and game.world_view.effects.phase == effects_phase, "Pause freezes actor animation and world VFX while HUD remains active")
	game.toggle_motion()
	check(game.world_view.player_view.reduced_motion and game.world_view.effects.reduced_motion and game.hud.skill_buttons[0].reduced_motion and game.hud.motion_button.text.ends_with("bật"), "Reduced-motion setting reaches actor, VFX and menu/hotbar presentation")
	game.toggle_motion()
	check(not game.world_view.player_view.reduced_motion and not game.world_view.effects.reduced_motion and not game.hud.skill_buttons[0].reduced_motion, "Reduced-motion setting can return all presentation layers to normal")
	game.toggle_pause()
	await create_timer(0.05).timeout
	check(game.world_view.player_view.phase > actor_phase, "Resume restarts world presentation")
	game.world_view.player_view.position = WorldGrid.project(Vector2(16, 21))
	game.world_view._process(0.25)
	var faded_canopy := false
	for prop in game.world_view.props:
		if prop.kind == "tree" and prop.cell == Vector2(16, 22):
			faded_canopy = prop.modulate.a < 0.25
	check(faded_canopy, "Foreground canopy fades enough to preserve actor visibility near a tree")
	# Deterministic presentation stepping proves interpolation never writes simulation state.
	var actor := ActorView.new()
	var state := {"cell": Vector2(15, 20), "facing": Vector2.RIGHT, "dead": false}
	actor.bind(state, true)
	state["cell"] = Vector2(16, 20)
	actor._process(0.05)
	check(actor.move_blend > 0.0 and actor.stride > 0.0 and state["cell"] == Vector2(16, 20), "Gait follows rendered distance without changing the authoritative cell")
	var stride_before := actor.stride
	actor.position = WorldGrid.project(state["cell"])
	actor._process(0.1)
	check(actor.stride == stride_before, "Idle animation does not advance walking stride")
	actor.receive({"kind": "dash", "to": Vector2(19, 20)})
	state["cell"] = Vector2(19, 20)
	actor._process(0.08)
	var during_dash := actor.position
	actor._process(0.08)
	check(during_dash.distance_to(actor.dash_end) > 0.01 and actor.position.is_equal_approx(actor.dash_end), "Dash eases across frames and ends exactly at the authorized destination")
	actor.receive({"kind": "cast_moon"})
	check(actor.action == "cast_moon" and actor.action_left > 0.0, "Accepted cast starts an event-driven actor pose")
	actor.receive({"kind": "player_hit"})
	check(actor.flash > 0.0, "Damage event starts a bounded actor hit reaction")
	actor.free()
	var effects := WorldEffects.new()
	effects.simulation = game.simulation
	for i in range(3):
		effects.receive({"kind": "hit", "at": Vector2(18, 20), "target": "wolf_0", "amount": 41})
	check(effects.effects[0]["lane"] != effects.effects[1]["lane"] and effects.effects[1]["lane"] != effects.effects[2]["lane"], "Simultaneous damage labels get separate lanes per victim")
	for i in range(70):
		effects.receive({"kind": "move", "at": Vector2(15, 20)})
	check(effects.effects.size() == WorldEffects.MAX_EFFECTS, "VFX queue remains bounded during event bursts")
	effects._process(1.1)
	check(effects.effects.is_empty(), "Expired effects release their storage")
	effects.free()
	game.hud.toast_queue.clear()
	game.hud.toast_left = 0.0
	game.hud.toast("A", false, 3.0)
	game.hud.toast("B")
	game.hud.toast("B")
	check(game.hud.toast_queue.size() == 1 and game.hud.toast_label.text.ends_with("A"), "Action receipts queue once instead of overwriting one another")
	game.hud.toast("Thiếu chân nguyên", true)
	check(game.hud.toast_error and game.hud.toast_label.text.ends_with("Thiếu chân nguyên"), "Denied action feedback appears immediately ahead of queued receipts")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	presentation_completed = true

func mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	root.push_input(event, true)

func hold_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event, true)

func _test_targeting() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	var sim := game.simulation
	sim.player["cell"] = Vector2(15, 20)
	game.world_view.player_view.position = WorldGrid.project(sim.player["cell"])
	game.world_view.camera.position = game.world_view.player_view.position + Vector2(0, -65)
	game.world_view.camera.force_update_scroll()
	check(not game.has_world_aim and game.aim_point().is_equal_approx(Vector2(sim.player["cell"]) + Vector2(sim.player["facing"]).normalized() * 3.0), "A dash before any world aim defaults to facing instead of a UI coordinate")
	for id in sim.mobs:
		sim.mobs[id]["dead"] = id not in ["wolf_0", "wolf_1", "wolf_2"]
	sim.mobs["wolf_0"]["cell"] = Vector2(18, 20)
	sim.mobs["wolf_1"]["cell"] = Vector2(15, 23)
	sim.mobs["wolf_2"]["cell"] = Vector2(22, 13)
	for id in game.world_view.actors:
		game.world_view.actors[id].bind(sim.mobs[id], false)
	await process_frame
	mouse(game.world_view.cell_to_screen(Vector2(18, 20)) + Vector2(0, -12))
	await process_frame
	await process_frame
	check(game.pointer_in_world and game.world_view.targeting.hovered_id == "wolf_0", "World mouse hover highlights the rendered living enemy")
	click(game.world_view.cell_to_screen(Vector2(18, 20)) + Vector2(0, -12))
	await process_frame
	check(game.world_view.selected_id == "wolf_0" and sim.player["path"].is_empty(), "Enemy click selects with feedback and does not start movement")
	key(KEY_F)
	check(game.world_view.selected_id == "wolf_1", "F cycles nearby on-screen targets with deterministic distance ties")
	key(KEY_F)
	check(game.world_view.selected_id == "wolf_0", "F wraps the target list while excluding dead and distant mobs")
	var mana := float(sim.player["mana"])
	var cooldowns := sim.cooldowns.duplicate()
	hold_key(KEY_ALT, true)
	await process_frame
	await process_frame
	check(game.preview_held and game.world_view.targeting.slot == 2 and game.hud.skill_detail.visible, "Holding Alt reveals the dash path and skill details through real key input")
	check(sim.player["mana"] == mana and sim.cooldowns == cooldowns and sim.player["path"].is_empty(), "Previewing a skill never spends mana, starts cooldown or sends movement")
	hold_key(KEY_ALT, false)
	await process_frame
	await process_frame
	check(game.world_view.targeting.slot == -1 and not game.hud.skill_detail.visible, "Releasing Alt removes its preview without an extra key press")
	mouse(game.world_view.cell_to_screen(Vector2(15, 22)))
	await process_frame
	await process_frame
	var remembered := game.world_aim
	mouse(game.hud.skill_buttons[2].get_global_rect().get_center())
	await process_frame
	await process_frame
	check(not game.pointer_in_world and game.world_aim.is_equal_approx(remembered) and game.world_view.targeting.hovered_id.is_empty(), "Entering the hotbar freezes the last world aim and clears world hover")
	check(game.hud.hovered_skill == 2 and game.hud.skill_detail.visible and game.world_view.targeting.slot == 2, "Hovering a skill opens its custom inspector and range preview")
	var expected := sim.preview_cast(2, "", remembered)
	check(not game.hud.skill_detail.get_global_rect().has_point(game.world_view.cell_to_screen(expected["destination"])), "Skill inspector leaves the near-player dash endpoint visible in the playfield")
	click(game.hud.skill_buttons[2].get_global_rect().get_center())
	await process_frame
	await process_frame
	check(Vector2(sim.player["cell"]).distance_to(expected["destination"]) < 0.02 and sim.player["mana"] == mana - expected["cost"], "Clicking dash on the hotbar uses the last world aim rather than the button position")
	sim.player["mana"] = 0.0
	mouse(game.hud.skill_buttons[0].get_global_rect().get_center())
	await process_frame
	await process_frame
	check(game.world_view.targeting.probe.get("error") == "NO_MANA" and game.hud.skill_reason.text == GameManager.ERRORS["NO_MANA"], "Hovered-skill inspector explains the authority's current resource denial")
	sim.player["mana"] = 100.0
	sim.mobs["wolf_0"]["cell"] = Vector2(24, 20)
	await process_frame
	await process_frame
	check(game.world_view.targeting.probe.get("error") == "OUT_OF_RANGE", "An open preview tracks a selected target leaving range")
	game.hud.toggle_bag()
	await process_frame
	await process_frame
	check(not game.hud.skill_detail.visible and not game.world_view.targeting.visible, "Opening inventory suppresses aim overlays and the skill inspector")
	game.hud.toggle_bag()
	game.toggle_pause()
	await process_frame
	await process_frame
	check(not game.world_view.targeting.visible and not game.hud.skill_detail.visible, "Pause hides targeting affordances while freezing the world")
	game.toggle_pause()
	game.preview_held = true
	for child in game.get_children():
		if child is GameInputController:
			child._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.preview_held and not game.pointer_in_world, "Losing application focus clears held-preview and pointer state")
	sim.mobs["wolf_0"]["dead"] = true
	game.world_view._process(0.01)
	check(game.world_view.selected_id.is_empty(), "Defeated selected target clears its selection marker")
	for mob in sim.mobs.values():
		mob["dead"] = true
	key(KEY_F)
	check(game.world_view.selected_id.is_empty(), "Target cycling with no eligible mobs leaves selection empty")
	game.queue_free()
	await process_frame
	await create_timer(0.08).timeout
	targeting_completed = true
