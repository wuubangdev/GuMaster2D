extends SceneTree
## Real native input for dialogue, quests and window flow. Later-region fixtures skip combat time.
var game: GameManager
var checks: Array[Dictionary] = []
var shots: Array[String] = []
var failures := 0

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	root.size = Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position = Vector2i(-1800,-1200)
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

func click_point(point: Vector2) -> void:
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
	if node is Button: found.append(node)
	for child in node.get_children(): found.append_array(buttons(child))
	return found

func press_text(text: String, within: Node = null) -> void:
	for button in buttons(game.hud.dialogue if within == null else within):
		if button.is_visible_in_tree() and button.text == text:
			# Reveal offscreen rows using the actual scroll viewport before clicking.
			var parent: Node = button.get_parent()
			while parent != null:
				if parent is ScrollContainer: parent.ensure_control_visible(button)
				parent = parent.get_parent()
			await process_frame
			click_point(button.get_global_rect().get_center())
			await settle()
			return
	check(false,"Button exists: " + text)

func settle() -> void:
	await process_frame
	await create_timer(.3).timeout
	await process_frame

func capture(label: String, record_check: bool = true) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/world40_" + label + ".png"
	var result := root.get_texture().get_image().save_png(path)
	if record_check: check(result == OK,"Native capture " + label)
	shots.append(path)

func at(id: String) -> void:
	game.simulation.player["cell"] = QuestCatalog.cell(id) + Vector2(.7,-1.2)
	game.simulation.combat_left = 0
	game.world_view.player_view.bind(game.simulation.player,true)
	await settle()

func travel(region: String) -> void:
	game.simulation.player["cell"] = WorldGrid.SPAWN
	game.simulation.combat_left = 0
	check(bool(game.simulation.travel(region)["ok"]),"Travel fixture to " + region)
	game.flush_events()
	await settle()

func jump(cell: Vector2) -> void:
	game.simulation.stop_navigation()
	game.simulation.player["cell"] = cell
	game.simulation.combat_left = 0
	game.world_view.player_view.bind(game.simulation.player,true)
	game.world_view._camera_follow = WorldGrid.project(cell)+Vector2(0,-24)
	game.world_view.camera.position = game.world_view._camera_follow
	game.world_view.camera.force_update_scroll()
	game.hud.toast_queue.clear()
	game.hud.toast_left = 0
	game.hud.toast_label.text = ""
	game.world_view.selected_id = ""
	game.simulation._discover_locations()
	game.flush_events()
	await settle()
func grant_prerequisites(id: String) -> void:
	for requirement in QuestCatalog.quest(id)["requires"]: grant_prerequisites(requirement)
	if id not in game.simulation.quests.accepted: game.simulation.quests.accepted.append(id)
	if id not in game.simulation.quests.claimed: game.simulation.quests.claimed.append(id)
	game.simulation.quests.revision += 1
func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	var sim := game.simulation
	check(not game.world_view.overland.water_cells.is_empty(),"Continuous river renderer follows colliding water cells")
	check(game.world_view.actors.size() == Bestiary.population(sim.expedition.region).size()+6 and game.world_view.npcs.size() == 3,"Expanded forest boots with all actors")
	check(not game.world_view.actors["f_thunder_0"].is_processing(),"Distant elite renderer sleeps")
	await capture("village")
	key(KEY_T)
	await settle()
	check(game.hud.cultivation_open and game.hud.cultivation_book.regional_atlas != null,"T opens regional atlas")
	var book := game.hud.cultivation_book
	await capture("forest_atlas")
	root.size = Vector2i(960,640)
	root.content_scale_size = Vector2i(960,640)
	await settle()
	check(Rect2(Vector2.ZERO,Vector2(960,640)).encloses(book.get_global_rect()) and book.content.size.x <= book.scroll.size.x,"Atlas fits minimum supported viewport without horizontal overflow")
	await capture("atlas_960")
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	await settle()
	click_point(book.regional_atlas.global_position+book.regional_atlas.project(Vector2(38,20)))
	await settle()
	check(book.atlas_go.size.x >= GuPixelUI.HAND_FONT.get_string_size(book.atlas_go.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+14,"Atlas button labels fit custom ink font")
	check(book.regional_atlas.selected == "f_bamboo" and "Rơi:" in book.atlas_info.text,"Native atlas click selects camp and shows drops")
	await press_text("Dẫn đường tới điểm đã chọn",book)
	check(not game.hud.cultivation_open and not sim.player["path"].is_empty() and sim.player["path"].back() == Vector2(38,20),"Atlas navigation requests real authority path to distant camp")
	await jump(Vector2(38,25))
	check(game.world_view.actors["f_bamboo_0"].is_processing() and game.world_view.actors["f_bamboo_0"].visible,"Nearby camp renderers wake at current position")
	await capture("bamboo")
	var target_id := "f_bamboo_3"
	var target_hp: float = sim.mobs[target_id]["hp"]
	click_point(game.world_view.cell_to_screen(sim.mobs[target_id]["cell"])+Vector2(0,-26))
	await process_frame
	key(KEY_1)
	await settle()
	check(game.world_view.selected_id == target_id and sim.mobs[target_id]["hp"] < target_hp,"Native click and numeric skill damage a new camp creature")
	sim.combat_left = 0
	await capture("wild_combat")
	# Real keyboard movement in expanded world.
	var origin: Vector2 = sim.player["cell"]
	var event := InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	sim.step(.2)
	event = InputEventKey.new()
	event.physical_keycode = KEY_D
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	check(Vector2(sim.player["cell"]).x > origin.x and sim.movement_direction == Vector2.ZERO,"WASD works and releases in enlarged map")
	var resource: Dictionary = WorldContent.resources("forest")[0]
	await jump(WorldContent.cell(resource))
	var quantity := int(sim.inventory.materials.get(resource["material"],0))
	key(KEY_E)
	await settle()
	check(sim.inventory.materials[resource["material"]] == quantity+2 and not game.hud.dialogue_open,"E gathers resources in the field")
	await capture("gather")
	grant_prerequisites("arrival")
	await jump(QuestCatalog.cell("trac_su")+Vector2(0,.7))
	key(KEY_E)
	await settle()
	check(game.hud.dialogue_open and game.hud.dialogue.npc_id == "trac_su","Remote hunter opens real dialogue")
	game.hud.dialogue.reveal = 100000
	await capture("hunter_dialogue")
	await press_text("Nhận nhiệm vụ • Lương thực của thương đội")
	await press_text("Nhận nhiệm vụ")
	check("boar_supply" in sim.quests.accepted,"NPC mouse dialogue accepts a new side quest")
	key(KEY_ESCAPE)
	key(KEY_F11)
	await settle()
	if not game.hud.npc_journal_open: await press_text("Nhiệm vụ NPC",game.hud.journal_panel)
	await press_text("Nhiệm vụ phụ",game.hud.npc_quest_list)
	check(game.hud.npc_quest_list.category == "side","Journal filter selects side quests")
	await capture("side_quests")
	await press_text("Tìm Dốc Hắc Mao",game.hud.npc_quest_list)
	check(not game.hud.journal_open and not sim.player["path"].is_empty() and sim.player["path"].back() == Vector2(62,16),"Active delivery quest routes to its farm camp instead of NPC")
	# Native captures show each anatomy at its authored camp, without changing original player art.
	for camp_id in ["f_boars","f_spiders","f_honey","f_thunder"]:
		var camp := WorldContent.location(camp_id)
		await jump(WorldContent.cell(camp)+Vector2(2,2))
		await capture(camp_id)
	# Charge telegraph and impact sample, with authority stepping and render frames.
	var mob: Dictionary = sim.mobs["f_thunder_0"]
	await jump(Vector2(mob["cell"])+Vector2(3,0))
	WildlifeAI.step(sim,"f_thunder_0",.01)
	game.flush_events()
	await capture("charge_warning")
	var health: float = sim.player["hp"]
	sim.player["cell"] += Vector2(0,3)
	WildlifeAI.step(sim,"f_thunder_0",1.3)
	game.flush_events()
	check(sim.player["hp"] == health,"Native charge fixture dodges the telegraphed lane")
	await capture("charge_impact")
	grant_prerequisites("bamboo_chart")
	await jump(Vector2(32,32))
	key(KEY_T)
	await settle()
	book.atlas_selection = "camp"
	book.signature = ""
	book.refresh()
	await settle()
	var money: int = sim.player["currency"]
	await press_text("Dịch chuyển nội vùng • 5 bạc",book)
	check(sim.player["cell"] == WorldGrid.SPAWN and sim.player["currency"] == money-5 and not game.hud.cultivation_open,"Native waypoint button travels and charges once")
	sim.progress["kills"] = 4
	key(KEY_T)
	await settle()
	await press_text("Sang vùng khác • Cổ trận",book)
	await capture("region_routes")
	await press_text("Dịch chuyển",book)
	check(sim.expedition.region == "ruins" and game.world_view.actors.size() == Bestiary.population(sim.expedition.region).size()+6,"Native route button loads expanded ruins")
	await settle()
	for camp_id in ["r_mine","r_marsh","r_guardian"]:
		await jump(WorldContent.cell(WorldContent.location(camp_id))+Vector2(2,2))
		await capture(camp_id)
	key(KEY_T)
	await settle()
	await press_text("Trong vùng • Bãi farm & trạm",book)
	await capture("ruins_atlas")
	key(KEY_ESCAPE)
	sim.expedition.realm_unlocked = true
	await travel("realm")
	check(sim.mobs.size() == Bestiary.population("realm").size() and sim.world.is_safe(Vector2(18,18)),"Expanded realm retains protected farm")
	await capture("realm_farm")
	await jump(WorldContent.cell(WorldContent.location("b_flowers"))+Vector2(2,2))
	await capture("realm_flowers")
	await jump(QuestCatalog.cell("linh_nha")+Vector2(0,.7))
	key(KEY_E)
	await settle()
	check(game.hud.dialogue_open and game.hud.dialogue.npc_id == "linh_nha","Realm wilderness NPC is reachable and interactive")
	await capture("realm_dialogue")
	key(KEY_ESCAPE)
	key(KEY_T)
	await settle()
	await capture("realm_atlas")
	key(KEY_ESCAPE)
	grant_prerequisites("antidote")
	sim.inventory.reward_material("herb",2)
	sim.inventory.reward_material("nectar",1)
	sim.player["hp"] = 60.0
	key(KEY_R)
	await settle()
	check(sim.player["hp"] > 60 and sim.journey.medicine_left == 15,"R activates quest-unlocked medicine through real input")
	grant_prerequisites("seal_breach")
	await jump(WorldGrid.SPAWN)
	sim.inventory.reward_material("herb_seed",3)
	sim.cultivation_command("plant",{"plot":0,"crop":"herb"})
	sim.cultivation_command("plant",{"plot":1,"crop":"herb"})
	key(KEY_H)
	await settle()
	await press_text("Tưới toàn bộ linh điền",book)
	check(sim.expedition.plots[0]["watered"] and sim.expedition.plots[1]["watered"],"Native farm action uses quest-unlocked irrigation")
	await capture("irrigation")
	check(game.test_mode,"Test game never accesses player profile")
	var file := FileAccess.open("res://artifacts/world40_native.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"shots":shots,"fixtures":"Position/progression fixtures skip travel and combat duration. Controls use actual input; player save disabled."},"  "))
	print("WORLD40_NATIVE ",checks.size()-failures,"/",checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
