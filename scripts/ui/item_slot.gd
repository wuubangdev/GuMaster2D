class_name GuItemSlot
extends Button
## A real inventory entry (unique Gu or one material stack), never a simulated item.
signal context_requested(item: Dictionary, at: Vector2)
signal move_requested(source_key: String, destination_slot: int, expected_version: int)

var entry: Dictionary = {}
var selected: bool = false
var item_texture: Texture2D
var slot_index := 0
var inventory_version := 0
var allow_empty_drop := true
var quantity_label: Label
var key_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(68, 72)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	quantity_label = _caption(HORIZONTAL_ALIGNMENT_RIGHT, 12, GuPixelUI.INK)
	quantity_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	quantity_label.offset_left = 10
	quantity_label.offset_right = -10
	quantity_label.offset_top = -28
	quantity_label.offset_bottom = -10
	key_label = _caption(HORIZONTAL_ALIGNMENT_LEFT, 10, GuPixelUI.JADE)
	key_label.position = Vector2(10, 8)
	key_label.size = Vector2(16, 16)
	_sync_captions()

func _caption(alignment_value: HorizontalAlignment, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GuPixelUI.HAND_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _sync_captions() -> void:
	if quantity_label == null: return
	quantity_label.visible = entry.get("type") == "material"
	quantity_label.text = str(entry.get("quantity", ""))
	var slot := int(entry.get("slot", -1))
	key_label.visible = entry.get("type") == "gu" and slot >= 0
	key_label.text = GameBindings.skill_label(slot) if slot >= 0 else ""

func set_entry(value: Dictionary, active: bool) -> void:
	if entry == value and selected == active:
		return
	entry = value.duplicate(true)
	selected = active
	disabled = false
	tooltip_text = "Ô trống • kéo vật phẩm vào để sắp xếp" if entry.is_empty() else str(entry["title"])
	if not entry.is_empty():
		if entry["type"] == "gu":
			tooltip_text += "\nBậc %d • mức %d • no đủ %.0f%%\n%s" % [entry.get("rank", 1), entry.get("cultivation", 1), entry.get("hunger", 100), entry.get("description", "")]
		else:
			tooltip_text += " ×%d\n%s" % [entry["quantity"], ItemCrafting.description(str(entry["material"]))]
	item_texture = null
	_sync_captions()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not entry.is_empty():
		context_requested.emit(entry.duplicate(true), get_global_transform_with_canvas() * event.position)
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if entry.is_empty() or not entry.has("key"): return null
	var preview := Label.new()
	preview.text = str(entry["title"])
	preview.add_theme_font_size_override("font_size", 13)
	preview.add_theme_color_override("font_color", GuPixelUI.INK)
	preview.add_theme_stylebox_override("normal", GuPixelUI.frame("panel", 12))
	set_drag_preview(preview)
	return {"inventory_key": str(entry["key"]), "inventory_version": inventory_version}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (not entry.is_empty() or allow_empty_drop) and data is Dictionary and data.get("inventory_key") is String and data.get("inventory_version") == inventory_version and not str(data["inventory_key"]).is_empty() and str(data["inventory_key"]) != str(entry.get("key", ""))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position, data):
		move_requested.emit(str(data["inventory_key"]), slot_index, int(data["inventory_version"]))

func _notification(what: int) -> void:
	if what in [NOTIFICATION_DRAG_BEGIN, NOTIFICATION_DRAG_END]: queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ONE, size - Vector2.ONE * 2)
	var frame := GuPixelUI.frame("normal", 0)
	frame.bg_color = Color("ddc8a0") if entry.is_empty() else Color("efddba")
	frame.border_color = Color(GuPixelUI.INK_SOFT, 0.14)
	frame.set_corner_radius_all(3)
	GuPixelUI.brush_fill(self, bounds, frame.bg_color, int(position.x + position.y), 0.48)
	var grain_bounds := bounds.grow(-2)
	GuPixelUI.paper_wash(self, grain_bounds, int(position.x * 3 + position.y))
	GuPixelUI.paper_grain(self, grain_bounds, int(position.x + position.y * 5))
	if entry.is_empty():
		var dropping := is_hovered() and get_viewport().gui_is_dragging() and _can_drop_data(Vector2.ZERO, get_viewport().gui_get_drag_data())
		GuPixelUI.brush_frame(self, bounds, GuPixelUI.JADE if dropping else Color(GuPixelUI.INK_SOFT, 0.46), int(position.x + position.y), 1.8 if dropping else 1.0)
		return
	var center := size / 2
	draw_circle(center + Vector2(1.2, 1.4), 12.8, Color(GuPixelUI.GOLD, 0.075), true, -1, true)
	if entry["type"] == "gu":
		GuPixelUI.icon(self, str(entry["kind"]), Vector2(size.x * .5, 42), 17, Color(str(entry["color"])))
		if float(entry.get("hunger", 100)) < 25:
			draw_circle(Vector2(size.x - 8, 9), 3, Color("e39c64"), true, -1, true)
	else:
		GuPixelUI.material_icon(self, str(entry["material"]), Vector2(size.x * .5, 26), 14)
	if selected:
		GuPixelUI.brush_frame(self, bounds.grow(-0.5), GuPixelUI.JADE, 11, 1.45)
		draw_line(Vector2(8, size.y - 4), Vector2(size.x - 8, size.y - 4), Color(GuPixelUI.JADE, 0.82), 1.25, true)
	elif is_hovered():
		GuPixelUI.brush_frame(self, bounds, GuPixelUI.GOLD, 5, 1.05)
	else:
		GuPixelUI.brush_frame(self, bounds, Color(GuPixelUI.INK_SOFT, 0.68), int(position.y), 1.2, 0.9)
