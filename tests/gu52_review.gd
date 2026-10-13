extends SceneTree
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
	await create_timer(.18).timeout

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)

func click(control: Control) -> void:
	var window := control.get_window()
	var point := control.get_global_rect().get_center()
	if window != root and window.is_embedded(): point += Vector2(window.position)
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
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(20, 780)
	Input.parse_input_event(motion)
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/gu52_%s.png" % name
	check(root.get_texture().get_image().save_png(path) == OK, "Native screenshot " + name)
	captures.append(path)

func _run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.hud.set_reduced_motion(true)
	key(KEY_G)
	await settle()
	var book := game.hud.cultivation_book
	var workshop := book.gu_workshop
	var inv := game.simulation.inventory
	check(game.hud.cultivation_open and workshop.visible and not book.scroll.visible and workshop.rows.size() == 4, "G opens the real workshop with all equipped Gu")
	check(workshop.action_button.disabled and workshop.reason.text.contains("Chưa đủ"), "Unavailable materials disable enhancement with a visible explanation")
	await capture("missing_1280")
	inv.reward_material("herb", 30)
	inv.reward_material("stone", 30)
	inv.reward_material("silk", 10)
	inv.reward_material("essence", 15)
	game.simulation.player["currency"] = 1000
	book.refresh()
	await settle()
	for slot in range(4):
		var id := "gu_%d" % (slot + 1)
		click(workshop.rows[id])
		await settle()
		check(book.selected_id == id and workshop.selected_id == id and workshop.title.text == game.simulation.catalog.slot(slot)["full_name"], "Real list click selects " + id)
		check(not workshop.action_button.disabled and workshop.preview["after"]["cultivation"] == 2 and workshop.stat_cells["strength"][2].text == "×1.12", "Selected Gu shows a ready level-two comparison")
		if slot == 1:
			check(workshop.stat_cells["effect"][2].text == "80", "Shield comparison respects the actual eighty-point cap")
		if slot == 2:
			check(workshop.stat_cells["cooldown"][2].text == "7.14 s", "Dash comparison shows its actual shorter cooldown")
		await capture("upgrade_%s_1280" % game.simulation.catalog.slot(slot)["kind"])
	click(workshop.rows["gu_1"])
	await settle()
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 640), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(book.get_global_rect()), "Workshop stays inside viewport at %s" % dimensions)
		check(book.get_global_rect().encloses(workshop.action_button.get_global_rect()) and workshop.action_button.size.y >= 38, "Primary enhancement action remains visible at %s" % dimensions)
		check(workshop.cost_labels["herb"]["label"].text.contains("30 / 2") and workshop.cost_labels["silver"]["label"].text.contains("1000 / 25"), "Owned and required material/currency amounts remain readable")
		await capture("upgrade_%d" % dimensions.x)
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	await settle()
	click(workshop.action_button)
	await settle()
	check(inv.slot_gu(0)["cultivation"] == 2 and inv.materials["herb"] == 28 and inv.materials["stone"] == 31 and game.simulation.player["currency"] == 975, "Actual enhancement click pays one exact upgrade")
	check(workshop.outcome.visible and workshop.outcome.text.contains("mức 2") and workshop.preview["after"]["cultivation"] == 3, "Enhancement updates current/next level and shows its real outcome")
	await capture("success_1280")
	click(workshop.action_button)
	await settle()
	var donor_one := inv.add_gu("GU-01")
	var donor_two := inv.add_gu("GU-01")
	donor_one["cultivation"] = 4
	book.refresh()
	click(workshop.mode_buttons["fuse"])
	await settle()
	check(workshop.rows.size() == 6 and workshop.donor_picker.item_count == 3 and workshop.donor_picker.selected == 0 and workshop.action_button.disabled, "Fusion shows all reserve Gu and requires an explicit donor")
	workshop.detail_scroll.ensure_control_visible(workshop.donor_picker)
	await settle()
	click(workshop.donor_picker)
	await settle()
	var popup := workshop.donor_picker.get_popup()
	var target_index := -1
	for index in range(workshop.donor_picker.item_count):
		if workshop.donor_picker.get_item_metadata(index) == donor_one["instance_id"]: target_index = index
	popup.set_focused_item(target_index)
	key(KEY_ENTER)
	await settle()
	check(workshop.donor_id == donor_one["instance_id"] and not workshop.action_button.disabled, "Native donor picker chooses the requested specific reserve Gu")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 640)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		workshop.detail_scroll.ensure_control_visible(workshop.donor_picker)
		await settle()
		check(book.get_global_rect().encloses(workshop.action_button.get_global_rect()) and book.get_global_rect().encloses(workshop.donor_picker.get_global_rect()), "Fusion action and chosen donor fit at %s" % dimensions)
		var caption_width := GuPixelUI.HAND_FONT.get_string_size(workshop.donor_caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		check(workshop.donor_caption.size.y <= 32 and workshop.donor_caption.size.x >= caption_width and workshop.donor_caption.get_global_rect().end.x <= workshop.donor_picker.get_global_rect().position.x, "Donor caption is readable without wrapping into vertical letters at %s" % dimensions)
		check(workshop.detail_scroll.get_global_rect().encloses(workshop.stat_cells["strength"][1].get_global_rect()) and workshop.detail_scroll.get_global_rect().encloses(workshop.donor_picker.get_global_rect()), "Fusion comparison and donor are visible together at %s" % dimensions)
		await capture("fusion_%d" % dimensions.x)
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	await settle()
	var money_before := int(game.simulation.player["currency"])
	click(workshop.action_button)
	await settle()
	check(workshop.confirmation.visible and workshop.confirmation.dialog_text.contains(str(donor_one["instance_id"])) and workshop.confirmation.dialog_text.contains("mức 4"), "Fusion confirmation names the exact donor and its level")
	await capture("confirm_1280")
	key(KEY_ESCAPE)
	await settle()
	check(not workshop.confirmation.visible and game.hud.cultivation_open and not inv.find_instance(str(donor_one["instance_id"])).is_empty() and game.simulation.player["currency"] == money_before, "Escape cancels fusion without consuming its donor or currency")
	click(workshop.action_button)
	await settle()
	inv.add_material("stone", 1)
	click(workshop.confirmation.get_ok_button())
	await settle()
	check(inv.slot_gu(0)["rank"] == 1 and not inv.find_instance(str(donor_one["instance_id"])).is_empty() and game.simulation.player["currency"] == money_before, "A stale fusion confirmation is rejected atomically")
	click(workshop.action_button)
	await settle()
	click(workshop.confirmation.get_ok_button())
	await settle()
	check(inv.slot_gu(0)["rank"] == 2 and inv.slot_gu(0)["cultivation"] == 1 and inv.slot_gu(0)["slot"] == 0 and inv.find_instance(str(donor_one["instance_id"])).is_empty() and not inv.find_instance(str(donor_two["instance_id"])).is_empty() and game.simulation.player["currency"] == money_before - 100, "Confirmed fusion consumes only the chosen donor and preserves the equipped skill")
	check(workshop.rows.size() == 5 and workshop.outcome.visible and game.hud.skill_buttons[0].gu_rank == 2, "Fusion refreshes the Gu list, result and equipped hotbar rank")
	await capture("fusion_success_1280")
	inv.slot_gu(0).merge({"rank": 3, "cultivation": 5}, true)
	inv.version += 1
	book.refresh()
	await settle()
	check(workshop.action_button.disabled and workshop.preview["cost"].is_empty() and workshop.reason.text.contains("cao nhất"), "Maximum rank has no misleading next rank or costs")
	await capture("maximum_1280")
	click(workshop.mode_buttons["upgrade"])
	await settle()
	check(workshop.action_button.disabled and workshop.reason.text.contains("viên mãn"), "Maximum enhancement is clearly disabled")
	click(workshop.rows["gu_2"])
	await settle()
	game.simulation.combat_left = 2.0
	book.refresh()
	check(workshop.action_button.disabled and workshop.reason.text.contains("giao chiến"), "Combat state disables enhancement and explains why")
	game.simulation.combat_left = 0
	game.simulation.player["dead"] = true
	book.refresh()
	check(workshop.action_button.disabled and workshop.reason.text.contains("trọng thương"), "Dead state disables enhancement")
	game.simulation.player["dead"] = false
	book.refresh()
	game.simulation.capture = {"target": "wolf_0"}
	book.refresh()
	check(workshop.action_button.disabled and workshop.reason.text.contains("phong ấn"), "Opening or starting capture disables progression immediately")
	game.simulation.capture.clear()
	book.refresh()
	check(not workshop.action_button.disabled, "Finishing capture restores progression availability without another inventory change")
	var row_identity: Button = workshop.rows["gu_2"]
	book.signature = ""
	book.refresh()
	check(workshop.rows["gu_2"] == row_identity, "Live refresh retains the controls rather than replacing the whole workshop")
	game.hud.set_reduced_motion(false)
	click(workshop.action_button)
	await process_frame
	check(workshop.portrait.celebration > 0, "A real upgrade starts the brief portrait success feedback")
	game.hud.set_reduced_motion(true)
	check(workshop.portrait.celebration == 0 and workshop.portrait.modulate.a == 1.0, "Reduced motion immediately stops portrait effects while retaining the outcome")
	var distant := {}
	for index in range(8): distant = inv.add_gu("GU-07")
	book.selected_id = str(distant["instance_id"])
	book.signature = ""
	book.refresh()
	await settle()
	check(workshop.selected_id == distant["instance_id"] and workshop.list_scroll.get_global_rect().encloses(workshop.rows[str(distant["instance_id"])].get_global_rect()), "Opening a distant reserve Gu automatically scrolls its selected row into view")
	key(KEY_ESCAPE)
	await settle()
	check(not game.hud.cultivation_open and not workshop.confirmation.visible, "Escape closes the workshop and clears its transient dialogs")
	key(KEY_T)
	await settle()
	check(book.page == "travel" and book.scroll.visible and not workshop.visible, "Travel still uses its existing atlas page")
	key(KEY_H)
	await settle()
	check(book.page == "farm" and book.scroll.visible and not workshop.visible, "Farm still uses its existing page")
	var failed := checks.filter(func(result: Dictionary): return not result["passed"]).size()
	FileAccess.open("res://artifacts/gu52_review_%s.json" % OS.get_name().to_lower(), FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures}, "  "))
	print("GU52_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
