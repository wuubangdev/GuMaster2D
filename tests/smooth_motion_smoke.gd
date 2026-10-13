extends SceneTree
## Native start/stop, turning, skill and F6 transition evidence. Input events
## drive the real game. Deterministic 60Hz capture is review playback, not FPS.

const FRAMES := 600
const SAMPLE_RATE := 60
const STEP := 1.0 / SAMPLE_RATE
const OUTPUT_DIRECTORY := "res://artifacts/smooth_motion"

var game: GameManager
var samples: Array[Dictionary] = []
var accepted_slots: Array[int] = []
var studio_actions: Array[String] = []
var studio_profile: Dictionary = {}
var studio_inventory: Dictionary = {}
var previous_pose: Dictionary = {}
var previous_mode := ""

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Smooth motion capture requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event, true)

func _tap(code: int) -> void:
	_key(code, true)
	_key(code, false)

func _click(button: Button) -> void:
	assert(button.is_visible_in_tree() and root.get_visible_rect().encloses(button.get_global_rect()), "The clicked workshop control belongs to the visible native UI")
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)

func _accept(slot: int) -> bool:
	if slot == 2:
		var aim := InputEventMouseMotion.new()
		aim.position = game.world_view.cell_to_screen(Vector2(16, 18))
		root.push_input(aim, true)
		assert(game.pointer_in_world, "A dash aim must belong to the real playfield")
	_tap(GameBindings.SKILL_KEYS[slot])
	if float(game.simulation.cooldowns[slot]) <= 0.0:
		printerr("Native smooth skill rejected: slot=", slot + 1, " player=", game.simulation.player["cell"], " probe=", game.simulation.preview_cast(slot, game.world_view.selected_id, game.aim_point()), " feedback=", game.hud.toast_label.text)
		quit(2)
		return false
	accepted_slots.append(slot + 1)
	return true

func _fixture() -> void:
	var sim := game.simulation
	sim.player.merge({"cell": Vector2(12, 20), "facing": Vector2.RIGHT, "path": [], "running": false, "dead": false, "hp": 200.0, "mana": 100.0, "shield": 0.0, "shield_left": 0.0}, true)
	sim.movement_direction = Vector2.ZERO
	for slot in range(sim.cooldowns.size()):
		sim.cooldowns[slot] = 0.0
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(17, 18), "spawn": Vector2(17, 18), "facing": Vector2.LEFT, "slow_left": 0.0, "hp": 140.0, "state": "idle"}, true)
	sim.drain_events()
	game.world_view.effects.effects.clear()
	var player := game.world_view.player_view
	player.position = WorldGrid.project(sim.player["cell"])
	player.spawn_left = 0.0
	player.action_left = 0.0
	player.flash = 0.0
	player.move_blend = 0.0
	player.character_view.present("idle", 0.0, Vector2.RIGHT)
	for id in game.world_view.actors:
		var actor: ActorView = game.world_view.actors[id]
		actor.position = WorldGrid.project(sim.mobs[id]["cell"])
		actor.was_dead = bool(sim.mobs[id]["dead"])
		actor.presentation_dead = actor.was_dead
		actor.pending_hit_left = 0.0
		actor.death_age = 1.0
		actor.flash = 0.0
	game.world_view.select_target("wolf_0")
	game.world_view._camera_follow = player.position + Vector2(0, -24)
	game.world_view._process(0.0)
	game.world_view.camera.force_update_scroll()
	game.hud.toast_left = 0.0
	game.hud.update_hud(0.0)
	game.update_targeting()

func _world_step() -> void:
	game.input_controller.update_movement()
	game.simulation.step(STEP)
	game.flush_events()
	var profile := game.simulation.to_profile().duplicate(true)
	var inventory := game.simulation.inventory.to_data().duplicate(true)
	game.world_view.player_view._process(STEP)
	for actor in game.world_view.actors.values():
		actor._process(STEP)
	game.world_view.effects._process(STEP)
	game.world_view._process(STEP)
	game.world_view.camera.force_update_scroll()
	game.world_view.targeting._process(STEP)
	game.hud.update_hud(STEP)
	game.update_targeting()
	for button in game.hud.skill_buttons:
		button._process(STEP)
	assert(game.simulation.to_profile() == profile and game.simulation.inventory.to_data() == inventory, "Advancing smooth presentation must not mutate the already accepted authoritative state")

func _pose_step(before: Dictionary, after: Dictionary) -> float:
	if before.is_empty():
		return 0.0
	var largest := 0.0
	for key in ["head", "torso", "foot_L", "foot_R"]:
		largest = maxf(largest, Vector2(before[key]).distance_to(after[key]))
	for side in ["L", "R"]:
		for joint in range(3):
			largest = maxf(largest, Vector2(before["arm_" + side][joint]).distance_to(after["arm_" + side][joint]))
	return largest

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Smooth motion and transition review"
	assert(DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY) == OK)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	for button in game.hud.skill_buttons:
		button.set_process(false)
	_fixture()
	var saw_walk := false
	var saw_run := false
	var saw_idle := false
	var world_directions := {}
	for frame in range(FRAMES):
		match frame:
			0: _key(KEY_D, true)
			45: _key(KEY_D, false)
			75: _key(KEY_D, true)
			105: _key(KEY_W, true)
			135: _key(KEY_D, false)
			165:
				_key(KEY_W, false)
				_key(KEY_S, true)
				_key(KEY_A, true)
			195: _key(KEY_SHIFT, true)
			225:
				_key(KEY_S, false)
				_key(KEY_A, false)
				_key(KEY_SHIFT, false)
			240:
				_key(KEY_D, true)
				if not _accept(0):
					return
			260: _key(KEY_D, false)
			275:
				if not _accept(1):
					return
			300:
				if not _accept(2):
					return
			330:
				if not _accept(3):
					return
			360:
				studio_profile = game.simulation.to_profile().duplicate(true)
				studio_inventory = game.simulation.inventory.to_data().duplicate(true)
				_tap(KEY_F6)
				await process_frame
				await process_frame
				assert(game.hud.character_studio.opened, "A real F6 InputEvent opens the animated workshop")
				game.hud.character_studio.set_process(false)
			375:
				_click(game.hud.character_studio.action_buttons[1])
				_click(game.hud.character_studio.direction_buttons[3])
			435:
				_click(game.hud.character_studio.action_buttons[2])
				_click(game.hud.character_studio.direction_buttons[7])
			495:
				_click(game.hud.character_studio.action_buttons[3])
				_click(game.hud.character_studio.direction_buttons[2])
			555:
				_click(game.hud.character_studio.action_buttons[4])
				_click(game.hud.character_studio.direction_buttons[4])
		var mode := "world" if frame < 360 else "workshop"
		var view: GuIllustratedCharacterView
		if mode == "world":
			_world_step()
			view = game.world_view.player_view.character_view
			saw_walk = saw_walk or view.current_action == "walk"
			saw_run = saw_run or view.current_action == "run"
			saw_idle = saw_idle or (frame > 45 and view.current_action == "idle")
			world_directions[view.current_direction] = true
		else:
			game.hud.character_studio._process(STEP)
			view = game.hud.character_studio.character_view
			assert(game.simulation.to_profile() == studio_profile and game.simulation.inventory.to_data() == studio_inventory, "Workshop action and facing changes must leave authority and inventory untouched")
			if frame in [375, 435, 495, 555]:
				studio_actions.append(game.hud.character_studio.action)
		var snapshot := view.capture_pose()
		var pose: Dictionary = snapshot["pose"]
		assert(view.hand_position("R").is_equal_approx(Vector2(snapshot["source_pose"]["grip_R"]) * float(snapshot["scale"])), "The exported spell hand equals the actual displayed blended pose")
		var step_distance := _pose_step(previous_pose, pose) if previous_mode == mode else 0.0
		previous_pose = pose.duplicate(true)
		previous_mode = mode
		await process_frame
		await RenderingServer.frame_post_draw
		var framebuffer := root.get_texture().get_image()
		assert(framebuffer.get_size() == Vector2i(1280, 800))
		var file_name := "frame%03d.png" % frame
		assert(framebuffer.save_png(OUTPUT_DIRECTORY + "/" + file_name) == OK)
		samples.append({"frame": frame, "file": "smooth_motion/" + file_name, "mode": mode, "action": view.current_action, "direction": view.current_direction, "phase": snapshot["phase"], "largest_joint_step_design_units": step_distance, "pose": str(pose), "hand_R": str(view.hand_position("R")), "held_direction": str(game.simulation.movement_direction), "running": game.simulation.player["running"], "player_cell": str(game.simulation.player["cell"]), "mana": game.simulation.player["mana"], "target_hp": game.simulation.mobs["wolf_0"]["hp"]})
	assert(saw_walk and saw_run and saw_idle and world_directions.size() >= 4, "Real movement input must show walk, run, stop and changing facings")
	assert(accepted_slots == [1, 2, 3, 4], "All four numeric skills must be accepted in the actual rendered scenario")
	assert(studio_actions == ["walk", "run", "attack", "defend"], "Real workshop mouse presses must select the requested action transitions")
	var output := FileAccess.open("res://artifacts/ink19_motion_capture.json", FileAccess.WRITE)
	assert(output != null)
	output.store_string(JSON.stringify({"revision": "ink19", "frames": FRAMES, "sample_rate": SAMPLE_RATE, "renderer": "GuIllustratedCharacterView", "native_size": [1280, 800], "engine": Engine.get_version_info()["string"], "backend": DisplayServer.get_name(), "accepted_slots": accepted_slots, "studio_actions": studio_actions, "saw_walk": saw_walk, "saw_run": saw_run, "saw_stop": saw_idle, "world_directions": world_directions.size(), "authority_unchanged_by_preview": game.simulation.to_profile() == studio_profile and game.simulation.inventory.to_data() == studio_inventory, "source": "Actual full native Godot framebuffer; real WASD/Shift/1-4/F6 and workshop mouse InputEvents. Authority and presentation are stepped deterministically. The 60Hz export is review playback, not an engine FPS benchmark.", "samples": samples}, "  "))
	output.close()
	print("SMOOTH_MOTION_SMOKE_COMPLETE ", FRAMES, " frames; real walk/run/turn/stop; four accepted skills; F6 mouse transitions; readonly preview")
	game.queue_free()
	await process_frame
	quit()
