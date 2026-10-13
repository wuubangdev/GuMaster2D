extends SceneTree
## Captures actual rendered UI states; intentionally exits without writing a user profile.

func _initialize() -> void:
	_run.call_deferred()

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	root.push_input(event, true)

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/%s.png" % name)
	print("VISUAL_CAPTURE ", name, " ", result)
	assert(result == OK)

func mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	root.push_input(event, true)

func click(point: Vector2) -> void:
	mouse(point)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)

func hold_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event, true)

func position_player(game: GameManager, point: Vector2) -> void:
	game.simulation.player["cell"] = point
	game.world_view.player_view.position = WorldGrid.project(point)
	game.world_view.camera.position = game.world_view.player_view.position + Vector2(0, -65)
	game.world_view.camera.force_update_scroll()

func capture_targeting(game: GameManager) -> void:
	game.set_physics_process(false)
	position_player(game, Vector2(15, 20))
	game.simulation.mobs["wolf_0"]["cell"] = Vector2(18, 20)
	game.world_view.actors["wolf_0"].position = WorldGrid.project(Vector2(18, 20))
	game.world_view.select_target("wolf_0")
	game.hud.showing_intro = false
	game.hud.toast_left = 0.0
	mouse(game.world_view.cell_to_screen(Vector2(18, 20)) + Vector2(0, -12))
	await create_timer(0.22).timeout
	await capture("windows_target_hover")
	position_player(game, Vector2(8, 18))
	mouse(game.world_view.cell_to_screen(Vector2(11, 18)))
	hold_key(KEY_ALT, true)
	await create_timer(0.2).timeout
	await capture("windows_dash_preview")
	hold_key(KEY_ALT, false)
	position_player(game, Vector2(15, 20))
	mouse(game.hud.skill_buttons[0].get_global_rect().get_center())
	await create_timer(0.2).timeout
	await capture("windows_skill_preview")
	game.simulation.mobs["wolf_0"]["cell"] = Vector2(24, 20)
	await create_timer(0.2).timeout
	await capture("windows_skill_denied")
	mouse(game.world_view.cell_to_screen(Vector2(15, 22)))
	game.set_physics_process(true)

func _run() -> void:
	assert("--test-mode" in OS.get_cmdline_user_args(), "Visual smoke must isolate user save")
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	root.add_child(game)
	await create_timer(0.5).timeout
	await capture("windows_first_playable")
	var press := InputEventMouseButton.new()
	press.position = game.hud.quest_toggle.get_global_rect().get_center()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	await create_timer(0.12).timeout
	await capture("windows_quest_collapsed")
	game.hud.toggle_quest()
	key(KEY_TAB)
	await create_timer(0.24).timeout
	await capture("windows_inventory")
	click(game.hud.inventory_browser.filter_buttons[2].get_global_rect().get_center())
	await create_timer(0.12).timeout
	await capture("windows_inventory_material")
	game.hud.inventory_browser.select_gu("gu_1")
	click(game.hud.inventory_browser.filter_buttons[0].get_global_rect().get_center())
	DisplayServer.window_set_size(Vector2i(960, 640))
	await create_timer(0.25).timeout
	await capture("windows_inventory_compact")
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await create_timer(0.25).timeout
	key(KEY_TAB)
	key(KEY_F3)
	await create_timer(0.24).timeout
	await capture("windows_character")
	key(KEY_F4)
	await create_timer(0.24).timeout
	await capture("windows_character_inventory")
	DisplayServer.window_set_size(Vector2i(960, 640))
	await create_timer(0.25).timeout
	await capture("windows_character_inventory_compact")
	DisplayServer.window_set_size(Vector2i(1280, 800))
	await create_timer(0.25).timeout
	key(KEY_F11)
	game.simulation.progress["kills"] = 2
	await create_timer(0.24).timeout
	await capture("windows_journal")
	game.simulation.progress["kills"] = 0
	key(KEY_ESCAPE)
	key(KEY_ESCAPE)
	await create_timer(0.24).timeout
	await capture("windows_pause")
	key(KEY_ESCAPE)
	await capture_targeting(game)
	game.simulation.player["cell"] = Vector2(15, 20)
	game.simulation.mobs["wolf_0"]["cell"] = Vector2(17.9, 20)
	game.simulation.mobs["wolf_0"]["spawn"] = Vector2(17.9, 20)
	game.world_view.selected_id = "wolf_0"
	game.simulation.cast(0, "wolf_0", Vector2.ZERO)
	game.simulation.cooldowns[0] = 0.0
	game.simulation.cast(0, "wolf_0", Vector2.ZERO)
	game.simulation.cast(3, "wolf_0", Vector2.ZERO)
	game.simulation.begin_capture("wolf_0")
	game.flush_events()
	await create_timer(0.4).timeout
	await capture("windows_capture")
	game.simulation._damage_player(1000)
	game.flush_events()
	await create_timer(0.12).timeout
	await capture("windows_death")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
