class_name GuInventoryBrowser
extends VBoxContainer

signal feed_requested(instance_id: String, food: String)
signal move_requested(source_key: String, destination_slot: int, expected_version: int)
signal discard_requested(key: String, quantity: int, expected_version: int)
signal open_gu_requested(instance_id: String)
signal craft_requested(recipe_id: String, batches: int, expected_version: int)
signal open_farm_requested
signal use_seal_requested
var simulation: LocalAuthority
var slots: Array[GuItemSlot] = []
var entries: Array[Dictionary] = []
var rows: Dictionary = {}
var details: VBoxContainer
var capacity_label: Label
var material_detail: Label
var description: Label
var filter_buttons: Array[Button] = []
var sort_button: Button
var filter_kind: String = "all"
var sort_by_name: bool = false
var selected_key: String = "gu:gu_1"
var context_menu: PopupMenu
var discard_dialog: ConfirmationDialog
var context_entry: Dictionary = {}
var discard_snapshot: Dictionary = {}
var actions: GuInventoryActions

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	add_theme_constant_override("separation", 7)
	capacity_label = _label("", 13)
	add_child(capacity_label)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 5)
	add_child(filters)
	for i in range(3):
		var button := GuInkButton.new()
		button.text = ["Tất cả", "Cổ trùng", "Vật liệu"][i]
		button.add_theme_font_size_override("font_size", 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.pressed.connect(set_filter.bind(["all", "gu", "material"][i]))
		filters.add_child(button)
		filter_buttons.append(button)
	sort_button = GuInkButton.new()
	sort_button.text = "Tên ↕"
	sort_button.custom_minimum_size.x = 54
	sort_button.tooltip_text = "Bật: theo tên A–Z. Tắt: bố cục đã sắp xếp; có thể kéo vào ô trống."
	sort_button.toggle_mode = true
	sort_button.add_theme_font_size_override("font_size", 12)
	sort_button.focus_mode = Control.FOCUS_NONE
	sort_button.pressed.connect(func():
		sort_by_name = not sort_by_name
		refresh())
	filters.add_child(sort_button)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	add_child(grid)
	for i in range(InventoryModel.CAPACITY):
		var slot := GuItemSlot.new()
		slot.slot_index = i
		slot.pressed.connect(_select_slot.bind(i))
		slot.context_requested.connect(_open_context)
		slot.move_requested.connect(_move_entry)
		grid.add_child(slot)
		slots.append(slot)
	context_menu = PopupMenu.new()
	context_menu.name = "ItemContextMenu"
	context_menu.theme = GuPixelUI.popup_theme()
	context_menu.id_pressed.connect(_context_action)
	context_menu.size_changed.connect(_fit_context_bounds)
	add_child(context_menu)
	get_viewport().size_changed.connect(_fit_context_bounds)
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.name = "DiscardConfirmation"
	discard_dialog.theme = context_menu.theme
	discard_dialog.title = "Xác nhận xóa vật phẩm"
	discard_dialog.ok_button_text = "Xóa vật phẩm"
	discard_dialog.cancel_button_text = "Giữ lại"
	discard_dialog.confirmed.connect(_confirm_discard)
	discard_dialog.canceled.connect(func(): discard_snapshot.clear())
	add_child(discard_dialog)
	details = VBoxContainer.new()
	details.custom_minimum_size.y = 82
	add_child(details)
	material_detail = _label("", 15)
	material_detail.custom_minimum_size.y = 82
	material_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(material_detail)
	actions = GuInventoryActions.new()
	add_child(actions)
	actions.setup(simulation)
	description = actions.description
	actions.feed_requested.connect(func(id: String, food: String): feed_requested.emit(id, food))
	actions.craft_requested.connect(func(recipe: String, batches: int, version: int): craft_requested.emit(recipe, batches, version))
	actions.gu_requested.connect(func(id: String): open_gu_requested.emit(id))
	actions.farm_requested.connect(func(): open_farm_requested.emit())
	actions.seal_requested.connect(func(): use_seal_requested.emit())
	actions.discard_requested.connect(_request_discard)
	actions.mode_changed.connect(func(_crafting: bool): _update_details_visibility(); _scroll_top())
	var footer := _label("Click xem · chuột phải thao tác · kéo để sắp xếp", 11)
	footer.modulate = GuPixelUI.MUTED
	add_child(footer)
	# The chosen item and its feed action stay above the grid at small viewports.
	move_child(details, 2)
	move_child(material_detail, 3)
	move_child(actions, 4)
	material_detail.custom_minimum_size.y = 40
	refresh()


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func set_filter(kind: String) -> void:
	filter_kind = kind
	refresh()

func select_gu(instance_id: String) -> void:
	filter_kind = "gu"
	selected_key = "gu:" + instance_id
	refresh()

func _select_slot(index: int) -> void:
	if slots[index].entry.is_empty():
		return
	selected_key = str(slots[index].entry["key"])
	refresh()
	_scroll_top()

func _move_entry(source_key: String, destination_slot: int, expected_version: int) -> void:
	var target: Dictionary = slots[destination_slot].entry
	var destination := destination_slot
	if (sort_by_name or filter_kind != "all") and not target.is_empty():
		destination = simulation.inventory.display_slots().find(str(target["key"]))
	sort_by_name = false
	filter_kind = "all"
	selected_key = source_key
	move_requested.emit(source_key, destination, expected_version)

func _open_context(item: Dictionary, at: Vector2) -> void:
	selected_key = str(item["key"])
	refresh()
	item = actions.entry.duplicate(true)
	if item.is_empty(): return
	context_entry = item
	context_menu.clear()
	context_menu.add_item("Xem thông tin", 0)
	var can_use: bool = not rows[str(item["instance_id"])].feed_button.disabled if item["type"] == "gu" else not actions.use_button.disabled
	context_menu.add_item("Cho Cổ ăn" if item["type"] == "gu" else actions.use_button.text, 1)
	context_menu.set_item_disabled(1, not can_use)
	context_menu.add_item("Nâng cấp / luyện hợp Cổ" if item["type"] == "gu" else "Chế tạo…", 2)
	context_menu.set_item_disabled(2, actions.craft_toggle.disabled)
	context_menu.add_separator()
	context_menu.add_item("Xóa vật phẩm…", 3)
	context_menu.set_item_disabled(context_menu.item_count - 1, item["type"] == "gu" and int(item["slot"]) >= 0)
	context_menu.reset_size()
	var dimensions := context_menu.get_contents_minimum_size()
	var viewport := get_viewport_rect().size
	at.x = clampf(at.x, 0, maxf(0, viewport.x - dimensions.x))
	at.y = clampf(at.y, 0, maxf(0, viewport.y - dimensions.y))
	context_menu.popup(Rect2i(Vector2i(at), Vector2i(dimensions)))
	_fit_context_bounds()
	_fit_context_bounds.call_deferred()

func _fit_context_bounds() -> void:
	if not context_menu.visible: return
	var viewport := get_viewport_rect().size
	var origin := Vector2(context_menu.position)
	# The final font/theme minimum can grow after popup() resolves its items.
	origin.x = clampf(origin.x, 0, maxf(0, viewport.x - context_menu.size.x))
	origin.y = clampf(origin.y, 0, maxf(0, viewport.y - context_menu.size.y))
	context_menu.position = Vector2i(origin)

func _context_action(id: int) -> void:
	if context_entry.is_empty() or str(context_entry["key"]) not in simulation.inventory.entry_keys():
		return
	match id:
		0:
			selected_key = str(context_entry["key"])
			actions.show_information()
			refresh()
			_scroll_top()
		1:
			actions.use_selected()
		2:
			actions.toggle_craft()
		3:
			_request_discard()

func _request_discard() -> void:
	var item := actions.entry
	if item.is_empty() or (item["type"] == "gu" and int(item["slot"]) >= 0): return
	discard_snapshot = {"key": str(item["key"]), "quantity": int(item.get("quantity", 1)), "version": simulation.inventory.version}
	discard_dialog.dialog_text = "Xóa %s%s? Không thể hoàn tác." % [str(item["title"]), " ×%d" % int(item["quantity"]) if item["type"] == "material" else ""]
	discard_dialog.popup_centered()

func _confirm_discard() -> void:
	if discard_snapshot.is_empty(): return
	var snapshot := discard_snapshot.duplicate()
	discard_snapshot.clear()
	discard_requested.emit(snapshot["key"], snapshot["quantity"], snapshot["version"])

func close_top_overlay() -> bool:
	if discard_dialog.visible:
		discard_dialog.hide()
		discard_snapshot.clear()
		return true
	if context_menu.visible:
		context_menu.hide()
		return true
	return false

func close_overlays() -> void:
	context_menu.hide()
	discard_dialog.hide()
	discard_snapshot.clear()

func _scroll_top() -> void:
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0

func _update_details_visibility() -> void:
	details.visible = actions.entry.get("type") == "gu" and not actions.crafting
	material_detail.visible = not details.visible and not actions.crafting

func refresh() -> void:
	var inv := simulation.inventory
	entries.clear()
	var present: Array[String] = []
	for item in inv.gu:
		var id := str(item["instance_id"])
		var definition := simulation.catalog.get_gu(str(item["definition_id"]))
		present.append(id)
		entries.append({"key": "gu:" + id, "type": "gu", "instance_id": id, "title": definition["full_name"], "kind": definition["kind"], "color": definition["color"], "slot": item["slot"], "hunger": item["hunger"], "rank": item["rank"], "cultivation": item.get("cultivation", 1), "description": definition["description"]})
		if not rows.has(id):
			var row := GuInventoryRow.new()
			row.configure(item, definition)
			row.feed_requested.connect(func(instance: String, food: String): feed_requested.emit(instance, food))
			rows[id] = row
			details.add_child(row)
		rows[id].refresh(item, inv.materials, bool(simulation.player["dead"]))
	for id in rows.keys():
		if id not in present:
			var removed: GuInventoryRow = rows[id]
			details.remove_child(removed)
			removed.queue_free()
			rows.erase(id)
	for kind in ExpeditionModel.MATERIAL_NAMES:
		var remaining := int(inv.materials.get(kind, 0))
		var stack := 0
		while remaining > 0:
			var quantity := mini(99, remaining)
			entries.append({"key": "material:%s:%d" % [kind, stack], "type": "material", "material": kind, "title": ExpeditionModel.material_name(kind), "quantity": quantity})
			remaining -= quantity
			stack += 1
	var order := inv.ordered_keys()
	entries.sort_custom(func(a: Dictionary, b: Dictionary): return order.find(str(a["key"])) < order.find(str(b["key"])))
	var visible_entries: Array[Dictionary] = []
	if filter_kind == "all" and not sort_by_name:
		var by_key := {}
		for entry in entries: by_key[entry["key"]] = entry
		for key in inv.display_slots(): visible_entries.append(by_key.get(key, {}))
	else:
		for entry in entries:
			if filter_kind == "all" or entry["type"] == filter_kind: visible_entries.append(entry)
	if sort_by_name:
		visible_entries.sort_custom(func(a: Dictionary, b: Dictionary): return str(a["title"]) + str(a["key"]) < str(b["title"]) + str(b["key"]))
	var selected: Dictionary = {}
	for entry in visible_entries:
		if entry.get("key", "") == selected_key:
			selected = entry
	if selected.is_empty() and not visible_entries.is_empty():
		for entry in visible_entries:
			if not entry.is_empty():
				selected = entry
				break
	selected_key = str(selected.get("key", ""))
	for i in range(slots.size()):
		var entry: Dictionary = visible_entries[i] if i < visible_entries.size() else {}
		slots[i].inventory_version = inv.version
		slots[i].allow_empty_drop = filter_kind == "all" and not sort_by_name
		slots[i].set_entry(entry, not entry.is_empty() and entry["key"] == selected_key)
	for i in range(filter_buttons.size()):
		filter_buttons[i].set_pressed_no_signal(filter_kind == ["all", "gu", "material"][i])
	sort_button.set_pressed_no_signal(sort_by_name)
	capacity_label.text = "Hành trang %d / 30 ô  ·  %d ngân lượng" % [inv.occupied_slots(), simulation.player["currency"]]
	if not inv.pending_materials.is_empty():
		capacity_label.text += "\nChiến lợi phẩm đang chờ ô trống."
	for id in rows:
		rows[id].visible = selected_key == "gu:" + str(id)
	actions.present(selected)
	_update_details_visibility()
	if selected.get("type", "") == "material":
		material_detail.text = "%s\nChồng %d / 99 · Tổng %d" % [selected["title"], selected["quantity"], inv.materials[selected["material"]]]
	elif selected.is_empty():
		material_detail.text = "Chưa có vật phẩm trong nhóm này."
