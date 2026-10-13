extends SceneTree
## Native F6 animation evidence. Real F6 InputEvent opens the workshop;
## only presentation playheads/cosmetics change during deterministic sampling.
## Exported 24Hz is a review playback rate, never an engine FPS benchmark.

const FRAMES := 144
const SAMPLE_RATE := 24
const OUTPUT_DIRECTORY := "res://artifacts/vector_studio_motion"
const CLIPS := [
	{"id": "idle_profile_blink", "action": "idle", "direction": 2, "weapon": "sword", "body": "male", "outfit": "jade", "hair": "topknot", "phase_start": .80, "phase_end": 1.05},
	{"id": "walk_right", "action": "walk", "direction": 2, "weapon": "sword", "body": "male", "outfit": "jade", "hair": "topknot", "phase_start": 0.0, "phase_end": 1.0},
	{"id": "run_left", "action": "run", "direction": 6, "weapon": "sword", "body": "male", "outfit": "jade", "hair": "topknot", "phase_start": 0.0, "phase_end": 1.0},
	{"id": "sword_attack_right", "action": "attack", "direction": 2, "weapon": "sword", "body": "male", "outfit": "jade", "hair": "topknot", "phase_start": 0.0, "phase_end": 1.0},
	{"id": "spear_attack_down_right", "action": "attack", "direction": 3, "weapon": "spear", "body": "female", "outfit": "ivory", "hair": "ponytail", "phase_start": 0.0, "phase_end": 1.0},
	{"id": "unarmed_attack_left", "action": "attack", "direction": 6, "weapon": "unarmed", "body": "male", "outfit": "crimson", "hair": "topknot", "phase_start": 0.0, "phase_end": 1.0},
]

var game: GameManager
var samples: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Workshop motion recording requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Illustrated workshop motion review"
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
	var authority_before := game.simulation.to_profile().duplicate(true)
	var inventory_before := game.simulation.inventory.to_data().duplicate(true)
	_key(KEY_F6)
	await process_frame
	await process_frame
	var studio: GuCharacterStudio = game.hud.character_studio
	assert(studio.opened and studio.is_visible_in_tree(), "A real F6 InputEvent must open the visible workshop")
	assert(studio.character_view is GuIllustratedCharacterView, "Workshop captures must display the actual illustrated character renderer")
	studio.set_process(false)
	var view: GuIllustratedCharacterView = studio.character_view
	for frame in range(FRAMES):
		var segment := frame / SAMPLE_RATE
		var frame_in_segment := frame % SAMPLE_RATE
		var clip: Dictionary = CLIPS[segment]
		if frame_in_segment == 0:
			studio.appearance = {"body": clip["body"], "outfit": clip["outfit"], "weapon": clip["weapon"], "hair": clip["hair"]}
			studio._sync_controls()
			studio._select_action(GuCharacterStudio.ACTIONS.find(str(clip["action"])))
			studio._select_direction(int(clip["direction"]))
		var phase := lerpf(float(clip["phase_start"]), float(clip["phase_end"]), float(frame_in_segment) / float(SAMPLE_RATE - 1))
		studio.playhead = phase * GuCharacterAnimations.duration(str(clip["action"]), str(clip["weapon"]))
		studio._present()
		await process_frame
		await RenderingServer.frame_post_draw
		var framebuffer := root.get_texture().get_image()
		assert(framebuffer.get_size() == Vector2i(1280, 800), "Every review frame keeps the whole native workshop viewport")
		var file_name := "frame%03d.png" % frame
		assert(framebuffer.save_png(OUTPUT_DIRECTORY + "/" + file_name) == OK)
		assert(game.simulation.to_profile() == authority_before and game.simulation.inventory.to_data() == inventory_before, "Previewing motion and cosmetic variants must never change gameplay authority or inventory")
		var snapshot := view.capture_pose()
		samples.append({"frame": frame, "file": "vector_studio_motion/" + file_name, "segment": segment, "clip": clip["id"], "action": view.current_action, "direction": view.current_direction, "appearance": studio.appearance.duplicate(true), "sample_phase": phase, "playhead_seconds": studio.playhead, "blink": snapshot.get("pose", {}).get("blink", 0.0), "native_size": [framebuffer.get_width(), framebuffer.get_height()], "pose": str(snapshot["pose"])})
		if frame_in_segment == SAMPLE_RATE - 1:
			print("VECTOR_STUDIO_MOTION_CLIP ", clip["id"], " 24 native frames")
	var output := FileAccess.open("res://artifacts/ink19_studio_motion_capture.json", FileAccess.WRITE)
	assert(output != null)
	output.store_string(JSON.stringify({"frames": FRAMES, "sample_rate": SAMPLE_RATE, "clips": CLIPS.size(), "renderer": "GuIllustratedCharacterView", "engine": Engine.get_version_info()["string"], "backend": DisplayServer.get_name(), "native_size": [1280, 800], "workshop_opened_by": "Real F6 InputEvent", "authority_unchanged": game.simulation.to_profile() == authority_before and game.simulation.inventory.to_data() == inventory_before, "source": "Actual full native Godot F6 workshop framebuffer. Preview cosmetics and presentation playheads alone select six animation segments. Export playback is 24Hz; clips are sampled across stated phases for legible review, not an engine FPS benchmark.", "samples": samples}, "  "))
	output.close()
	print("VECTOR_STUDIO_MOTION_SMOKE_COMPLETE ", FRAMES, " frames; six illustrated clips; real F6; unchanged authority")
	game.queue_free()
	await process_frame
	quit()
