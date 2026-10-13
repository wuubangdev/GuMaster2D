class_name GuInventoryActions
extends VBoxContainer
## Item inspector actions; authority owns every item/currency mutation.
signal feed_requested(instance_id: String, food: String)
signal craft_requested(recipe_id: String, batches: int, expected_version: int)
signal gu_requested(instance_id: String)
signal farm_requested
signal seal_requested
signal discard_requested
signal mode_changed(crafting: bool)
var simulation: LocalAuthority
var entry: Dictionary = {}
var description: Label
var use_button: Button
var craft_toggle: Button
var delete_button: Button
var target_row: HBoxContainer
var target_picker: OptionButton
var craft_box: PanelContainer
var recipe_picker: OptionButton
var amount_spin: SpinBox
var cost_label: Label
var output_label: Label
var reason_label: Label
var craft_button: Button
var crafting := false
var recipe_ids: Array[String] = []
var target_ids: Array[String] = []

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	add_theme_constant_override("separation", 7)
	description = _label("", 12)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	target_row = HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 8)
	add_child(target_row)
	target_row.add_child(_label("Cho Cổ", 12))
	target_picker = OptionButton.new()
	target_picker.custom_minimum_size.y = 28
	target_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_picker.add_theme_font_size_override("font_size", 12)
	target_picker.item_selected.connect(func(_index: int): _refresh_use())
	target_row.add_child(target_picker)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 7)
	add_child(bar)
	use_button = _button(bar, "Dùng", use_selected)
	craft_toggle = _button(bar, "Chế tạo", toggle_craft)
	craft_toggle.toggle_mode = true
	delete_button = _button(bar, "Xóa…", func(): discard_requested.emit())
	craft_box = PanelContainer.new()
	craft_box.add_theme_stylebox_override("panel", GuPixelUI.frame("slot", 12))
	add_child(craft_box)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	craft_box.add_child(content)
	content.add_child(_label("CHẾ TẠO VẬT PHẨM", 14))
	recipe_picker = OptionButton.new()
	recipe_picker.custom_minimum_size.y = 30
	recipe_picker.add_theme_font_size_override("font_size", 13)
	recipe_picker.item_selected.connect(func(_index: int): refresh_craft())
	content.add_child(recipe_picker)
	var amount_row := HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 8)
	content.add_child(amount_row)
	var amount_caption := _label("Số lượt", 12)
	amount_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_row.add_child(amount_caption)
	amount_spin = SpinBox.new()
	amount_spin.min_value = 1
	amount_spin.max_value = 99
	amount_spin.step = 1
	amount_spin.value = 1
	amount_spin.custom_minimum_size = Vector2(88, 28)
	amount_spin.value_changed.connect(func(_value: float): refresh_craft())
	amount_row.add_child(amount_spin)
	cost_label = _label("", 12)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(cost_label)
	output_label = _label("", 13)
	output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output_label.add_theme_color_override("font_color", GuPixelUI.JADE)
	content.add_child(output_label)
	craft_button = _button(content, "Chế tạo", func():
		if recipe_picker.selected >= 0:
			craft_requested.emit(str(recipe_picker.get_item_metadata(recipe_picker.selected)), int(amount_spin.value), simulation.inventory.version))
	reason_label = _label("", 11)
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(reason_label)
	craft_box.hide()

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GuPixelUI.INK)
	return label

func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var button := GuInkButton.new()
	button.text = caption
	button.custom_minimum_size.y = 32
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func present(item: Dictionary) -> void:
	var changed := str(item.get("key", "")) != str(entry.get("key", ""))
	entry = item.duplicate(true)
	visible = not entry.is_empty()
	if entry.is_empty(): show_information(); return
	if changed: show_information()
	var is_gu: bool = entry["type"] == "gu"
	description.text = "Bậc %d • tu luyện %d/5\n%s" % [entry.get("rank", 1), entry.get("cultivation", 1), entry["description"]] if is_gu else ItemCrafting.description(str(entry["material"]))
	delete_button.disabled = is_gu and int(entry["slot"]) >= 0
	delete_button.tooltip_text = "Cổ đang khảm được bảo vệ." if delete_button.disabled else "Xóa vật phẩm sau bước xác nhận."
	craft_toggle.text = "Nâng / hợp Cổ" if is_gu else ("Đóng chế tạo" if crafting else "Chế tạo")
	var allowed: Array[String] = []
	if not is_gu: allowed = ItemCrafting.for_material(str(entry["material"]))
	craft_toggle.disabled = not is_gu and allowed.is_empty()
	craft_toggle.tooltip_text = "Chưa có công thức dùng vật liệu này." if craft_toggle.disabled else "Xem công thức và sản phẩm trước khi chế tạo."
	if allowed != recipe_ids:
		recipe_ids = allowed
		recipe_picker.clear()
		for id in recipe_ids:
			recipe_picker.add_item(str(ItemCrafting.all()[id]["name"]))
			recipe_picker.set_item_metadata(recipe_picker.item_count - 1, id)
		if recipe_picker.item_count > 0: recipe_picker.select(0)
	_refresh_targets()
	_refresh_use()
	refresh_craft()

func _refresh_targets() -> void:
	var ids: Array[String] = []
	if entry.get("type") == "material":
		for item in simulation.inventory.gu:
			if simulation.catalog.get_gu(str(item["definition_id"])).get("food") == entry["material"]:
				ids.append(str(item["instance_id"]))
	if ids != target_ids:
		target_ids = ids
		target_picker.clear()
		for id in ids:
			target_picker.add_item(id)
			target_picker.set_item_metadata(target_picker.item_count - 1, id)
		for index in range(ids.size()):
			if float(simulation.inventory.find_instance(ids[index])["hunger"]) < 100:
				target_picker.select(index)
				break
	for index in range(ids.size()):
		var item := simulation.inventory.find_instance(ids[index])
		var definition := simulation.catalog.get_gu(str(item["definition_id"]))
		target_picker.set_item_text(index, "%s • %.0f%% • %s" % [definition["name"], item["hunger"], ids[index]])
	target_row.visible = not ids.is_empty() and not crafting

func _refresh_use() -> void:
	if entry.is_empty(): return
	use_button.visible = entry["type"] == "material"
	use_button.disabled = bool(simulation.player["dead"])
	var kind := str(entry.get("material", ""))
	use_button.text = "Cho Cổ ăn" if not target_ids.is_empty() else ("Dùng phong ấn" if kind == "seal" else ("Mở gieo trồng" if kind.ends_with("_seed") else "Dùng"))
	if not target_ids.is_empty():
		var target := str(target_picker.get_item_metadata(target_picker.selected)) if target_picker.selected >= 0 else ""
		var item := simulation.inventory.find_instance(target)
		use_button.disabled = use_button.disabled or item.is_empty() or float(item["hunger"]) >= 100
		use_button.tooltip_text = "Cổ đã no; chọn Cổ khác trong danh sách." if use_button.disabled else "Dùng 1 %s cho Cổ đã chọn, hồi tối đa 40 no đủ." % entry["title"]
	else:
		use_button.disabled = use_button.disabled or (kind != "seal" and not kind.ends_with("_seed"))
		use_button.tooltip_text = ItemCrafting.description(kind)

func use_selected() -> void:
	if entry.is_empty(): return
	if entry["type"] == "gu":
		var item := simulation.inventory.find_instance(str(entry["instance_id"]))
		if not item.is_empty(): feed_requested.emit(str(item["instance_id"]), str(simulation.catalog.get_gu(str(item["definition_id"]))["food"]))
	elif not target_ids.is_empty() and target_picker.selected >= 0:
		feed_requested.emit(str(target_picker.get_item_metadata(target_picker.selected)), str(entry["material"]))
	elif entry["material"] == "seal": seal_requested.emit()
	elif str(entry["material"]).ends_with("_seed"): farm_requested.emit()

func toggle_craft() -> void:
	if entry.is_empty(): return
	if entry["type"] == "gu":
		craft_toggle.set_pressed_no_signal(false)
		gu_requested.emit(str(entry["instance_id"]))
		return
	if recipe_ids.is_empty(): return
	crafting = not crafting
	craft_box.visible = crafting
	description.visible = not crafting
	target_row.visible = not crafting and not target_ids.is_empty()
	craft_toggle.set_pressed_no_signal(crafting)
	craft_toggle.text = "Đóng chế tạo" if crafting else "Chế tạo"
	refresh_craft()
	mode_changed.emit(crafting)

func show_information() -> void:
	var changed := crafting
	crafting = false
	craft_box.hide()
	description.show()
	craft_toggle.set_pressed_no_signal(false)
	if changed: mode_changed.emit(false)

func refresh_craft() -> void:
	if recipe_picker == null or recipe_picker.selected < 0: return
	var id := str(recipe_picker.get_item_metadata(recipe_picker.selected))
	var recipe: Dictionary = ItemCrafting.all()[id]
	var batches := int(amount_spin.value)
	var costs: Array[String] = []
	for key in recipe["cost"]:
		var have := int(simulation.player["currency"]) if key == "silver" else int(simulation.inventory.materials.get(key, 0))
		var need := int(recipe["cost"][key]) * batches
		costs.append("%s %s: %d / %d" % ["✓" if have >= need else "✕", ExpeditionModel.material_name(str(key)), have, need])
	cost_label.text = "Nguyên liệu (có / cần)\n" + "\n".join(costs)
	var result: Array[String] = []
	for key in recipe["output"]: result.append("%s ×%d" % [ExpeditionModel.material_name(str(key)), int(recipe["output"][key]) * batches])
	output_label.text = "Nhận: " + ", ".join(result)
	var probe := ItemCrafting.preview(simulation, id, batches)
	craft_button.disabled = not probe["ok"]
	reason_label.text = {"DEAD": "Đang trọng thương.", "IN_COMBAT": "Chờ hết giao chiến hoặc phong ấn.", "AT_CAMP": "Chế tạo tại trại, trạm nghỉ hoặc điền viên.", "NEED_MATERIALS": "Chưa đủ nguyên liệu hoặc bạc.", "BAG_FULL": "Cần thêm ô trống cho sản phẩm."}.get(str(probe.get("error", "")), "Sẵn sàng chế tạo tại vùng an toàn.")
	reason_label.add_theme_color_override("font_color", GuPixelUI.MUTED if probe["ok"] else GuPixelUI.VERMILION)
