extends SceneTree
var game: GameManager
var checks: Array[Dictionary] = []
var captures: Array[String] = []
var review_prefix := "inventory51"

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-prefix="):
			var candidate := argument.trim_prefix("--review-prefix=")
			if candidate.is_valid_identifier(): review_prefix = candidate
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
	var viewport: Viewport = root
	if game != null and game.hud != null:
		var browser := game.hud.inventory_browser
		if browser.discard_dialog.visible: viewport = browser.discard_dialog
		elif browser.context_menu.visible: viewport = browser.context_menu
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.window_id = viewport.get_window().get_window_id()
		Input.parse_input_event(event)

func pointer(point: Vector2, held: bool = false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(motion)

func click(control: Control, button: int = MOUSE_BUTTON_LEFT) -> void:
	var viewport := control.get_viewport()
	var point := control.get_global_rect().get_center()
	if viewport != root and control.get_window().is_embedded():
		point += Vector2(control.get_window().position)
		viewport = root
	if viewport == root: pointer(point)
	else:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.window_id = viewport.get_window().get_window_id()
		Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = button
		event.pressed = pressed
		event.window_id = viewport.get_window().get_window_id()
		Input.parse_input_event(event)

func drag(source: Control, destination: Control) -> void:
	var start := source.get_global_rect().get_center()
	var end := destination.get_global_rect().get_center()
	pointer(start)
	var press := InputEventMouseButton.new()
	press.position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = start + Vector2(24, 18)
	motion.relative = Vector2(24, 18)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	pointer(end, true)
	await process_frame
	check(root.gui_is_dragging(), "Real mouse movement starts an inventory drag")
	var release := InputEventMouseButton.new()
	release.position = end
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await settle()

func slot(key_value: String) -> GuItemSlot:
	for item in game.hud.inventory_browser.slots:
		if item.entry.get("key", "") == key_value: return item
	return null

func select(key_value: String) -> void:
	await settle()
	var target := slot(key_value)
	if target == null: check(false, "Entry exists " + key_value); return
	var scroll: ScrollContainer = game.hud.inventory_browser.get_parent()
	scroll.ensure_control_visible(target)
	await settle()
	scroll.ensure_control_visible(target)
	await settle()
	click(target)
	await settle()
	check(game.hud.inventory_browser.selected_key == key_value and game.hud.bag_open, "Real item click selects " + key_value)

func capture(name: String) -> void:
	pointer(Vector2(420, 340))
	await settle()
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/%s_%s.png" % [review_prefix, name]
	check(root.get_texture().get_image().save_png(path) == OK, "Native screenshot " + name)
	captures.append(path)

func _run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.hud.set_reduced_motion(true)
	key(KEY_TAB)
	await settle()
	var hud := game.hud
	var browser := hud.inventory_browser
	var actions := browser.actions
	var inv := game.simulation.inventory
	check(hud.bag_open and browser.rows.size() == 4, "Tab opens real inventory and item inspector")
	await capture("information_1280")
	var amount_before := inv.materials.duplicate(true)
	await drag(browser.slots[0], browser.slots[9])
	check(inv.display_slots()[9] == "gu:gu_1" and inv.display_slots()[0] == "" and inv.materials == amount_before, "Real drag places the selected Cổ in an empty slot without consuming items")
	await drag(browser.slots[9], browser.slots[1])
	check(inv.display_slots()[1] == "gu:gu_1" and inv.display_slots()[9] == "gu:gu_2", "Real drag swaps occupied slots")
	var restored := InventoryModel.new()
	check(restored.load_data(inv.to_data(), game.simulation.catalog) and restored.display_slots() == inv.display_slots(), "Dragged layout survives profile data roundtrip")
	var reserve := inv.add_gu("GU-01")
	reserve["hunger"] = 10.0
	inv.add_material("egg", 4)
	inv.add_material("hide", 4)
	inv.add_material("herb", 2)
	inv.add_material("pollen", 6)
	browser.refresh()
	await select("material:meat:0")
	check(actions.target_picker.item_count == 2 and not actions.use_button.disabled, "Food inspector exposes an explicit Cổ target selector")
	for i in range(actions.target_picker.item_count):
		if actions.target_picker.get_item_metadata(i) == reserve["instance_id"]:
			actions.target_picker.select(i)
			actions.target_picker.item_selected.emit(i)
	await capture("food_1280")
	var hunger_before: float = inv.find_instance("gu_1")["hunger"]
	var food_before := int(inv.materials["meat"])
	click(actions.use_button)
	await settle()
	check(reserve["hunger"] == 50.0 and inv.find_instance("gu_1")["hunger"] == hunger_before and inv.materials["meat"] == food_before - 1, "Use feeds exactly the chosen Cổ")
	await select("gu:" + str(reserve["instance_id"]))
	click(slot("gu:" + str(reserve["instance_id"])), MOUSE_BUTTON_RIGHT)
	await settle()
	check(browser.context_menu.visible and not browser.context_menu.is_item_disabled(4), "Right click exposes reserve Cổ actions")
	browser.context_menu.set_focused_item(browser.context_menu.get_item_index(2))
	key(KEY_ENTER)
	await settle()
	check(hud.cultivation_open and hud.cultivation_book.selected_id == reserve["instance_id"], "Right-click upgrade action opens the exact selected reserve Cổ")
	key(KEY_ESCAPE)
	key(KEY_TAB)
	await settle()
	await select("material:egg:0")
	click(actions.craft_toggle)
	await settle()
	check(actions.crafting and not actions.craft_button.disabled and actions.output_label.text.contains("×3"), "Craft drawer shows a usable recipe and its output")
	for dimensions in [Vector2i(1280, 800), Vector2i(960, 640), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		browser.get_parent().scroll_vertical = 0
		await settle()
		check(hud.bag.get_global_rect().encloses(actions.craft_button.get_global_rect()) and actions.craft_button.size.y >= 32, "Craft controls are visible and fit at %s" % dimensions)
		check(actions.cost_label.text.contains("4 / 2") and actions.output_label.text.contains("×3"), "Craft drawer shows owned/required amounts at %s" % dimensions)
		await capture("craft_%d" % dimensions.x)
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	await settle()
	actions.amount_spin.value = 2
	var stone_before := int(inv.materials["stone"])
	click(actions.craft_button)
	await settle()
	check(inv.materials["egg"] == 0 and inv.materials["stone"] == stone_before + 6, "Craft button executes an exact two-batch authority transaction")
	check(hud.toast_label.text.contains("Chế tạo thành công"), "Crafting displays a success receipt")
	await select("material:hide:0")
	click(actions.craft_toggle)
	await settle()
	actions.amount_spin.value = 1
	check(actions.cost_label.text.contains("Bạc") and actions.output_label.text.contains("Phong ấn"), "A second recipe shows currency and material costs")
	await capture("seal_recipe_1280")
	actions.show_information()
	await select("material:pollen:0")
	click(slot("material:pollen:0"), MOUSE_BUTTON_RIGHT)
	await settle()
	browser.context_menu.set_focused_item(browser.context_menu.get_item_index(3))
	key(KEY_ENTER)
	await settle()
	check(browser.discard_dialog.visible and browser.discard_dialog.dialog_text.contains("×6"), "Delete opens a named quantity confirmation")
	await capture("delete_1280")
	key(KEY_ESCAPE)
	await settle()
	check(not browser.discard_dialog.visible and hud.bag_open and inv.materials["pollen"] == 6, "Escape cancels deletion while keeping the bag open")
	click(actions.delete_button)
	await settle()
	inv.add_material("pollen", 1)
	browser.discard_dialog.confirmed.emit()
	browser.discard_dialog.hide()
	await settle()
	check(inv.materials["pollen"] == 7, "Inventory changes invalidate an old deletion confirmation")
	await select("material:pollen:0")
	click(actions.delete_button)
	await settle()
	click(browser.discard_dialog.get_ok_button())
	await settle()
	check(inv.materials["pollen"] == 0, "Confirmed deletion removes only the selected material stack")
	await select("gu:gu_1")
	check(actions.delete_button.disabled, "Equipped Cổ deletion remains disabled in the inspector")
	click(slot("gu:gu_1"), MOUSE_BUTTON_RIGHT)
	await settle()
	check(browser.context_menu.is_item_disabled(4), "Equipped Cổ deletion remains disabled in right-click menu")
	await capture("context_1280")
	browser.context_menu.hide()
	await select("material:seal:0")
	game.world_view.selected_id = ""
	var seals_before := int(inv.materials["seal"])
	click(actions.use_button)
	await settle()
	check(hud.bag_open and inv.materials["seal"] == seals_before, "Using a seal without a target reports a failure and preserves inventory")
	var target: Dictionary = game.simulation.mobs["wolf_0"]
	target["cell"] = game.simulation.player["cell"] + Vector2(1, 0)
	target["dead"] = false
	target["owned"] = true
	target["hp"] = float(target["max_hp"]) * .25
	game.world_view.selected_id = "wolf_0"
	click(actions.use_button)
	await settle()
	check(not hud.bag_open and not game.simulation.capture.is_empty() and inv.materials["seal"] == seals_before - 1, "A valid seal use consumes exactly one seal, starts capture, and returns to the world")
	game.simulation.capture.clear()
	key(KEY_TAB)
	await settle()
	inv.add_material("herb_seed", 1)
	browser.refresh()
	await select("material:herb_seed:0")
	click(actions.use_button)
	await settle()
	check(hud.cultivation_open and hud.cultivation_book.page == "farm" and inv.materials["herb_seed"] == 1, "Seed use opens planting controls without consuming a seed before planting")
	key(KEY_ESCAPE)
	await settle()
	key(KEY_TAB)
	await settle()
	await select("gu:gu_1")
	browser._open_context(actions.entry, Vector2(1279, 799))
	await settle()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(Rect2(Vector2(browser.context_menu.position), Vector2(browser.context_menu.size))), "Context menu clamps to viewport edges")
	key(KEY_ESCAPE)
	await settle()
	key(KEY_ESCAPE)
	await settle()
	check(not hud.bag_open and not browser.context_menu.visible and not browser.discard_dialog.visible, "Closing the bag clears its transient menus")
	var failed := checks.filter(func(result: Dictionary): return not result["passed"]).size()
	FileAccess.open("res://artifacts/%s_review_%s.json" % [review_prefix, OS.get_name().to_lower()], FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures, "platform": OS.get_name()}, "  "))
	print("INVENTORY51_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
