extends SceneTree
## Native rendered workshop evidence. Run sequentially with other GUI captures.

var game: GameManager
var studio: GuCharacterStudio
var records: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Workshop screenshots require a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	root.push_input(event, true)

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/%s.png" % name)
	print("STUDIO_CAPTURE ", name, " ", error)
	assert(error == OK)

func _look(value: Dictionary) -> void:
	studio.appearance = value.duplicate(true)
	studio._sync_controls()
	studio.appearance_applied.emit(value)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	_key(KEY_F6)
	studio = game.hud.character_studio
	studio.set_process(false)
	studio._select_direction(4)
	studio._select_action(0)
	studio.playhead = 0.25
	studio._present()
	await _capture("character_studio_male")
	_look({"body": "female", "outfit": "ivory", "weapon": "spear", "hair": "ponytail"})
	studio._select_action(1)
	studio.playhead = 0.2
	studio._present()
	await _capture("character_studio_female_spear")
	studio._select_direction(0)
	await _capture("character_studio_rear")
	studio._select_direction(2)
	await _capture("character_studio_side")
	studio._select_direction(4)
	_look({"body": "male", "outfit": "crimson", "weapon": "unarmed", "hair": "topknot"})
	studio._select_action(4)
	studio.playhead = 0.2
	studio._present()
	await _capture("character_studio_unarmed_guard")
	_look({"body": "female", "outfit": "jade", "weapon": "sword", "hair": "ponytail"})
	studio._select_action(0)
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await _capture("character_studio_960")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts/studio_frames")
	for frame in range(99):
		var action_index: int = mini(10, frame / 9)
		var local_frame := frame % 9
		if studio.action != studio.ACTIONS[action_index]:
			studio._select_action(action_index)
		studio.playhead = float(local_frame) / 8.0 * GuCharacterAnimations.duration(studio.action)
		studio._select_direction(4 if frame < 32 else 3)
		studio._present()
		await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://artifacts/studio_frames/frame_%03d.png" % frame)
		assert(error == OK)
		records.append({"frame": frame, "action": studio.action, "direction": studio.direction_index, "time": studio.playhead, "appearance": studio.appearance.duplicate(true)})
	var output := FileAccess.open("res://artifacts/studio_motion_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"frames": records.size(), "playback_fps": 24, "source": "Godot native SubViewport rendering; presentation clock sampled deterministically", "samples": records}, "  "))
	output.close()
	_key(KEY_ESCAPE)
	_key(KEY_F3)
	await _capture("character_sheet_modular")
	print("STUDIO_SMOKE_COMPLETE 99 frames, 7 screenshots")
	game.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	quit()
