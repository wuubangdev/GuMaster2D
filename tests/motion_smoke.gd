extends SceneTree
## Records real Godot frames with deterministic 24 Hz simulation/presentation stepping.
## Requires a rendering backend; no screenshots are fabricated or composited.

const FRAME_COUNT: int = 80
const STEP: float = 1.0 / 24.0

func _initialize() -> void:
	_run.call_deferred()

func key_event(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event, true)

func _run() -> void:
	assert("--test-mode" in OS.get_cmdline_user_args(), "Motion recording must isolate the user profile")
	DirAccess.make_dir_recursive_absolute("res://artifacts/motion")
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game: GameManager = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.sounds.toggle()
	var sim := game.simulation
	sim.player["cell"] = Vector2(15, 20)
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(19, 20), "spawn": Vector2(19, 20)}, true)
	game.world_view.selected_id = "wolf_0"
	game.world_view.player_view.position = WorldGrid.project(sim.player["cell"])
	for id in game.world_view.actors:
		game.world_view.actors[id].bind(sim.mobs[id], false)
		game.world_view.actors[id].death_age = 1.0
	game.world_view.camera.position = game.world_view.player_view.position + Vector2(0, -65)
	game.hud.toast_left = 0.0
	game.hud.showing_intro = false
	for button in game.hud.skill_buttons:
		button.set_process(false)
	var samples: Array[Dictionary] = []
	for frame in range(FRAME_COUNT):
		if frame == 18:
			game.preview_held = true
			game.world_aim = Vector2(18, 22)
			game.has_world_aim = true
		if frame == 28:
			game.preview_held = false
		if frame == 0:
			key_event(KEY_S, true)
		if frame == 11:
			key_event(KEY_S, false)
		var slot := -1
		match frame:
			18: slot = 1
			28: slot = 2
			40: slot = 0
			52: slot = 3
		if slot >= 0:
			key_event(GameBindings.SKILL_KEYS[slot], true)
			key_event(GameBindings.SKILL_KEYS[slot], false)
		if slot >= 0 and sim.cooldowns[slot] <= 0.0:
			printerr("Motion keyboard cast rejected at frame ", frame, ": ", game.hud.toast_label.text)
			game.queue_free()
			await process_frame
			quit(1)
			return
		sim.step(STEP)
		game.flush_events()
		game.world_view.player_view._process(STEP)
		for actor in game.world_view.actors.values():
			actor._process(STEP)
		for prop in game.world_view.props:
			if prop.kind in ["lantern", "altar", "monolith"]:
				prop._process(STEP)
		game.world_view.effects._process(STEP)
		game.world_view._process(STEP)
		game.world_view.camera.force_update_scroll()
		game.hud.update_hud(STEP)
		game.update_targeting()
		game.world_view.targeting._process(STEP)
		for button in game.hud.skill_buttons:
			button._process(STEP)
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://artifacts/motion/frame_%03d.png" % frame)
		assert(result == OK)
		samples.append({"frame": frame, "stride": game.world_view.player_view.stride, "keyboard_direction": [sim.movement_direction.x, sim.movement_direction.y], "action": game.world_view.player_view.action, "action_left": game.world_view.player_view.action_left, "wolf_state": sim.mobs["wolf_0"]["state"], "shield": sim.player["shield"], "preview_slot": game.world_view.targeting.slot})
	var file := FileAccess.open("res://artifacts/motion_samples.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames": FRAME_COUNT, "sample_rate": 24, "stepping": "WASD and numeric InputEvent; deterministic simulation/presentation; actual Windows renderer", "samples": samples}, "  "))
	file.close()
	print("MOTION_CAPTURE ", FRAME_COUNT, " frames OK")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
