extends SceneTree
var files: Array[String] = []
var results: Array[Dictionary] = []
var failures := 0
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	root.size = Vector2i(1280,800)
	root.position = Vector2i(-1800,-1200)
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280,800)
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_physics_process(false)
	var sim := game.simulation
	sim.progress["kills"] = 1
	sim.travel("ruins")
	game.flush_events()
	for mob in sim.mobs.values():
		mob["dead"] = true
	for rank_value in [1,2]:
		for slot in range(4):
			sim.player["cell"] = Vector2(15,20)
			sim.player["mana"] = 100
			sim.mobs["wolf_0"].merge({"dead":false,"hp":185.0,"cell":Vector2(18,20)},true)
			sim.inventory.slot_gu(slot)["rank"] = rank_value
			sim.cooldowns[slot] = 0
			game.world_view.selected_id = "wolf_0"
			game.world_view.effects.effects.clear()
			game.world_view.effects.set_process(true)
			game.world_aim = Vector2(16.5,20)
			game.has_world_aim = true
			game.pointer_in_world = false
			game.world_view.player_view.bind(sim.player,true)
			game.world_view.camera.position = WorldGrid.project(sim.player["cell"]) + Vector2(0,-24)
			await create_timer(.25).timeout
			game.use_skill(slot)
			game.world_view.effects.set_process(false)
			var kind: String = ["cast_moon","shield","dash","cast_frost"][slot]
			var valid := game.world_view.effects.effects.any(func(event: Dictionary): return event["kind"] == kind and int(event.get("rank",0)) == rank_value)
			results.append({"kind":kind,"rank":rank_value,"accepted_with_rank":valid})
			if not valid:
				failures += 1
			for effect in game.world_view.effects.effects:
				effect["age"] = .18
			game.world_view.effects.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://artifacts/expansion38_fx_%s_rank%d.png" % [kind,rank_value]
			if root.get_texture().get_image().save_png(path) != OK:
				failures += 1
			files.append(path)
			game.world_view.set_reduced_motion(true)
			await process_frame
			await RenderingServer.frame_post_draw
			path = "res://artifacts/expansion38_fx_%s_rank%d_reduced.png" % [kind,rank_value]
			if root.get_texture().get_image().save_png(path) != OK:
				failures += 1
			files.append(path)
			game.world_view.set_reduced_motion(false)
	var file := FileAccess.open("res://artifacts/expansion38_fx.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed":failures,"cases":results,"screenshots":files},"  "))
	file.close()
	game.queue_free()
	await process_frame
	print("CULTIVATION_FX ",results.size()," cases; ",files.size()," screenshots; failures=",failures)
	quit(1 if failures else 0)
