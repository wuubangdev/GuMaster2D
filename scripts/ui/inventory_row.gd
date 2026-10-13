class_name GuInventoryRow
extends HBoxContainer
## Reused by instance ID: feeding never discards the selected Gu's pressed button.

signal feed_requested(instance_id: String, food: String)
var instance_id: String
var definition: Dictionary
var title_label: Label
var detail_label: Label
var hunger_bar: ProgressBar
var hunger_label: Label
var feed_button: Button

func configure(item: Dictionary, gu: Dictionary) -> void:
	instance_id = str(item["instance_id"])
	definition = gu
	custom_minimum_size.y = 82
	add_theme_constant_override("separation", 10)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 49
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(spacer)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	add_child(details)
	title_label = _label(str(gu["full_name"]), 15, GuPixelUI.JADE)
	details.add_child(title_label)
	detail_label = _label("", 11, GuPixelUI.MUTED)
	details.add_child(detail_label)
	hunger_bar = ProgressBar.new()
	hunger_bar.custom_minimum_size.y = 4
	hunger_bar.show_percentage = false
	hunger_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = GuPixelUI.PAPER_SHADE
	background.border_color = GuPixelUI.PAPER_SHADE.darkened(0.18)
	hunger_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GuPixelUI.JADE_LIGHT
	hunger_bar.add_theme_stylebox_override("fill", fill)
	details.add_child(hunger_bar)
	hunger_label = _label("", 11, GuPixelUI.MUTED)
	details.add_child(hunger_label)
	feed_button = GuInkButton.new()
	feed_button.name = "FeedButton"
	feed_button.custom_minimum_size = Vector2(88, 34)
	feed_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	feed_button.add_theme_font_size_override("font_size", 11)
	feed_button.pressed.connect(func(): feed_requested.emit(instance_id, str(definition["food"])))
	add_child(feed_button)
	tooltip_text = str(gu["description"])

func refresh(item: Dictionary, materials: Dictionary, dead: bool) -> void:
	var hunger := float(item["hunger"])
	var count := int(materials.get(definition["food"], 0))
	var slot := int(item["slot"])
	detail_label.text = "Khảm [%s]  ·  %s ×%d" % [GameBindings.skill_label(slot), GuCatalog.FOOD_NAMES[definition["food"]], count] if slot >= 0 else "Thu phục  ·  %s ×%d" % [GuCatalog.FOOD_NAMES[definition["food"]], count]
	hunger_bar.value = hunger
	hunger_label.text = "No đủ %.1f / 100" % hunger
	hunger_label.add_theme_color_override("font_color", GuPixelUI.VERMILION if hunger < 25 else GuPixelUI.MUTED)
	feed_button.disabled = dead or hunger > 99.99 or count <= 0
	feed_button.text = "Trọng thương" if dead else ("Đã no" if hunger > 99.99 else ("Hết thức ăn" if count <= 0 else "Cho ăn +40"))
	feed_button.tooltip_text = "Dùng 1 %s, tăng tối đa 40 no đủ." % GuCatalog.FOOD_NAMES[definition["food"]]

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _draw() -> void:
	var socket := Rect2(1, 7, 44, 47)
	draw_rect(socket, Color("ead8b7"))
	draw_rect(socket.grow(-0.5), GuPixelUI.INK_SOFT, false, 1)
	draw_rect(socket.grow(-4), Color("c5ae83"), false, 1)
	GuPixelUI.icon(self, str(definition["kind"]), socket.get_center(), 15, Color(str(definition["color"])))
	draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(GuPixelUI.INK_SOFT, 0.28), 1.0)
