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
	var path := "res://artifacts/quests39_" + label + ".png"
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

func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	var sim := game.simulation
	check(game.world_view.npcs.size() == 2 and game.world_view.landmarks.size() == 3,"Forest has two animated NPCs and three landmarks")
	await capture("forest")
	# E at the portal must still open travel, even with an NPC nearby.
	sim.player["cell"] = WorldGrid.SPAWN
	key(KEY_E)
	await settle()
	check(game.hud.cultivation_open and not game.hud.dialogue_open,"Portal E remains travel")
	key(KEY_ESCAPE)
	await at("lam_an")
	var npc: NpcView = game.world_view.npcs["lam_an"]
	check(npc.marker == "!" and npc.prompt_visible,"Mentor offers first quest and matching E prompt")
	var pivot := npc.position
	var idle_pose: Dictionary = npc.character.capture_pose()["source_pose"]
	await create_timer(.4).timeout
	check(npc.animation_samples > 3 and idle_pose != npc.character.capture_pose()["source_pose"],"Idle rig changes pose over time")
	sim.move_to(Vector2(11,19))
	key(KEY_E)
	await settle()
	check(game.hud.dialogue_open and game.world_view.active_npc == "lam_an" and sim.player["path"].is_empty(),"Real E opens mentor dialogue and stops route")
	key(KEY_1)
	key(KEY_W)
	check(sim.cooldowns[0] == 0 and sim.movement_direction == Vector2.ZERO and game.input_controller.held_movement.is_empty(),"Dialogue blocks numeric casting and movement")
	check(game.hud.dialogue.speech.visible_characters > 0 and game.hud.dialogue.speech.visible_characters < game.hud.dialogue.speech.get_total_character_count(),"Dialogue reveals text progressively")
	click_point(game.hud.dialogue.speech.get_global_rect().get_center())
	await process_frame
	check(game.hud.dialogue.speech.visible_characters >= game.hud.dialogue.speech.get_total_character_count() or game.hud.dialogue.speech.visible_characters == -1,"Click reveals entire speech")
	await capture("mentor_dialogue")
	await press_text(str(QuestCatalog.npc("lam_an")["topics"][0]["label"]))
	check(game.hud.dialogue.current_topic == 0 and game.hud.dialogue.speech.text == QuestCatalog.npc("lam_an")["topics"][0]["text"],"Lore option shows authored response")
	await press_text("Tôi còn muốn hỏi…")
	await press_text("Nhận nhiệm vụ • Lời dặn dưới đèn")
	await press_text("Nhận nhiệm vụ")
	check("arrival" in sim.quests.accepted and sim.quests.tracked == "arrival","Mouse option accepts and tracks actual quest")
	game.hud.dialogue.reveal = 100000
	await capture("quest_accepted")
	var talk_pose: Dictionary = npc.character.capture_pose()["source_pose"]
	game.hud.root.hide()
	game.world_view.desired_zoom = 3
	await settle()
	for frame in range(24):
		await create_timer(.1).timeout
		await capture("talk_%02d" % frame,false)
	game.world_view.desired_zoom = 2
	game.hud.root.show()
	await settle()
	check(npc.position == pivot and talk_pose != npc.character.capture_pose()["source_pose"],"Talk animation changes articulated pose with stable feet pivot")
	key(KEY_ESCAPE)
	await settle()
	check(not game.hud.dialogue_open and not game.paused and not npc.talking,"Esc ends dialogue and actor talk state")
	key(KEY_F11)
	await settle()
	check(game.hud.journal_open and game.hud.npc_journal_open,"F11 selects NPC journal after accepting quest")
	await capture("journal")
	await press_text("Khảo nghiệm cũ",game.hud.journal_panel)
	check(not game.hud.npc_journal_open and game.hud.journal_track.is_visible_in_tree(),"Legacy trial remains accessible")
	await press_text("Nhiệm vụ NPC",game.hud.journal_panel)
	await press_text("Tìm Yên Chi",game.hud.journal_panel)
	check(not game.hud.journal_open and not sim.player["path"].is_empty(),"Quest journal starts route to objective NPC")
	sim.stop_navigation()
	await at("yen_chi")
	var screen := game.world_view.cell_to_screen(QuestCatalog.cell("yen_chi")) + Vector2(0,-34)*game.world_view.camera.zoom
	click_point(screen)
	await settle()
	check(game.hud.dialogue_open and game.hud.dialogue.npc_id == "yen_chi" and sim.quests.ready("arrival",sim),"Actual NPC click opens herbalist and credits talk objective")
	game.hud.dialogue.reveal = 100000
	await capture("herbalist_dialogue")
	key(KEY_TAB)
	await settle()
	check(game.hud.bag_open and not game.hud.dialogue_open and game.world_view.active_npc == "","Opening inventory closes dialogue cleanly")
	key(KEY_ESCAPE)
	await at("lam_an")
	check(npc.marker == "?","Ready quest replaces offer with turn-in marker")
	key(KEY_E)
	await settle()
	await press_text("Trả nhiệm vụ • Lời dặn dưới đèn")
	var silver := int(sim.player["currency"])
	await press_text("Hoàn thành & nhận thưởng")
	check("arrival" in sim.quests.claimed and int(sim.player["currency"]) == silver+35,"Native turn-in pays one reward and advances quest line")
	game.hud.dialogue.reveal = 100000
	await capture("quest_reward")
	await press_text("Nhận nhiệm vụ • Giữ lối về trại")
	await press_text("Nhận nhiệm vụ")
	# Live readiness refresh: complete the two kills while inspecting objective.
	sim.progress["kills"] = 2
	await settle()
	check(buttons(game.hud.dialogue).any(func(b: Button): return b.text == "Hoàn thành & nhận thưởng"),"Visible objective refreshes when progress becomes ready")
	await press_text("Hoàn thành & nhận thưởng")
	key(KEY_ESCAPE)
	# Conversation auto-closes if a future teleport/network correction removes access.
	key(KEY_E)
	await settle()
	sim.player["cell"] = Vector2(16,20)
	await settle()
	check(not game.hud.dialogue_open and game.world_view.active_npc == "","Moving out of conversation range closes dialogue")
	game.talk_to_npc("yen_chi")
	check(not game.hud.dialogue_open,"Far conversation denied")
	await travel("ruins")
	check(game.world_view.npcs.keys() == ["tham_nghi"] and game.world_view.landmarks.size() == 2,"Region switch removes forest actors and installs ruins NPC")
	await at("tham_nghi")
	await capture("ruins")
	key(KEY_E)
	await settle()
	await press_text("Nhận nhiệm vụ • Dấu ấn thất lạc")
	await press_text("Nhận nhiệm vụ")
	game.hud.dialogue.reveal = 100000
	await capture("ruins_dialogue")
	key(KEY_ESCAPE)
	# Realm fixture: underlying unlock economy is covered by quest_tests and cultivation_tests.
	sim.expedition.realm_unlocked = true
	await travel("realm")
	check(game.world_view.npcs.keys() == ["moc_mien"] and game.world_view.actors.is_empty(),"Realm has gardener and no enemies or stale NPCs")
	await at("moc_mien")
	key(KEY_E)
	await settle()
	await press_text("Trả nhiệm vụ • Dấu ấn thất lạc")
	await press_text("Hoàn thành & nhận thưởng")
	await press_text("Nhận nhiệm vụ • Gieo lại linh mạch")
	await press_text("Nhận nhiệm vụ")
	check("lost_seal" in sim.quests.claimed and "first_harvest" in sim.quests.accepted,"Cross-region turn-in opens first farming quest")
	game.hud.dialogue.reveal = 100000
	await capture("gardener_dialogue")
	root.size = Vector2i(960,640)
	root.content_scale_size = Vector2i(960,640)
	await settle()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.hud.dialogue.get_global_rect()),"Dialogue fits minimum 960 by 640 viewport")
	check(game.hud.dialogue.options.size.x <= game.hud.dialogue.options.get_parent().size.x,"Dialogue options have no horizontal overflow")
	await capture("dialogue_960")
	key(KEY_F11)
	await settle()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.hud.journal_panel.get_global_rect()) and game.hud.npc_quest_list.content.size.x <= game.hud.npc_quest_list.size.x,"NPC journal fits minimum viewport with vertical scrolling")
	await capture("journal_960")
	key(KEY_ESCAPE)
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	await settle()
	sim.inventory.reward_material("herb_seed",1)
	sim.cultivation_command("plant",{"plot":0,"crop":"herb"})
	sim.cultivation_command("water",{"plot":0})
	sim.inventory.reward_material("fruit",2)
	sim.cultivation_command("buy_animal",{"pen":0,"kind":"silkworm"})
	sim.cultivation_command("feed_animal",{"pen":0})
	sim.expedition.step(20)
	game.flush_events()
	sim.player["cell"] = Vector2(12,19)
	game.world_view.player_view.bind(sim.player,true)
	await create_timer(.8).timeout
	await capture("realm")
	# Inspect landmark occlusion and reduced-motion ownership.
	var landmark: StoryLandmark = game.world_view.landmarks[0]
	sim.player["cell"] = WorldGrid.unproject(landmark.position+Vector2(0,-20))
	await create_timer(.4).timeout
	check(landmark.modulate.a < .5,"Foreground landmark fades when obscuring player")
	await at("moc_mien")
	key(KEY_E)
	await settle()
	game.world_view.set_reduced_motion(true)
	game.hud.set_reduced_motion(true)
	await settle()
	var gardener: NpcView = game.world_view.npcs["moc_mien"]
	var frozen_phase := gardener.phase
	var frozen_pose: Dictionary = gardener.character.capture_pose()["source_pose"]
	await create_timer(.5).timeout
	check(gardener.phase == frozen_phase and gardener.character.capture_pose()["source_pose"] == frozen_pose and game.world_view.environment_details.phase == 0 and game.hud.dialogue.speech.visible_characters == -1,"Reduced motion freezes NPC/environment and reveals full speech")
	await capture("reduced_motion")
	key(KEY_ESCAPE)
	game.world_view.set_reduced_motion(false)
	game.hud.set_reduced_motion(false)
	# Nearest interaction prompt and E share the exact target resolver.
	for point in [Vector2(11.8,20),Vector2(15.8,21),ExpeditionModel.PLOTS[0]]:
		sim.player["cell"] = point
		await settle()
		check(gardener.prompt_visible == (sim.interaction_npc() == "moc_mien"),"E prompt matches interaction priority at " + str(point))
	var file := FileAccess.open("res://artifacts/quests39_native.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"passed":checks.size()-failures,"failed":failures,"checks":checks,"screenshots":shots,"fixtures":"Real E/mouse/input for first quest and UI; later combat/unlock time skipped via fixtures, authority chain tested separately."},"  "))
	file.close()
	game.queue_free()
	await process_frame
	print("QUEST_NATIVE ",checks.size()-failures,"/",checks.size()," passed; ",shots.size()," screenshots")
	quit(1 if failures else 0)
