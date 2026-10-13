extends SceneTree
## Native integration evidence. --test-mode never touches the real profile.
var game: GameManager
var checks: Array[Dictionary] = []
var shots: Array[String] = []
var failures := 0

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	root.size = Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args():
		root.position = Vector2i(-1800,-1200)
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks.append({"name":label,"passed":value})
	if not value:
		failures += 1
		printerr("FAIL: ",label)

func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)

func buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(buttons(child))
	return found

func press_text(text: String) -> void:
	for button in buttons(game.hud.cultivation_book):
		if button.visible and button.text == text:
			click(button)
			return
	check(false,"Button exists: " + text)

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/expansion38_" + label + ".png"
	var error := root.get_texture().get_image().save_png(path)
	check(error == OK,"Native screenshot " + label)
	shots.append(path)

func settle() -> void:
	await process_frame
	await process_frame
	await create_timer(.28).timeout
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	var sim := game.simulation
	key(KEY_TAB)
	await settle()
	click(game.hud.bag_rows["gu_1"].feed_button)
	await process_frame
	check(int(sim.progress["feeds"]) == 1 and not game.hud.cultivation_open,"New HUD shortcut does not obscure inventory feed action")
	key(KEY_TAB)
	await settle()
	sim.move_to(Vector2(13,20))
	key(KEY_T)
	await settle()
	check(sim.player["path"].is_empty(),"Opening book cancels a previous click route")
	check(game.hud.cultivation_open and game.hud.cultivation_book.page == "travel","T opens travel book through real input")
	await capture("travel_locked_1280")
	key(KEY_G)
	await settle()
	check(game.hud.cultivation_open and game.hud.cultivation_book.page == "gu","G switches book page")
	key(KEY_1)
	check(sim.cooldowns[0] == 0,"Open cultivation book blocks skill keys")
	key(KEY_ESCAPE)
	await settle()
	check(not game.hud.has_open_window() and not game.paused,"Escape closes book before pausing")
	# Use real numeric casts to earn the first exploration unlock.
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999
	sim.mobs["wolf_0"].merge({"dead":false,"hp":140.0,"cell":Vector2(18,20)},true)
	sim.player["cell"] = Vector2(15,20)
	game.world_view.selected_id = "wolf_0"
	for i in range(4):
		key(KEY_1)
		await process_frame
		sim.cooldowns[0] = 0
	await process_frame
	print("CAST_FIXTURE kills=",sim.progress["kills"]," hp=",sim.mobs["wolf_0"]["hp"]," mana=",sim.player["mana"]," book=",game.hud.has_open_window())
	check(int(sim.progress["kills"]) == 1,"Four real casts earn first region unlock")
	sim.combat_left = 0
	sim.player["cell"] = WorldGrid.SPAWN
	key(KEY_T)
	await settle()
	press_text("Dịch chuyển")
	await settle()
	check(sim.expedition.region == "ruins" and game.world_view.ground.world.region == "ruins" and game.world_view.actors.size() == 6 and game.world_view.selected_id == "", "Travel button swaps map, population, target and closes modal")
	await capture("ruins_world_1280")
	# Fixture advances the two remaining encounters; economy rules remain authority commands.
	sim._damage_mob("wolf_0",999)
	sim._damage_mob("wolf_1",999)
	sim.player["cell"] = WorldGrid.SHRINE
	game.flush_events()
	key(KEY_T)
	await settle()
	game.hud.cultivation_book.scroll.scroll_vertical = 2000
	await settle()
	press_text("Phục hồi tại cổ trận • tốn 2 cổ tinh")
	await settle()
	check(sim.expedition.realm_unlocked,"Native unlock action creates realm")
	game.cultivate("travel",{"region":"realm"})
	await settle()
	check(sim.expedition.region == "realm" and game.world_view.actors.is_empty() and game.world_view.effects.actor_views.is_empty(),"Realm removes stale enemies and effect targets")
	sim.player["currency"] = 600
	key(KEY_H)
	await settle()
	check(game.hud.cultivation_book.page == "farm","H opens realm management")
	press_text("Gieo Linh thảo")
	await settle()
	press_text("Tưới nước • miễn phí")
	await settle()
	check(sim.expedition.plots[0]["watered"],"Live plot buttons plant then water")
	game.cultivate("plant",{"plot":1,"crop":"flower"})
	game.cultivate("water",{"plot":1})
	game.cultivate("plant",{"plot":2,"crop":"fruit"})
	game.cultivate("water",{"plot":2})
	game.cultivate("buy_animal",{"pen":0,"kind":"silkworm"})
	game.cultivate("buy_animal",{"pen":1,"kind":"hen"})
	game.cultivate("feed_animal",{"pen":0})
	game.cultivate("feed_animal",{"pen":1})
	await settle()
	await capture("farm_book_1280")
	key(KEY_ESCAPE)
	await settle()
	sim.player["cell"] = Vector2(13,19)
	game.world_view.player_view.bind(sim.player,true)
	sim.step(76)
	game.flush_events()
	await create_timer(.8).timeout
	await capture("realm_world_1280")
	# E collects a ready plot without opening a modal.
	sim.player["cell"] = ExpeditionModel.PLOTS[0]
	key(KEY_E)
	await process_frame
	check(int(sim.inventory.materials.get("herb",0)) == 4 and not game.hud.has_open_window(),"E harvests nearby mature crop")
	key(KEY_G)
	await settle()
	press_text("Nâng lên mức 2")
	await settle()
	check(int(sim.inventory.slot_gu(0).get("cultivation",1)) == 2,"Upgrade button changes actual Gu stats")
	sim.inventory.reward_material("herb",10)
	sim.inventory.reward_material("stone",10)
	sim.inventory.reward_material("essence",3)
	game.cultivate("collect_animal",{"pen":0})
	game.cultivate("upgrade",{"id":"gu_1"})
	sim.inventory.add_gu("GU-01")
	game.hud.cultivation_book.signature = ""
	game.hud.cultivation_book.refresh()
	await settle()
	game.hud.cultivation_book.scroll.scroll_vertical = 1000
	await settle()
	await capture("gu_recipe_1280")
	press_text("Hợp thành bậc 2")
	await settle()
	check(int(sim.inventory.slot_gu(0)["rank"]) == 2,"Visible fusion recipe consumes donor and raises rank")
	game.hud.cultivation_book.scroll.scroll_vertical = 0
	await settle()
	await capture("gu_rank2_1280")
	check(game.hud.skill_buttons[0].gu_rank == 2,"Hotbar shows actual Gu rank after fusion")
	# Native compact layouts; each page remains inside viewport and scrollable.
	root.size = Vector2i(960,640)
	root.content_scale_size = Vector2i(960,640)
	await settle()
	for page in ["travel","gu","farm"]:
		game.hud.cultivation_book.open_page(page)
		await settle()
		check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.hud.cultivation_book.get_global_rect()),"Book stays on screen at 960: " + page)
		check(game.hud.cultivation_book.content.size.x <= game.hud.cultivation_book.scroll.size.x,"No horizontal clipping at 960: " + page)
		await capture(page+"_960")
	key(KEY_ESCAPE)
	await settle()
	key(KEY_ESCAPE)
	await process_frame
	var timer_before := float(sim.expedition.plots[1]["left"])
	game._physics_process(5)
	check(game.paused and float(sim.expedition.plots[1]["left"]) == timer_before,"Pause stops farm clocks")
	key(KEY_ESCAPE)
	await settle()
	# Rank II skill frame is actual WorldEffects rendering.
	sim.player["cell"] = WorldGrid.SPAWN
	sim.travel("ruins")
	game.flush_events()
	sim.player["cell"] = Vector2(15,20)
	sim.mobs["wolf_0"].merge({"dead":false,"hp":185.0,"cell":Vector2(18,20)},true)
	game.world_view.selected_id = "wolf_0"
	sim.cooldowns[0] = 0
	sim.player["mana"] = 100
	await settle()
	game.use_skill(0)
	game.world_view.effects.set_process(false)
	for effect in game.world_view.effects.effects:
		effect["age"] = .22
	game.world_view.effects.queue_redraw()
	await capture("rank2_skill")
	check(float(sim.mobs["wolf_0"]["hp"]) < 140,"Rank II spell does more actual damage")
	game.world_view.set_reduced_motion(true)
	await capture("rank2_reduced_motion")
	var file := FileAccess.open("res://artifacts/expansion38_native.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"passed":checks.size()-failures,"failed":failures,"checks":checks,"screenshots":shots},"  "))
	file.close()
	game.queue_free()
	await process_frame
	print("CULTIVATION_NATIVE ",checks.size()-failures,"/",checks.size()," passed; ",shots.size()," screenshots")
	quit(1 if failures else 0)
