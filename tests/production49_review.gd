extends SceneTree
## Native UI and inventory acceptance at the two supported PC sizes.
var checks: Array[Dictionary] = []
var captures: Array[String] = []
var game: GameManager

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	checks.append({"name": name, "passed": condition})
	if not condition: printerr("FAIL ", name)

func settle() -> void:
	await process_frame
	await process_frame
	await create_timer(.12).timeout

func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/production49_%s.png" % name
	check(root.get_texture().get_image().save_png(path) == OK, "Native screenshot " + name)
	captures.append(path)

func _run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	var hud := game.hud
	var minimap: GuMinimap = hud.minimap
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 640)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.map_panel.get_global_rect()), "Minimap fits %s" % dimensions)
		check(not hud.map_panel.get_global_rect().intersects(hud.cultivation_button.get_global_rect()), "Minimap and Cổ giới button stay separate at %s" % dimensions)
		check(hud.map_coordinates.text.contains("12") and hud.map_coordinates.text.contains("Đông"), "Current coordinates and facing are visible")
		await capture("hud_%d" % dimensions.x)
		minimap.open_requested.emit()
		await settle()
		check(hud.large_map_open, "Clicking minimap opens large regional atlas")
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.large_map.get_global_rect()), "Large atlas fits %s" % dimensions)
		await capture("atlas_%d" % dimensions.x)
		hud.close_large_map()
		game.toggle_pause()
		await settle()
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.pause_panel.get_global_rect()), "Settings fit %s" % dimensions)
		await capture("settings_%d" % dimensions.x)
		game.toggle_pause()
		if dimensions.x == 1280:
			hud.toggle_bag()
			await capture("inventory_1280")
			var slot := hud.inventory_browser.slots[0]
			var point := slot.get_global_rect().get_center()
			var motion := InputEventMouseMotion.new()
			motion.position = root.get_final_transform() * point
			Input.parse_input_event(motion)
			var right_click := InputEventMouseButton.new()
			right_click.position = motion.position
			right_click.button_index = MOUSE_BUTTON_RIGHT
			right_click.pressed = true
			Input.parse_input_event(right_click)
			await settle()
			check(hud.inventory_browser.context_menu.visible and hud.inventory_browser.context_menu.is_item_disabled(4), "Right click exposes safe equipped Cổ menu")
			var before_feed := int(game.simulation.inventory.materials["meat"])
			hud.inventory_browser._context_action(1)
			await settle()
			check(int(game.simulation.inventory.materials["meat"]) == before_feed - 1, "Context menu feeds Cổ through authority")
			hud.inventory_browser.context_menu.hide()
			hud.toggle_bag()
	hud.volume_slider.value = 40
	check(is_equal_approx(game.sounds.volume, .4), "Volume slider reaches sound layer")
	hud.volume_slider.value = 0
	game.sounds.play("cast")
	check(game.sounds.voices.all(func(voice: AudioStreamPlayer): return not voice.playing), "Zero volume silences active and future effects")
	hud.volume_slider.value = 40
	hud.resolution_picker.select(0)
	hud.resolution_picker.item_selected.emit(0)
	check(game.preferred_window_size == Vector2i(960, 640), "Resolution control updates display preference")
	hud.fullscreen_button.button_pressed = true
	check(game.preferred_fullscreen, "Fullscreen control updates display preference")
	var inventory := game.simulation.inventory
	var first := inventory.ordered_keys()[0]
	var second := inventory.ordered_keys()[1]
	check(inventory.move_entry(second, first) and inventory.ordered_keys()[0] == second, "Inventory drag order changes")
	var restored := InventoryModel.new()
	check(restored.load_data(inventory.to_data(), game.simulation.catalog) and restored.ordered_keys()[0] == second, "Inventory order survives save roundtrip")
	check(not inventory.discard_entry("gu:gu_1", 1), "Equipped Cổ cannot be discarded")
	var before := int(inventory.materials["meat"])
	check(inventory.discard_entry("material:meat:0", 1) and int(inventory.materials["meat"]) == before - 1, "Confirmed material discard consumes exactly one item")
	var failed := checks.filter(func(item: Dictionary): return not item["passed"]).size()
	FileAccess.open("res://artifacts/production49_review.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures}, "  "))
	print("PRODUCTION49_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
