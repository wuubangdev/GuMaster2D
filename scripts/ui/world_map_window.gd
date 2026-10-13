class_name GuWorldMapWindow
extends PanelContainer
## A large regional map that uses the same terrain, sites and facing as the HUD.
signal close_requested
signal travel_requested
var simulation: LocalAuthority
var atlas: RegionalAtlas
var title: Label
var position_label: Label
var refresh_left := 0.0

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	name = "LargeWorldMap"
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", GuPixelUI.frame("panel", 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	box.add_child(heading)
	title = _label("ĐỊA ĐỒ", 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := GuInkButton.new()
	close.text = "Đóng [Esc / F2]"
	close.custom_minimum_size = Vector2(128, 34)
	close.add_theme_font_size_override("font_size", 13)
	close.pressed.connect(func(): close_requested.emit())
	heading.add_child(close)
	position_label = _label("", 15)
	position_label.add_theme_color_override("font_color", GuPixelUI.JADE)
	box.add_child(position_label)
	atlas = RegionalAtlas.new()
	atlas.simulation = simulation
	atlas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(atlas)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var help := _label("Chọn bãi farm, trạm hoặc NPC trên bản đồ.", 13)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(help)
	var travel := GuInkButton.new()
	travel.text = "Dẫn đường / Cổ trận [T]"
	travel.custom_minimum_size = Vector2(196, 34)
	travel.add_theme_font_size_override("font_size", 13)
	travel.pressed.connect(func(): travel_requested.emit())
	footer.add_child(travel)
	get_viewport().size_changed.connect(fit)
	fit()
	hide()

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GuPixelUI.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func fit() -> void:
	var viewport := get_viewport_rect().size
	var dimensions := Vector2(minf(1400, viewport.x - 48), minf(920, viewport.y - 48))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = (viewport - dimensions) * .5
	size = dimensions

func open_map() -> void:
	fit()
	atlas.selected = "camp"
	refresh()
	show()

func refresh() -> void:
	title.text = "ĐỊA ĐỒ  /  " + str(ExpeditionModel.REGIONS[simulation.expedition.region]["name"]).to_upper()
	var cell := Vector2(simulation.player["cell"])
	position_label.text = "Vị trí hiện tại  X: %d  Y: %d    •    Hướng: %s" % [roundi(cell.x), roundi(cell.y), GuMinimap.direction_label(simulation.player["facing"])]
	atlas.queue_redraw()

func _process(delta: float) -> void:
	if not visible or simulation == null: return
	refresh_left -= delta
	if refresh_left <= 0.0:
		refresh_left = .1
		refresh()
