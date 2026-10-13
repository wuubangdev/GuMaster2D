extends "res://tests/world40_visual_smoke.gd"
## Isolated real scene: native atlas/input, streamed scenery and expanded-region captures.
var region_metrics: Dictionary = {}
var decoration_draws := 0

func decoration_redrawn() -> void:
	decoration_draws += 1

func capture(label: String, record_check: bool = true) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/world45_" + label + ".png"
	var result := root.get_texture().get_image().save_png(path)
	if record_check: check(result == OK,"Native capture " + label)
	shots.append(path)

func verify_stream(label: String) -> void:
	game.world_view._refresh_visible_world()
	var view := game.world_view
	var expected := game.simulation.world.props_near(game.simulation.player["cell"],view._visible_radius())
	var resident := {}
	for prop in view.props: resident["%s:%s:%s" % [prop.cell,prop.kind,prop.variant]] = true
	var complete := true
	for data in expected:
		complete = complete and resident.has("%s:%s:%s" % [data["cell"],data["kind"],data["variant"]])
	check(complete,label+" all scenery within camera coverage is resident")
	check(view.props.size() < game.simulation.world.props.size()/3,label+" resident props bounded to local area")
	check(view.props.size() == view._prop_nodes.size(),label+" no duplicate or orphan streamed nodes")
	check(view.overland.nearby_water().size() <= view.overland.water_cells.size(),label+" local river bucket query is bounded")

func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	var started := Time.get_ticks_msec()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	var sim := game.simulation
	check(game.test_mode,"Fixture isolates the player save")
	check(sim.world.SIZE == 256,"Expanded playable extent 256 by 256")
	check(game.world_view.actors.size() == sim.mobs.size(),"All authority creatures have an actor binding")
	region_metrics["boot_ms"] = Time.get_ticks_msec()-started
	await capture("village")
	key(KEY_G)
	await settle()
	check(game.hud.cultivation_open and game.hud.cultivation_book.page == "gu","G opens redesigned Gu board via real input")
	await capture("gu_board")
	key(KEY_ESCAPE)
	sim.progress["kills"] = 4
	sim.expedition.realm_unlocked = true
	grant_prerequisites("bamboo_chart")
	for region_id in ["forest","ruins","realm"]:
		if sim.expedition.region != region_id: await travel(region_id)
		verify_stream(region_id+" village")
		var camps := WorldContent.camps(region_id)
		var far: Array = []
		for camp in camps:
			if WorldContent.cell(camp).x > 96 or WorldContent.cell(camp).y > 96: far.append(camp)
		check(far.size() >= 12,region_id+" has authored content beyond old border")
		key(KEY_T)
		await settle()
		check(game.hud.cultivation_open,"Atlas opens in "+region_id)
		await capture(region_id+"_atlas")
		var book := game.hud.cultivation_book
		var chosen: Dictionary = far.back()
		click_point(book.regional_atlas.global_position+book.regional_atlas.project(WorldContent.cell(chosen)))
		await settle()
		check(book.regional_atlas.selected == chosen["id"],region_id+" native atlas selects remote camp")
		await press_text("Dẫn đường tới điểm đã chọn",book)
		check(not sim.player["path"].is_empty() and sim.player["path"].back() == WorldContent.cell(chosen),region_id+" native atlas issues full remote navigation")
		for index in [0,4,10,15]:
			var camp: Dictionary = far[mini(index,far.size()-1)]
			await jump(WorldContent.cell(camp)+Vector2(0,5))
			verify_stream(str(camp["id"]))
			await capture(str(camp["id"]))
		game.world_view.desired_zoom = 1
		await settle()
		verify_stream(region_id+" zoom1")
		game.world_view.desired_zoom = 2
		decoration_draws = 0
		game.world_view.environment_details.draw.connect(decoration_redrawn)
		game.world_view.set_reduced_motion(true)
		await jump(WorldContent.cell(far[2])+Vector2(0,5))
		check(decoration_draws>0 and game.world_view.environment_details.phase==0,region_id+" reduced motion redraws newly revealed scenery without swaying")
		game.world_view.set_reduced_motion(false)
		# Measure real authority steps separately from software-rendered frame rate.
		var begin := Time.get_ticks_usec()
		for i in range(180): sim.step(1.0/60)
		var authority_ms := (Time.get_ticks_usec()-begin)/1000.0
		var active := 0
		for actor in game.world_view.actors.values():
			if actor.is_processing(): active += 1
		region_metrics[region_id] = {"cells":WorldGrid.SIZE*WorldGrid.SIZE,"total_props":sim.world.props.size(),"resident_props":game.world_view.props.size(),"creatures":sim.mobs.size(),"active_actor_views":active,"authority_180_steps_ms":authority_ms}
		# Move to a discovered far gate and return through the real command.
		var gate: Dictionary = WorldContent.waypoints(region_id).back()
		await jump(WorldContent.cell(gate))
		check(gate["id"] in sim.journey.discovered,region_id+" far waypoint discovers on arrival")
		sim.combat_left = 0
		var result := sim.journey_command("waygate",{"id":"camp"})
		check(result["ok"] and sim.player["cell"] == WorldGrid.SPAWN,region_id+" far waypoint returns to village")
		game.flush_events()
		await settle()
		verify_stream(region_id+" after waygate")
		check(sim.world.is_safe(sim.player["cell"]),region_id+" arrival remains safe")
		await jump(WorldContent.cell(far.back())+Vector2(0,5))
		sim._respawn_player()
		game.flush_events()
		check(game.world_view.camera.position.distance_to(WorldGrid.project(WorldGrid.SPAWN)+Vector2(0,-24))<.1,region_id+" distant respawn snaps camera to the safe camp")
		check(game.world_view.ground._tile_window.has_point(Vector2i(WorldGrid.SPAWN)),region_id+" respawn terrain is resident in the same event")
		verify_stream(region_id+" after respawn")
	key(KEY_T)
	await settle()
	root.size = Vector2i(960,640)
	root.content_scale_size = root.size
	await settle()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.hud.cultivation_book.get_global_rect()),"Atlas remains in minimum PC viewport")
	await capture("atlas_960")
	var report := {"passed":checks.size()-failures,"failed":failures,"checks":checks,"captures":shots,"metrics":region_metrics}
	FileAccess.open("res://artifacts/world45_native.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("WORLD45_NATIVE ",checks.size()-failures,"/",checks.size()," ",region_metrics)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
