extends "res://tests/hud53_review.gd"
## Covers the actual label rectangles inside formerly hand-positioned text.

func label_fits(label: Label, owner_control: Control, inset: float, name_text: String) -> void:
	var font: Font = label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	check(owner_control.get_global_rect().grow(-inset).grow(.1).encloses(label.get_global_rect()), name_text + ": text box stays inside the ink safe area")
	check(label.size.y + .1 >= font.get_height(font_size), name_text + ": accents and descenders fit vertically")
	check(label.clip_text or font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= label.size.x, name_text + ": full text fits or has explicit overflow handling")

func _run() -> void:
	review_prefix = "hud54_text"
	game = preload("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.set_process(false)
	var hud := game.hud
	hud.set_reduced_motion(true)
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		for state in ["ready", "cooldown", "hungry", "mana", "dead"]:
			for button in hud.skill_buttons:
				button.update_state(7.9 if state == "cooldown" else 0, 0 if state == "hungry" else 100, 0 if state == "mana" else 100, 100, state == "dead")
			await settle()
			for button in hud.skill_buttons:
				label_fits(button.name_label, button, 5, "%s skill name %s" % [dimensions.x, state])
				label_fits(button.status_label, button, 5, "%s skill status %s" % [dimensions.x, state])
				label_fits(button.hotkey_label, button, 5, "%s hotkey %s" % [dimensions.x, state])
				check(not button.name_label.get_global_rect().intersects(button.status_label.get_global_rect()), "Name and status have separate lines")
			await capture("skills_%s_%d" % [state, dimensions.x])
		hud.toggle_bag()
		hud.update_hud(0)
		var browser := hud.inventory_browser
		browser.set_filter("all")
		for quantity in [1, 9, 99]:
			game.simulation.inventory.materials["meat"] = quantity
			game.simulation.inventory.version += 1
			browser.selected_key = "material:meat:0"
			browser.refresh()
			await settle()
			for slot in browser.slots:
				if slot.entry.get("key") == "material:meat:0":
					check(slot.selected and slot.quantity_label.text == str(quantity), "Selected material shows its updated quantity")
					label_fits(slot.quantity_label, slot, 8, "Stack %d" % quantity)
					check(slot.quantity_label.get_rect().end.y <= slot.size.y - 10, "Quantity clears selected underline")
				if slot.key_label.visible: label_fits(slot.key_label, slot, 8, "Equipped item key")
			await capture("quantity_%d_%d" % [quantity, dimensions.x])
		browser.get_parent().scroll_vertical = 99999
		await capture("scroll_bottom_%d" % dimensions.x)
		hud.toggle_bag()
		hud.toggle_cultivation("gu")
		hud.update_hud(0)
		var workshop := hud.cultivation_book.gu_workshop
		await settle()
		for row in workshop.rows.values():
			for label in row.captions: label_fits(label, row, 8, "Gu list caption")
			for i in range(2): check(not row.captions[i].get_global_rect().intersects(row.captions[i + 1].get_global_rect()), "Gu list text lines stay separate")
		var reserve := game.simulation.inventory.add_gu("GU-01")
		reserve["instance_id"] = "gu_12345678901234567890"
		workshop.present(str(reserve["instance_id"]))
		await settle()
		var long_row: Control = workshop.rows[str(reserve["instance_id"])]
		check(long_row.captions[1].text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and long_row.tooltip_text.contains(str(reserve["instance_id"])), "Long reserve ID truncates with the full value in its tooltip")
		await capture("gu_long_id_%d" % dimensions.x)
		hud.toggle_cultivation("gu")
		game.simulation.inventory.gu.erase(reserve)
	var failed := checks.filter(func(row: Dictionary): return not row.passed).size()
	FileAccess.open("res://artifacts/hud54_text_review.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "failed": failed, "checks": checks, "captures": captures}, "  "))
	print("HUD54_TEXT_REVIEW ", checks.size() - failed, "/", checks.size())
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
