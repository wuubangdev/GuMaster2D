extends SceneTree
## Real input, centering, region changes and native screenshots for the map UI.
var game: GameManager
var checks: Array[Dictionary] = []
var captures: Array[String] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	checks.append({"name": name, "passed": condition})
	if not condition: printerr("FAIL: ", name)

func settle() -> void:
	await process_frame
	await process_frame
	await create_timer(.2).timeout

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)

func click(point: Vector2) -> void:
	point = root.get_final_transform() * point
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)

func capture(name: String) -> void:
	# Keep tooltips outside the image without changing the inspected state.
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(420, 340)
	Input.parse_input_event(motion)
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/minimap50_%s.png" % name
	check(root.get_texture().get_image().save_png(path) == OK, "Native capture " + name)
	captures.append(path)

func _run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.hud.toast_left = 0
	game.hud.toast_queue.clear()
	var hud := game.hud
	var sim := game.simulation
	var map := hud.minimap
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 640), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		var screen := Rect2(Vector2.ZERO, Vector2(dimensions))
		check(screen.encloses(hud.map_panel.get_global_rect()), "Compact minimap fits %s" % dimensions)
		check(hud.map_panel.get_theme_stylebox("panel") is StyleBoxEmpty, "Map border surrounds terrain rather than an extended paper panel")
		check(map.size.x >= 190 and map.size.y >= 120 and hud.map_panel.size.y <= 208, "Readable terrain with compact overall height at %s" % dimensions)
		check(not hud.map_panel.get_global_rect().intersects(hud.cultivation_button.get_global_rect()), "Map and Cổ giới control have separate bounds at %s" % dimensions)
		check(hud.map_coordinates.text.contains("X: 12") and hud.map_coordinates.text.contains("Y: 20") and hud.map_coordinates.text.contains("Đông Bắc"), "Current X/Y and named direction are readable")
		await capture("hud_%d" % dimensions.x)
		var inventory_before := sim.inventory.to_data()
		sim.move_to(Vector2(13, 20))
		click(map.get_global_rect().get_center())
		await settle()
		check(hud.large_map_open and sim.player["path"].is_empty(), "Real minimap click opens enlarged map and stops an old path")
		check(screen.encloses(hud.large_map.get_global_rect()), "Enlarged map fits %s" % dimensions)
		check(hud.large_map.atlas.bounds().size.x >= map.map_bounds().size.x * 2.0, "Enlarged terrain is at least twice the minimap width at %s" % dimensions)
		var mana: float = sim.player["mana"]
		key(KEY_1)
		key(KEY_W)
		check(sim.player["mana"] == mana and sim.movement_direction == Vector2.ZERO and sim.inventory.to_data() == inventory_before, "Enlarged map blocks combat/movement input without altering inventory")
		var site: Dictionary = WorldContent.camps(sim.expedition.region)[4]
		click(hud.large_map.atlas.global_position + hud.large_map.atlas.project(WorldContent.cell(site)))
		await settle()
		check(hud.large_map.atlas.selected == str(site["id"]), "Real atlas click selects a camp")
		await capture("large_%d" % dimensions.x)
		key(KEY_T)
		await settle()
		check(not hud.large_map_open and hud.cultivation_open and hud.cultivation_book.atlas_selection == str(site["id"]), "T transfers the selected site into travel/navigation controls")
		key(KEY_ESCAPE)
		await settle()
		check(not hud.has_open_window() and not game.paused, "Escape closes the map flow before pausing")
		key(KEY_F2)
		await settle()
		check(hud.large_map_open, "F2 opens the enlarged map")
		key(KEY_F2)
		await settle()
		check(not hud.has_open_window(), "F2 closes the enlarged map")
		click(hud.map_expand_button.get_global_rect().get_center())
		await settle()
		check(hud.large_map_open, "Expand button opens the map through real mouse input")
		key(KEY_ESCAPE)
		await settle()
	var directions := [Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1), Vector2.UP, Vector2(1, -1)]
	var names := ["Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc", "Bắc", "Đông Bắc"]
	for i in range(directions.size()):
		sim.player["facing"] = directions[i].normalized()
		sim.player["cell"] = Vector2(12.35 + i * .031, 20.27 + i * .04)
		hud.update_hud(0)
		check(hud.map_coordinates.text.ends_with(names[i]) and map.project(sim.player["cell"]).distance_to(map.map_bounds().get_center()) < .001, "Heading %s stays labeled and centered during fractional movement" % names[i])
	var cached := map.terrain
	await settle()
	check(map.terrain == cached, "Fractional movement reuses cached regional terrain")
	sim.player["cell"] = WorldGrid.SPAWN
	sim.progress["kills"] = 3
	sim.expedition.realm_unlocked = true
	for region in ["ruins", "realm", "forest"]:
		sim.combat_left = 0
		check(sim.travel(region).get("ok", false), "Travel fixture enters " + region)
		game.flush_events()
		await settle()
		check(map.rendered_region == region and map.terrain == RegionalAtlas.terrain_preview_for(sim, true), "Minimap terrain switches to " + region)
	hud.toggle_bag()
	key(KEY_F2)
	await settle()
	check(hud.large_map_open and not hud.bag_open, "Opening enlarged map closes inventory")
	key(KEY_TAB)
	await settle()
	check(hud.bag_open and not hud.large_map_open, "Opening inventory closes enlarged map")
	key(KEY_ESCAPE)
	var failed := checks.filter(func(result: Dictionary): return not result["passed"]).size()
	FileAccess.open("res://artifacts/minimap50_review_%s.json" % OS.get_name().to_lower(), FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures, "platform": OS.get_name(), "engine": Engine.get_version_info()["string"]}, "  "))
	print("MINIMAP50_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
