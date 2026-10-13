class_name GameManager
extends Node2D

const STEP: float = 0.05
const ERRORS: Dictionary = {
	"DEAD": "Đang trọng thương, chờ hồi sinh.",
	"BAD_SITE":"Điểm tương tác không hợp lệ ở vùng này.", "SITE_TOO_FAR":"Lại gần nguồn tài nguyên rồi nhấn E.",
	"RESOURCE_RESTING":"Nguồn tài nguyên đang hồi lại.", "NEED_WAYGATES":"Hoàn thành Đường qua rừng trúc để dùng trạm nội vùng.",
	"SITE_UNDISCOVERED":"Cần đi đến trạm để ghi dấu lần đầu.", "ALREADY_HERE":"Bạn đang ở điểm này.",
	"NEED_MEDICINE":"Hoàn thành Dược phương đường xa để dùng R.", "FULL_HEALTH":"Sinh lực đã đầy.", "MEDICINE_COOLDOWN":"Dược phương cần hồi lại trong 15 giây.",
	"NEED_IRRIGATION":"Hoàn thành Khơi lại dòng Thanh Nang để mở linh mương.", "NO_DRY_PLOTS":"Không có luống đã gieo nào cần tưới.",
	"NPC_UNAVAILABLE": "NPC không ở vùng này.", "NPC_TOO_FAR": "Lại gần NPC rồi nhấn E hoặc click để trò chuyện.",
	"BAD_QUEST": "Nhiệm vụ không hợp lệ.", "QUEST_UNAVAILABLE": "Nhiệm vụ đã nhận hoặc chưa đủ điều kiện mở.",
	"QUEST_NOT_READY": "Chưa đủ mục tiêu, đã nhận thưởng hoặc chưa gặp đúng người trả nhiệm vụ.",
	"IN_COMBAT": "Chờ hết giao chiến hoặc phong ấn trước khi thực hiện.",
	"AT_PORTAL": "Đến trại ngọc hoặc cổ trận để dịch chuyển.", "BAD_REGION": "Bạn đã ở vùng này hoặc vùng không tồn tại.",
	"NEED_FIRST_KILL": "Hạ 1 sói để mở đường đến Tam Vương Cổ Địa.", "REALM_LOCKED": "Phục hồi cổ trận Tam Vương Cổ Địa để mở bí cảnh.",
	"AT_RUIN_SHRINE": "Đến cổ trận trung tâm Tam Vương Cổ Địa để phục hồi ấn.", "NEED_TRIAL": "Cần hạ tổng cộng 3 sói để phục hồi ấn.",
	"NEED_MATERIALS": "Chưa đủ nguyên liệu hoặc bạc; xem số có/cần trong công thức.",
	"AT_CAMP": "Về trại, trạm nghỉ hoặc bí cảnh để luyện Cổ và chế tạo.", "AT_REALM": "Về Thanh Nang Bí Cảnh để chăm sóc điền viên.",
	"MAX_CULTIVATION": "Cổ đã đạt mức tu luyện 5.", "MAX_RANK": "Cổ đã đạt bậc III.",
	"NEED_CULTIVATION": "Tu luyện Cổ đến mức yêu cầu trước khi hợp thành.",
	"NEED_DONOR": "Cần một Cổ dự trữ bậc I cùng loại. Cổ trang bị không thể dùng làm phôi.",
	"ALREADY_UNLOCKED": "Bí cảnh đã mở.", "BAD_RECIPE": "Công thức không hợp lệ.",
	"BAD_PLOT": "Ô đất/chuồng không phù hợp với thao tác này.", "NO_SEED": "Hết hạt giống; mua thêm trong bảng Bí cảnh.",
	"ALREADY_WATERED": "Cây đã được tưới, hãy chờ lớn.", "ALREADY_FED": "Thú đã ăn, hãy chờ sản vật.", "NOT_READY": "Sản vật chưa sẵn sàng thu hoạch.", "BAD_PATH": "Vị trí bị chặn. Chọn một ô trống.",
	"NO_PATH": "Không có đường tới đó.", "BAD_SLOT": "Kỹ năng không hợp lệ.",
	"HUNGRY": "Cổ đã đói. Mở túi [Tab] để cho ăn.", "COOLDOWN": "Cổ đang hồi chiêu.",
	"NO_MANA": "Không đủ chân nguyên.", "NO_TARGET": "Click chọn một mục tiêu trước.",
	"OUT_OF_RANGE": "Mục tiêu ngoài tầm. Di chuyển lại gần.", "NO_LOS": "Vật cản che mục tiêu.",
	"SAFE_ZONE": "Rời vòng trại an toàn để chiến đấu.", "HP_TOO_HIGH": "Hạ HP mục tiêu xuống ≤30% trước khi bắt.",
	"NO_SEAL": "Hết phong ấn. Hạ sói hoặc chế tạo trong túi.", "BAG_FULL": "Túi đầy; cần chỗ cho Cổ hoặc vật phẩm mới.",
	"CAPTURING": "Đang phong ấn mục tiêu.", "WRONG_FOOD": "Thức ăn không phù hợp.",
	"BAD_APPEARANCE": "Diện mạo không hợp lệ.", "FULL_HUNGER": "Cổ đã no.", "NO_FOOD": "Không đủ thức ăn.",
	"VERSION_CONFLICT": "Túi vừa thay đổi, hãy thử lại.", "NOT_OWNED": "Không tìm thấy Cổ trong túi.",
	"INVALID_REQUEST": "Thao tác không hợp lệ; hãy chọn lại vật phẩm.", "REQUEST_CONFLICT": "Thao tác đã được xử lý với thông tin khác; hãy thử lại."
}
var simulation: LocalAuthority
var world_view: WorldView
var hud: GameHUD
var sounds: SoundLayer
var input_controller: GameInputController
var save_store := SaveStore.new()
var paused: bool = false
var accumulator: float = 0.0
var autosave_left: float = 10.0
var test_mode: bool = false
var save_failed: bool = false
var request_serial: int = 0
var cursor_screen: Vector2 = Vector2.ZERO
var world_aim: Vector2 = Vector2.ZERO
var has_world_aim: bool = false
var pointer_in_world: bool = false
var preview_held: bool = false
var preferred_window_size := Vector2i(1280, 800)
var preferred_fullscreen := false

func _ready() -> void:
	test_mode = "--test-mode" in OS.get_cmdline_user_args()
	simulation = LocalAuthority.new(74021, true)
	if not test_mode:
		var saved := save_store.load_profile()
		if not saved.is_empty() and not simulation.load_profile(saved):
			push_warning("Profile validation failed; starting teaching sandbox.")
	world_view = WorldView.new()
	add_child(world_view)
	world_view.setup(simulation)
	hud = GameHUD.new()
	add_child(hud)
	hud.setup(simulation, world_view)
	hud.skill_requested.connect(use_skill)
	hud.feed_requested.connect(feed)
	hud.pause_requested.connect(toggle_pause)
	hud.mute_requested.connect(toggle_mute)
	hud.motion_requested.connect(toggle_motion)
	hud.volume_requested.connect(set_audio_volume)
	hud.display_requested.connect(set_display)
	hud.inventory_move_requested.connect(move_inventory_entry)
	hud.inventory_discard_requested.connect(discard_inventory_entry)
	hud.inventory_craft_requested.connect(craft_inventory_item)
	hud.inventory_seal_requested.connect(use_inventory_seal)
	hud.appearance_requested.connect(apply_appearance)
	hud.cultivation_requested.connect(cultivate)
	hud.dialogue_requested.connect(dialogue_action)
	hud.dialogue_closed.connect(func(): world_view.talk_to_npc(""))
	hud.npc_quest_requested.connect(npc_quest_action)
	sounds = SoundLayer.new()
	add_child(sounds)
	hud.set_audio_volume(sounds.volume)
	_load_preferences()
	input_controller = GameInputController.new()
	input_controller.manager = self
	add_child(input_controller)
	hud.gameplay_window_opened.connect(_on_gameplay_window_opened)
	get_tree().auto_accept_quit = false
	cursor_screen = get_viewport().get_mouse_position()
	_capture_if_requested.call_deferred()

func _physics_process(delta: float) -> void:
	if input_controller != null:
		input_controller.update_movement()
	if paused or simulation == null:
		return
	accumulator += delta
	while accumulator >= STEP:
		simulation.step(STEP)
		accumulator -= STEP
	flush_events()
	autosave_left -= delta
	if autosave_left <= 0.0:
		autosave_left = 10.0
		persist()

func _process(delta: float) -> void:
	if hud != null:
		hud.update_hud(delta)
		update_targeting()
		if hud.dialogue_open and not bool(simulation.can_talk(hud.dialogue.npc_id)["ok"]):
			hud.close_dialogue()

func remember_world_pointer(point: Vector2) -> void:
	pointer_in_world = true
	world_aim = world_view.screen_to_cell(point)
	has_world_aim = true

func aim_point() -> Vector2:
	if pointer_in_world:
		return world_view.screen_to_cell(cursor_screen)
	if has_world_aim:
		return world_aim
	return Vector2(simulation.player["cell"]) + Vector2(simulation.player["facing"]).normalized() * 3.0

func update_targeting() -> void:
	var active := not paused and not hud.has_open_window() and not bool(simulation.player["dead"])
	if active and pointer_in_world:
		remember_world_pointer(cursor_screen)
	var slot := hud.hovered_skill if hud.hovered_skill >= 0 else (2 if preview_held else -1)
	if not active:
		slot = -1
	var point := aim_point()
	var probe := simulation.preview_cast(slot, world_view.selected_id, point) if slot >= 0 else {}
	var overlay := world_view.targeting
	overlay.visible = active
	overlay.slot = slot
	overlay.probe = probe
	overlay.cursor_cell = point
	overlay.show_pointer = active and pointer_in_world
	overlay.hovered_id = world_view.pick_mob(cursor_screen) if active and pointer_in_world else ""
	overlay.selected_id = world_view.selected_id
	hud.update_skill_detail(slot, probe, str(ERRORS.get(str(probe.get("error", "")), "Chưa thể dùng Cổ.")))

func use_skill(slot: int) -> void:
	if paused or hud.has_open_window():
		return
	var point := aim_point()
	var result := simulation.cast(slot, world_view.selected_id, point)
	if not bool(result.get("ok", false)) and slot >= 0 and slot < hud.skill_buttons.size():
		hud.skill_buttons[slot].flash_result(false)
	handle_result(result)
	flush_events()

func apply_appearance(value: Dictionary) -> void:
	if paused or not hud.studio_open:
		return
	var result := simulation.set_appearance(value)
	if not bool(result.get("ok", false)):
		handle_result(result)
		return
	hud.refresh_appearance()
	flush_events()
	persist()

func feed(instance_id: String, food: String) -> void:
	if paused or not hud.bag_open:
		return
	request_serial += 1
	var request_id := "%d-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), request_serial]
	handle_result(simulation.feed_gu(request_id, instance_id, food, simulation.inventory.version))
	flush_events()

func handle_result(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		var code := str(result.get("error", "UNKNOWN"))
		hud.toast(str(ERRORS.get(code, "Không thể thực hiện thao tác.")), true)
		sounds.play("denied")

func flush_events() -> void:
	var dirty := false
	for event in simulation.drain_events():
		world_view.receive(event)
		hud.receive(event)
		sounds.receive(event)
		if event.has("text"):
			hud.toast(str(event["text"]), event["kind"] == "capture_fail")
		if bool(event.get("persistent", false)) or event["kind"] in ["loot", "capture_start", "capture_success", "feed", "player_death", "quest_complete"]:
			dirty = true
	if dirty:
		persist()

func persist() -> void:
	if test_mode or simulation == null:
		return
	if not save_store.save_profile(simulation.to_profile()):
		if not save_failed:
			hud.toast("Lưu tiến độ thất bại: " + save_store.last_error, true, 6)
		save_failed = true
	else:
		save_failed = false

func toggle_pause() -> void:
	paused = not paused
	if paused and input_controller != null:
		input_controller.clear_movement()
	world_view.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	hud.set_paused(paused)
	if paused:
		persist()

func toggle_mute() -> void:
	hud.mute_button.text = "Âm thanh: %s  [M]" % ("tắt" if sounds.toggle() else "bật")
	_save_preferences()

func toggle_motion() -> void:
	var value := not world_view.reduced_motion
	world_view.set_reduced_motion(value)
	hud.set_reduced_motion(value)
	_save_preferences()

func set_audio_volume(value: float) -> void:
	sounds.set_volume(value)
	_save_preferences()

func set_display(window_size: Vector2i, fullscreen: bool) -> void:
	preferred_window_size = window_size
	preferred_fullscreen = fullscreen
	if not test_mode:
		_apply_display()
	_save_preferences()

func move_inventory_entry(source_key: String, destination_slot: int, expected_version: int) -> void:
	if paused or not hud.bag_open: return
	if simulation.inventory.move_to_slot(source_key, destination_slot, expected_version):
		hud.inventory_browser.refresh()
		persist()
	else:
		handle_result({"ok": false, "error": "VERSION_CONFLICT"})
		hud.inventory_browser.refresh()

func discard_inventory_entry(key: String, quantity: int, expected_version: int) -> void:
	if paused or not hud.bag_open: return
	if expected_version != simulation.inventory.version:
		handle_result({"ok": false, "error": "VERSION_CONFLICT"})
		return
	if simulation.inventory.discard_entry(key, quantity):
		hud.inventory_browser.refresh()
		hud.toast("Đã xóa vật phẩm khỏi hành trang.")
		persist()
	else:
		hud.toast("Không thể xóa Cổ đang khảm hoặc vật phẩm đã thay đổi.", true)

func craft_inventory_item(recipe_id: String, batches: int, expected_version: int) -> void:
	if paused or not hud.bag_open: return
	request_serial += 1
	var request_id := "craft-%d-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), request_serial]
	handle_result(simulation.craft_item(request_id, recipe_id, batches, expected_version))
	flush_events()
	hud.inventory_browser.refresh()

func use_inventory_seal() -> void:
	if paused or not hud.bag_open: return
	var result := simulation.begin_capture(world_view.selected_id)
	handle_result(result)
	if result.get("ok", false): hud.toggle_bag()
	flush_events()

func _apply_display() -> void:
	if preferred_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(preferred_window_size)

func _load_preferences() -> void:
	if test_mode:
		return
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") != OK:
		return
	var motion: bool = settings.get_value("accessibility", "reduced_motion", false) == true
	world_view.set_reduced_motion(motion)
	hud.set_reduced_motion(motion)
	sounds.set_volume(clampf(float(settings.get_value("audio", "volume", 0.75)), 0.0, 1.0))
	hud.set_audio_volume(sounds.volume)
	if settings.get_value("audio", "muted", false) == true:
		sounds.toggle()
		hud.mute_button.text = "Âm thanh: tắt  [M]"
	var width := int(settings.get_value("display", "width", 1280))
	var height := int(settings.get_value("display", "height", 800))
	var requested := Vector2i(width, height)
	if requested in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		preferred_window_size = requested
	preferred_fullscreen = settings.get_value("display", "fullscreen", false) == true
	hud.set_display_preferences(preferred_window_size, preferred_fullscreen)
	_apply_display()

func _save_preferences() -> void:
	if test_mode:
		return
	var settings := ConfigFile.new()
	settings.load("user://settings.cfg")
	settings.set_value("accessibility", "reduced_motion", world_view.reduced_motion)
	settings.set_value("audio", "muted", sounds.muted)
	settings.set_value("audio", "volume", sounds.volume)
	settings.set_value("display", "width", preferred_window_size.x)
	settings.set_value("display", "height", preferred_window_size.y)
	settings.set_value("display", "fullscreen", preferred_fullscreen)
	var result := settings.save("user://settings.cfg")
	if result != OK:
		hud.toast("Chưa lưu được tùy chọn hiển thị/âm thanh.", true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist()
		get_tree().quit()

func _capture_if_requested() -> void:
	var destination := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			destination = argument.trim_prefix("--capture=")
	if destination.is_empty():
		return
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(destination)
	print("CAPTURE_RESULT ", error, " ", destination)
	get_tree().quit(error)

func cultivate(command: String, args: Dictionary) -> void:
	if paused or not hud.cultivation_open:
		return
	if command == "navigate":
		var result := simulation.move_to(args.get("cell", WorldGrid.SPAWN))
		handle_result(result)
		if bool(result.get("ok", false)):
			hud.toggle_cultivation(hud.cultivation_book.page)
		return
	var result := simulation.journey_command(command,args) if command in ["waygate","medicine","irrigate"] else simulation.cultivation_command(command, args)
	handle_result(result)
	if bool(result.get("ok", false)) and command in ["travel","waygate"]:
		hud.toggle_cultivation(hud.cultivation_book.page)
		input_controller.clear_movement()
		has_world_aim = false
		pointer_in_world = false
	flush_events()

func interact() -> void:
	if paused or hud.has_open_window() or bool(simulation.player["dead"]):
		return
	var cell: Vector2 = simulation.player["cell"]
	var npc_id := simulation.interaction_npc()
	if npc_id != "":
		talk_to_npc(npc_id)
		return
	var resource := simulation.nearby_resource()
	if resource != "":
		handle_result(simulation.journey_command("gather",{"id":resource}))
		flush_events()
		return
	if simulation.expedition.region == "realm":
		for i in range(ExpeditionModel.PLOTS.size()):
			if cell.distance_to(ExpeditionModel.PLOTS[i]) <= 1.4:
				var plot := simulation.expedition.plots[i]
				if plot["crop"] == "":
					hud.toggle_cultivation("farm")
				else:
					handle_result(simulation.cultivation_command("harvest" if bool(plot["watered"]) else "water", {"plot": i}))
					flush_events()
				return
		for i in range(ExpeditionModel.PENS.size()):
			if cell.distance_to(ExpeditionModel.PENS[i]) <= 1.6:
				var animal := simulation.expedition.animals[i]
				if animal["kind"] == "":
					hud.toggle_cultivation("farm")
				else:
					handle_result(simulation.cultivation_command("collect_animal" if bool(animal["fed"]) else "feed_animal", {"pen": i}))
					flush_events()
				return
	if simulation.at_portal():
		hud.toggle_cultivation("travel")
	else:
		hud.toast("E: đứng gần NPC, cổ trận, ô đất hoặc chuồng để tương tác.")

func _on_gameplay_window_opened() -> void:
	input_controller.clear_movement()
	if hud.cultivation_open or hud.dialogue_open or hud.large_map_open:
		simulation.stop_navigation()

func talk_to_npc(id: String) -> void:
	if paused or hud.has_open_window(): return
	var result := simulation.talk_to(id)
	handle_result(result)
	if bool(result["ok"]):
		hud.open_dialogue(id)
		world_view.talk_to_npc(id)
	flush_events()

func dialogue_action(command: String, id: String) -> void:
	if paused or not hud.dialogue_open: return
	var result := simulation.quest_command(command,hud.dialogue.npc_id,id)
	handle_result(result)
	if bool(result["ok"]):
		hud.dialogue.command_result(command,id)
	flush_events()

func npc_quest_action(command: String, id: String) -> void:
	if paused or not hud.journal_open: return
	if command == "track":
		handle_result(simulation.quest_command(command,"",id))
		flush_events()
		hud.npc_quest_list.refresh()
		return
	if command != "navigate": return
	var definition := QuestCatalog.quest(id)
	if definition.is_empty(): return
	var destination := QuestCatalog.objective_location(id,simulation)
	if destination["region"] != simulation.expedition.region:
		hud.toast("Mục tiêu ở " + str(ExpeditionModel.REGIONS[destination["region"]]["name"]) + " • dùng T tại cổ trận để đi.")
		return
	var result := simulation.move_to(destination["cell"])
	handle_result(result)
	if bool(result["ok"]): hud.toggle_journal()

func use_medicine() -> void:
	if paused or hud.has_open_window(): return
	handle_result(simulation.journey_command("medicine"))
	flush_events()
