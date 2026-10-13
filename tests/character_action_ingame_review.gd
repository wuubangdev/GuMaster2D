extends "res://tests/world40_visual_smoke.gd"

var review_prefix := "concept42"
var north_capture := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument=="--facing-north": north_capture=true
		if argument.begins_with("--capture-prefix="):
			review_prefix=argument.trim_prefix("--capture-prefix=").validate_filename()
	super._initialize()

func capture(label: String, record_check: bool = true) -> void:
	# The fixture pauses automatic processing. Refresh the same streamed
	# terrain and content that normal gameplay updates after moving the camera.
	game.world_view.camera.force_update_scroll()
	game.world_view.ground._refresh_visible_tiles()
	game.world_view._refresh_visible_world()
	game.world_view.overland.queue_redraw()
	game.world_view.environment_details.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/"+review_prefix+"_"+label+".png"
	check(root.get_texture().get_image().save_png(path)==OK,"Native world capture "+label)
	shots.append(path)

func _run() -> void:
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.hud.showing_intro=false
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode=Node.PROCESS_MODE_DISABLED
	var actor: ActorView = game.world_view.player_view
	for region_id in ["forest","ruins"]:
		if region_id=="ruins":
			game.simulation.progress["kills"]=1
			game.simulation.player["cell"]=WorldGrid.SPAWN
			game.simulation.combat_left=0
			check(game.simulation.travel(region_id)["ok"],"Travel to mine fixture")
			game.flush_events()
		var resources := WorldContent.resources(region_id)
		var site: Dictionary = resources[0]
		if region_id=="ruins":
			for candidate in resources:
				if candidate["material"] in ["ore","stone"]: site=candidate; break
		await jump(WorldContent.cell(site)+(Vector2(0,.7) if north_capture else Vector2(-.7,.1)))
		actor.move_blend=0
		if region_id=="forest":
			game.simulation.player["facing"]=Vector2.DOWN
			for step in range(24): actor._process(1.0/60)
			game.world_view.camera.zoom=Vector2.ONE
			game.world_view.camera.force_update_scroll()
			await capture("world_front")
		game.world_view.camera.zoom=Vector2(2,2)
		var before: int = game.simulation.inventory.materials.get(site["material"],0)
		key(KEY_E)
		await process_frame
		var expected := "gather" if region_id=="forest" else "mine"
		check(actor.action==expected and actor.action_left>0,"Real E input starts "+expected)
		check(int(game.simulation.inventory.materials[site["material"]])==before+int(site["yield_count"]),"Real E rewards once")
		var serial := actor.action_serial
		key(KEY_E)
		await process_frame
		check(actor.action_serial==serial,"Denied E repeat does not restart animation")
		game.hud.toast_queue.clear()
		game.hud.toast_left=0
		game.hud.toast_label.text=""
		var duration := actor.action_duration
		for frame in range(1,61):
			actor._process(duration/60)
			game.world_view.effects._process(duration/60)
			if frame in [17,30,45]:
				game.hud.update_hud(0)
				await capture("world_"+expected+"_%02d" % frame)
		check(actor.action_left<.0001,"Work action finishes without leaving a tool equipped")
		actor._process(.02)
		check(actor.character_view.current_action=="idle","Work returns to idle")
	key(KEY_F6)
	await process_frame
	var studio: GuCharacterStudio = game.hud.character_studio
	check(studio.visible,"F6 opens the character studio")
	studio.playing=false
	studio._select_action(GuCharacterStudio.ACTIONS.find("mine"))
	studio.playhead=GuCharacterAnimations.duration("mine")*.30
	studio._present(0)
	await capture("studio_mine")
	var output := FileAccess.open("res://artifacts/"+review_prefix+"_ingame.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"captures":shots},"  "))
	print("ACTION_INGAME ",checks.size()-failures,"/",checks.size())
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
