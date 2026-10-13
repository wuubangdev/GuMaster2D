extends SceneTree
## Native visual evidence for the ink-on-paper HUD and modal windows.

var game: GameManager
var captures: Array[Dictionary] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("UI style review requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://artifacts/%s.png" % name
	assert(image.save_png(path) == OK)
	captures.append({"file": name + ".png", "size": [image.get_width(), image.get_height()]})
	print("UI_STYLE_CAPTURE ", name, " ", image.get_width(), "x", image.get_height())

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — UI mực trên giấy review"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	game.hud.set_reduced_motion(true)
	game.hud.toast_left = 0.0
	game.world_view.select_target("wolf_0")
	game.hud.update_hud(0.0)
	await _capture("ink20_ui_hud_1280")

	game.hud.toggle_bag()
	await _capture("ink20_ui_inventory_1280")
	game.hud.toggle_bag()
	game.hud.toggle_character()
	var doll: GuCharacterDoll = game.hud.character_doll
	assert(doll.concept_art.visible and not doll.avatar.visible, "The default character modal uses the approved concept illustration")
	var concept_atlas := doll.concept_art.texture as AtlasTexture
	assert(concept_atlas != null and concept_atlas.atlas.resource_path == GuCharacterDoll.CONCEPT_ATLAS_PATH and concept_atlas.region == GuCharacterDoll.CONCEPT_ART_REGION, "The portrait comes from the exact source concept region")
	await _capture("ink20_ui_character_1280")
	var alternate_look := GuCharacterAppearance.default_data()
	alternate_look["outfit"] = "crimson"
	doll.simulation.player["appearance"] = alternate_look
	doll.refresh_appearance()
	assert(not doll.concept_art.visible and doll.avatar.visible, "Alternate outfits fall back to the live appearance renderer")
	doll.simulation.player["appearance"] = GuCharacterAppearance.default_data()
	doll.refresh_appearance()
	assert(doll.concept_art.visible and not doll.avatar.visible, "Restoring the approved default restores the concept portrait")
	game.hud.toggle_character()
	game.hud.toggle_journal()
	await _capture("ink20_ui_journal_1280")
	game.hud.toggle_journal()
	game.hud.set_paused(true)
	await _capture("ink20_ui_pause_1280")
	game.hud.set_paused(false)
	game.hud.toggle_studio()
	await _capture("ink20_ui_studio_1280")
	game.hud.toggle_studio()

	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	game.world_view.camera.force_update_scroll()
	game.hud.update_hud(0.0)
	await _capture("ink20_ui_hud_1280x720")
	game.hud.toggle_bag()
	await _capture("ink20_ui_inventory_1280x720")
	game.hud.toggle_bag()
	game.hud.toggle_studio()
	await _capture("ink20_ui_studio_1280x720")
	game.hud.toggle_studio()

	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await process_frame
	await process_frame
	game.world_view.camera.force_update_scroll()
	game.hud.update_hud(0.0)
	await _capture("ink20_ui_hud_960")
	game.hud.toggle_bag()
	await _capture("ink20_ui_inventory_960")

	var output := FileAccess.open("res://artifacts/ink20_ui_visual_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"style": "ink-on-paper 0.20", "native_renderer": DisplayServer.get_name(), "screenshots": captures}, "  "))
	output.close()
	game.queue_free()
	await process_frame
	print("UI_STYLE_SMOKE_COMPLETE ", captures.size(), " screenshots")
	quit()
