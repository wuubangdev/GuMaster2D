class_name GuCultivationWorkshop
extends HBoxContainer
## Persistent workshop controls; progression queries/mutations stay in authority.
signal command_requested(command: String, args: Dictionary)
signal selection_changed(instance_id: String)

var simulation: LocalAuthority
var selected_id := "gu_1"
var mode := "upgrade"
var donor_id := ""
var reduced_motion := false
var rows: Dictionary = {}
var list_box: VBoxContainer
var list_scroll: ScrollContainer
var count_label: Label
var title: Label
var state_label: Label
var description: Label
var portrait: GuSkillPortrait
var mode_buttons: Dictionary = {}
var detail_scroll: ScrollContainer
var stat_cells: Dictionary = {}
var donor_row: HBoxContainer
var donor_picker: OptionButton
var donor_caption: Label
var donor_ids: Array[String] = []
var explanation: Label
var cost_labels: Dictionary = {}
var cost_grid: GridContainer
var reason: Label
var action_button: Button
var outcome: Label
var confirmation: ConfirmationDialog
var pending: Dictionary = {}
var preview: Dictionary = {}
var selection_tween: Tween

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 22)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 200
	sidebar.add_theme_constant_override("separation", 8)
	add_child(sidebar)
	count_label = _label("", 15, GuPixelUI.JADE)
	sidebar.add_child(count_label)
	sidebar.add_child(_label("Trang bị / dự trữ", 12, GuPixelUI.MUTED))
	list_scroll = ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(list_scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 4)
	list_scroll.add_child(list_box)
	var divider := VSeparator.new()
	divider.modulate = Color(GuPixelUI.MUTED, .35)
	add_child(divider)
	var workspace := VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 8)
	add_child(workspace)
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 14)
	workspace.add_child(hero)
	portrait = GuSkillPortrait.new()
	portrait.custom_minimum_size = Vector2(144, 118)
	hero.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 4)
	hero.add_child(identity)
	title = _label("", 26)
	identity.add_child(title)
	state_label = _label("", 15, GuPixelUI.JADE)
	identity.add_child(state_label)
	description = _label("", 13, GuPixelUI.MUTED)
	identity.add_child(description)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	workspace.add_child(navigation)
	for id in ["upgrade", "fuse"]:
		var tab := _button(navigation, "Cường hóa • mức 1–5" if id == "upgrade" else "Nâng bậc • luyện hợp", func(): set_mode(id))
		tab.toggle_mode = true
		mode_buttons[id] = tab
	detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 9)
	detail_scroll.add_child(detail)
	var stats := GridContainer.new()
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 18)
	stats.add_theme_constant_override("v_separation", 5)
	detail.add_child(stats)
	for caption in ["CHỈ SỐ", "Hiện tại", "Sau thao tác"]:
		var heading := _label(caption, 13, GuPixelUI.MUTED)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(heading)
	for key in ["strength", "effect", "cooldown", "mana", "hunger"]:
		var cells: Array[Label] = []
		for i in range(3):
			var cell := _label("", 15, GuPixelUI.JADE if i == 2 else GuPixelUI.INK)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			stats.add_child(cell)
			cells.append(cell)
		stat_cells[key] = cells
	donor_row = HBoxContainer.new()
	donor_row.add_theme_constant_override("separation", 10)
	detail.add_child(donor_row)
	donor_caption = _label("Phôi tiêu hao", 13)
	donor_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	donor_row.add_child(donor_caption)
	donor_picker = OptionButton.new()
	donor_picker.custom_minimum_size.y = 32
	donor_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	donor_picker.add_theme_font_size_override("font_size", 13)
	donor_picker.get_popup().theme = GuPixelUI.popup_theme()
	donor_picker.item_selected.connect(func(index: int): donor_id = str(donor_picker.get_item_metadata(index)); present(selected_id))
	donor_row.add_child(donor_picker)
	explanation = _label("", 12, GuPixelUI.MUTED)
	detail.add_child(explanation)
	var separator := HSeparator.new()
	separator.modulate = Color(GuPixelUI.MUTED, .35)
	workspace.add_child(separator)
	workspace.add_child(_label("NGUYÊN LIỆU  ·  CÓ / CẦN", 12, GuPixelUI.MUTED))
	cost_grid = GridContainer.new()
	cost_grid.columns = 3
	cost_grid.add_theme_constant_override("h_separation", 14)
	workspace.add_child(cost_grid)
	for key in ["herb", "stone", "silk", "essence", "silver"]:
		var group := HBoxContainer.new()
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_theme_constant_override("separation", 5)
		cost_grid.add_child(group)
		var token := MaterialToken.new()
		token.kind = key
		group.add_child(token)
		var caption := _label("", 13)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_child(caption)
		cost_labels[key] = {"group": group, "label": caption}
	reason = _label("", 12)
	workspace.add_child(reason)
	action_button = _button(workspace, "", _submit)
	action_button.custom_minimum_size.y = 38
	confirmation = ConfirmationDialog.new()
	confirmation.name = "ConfirmGuFusion"
	confirmation.theme = GuPixelUI.popup_theme()
	confirmation.title = "Xác nhận luyện hợp Cổ"
	confirmation.ok_button_text = "Nâng bậc"
	confirmation.cancel_button_text = "Giữ lại"
	confirmation.confirmed.connect(_confirm)
	confirmation.canceled.connect(func(): pending.clear())
	add_child(confirmation)
	outcome = _label("", 13, GuPixelUI.JADE)
	outcome.hide()
	workspace.add_child(outcome)
	present(selected_id)

func _label(value: String, font_size: int, color: Color = GuPixelUI.INK) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	return result

func _button(parent: Node, caption: String, callback: Callable) -> Button:
	var result := GuInkButton.new()
	result.text = caption
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.y = 32
	result.add_theme_font_size_override("font_size", 14)
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func present(id: String) -> void:
	if simulation == null: return
	var item := simulation.inventory.find_instance(id)
	if item.is_empty():
		item = simulation.inventory.slot_gu(0)
		id = str(item["instance_id"])
	var changed := selected_id != id
	selected_id = id
	if changed:
		donor_id = ""
		detail_scroll.scroll_vertical = 0
		outcome.hide()
		if selection_tween != null and selection_tween.is_valid(): selection_tween.kill()
		portrait.modulate.a = 1.0 if reduced_motion else .45
		if not reduced_motion:
			selection_tween = create_tween()
			selection_tween.tween_property(portrait, "modulate:a", 1.0, .14)
	var present_ids: Array[String] = []
	for gu in simulation.inventory.gu:
		var instance := str(gu["instance_id"])
		present_ids.append(instance)
		if not rows.has(instance):
			var row := GuRow.new()
			row.pressed.connect(func(): selection_changed.emit(instance); present(instance))
			list_box.add_child(row)
			rows[instance] = row
		rows[instance].present(gu, simulation.catalog.get_gu(str(gu["definition_id"])), instance == selected_id)
	for instance in rows.keys():
		if instance not in present_ids:
			list_box.remove_child(rows[instance])
			rows[instance].queue_free()
			rows.erase(instance)
	if changed: _reveal_selected.call_deferred()
	count_label.text = "CỔ ĐANG CÓ  ·  %d" % present_ids.size()
	var definition := simulation.catalog.get_gu(str(item["definition_id"]))
	title.text = str(definition["full_name"])
	state_label.text = "Bậc %s  ·  Cường hóa %d/5  ·  %s\nNo đủ %.0f%%  ·  %d chân nguyên  ·  hồi chiêu %.2fs" % [rank_label(int(item["rank"])), item.get("cultivation", 1), "Khảm [%d]" % (int(item["slot"]) + 1) if int(item["slot"]) >= 0 else "Dự trữ", item["hunger"], definition["mana"], GuCultivationRules.stats(simulation, item)["cooldown"]]
	description.text = str(definition["description"])
	portrait.kind = str(definition["kind"])
	portrait.rank_value = int(item["rank"])
	portrait.queue_redraw()
	_refresh_donors(item)
	preview = GuCultivationRules.preview(simulation, mode, selected_id, donor_id)
	for key in mode_buttons: mode_buttons[key].set_pressed_no_signal(mode == key)
	donor_row.visible = mode == "fuse"
	_refresh_stats(definition)
	for key in cost_labels:
		var required := int(preview["cost"].get(key, 0))
		cost_labels[key]["group"].visible = required > 0
		var have := int(simulation.player["currency"]) if key == "silver" else int(simulation.inventory.materials.get(key, 0))
		var caption: Label = cost_labels[key]["label"]
		caption.text = "%s\n%d / %d" % [ExpeditionModel.material_name(key), have, required]
		caption.add_theme_color_override("font_color", GuPixelUI.INK if have >= required else GuPixelUI.VERMILION)
	reason.text = _reason(str(preview["error"]), item)
	reason.add_theme_color_override("font_color", GuPixelUI.JADE if preview["ok"] else GuPixelUI.VERMILION)
	action_button.disabled = not preview["ok"]
	var after: Dictionary = preview["after"]
	action_button.text = "Cường hóa lên mức %d" % after["cultivation"] if mode == "upgrade" else "Nâng lên bậc %s" % rank_label(int(after["rank"]))
	if str(preview["error"]) in ["MAX_CULTIVATION", "MAX_RANK"]: action_button.text = "Đã đạt mức tối đa" if mode == "upgrade" else "Đã đạt bậc III"
	explanation.text = "Tăng một mức, giữ bậc và Cổ hiện tại. Thành công 100%." if mode == "upgrade" else "Tiêu hao phôi đã chọn; Cổ chính lên bậc %s, về mức 1 và no đủ 100%%. Giữ ô kỹ năng. Thành công 100%%." % rank_label(int(after["rank"]))
	if str(preview["error"]) == "MAX_RANK": explanation.text = "Bậc III là giới hạn hiện có. Cổ chính và phôi được giữ nguyên."
	if definition["kind"] == "shield": explanation.text += " Khiên tối đa bằng 40% sinh lực."

static func rank_label(value: int) -> String:
	return ["I", "II", "III"][clampi(value, 1, 3) - 1]

func _reveal_selected() -> void:
	# Container layout must settle before a newly created reserve row can scroll.
	await get_tree().process_frame
	if rows.has(selected_id) and is_inside_tree(): list_scroll.ensure_control_visible(rows[selected_id])

func _refresh_donors(item: Dictionary) -> void:
	var eligible := GuCultivationRules.donors(simulation, item)
	var ids: Array[String] = []
	for candidate in eligible: ids.append(str(candidate["instance_id"]))
	if donor_id not in ids: donor_id = ""
	if ids != donor_ids or donor_picker.item_count == 0:
		donor_ids = ids
		donor_picker.clear()
		donor_picker.add_item("Chọn Cổ dự trữ cùng loại…")
		donor_picker.set_item_metadata(0, "")
		for candidate in eligible:
			donor_picker.add_item("%s · bậc I · mức %d" % [candidate["instance_id"], candidate.get("cultivation", 1)])
			donor_picker.set_item_metadata(donor_picker.item_count - 1, str(candidate["instance_id"]))
	for index in range(eligible.size()):
		donor_picker.set_item_text(index + 1, "%s · bậc I · mức %d" % [eligible[index]["instance_id"], eligible[index].get("cultivation", 1)])
	donor_picker.select(ids.find(donor_id) + 1 if donor_id != "" else 0)
	donor_picker.disabled = ids.is_empty()

func _refresh_stats(definition: Dictionary) -> void:
	var before: Dictionary = preview["before_stats"]
	var after: Dictionary = preview["after_stats"]
	var kind := str(definition["kind"])
	var values := {
		"strength": ["Sức mạnh", "×%.2f" % before["strength"], "×%.2f" % after["strength"]],
		"effect": ["Khiên hấp thụ" if kind == "shield" else ("Tầm lướt" if kind == "dash" else "Sát thương"), "%.0f" % before["shield"] if kind == "shield" else ("%.0f ô" % definition["range"] if kind == "dash" else str(before["damage"])), "%.0f" % after["shield"] if kind == "shield" else ("%.0f ô" % definition["range"] if kind == "dash" else str(after["damage"]))],
		"cooldown": ["Hồi chiêu", "%.2f s" % before["cooldown"], "%.2f s" % after["cooldown"]],
		"mana": ["Chân nguyên", str(before["mana"]), str(after["mana"])],
		"hunger": ["No đủ", "%.0f%%" % before["hunger"], "%.0f%%" % after["hunger"]]
	}
	for key in stat_cells:
		var show_row: bool = key == "strength" or (key == "cooldown" and kind == "dash") or (key == "effect" and kind != "dash")
		for index in range(3):
			stat_cells[key][index].text = values[key][index]
			stat_cells[key][index].visible = show_row

func _reason(code: String, item: Dictionary) -> String:
	return {"": "Đủ điều kiện • thực hiện tại vùng an toàn.", "DEAD": "Đang trọng thương.", "IN_COMBAT": "Chờ hết giao chiến hoặc phong ấn.", "AT_CAMP": "Về trại, trạm nghỉ hoặc bí cảnh để luyện Cổ.", "MAX_CULTIVATION": "Cường hóa viên mãn. Chuyển Nâng bậc để luyện hợp.", "MAX_RANK": "Cổ đã đạt bậc cao nhất hiện có.", "NEED_CULTIVATION": "Cổ chính cần cường hóa mức %d trước khi nâng bậc." % (3 if int(item["rank"]) == 1 else 5), "NEED_DONOR": "Chọn một phôi dự trữ bậc I cùng loại." if not donor_ids.is_empty() else "Chưa có phôi dự trữ bậc I cùng loại; bắt thêm Cổ [C].", "NEED_MATERIALS": "Chưa đủ nguyên liệu hoặc bạc; xem số có / cần."}.get(code, "Không thể thực hiện.")

func set_mode(value: String) -> void:
	mode = value
	outcome.hide()
	detail_scroll.scroll_vertical = 0
	present(selected_id)

func _submit() -> void:
	present(selected_id)
	if not preview["ok"]: return
	var args := {"id": selected_id, "version": simulation.inventory.version}
	if mode == "upgrade":
		command_requested.emit("upgrade", args)
		return
	args["donor"] = donor_id
	pending = args.duplicate(true)
	var phoi := simulation.inventory.find_instance(donor_id)
	var costs: Array[String] = []
	for key in preview["cost"]: costs.append("%s ×%d" % [ExpeditionModel.material_name(key), preview["cost"][key]])
	confirmation.dialog_text = "Nâng %s (%s) lên bậc %s, mức 1.\nTiêu hao phôi %s (bậc I, mức %d).\nNguyên liệu: %s.\nCổ chính và ô kỹ năng được giữ lại.\nPhôi đã tiêu hao không thể hoàn tác." % [title.text, selected_id, rank_label(int(preview["after"]["rank"])), donor_id, phoi.get("cultivation", 1), ", ".join(costs)]
	confirmation.popup_centered()

func _confirm() -> void:
	if pending.is_empty(): return
	var args := pending.duplicate(true)
	pending.clear()
	command_requested.emit("fuse", args)

func close_overlays() -> void:
	confirmation.hide()
	donor_picker.get_popup().hide()
	pending.clear()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		if selection_tween != null and selection_tween.is_valid(): selection_tween.kill()
		portrait.modulate.a = 1.0
		portrait.celebrate(true)

func receive(event: Dictionary) -> void:
	if event["kind"] not in ["gu_upgrade", "gu_fusion"]: return
	if event["kind"] == "gu_upgrade" and not event.get("cultivated_gu", false): return
	present(selected_id)
	outcome.text = str(event.get("text", "Thành công"))
	outcome.show()
	portrait.celebrate(reduced_motion)

class GuRow extends Button:
	var item: Dictionary = {}
	var definition: Dictionary = {}
	var active := false
	var captions: Array[Label] = []
	func _ready() -> void:
		custom_minimum_size = Vector2(190, 84)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		for i in range(3):
			var caption := Label.new()
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			caption.add_theme_font_override("font", GuPixelUI.HAND_FONT)
			caption.add_theme_font_size_override("font_size", 15 if i == 0 else 12)
			caption.add_theme_color_override("font_color", [GuPixelUI.INK, GuPixelUI.MUTED, GuPixelUI.JADE][i])
			caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			caption.clip_text = true
			caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(caption)
			captions.append(caption)
		resized.connect(_layout_captions)
		_layout_captions()
	func _layout_captions() -> void:
		for i in range(captions.size()):
			captions[i].position = Vector2(56, [8, 35, 57][i])
			captions[i].size = Vector2(maxf(0, size.x - 66), 24 if i == 0 else 18)
	func present(value: Dictionary, catalog_entry: Dictionary, selected: bool) -> void:
		item = value.duplicate(true)
		definition = catalog_entry
		active = selected
		var slot := int(item["slot"])
		captions[0].text = str(definition["name"])
		captions[1].text = "Khảm [%d]" % (slot + 1) if slot >= 0 else "Dự trữ · " + str(item["instance_id"])
		captions[2].text = "Bậc %s · mức %d/5" % [GuCultivationWorkshop.rank_label(int(item["rank"])), item.get("cultivation", 1)]
		tooltip_text = "%s\n%s\n%s" % [definition["full_name"], captions[1].text, captions[2].text]
		queue_redraw()
	func _draw() -> void:
		if item.is_empty(): return
		var bounds := Rect2(Vector2.ONE, size - Vector2.ONE * 2)
		if active or is_hovered():
			GuPixelUI.brush_fill(self, bounds, GuPixelUI.JADE_LIGHT if active else GuPixelUI.PAPER_LIGHT, 42, .3)
			GuPixelUI.brush_frame(self, bounds, GuPixelUI.JADE if active else GuPixelUI.MUTED, 15, 1.1, .4)
		GuSkillArt.draw(self, str(definition["kind"]), Vector2(28, 42), 18)

class MaterialToken extends Control:
	var kind := "herb"
	func _init() -> void:
		custom_minimum_size = Vector2(26, 32)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if kind == "silver":
			draw_circle(Vector2(13, 17), 9, GuPixelUI.PAPER_SHADE, true, -1, true)
			draw_arc(Vector2(13, 17), 9, 0, TAU, 24, GuPixelUI.GOLD, 1.5, true)
			draw_rect(Rect2(Vector2(10, 14), Vector2(6, 6)), GuPixelUI.INK_SOFT, false, 1)
		else: GuPixelUI.material_icon(self, kind, Vector2(13, 17), 10)
