extends "res://tests/ui_style_visual_smoke.gd"
## Verify the new limb kit in world, alternate-outfit F3 and the live F6 studio.
func _run() -> void:
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	root.position=Vector2i(-1800,-1200)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro=false
	game.hud.toast_left=0
	game.hud.update_hud(0)
	var look := GuCharacterAppearance.default_data()
	game.simulation.player["appearance"]=look
	game.simulation.player["facing"]=WorldGrid.unproject(Vector2.DOWN)
	game.world_view.player_view._sync_character()
	await _capture("concept41_world_male")
	look=look.duplicate()
	look["body"]="female"
	look["outfit"]="crimson"
	look["boots"]="leather"
	look["weapon"]="spear"
	game.simulation.player["appearance"]=look
	game.simulation.player["facing"]=WorldGrid.unproject(Vector2.UP)
	game.world_view.player_view._sync_character()
	await _capture("concept41_world_female")
	game.hud.toggle_character()
	game.hud.character_doll.refresh_appearance()
	assert(game.hud.character_doll.avatar.visible,"Alternate appearance uses the new live limb renderer")
	await _capture("concept41_character_equipment")
	game.hud.toggle_character()
	game.hud.toggle_studio()
	await _capture("concept41_studio")
	game.hud.toggle_studio()
	var output := FileAccess.open("res://artifacts/concept41_ingame.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"captures":captures},"  "))
	output.close()
	game.queue_free()
	await process_frame
	quit()
