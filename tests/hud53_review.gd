extends SceneTree
## Real native layout at supported PC sizes, including translated and stateful text.
var game: GameManager
var checks: Array[Dictionary] = []
var captures: Array[String] = []
var review_prefix := "hud53"

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-prefix="):
			var candidate := argument.trim_prefix("--review-prefix=")
			if candidate.is_valid_identifier(): review_prefix = candidate
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks.append({"name": message, "passed": value})
	if not value: printerr("FAIL: ", message)

func settle() -> void:
	await process_frame
	await process_frame
	await create_timer(.16).timeout

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
	await settle()

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
	await settle()

func inspect(node: Node, issues: Array[String]) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is GuInkButton and not node.text.is_empty():
		var font: Font = node.get_theme_font("font")
		var font_size: int = node.get_theme_font_size("font_size")
		var text_size := font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if node.size.x + .1 < text_size.x + GuInkButton.TEXT_INSET.x * 2 or node.size.y + .1 < font.get_height(font_size) + GuInkButton.TEXT_INSET.y * 2:
			issues.append("Button '%s': %s, text %s" % [node.text, node.size, text_size])
	if node is GuLacquerPanel:
		var safe: Rect2 = node.get_global_rect().grow(-GuLacquerPanel.CONTENT_INSET).grow(.2)
		for child in node.get_children():
			if child is Control and child.visible and not safe.encloses(child.get_global_rect()):
				issues.append("Panel %s: child outside inset" % node.get_path())
	for child in node.get_children(): inspect(child, issues)

func capture(name: String) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(5, root.size.y - 5)
	Input.parse_input_event(motion)
	await settle()
	var issues: Array[String] = []
	inspect(game.hud.root, issues)
	check(issues.is_empty(), "%s: text has safe insets; %s" % [name, "; ".join(issues)])
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/%s_%s.png" % [review_prefix, name]
	check(root.get_texture().get_image().save_png(path) == OK, "Screenshot " + name)
	captures.append(path)

func _run() -> void:
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.simulation.inventory.reward_material("egg", 4)
	var hud := game.hud
	hud.set_reduced_motion(true)
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		var suffix := str(dimensions.x)
		check(not hud.status_panel.get_global_rect().intersects(hud.quest_panel.get_global_rect()), "HUD panels separated at " + suffix)
		check(not hud.hint.get_global_rect().intersects(hud.action_belt.get_global_rect()), "Hint and hotbar separated at " + suffix)
		for bar in [hud.hp_bar, hud.mana_bar]:
			var readout: Label = bar.get_child(0)
			check(bar.size.y >= readout.get_theme_font("font").get_height(12) + 8, "Vital text clears border at " + suffix)
		await capture("hud_" + suffix)
		await key(KEY_TAB)
		check(hud.bag_open, "Tab opens bag at " + suffix)
		check(hud.bag.get_global_rect().end.y + 8 <= hud.action_belt.get_global_rect().position.y, "Bag clears skill dock at " + suffix)
		await capture("bag_" + suffix)
		await key(KEY_F3)
		check(hud.character_open and hud.bag_open and not hud.character_panel.get_global_rect().intersects(hud.bag.get_global_rect()), "Both side windows fit at " + suffix)
		await capture("paired_" + suffix)
		await key(KEY_F3)
		hud.inventory_browser.set_filter("all")
		hud.inventory_browser.selected_key = "material:egg:0"
		hud.inventory_browser.refresh()
		hud.inventory_browser.actions.show_information()
		hud.inventory_browser._scroll_top()
		await settle()
		await click(hud.inventory_browser.actions.craft_toggle)
		check(hud.inventory_browser.actions.crafting, "Craft toggle opens at " + suffix)
		await capture("craft_" + suffix)
		await key(KEY_ESCAPE)
		await key(KEY_G)
		await capture("gu_" + suffix)
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
		check(hud.paused and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.pause_panel.get_global_rect()), "Settings fit at " + suffix)
		await capture("settings_" + suffix)
		await key(KEY_ESCAPE)
		await key(KEY_F6)
		check(hud.studio_open and Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(hud.character_studio.get_global_rect()), "Character studio fits at " + suffix)
		await capture("studio_" + suffix)
		await key(KEY_ESCAPE)
		await key(KEY_J)
		await capture("quests_" + suffix)
		await key(KEY_ESCAPE)
		hud.inventory_browser.select_gu("gu_1")
	var failed := checks.filter(func(row: Dictionary): return not row.passed).size()
	FileAccess.open("res://artifacts/%s_review.json" % review_prefix, FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures}, "  "))
	print(review_prefix.to_upper(), "_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
