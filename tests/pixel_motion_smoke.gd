extends SceneTree
## Actual native frames driven by real WASD, Shift and numeric InputEvents.
## Simulation and sprite clocks advance deterministically at 24Hz. Requires an
## isolated user save and an exclusive native game window during capture.

const FRAMES := 96
const STEP := 1.0 / 24.0
var samples: Array[Dictionary] = []
var accepted_slots: Array[int] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Pixel motion recording requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event, true)

func _cast(game: GameManager, slot: int) -> bool:
	_key(GameBindings.SKILL_KEYS[slot], true)
	_key(GameBindings.SKILL_KEYS[slot], false)
	if float(game.simulation.cooldowns[slot]) <= 0.0:
		printerr("Native pixel cast rejected for slot ", slot + 1, ": ", game.hud.toast_label.text)
		return false
	accepted_slots.append(slot + 1)
	return true

func _aim(game: GameManager, cell: Vector2) -> void:
	# A native OS pointer can already be inside the game window. Send a real
	# viewport event so the intended aim owns both cursor and remembered target.
	var event := InputEventMouseMotion.new()
	event.position = game.world_view.cell_to_screen(cell)
	root.push_input(event, true)
	assert(game.pointer_in_world, "The scripted aim must lie on the visible playfield")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Pixel movement verification"
	DirAccess.make_dir_recursive_absolute("res://artifacts/pixel_motion")
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.world_view.player_view.character_view is GuIllustratedCharacterView)
	game.set_physics_process(false)
	game.set_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	game.hud.toast_left = 0.0
	var sim := game.simulation
	sim.player["cell"] = Vector2(12, 20)
	sim.player["facing"] = Vector2.RIGHT
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(17, 18), "spawn": Vector2(17, 18), "slow_left": 0.0, "hp": 140.0}, true)
	game.world_view.selected_id = "wolf_0"
	game.world_view.player_view.position = WorldGrid.project(sim.player["cell"])
	game.world_view.player_view.spawn_left = 0.0
	for actor in game.world_view.actors.values():
		actor.death_age = 1.0
	for button in game.hud.skill_buttons:
		button.set_process(false)
	var saw_walk := false
	var saw_run := false
	for frame in range(FRAMES):
		match frame:
			0: _key(KEY_D, true)
			18: _key(KEY_D, false)
			24:
				_key(KEY_SHIFT, true)
				_key(KEY_W, true)
			42:
				_key(KEY_W, false)
				_key(KEY_SHIFT, false)
			48:
				if not _cast(game, 0):
					quit(1)
					return
			60:
				if not _cast(game, 1):
					quit(1)
					return
			72:
				_aim(game, Vector2(16, 18))
				if not _cast(game, 2):
					quit(1)
					return
			84:
				if not _cast(game, 3):
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
		var view: GuPixelCharacterView = game.world_view.player_view.character_view
		saw_walk = saw_walk or view.current_action == "walk"
		saw_run = saw_run or view.current_action == "run"
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/pixel_motion/frame_%03d.png" % frame) == OK)
		samples.append({"frame": frame, "cell": [sim.player["cell"].x, sim.player["cell"].y], "held_direction": [sim.movement_direction.x, sim.movement_direction.y], "running": sim.player["running"], "sprite_action": view.current_action, "sprite_direction": view.current_direction, "sprite_frame": view.current_frame, "accepted_actor_action": game.world_view.player_view.action, "mana": sim.player["mana"], "shield": sim.player["shield"]})
	assert(saw_walk and saw_run, "Real native WASD and Shift events must display distinct walk/run states")
	assert(accepted_slots == [1, 2, 3, 4], "All numeric skill slots must be accepted in the rendered scenario")
	var output := FileAccess.open("res://artifacts/pixel_motion_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"revision":"ink19", "renderer":"GuIllustratedCharacterView", "frames": FRAMES, "sample_rate": 24, "engine": Engine.get_version_info()["string"], "source": "Actual native Godot framebuffer; real WASD/Shift/1–4 InputEvents; continuous SVG rig and vector VFX; deterministic authority and presentation stepping", "accepted_slots": accepted_slots, "saw_walk": saw_walk, "saw_run": saw_run, "samples": samples}, "  "))
	output.close()
	print("PIXEL_MOTION_SMOKE_COMPLETE ", FRAMES, " frames; WASD walk/run; four accepted numeric skills")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
