extends SceneTree
## Native evidence of the complete pixel game and the exact gameplay sprite
## renderer. Run alone so operating-system focus cannot corrupt GUI input.

var game: GameManager
var records: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Pixel screenshots require a native renderer and -- --test-mode.")
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

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://artifacts/%s.png" % name)
	assert(error == OK)
	print("PIXEL_CAPTURE ", name, " ", image.get_size())
	records.append({"file": name + ".png", "size": [image.get_width(), image.get_height()], "backend": DisplayServer.get_name(), "source": "Actual native Godot window framebuffer"})

func _position_player(cell: Vector2, facing: Vector2 = Vector2.DOWN) -> void:
	game.simulation.player["cell"] = cell
	game.simulation.player["facing"] = facing
	game.world_view.player_view.position = WorldGrid.project(cell)
	game.world_view.player_view.spawn_left = 0.0
	game.world_view.player_view.death_age = 0.0
	game.world_view.player_view._sync_character()
	game.world_view._process(0.0)
	game.world_view.camera.position = (game.world_view.player_view.position + Vector2(0, -32)).round()
	game.world_view.camera.force_update_scroll()
	game.hud.update_hud(0.0)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Pixel art review"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	game.hud.toast_left = 0.0
	_position_player(WorldGrid.SPAWN)
	await _capture("pixel_gameplay_camp")
	_position_player(Vector2(12, 14), Vector2.UP)
	await _capture("pixel_gameplay_shrine")
	_position_player(Vector2(15, 18), Vector2.RIGHT)
	game.world_view.select_target("wolf_0")
	await _capture("pixel_gameplay_forest")
	_key(KEY_F6)
	await process_frame
	var studio: GuCharacterStudio = game.hud.character_studio
	studio.set_process(false)
	studio._select_direction(4)
	studio._select_action(0)
	studio.playhead = 0.0
	studio._present()
	await _capture("pixel_studio_male")
	studio.appearance = {"body": "female", "outfit": "ivory", "weapon": "spear", "hair": "ponytail"}
	studio._sync_controls()
	studio._select_action(3)
	studio._select_direction(3)
	studio.playhead = GuCharacterAnimations.duration("attack", "spear") * 0.40
	studio._present()
	await _capture("pixel_studio_female_spear")
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await _capture("pixel_studio_960")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	_key(KEY_ESCAPE)
	_key(KEY_F3)
	await _capture("pixel_character_sheet")
	_key(KEY_ESCAPE)
	_key(KEY_F4)
	await create_timer(0.24).timeout
	await _capture("pixel_inventory_1280")
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await _capture("pixel_inventory_960")
	_key(KEY_ESCAPE)
	await create_timer(0.24).timeout
	_position_player(WorldGrid.SPAWN)
	await _capture("pixel_gameplay_960")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	await _contact_sheet()
	var output := FileAccess.open("res://artifacts/pixel_visual_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"screenshots": records.size(), "engine": Engine.get_version_info()["string"], "source": "Native Godot 2D sprite runtime; authored PNG atlas pixels; no image compositing", "samples": records}, "  "))
	output.close()
	print("PIXEL_VISUAL_SMOKE_COMPLETE ", records.size(), " screenshots")
	game.queue_free()
	await process_frame
	quit()

func _label(parent: Node, text: String, position: Vector2, width: float, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _contact_sheet() -> void:
	var sheet := CanvasLayer.new()
	sheet.layer = 100
	root.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color("243a35")
	background.size = Vector2(1280, 800)
	sheet.add_child(background)
	_label(sheet, "CỔ SƯ / PIXEL 2D", Vector2(20, 24), 1240, 28, Color("f3e8c1"))
	_label(sheet, "48px • Tám hướng vẽ riêng • Cùng sprite trong bản đồ, HUD và F6", Vector2(20, 70), 1240, 15, Color("becdb0"))
	_label(sheet, "TÁM HƯỚNG", Vector2(20, 118), 1240, 13, Color("dec992"))
	var names := ["Bắc", "Đông Bắc", "Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc"]
	for direction in range(8):
		var view := GuPixelCharacterView.new()
		sheet.add_child(view)
		view.configure(256, 96)
		view.position = Vector2(80 + direction * 160, 290)
		view.present("idle", 0.0, Vector2.UP.rotated(direction * TAU / 8.0))
		view.set_active(false)
		_label(sheet, names[direction], Vector2(direction * 160, 315), 160, 15, Color("efe5c7"))
	_label(sheet, "ĐỘNG TÁC / TRANG PHỤC / VŨ KHÍ", Vector2(20, 365), 1240, 13, Color("dec992"))
	var actions := GuCharacterAnimations.clip_names()
	for index in range(actions.size()):
		var column := index % 6
		var row := index / 6
		var view := GuPixelCharacterView.new()
		sheet.add_child(view)
		view.configure(256, 96)
		view.position = Vector2(140 + column * 200, 535 + row * 200)
		var look := {"body": "female" if index % 2 else "male", "outfit": ["jade", "crimson", "ivory"][index % 3], "weapon": ["sword", "spear", "unarmed"][index % 3], "hair": "ponytail" if index % 2 else "topknot"}
		view.set_appearance(look)
		view.present(actions[index], GuCharacterAnimations.duration(actions[index], look["weapon"]) * (0.90 if actions[index] == "death" else 0.4), Vector2(1, 1))
		view.set_active(false)
		_label(sheet, GuCharacterAnimations.LABELS[actions[index]], Vector2(40 + column * 200, 555 + row * 200), 200, 15, Color("efe5c7"))
	await _capture("pixel_character_directions_actions")
	sheet.queue_free()
	await process_frame
