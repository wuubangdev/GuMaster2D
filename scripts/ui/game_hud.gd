class_name GameHUD
extends CanvasLayer

signal skill_requested(slot: int)
signal feed_requested(instance_id: String, food: String)
signal pause_requested
signal mute_requested
signal motion_requested
signal volume_requested(value: float)
signal display_requested(window_size: Vector2i, fullscreen: bool)
signal inventory_move_requested(source_key: String, destination_slot: int, expected_version: int)
signal inventory_discard_requested(key: String, quantity: int, expected_version: int)
signal inventory_craft_requested(recipe_id: String, batches: int, expected_version: int)
signal inventory_seal_requested
signal gameplay_window_opened
signal appearance_requested(appearance: Dictionary)

const INK := GuPixelUI.INK
const IVORY := GuPixelUI.INK
const MUTED := GuPixelUI.MUTED
signal cultivation_requested(command: String, args: Dictionary)
signal dialogue_requested(command: String, id: String)
signal dialogue_closed
signal npc_quest_requested(command: String, id: String)
var dialogue: NpcDialogue
var dialogue_open := false
var npc_quest_list: NpcQuestList
var npc_journal_open := false
var journal_switch: Button
var legacy_journal_nodes: Array[Node] = []
var quest_title_label: Label
var quest_reward_label: Label
var cultivation_book: CultivationBook
var cultivation_open := false
var region_title: Label
var map_coordinates: Label
var minimap: GuMinimap
var map_expand_button: Button
var large_map: GuWorldMapWindow
var large_map_open := false
var cultivation_button: Button
var simulation: LocalAuthority
var world_view: WorldView
var root: Control
var quest_text: Label
var quest_panel: PanelContainer
var quest_content: VBoxContainer
var hotbar: HBoxContainer
var map_panel: PanelContainer
var quest_toggle: Button
var quest_collapsed: bool = false
var status_panel: PanelContainer
var action_belt: Panel
var bag_button: Button
var settings_button: Button
var character_button: Button
var journal_button: Button
var character_panel: PanelContainer
var journal_panel: PanelContainer
var character_open: bool = false
var journal_open: bool = false
var window_order: Array[String] = []
var character_title: Label
var character_values: Dictionary = {}
var character_doll: GuCharacterDoll
var portrait_doll: GuCharacterDoll
var character_studio: GuCharacterStudio
var studio_open: bool = false
var journal_objectives: Array[Label] = []
var journal_bars: Array[ProgressBar] = []
var journal_reward: Label
var journal_track: Button
var quest_tracked: bool = true
var journal_signature: String = ""
const BAG_LEFT: float = -488.0
const BAG_RIGHT: float = -26.0
var status_text: Label
var xp_bar: ProgressBar
var xp_text: Label
var shield_text: Label
var hp_bar: ProgressBar
var mana_bar: ProgressBar
var hp_readout: Label
var mana_readout: Label
var target_panel: PanelContainer
var target_text: Label
var target_bar: ProgressBar
var target_hint: Label
var skill_buttons: Array[SkillButton] = []
var hovered_skill: int = -1
var skill_detail: PanelContainer
var skill_title: Label
var skill_stats: Label
var skill_reason: Label
var skill_description: Label
var bag: PanelContainer
var bag_list: VBoxContainer
var materials_text: Label
var inventory_browser: GuInventoryBrowser
var bag_open: bool = false
var bag_version: int = -1
var bag_refresh: float = 0.0
var bag_rows: Dictionary = {}
var bag_tween: Tween
var backdrop: ColorRect
var overlay_tween: Tween
var pause_panel: PanelContainer
var paused: bool = false
var mute_button: Button
var motion_button: Button
var volume_slider: HSlider
var volume_value: Label
var resolution_picker: OptionButton
var fullscreen_button: CheckButton
var reduced_motion: bool = false
var death_text: Label
var capture_label: Label
var capture_bar: ProgressBar
var toast_label: Label
var toast_left: float = 0.0
var toast_queue: Array[Dictionary] = []
var toast_error: bool = false
var showing_intro: bool = false
var hint: Label

func setup(authority: LocalAuthority, view: WorldView) -> void:
	simulation = authority
	world_view = view
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
	# Only the actual skill dock consumes gaps between action buttons.
	action_belt = Panel.new()
	action_belt.name = "ActionBelt"
	_place(action_belt, Vector2(-176, -118), Vector2(352, 114), Control.PRESET_CENTER_BOTTOM)
	action_belt.mouse_filter = Control.MOUSE_FILTER_STOP
	action_belt.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var chrome := GuHudChrome.new()
	root.add_child(chrome)
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quest_panel = _panel(root, Vector2(14, 174), Vector2(266, 156))
	var quest_box := _vbox(quest_panel)
	var quest_header := HBoxContainer.new()
	quest_header.alignment = BoxContainer.ALIGNMENT_CENTER
	quest_box.add_child(quest_header)
	var quest_title := _label("KHẢO NGHIỆM NHẬP MÔN", 12, GuPixelUI.INK_SOFT)
	quest_title_label = quest_title
	quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_header.add_child(quest_title)
	quest_toggle = GuInkButton.new()
	quest_toggle.text = "−"
	quest_toggle.tooltip_text = "Thu gọn nhiệm vụ"
	quest_toggle.custom_minimum_size = Vector2(22, 22)
	quest_toggle.add_theme_font_size_override("font_size", 18)
	for state in ["normal", "hover", "pressed"]:
		quest_toggle.add_theme_stylebox_override(state, _frame("slot" if state == "normal" else state, 3))
	quest_toggle.focus_mode = Control.FOCUS_NONE
	quest_toggle.pressed.connect(toggle_quest)
	quest_header.add_child(quest_toggle)
	quest_content = _vbox(quest_box)
	quest_text = _label("", 13, IVORY)
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_content.add_child(quest_text)
	quest_reward_label = _label("Thưởng: 200 ngân lượng", 12, GuPixelUI.GOLD.darkened(0.12))
	quest_content.add_child(quest_reward_label)
	map_panel = PanelContainer.new()
	_place(map_panel, Vector2(-206, 14), Vector2(192, 192), Control.PRESET_TOP_RIGHT)
	map_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var map_box := _vbox(map_panel)
	map_box.add_theme_constant_override("separation", 4)
	var map_title := _label("VẠN THÚ SƠN", 13, GuPixelUI.PAPER_LIGHT)
	region_title = map_title
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_plate := _style(Color(GuPixelUI.INK, .92), Color.TRANSPARENT, 3)
	title_plate.set_border_width_all(0)
	map_title.add_theme_stylebox_override("normal", title_plate)
	map_box.add_child(map_title)
	minimap = GuMinimap.new()
	minimap.simulation = authority
	minimap.custom_minimum_size = Vector2(192, 124)
	minimap.open_requested.connect(toggle_large_map)
	map_box.add_child(minimap)
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel", _style(Color(GuPixelUI.INK, .92), Color.TRANSPARENT, 4))
	map_box.add_child(footer)
	var map_footer := HBoxContainer.new()
	map_footer.add_theme_constant_override("separation", 4)
	footer.add_child(map_footer)
	map_coordinates = _label("X: 0  Y: 0\nHướng: Nam", 12, GuPixelUI.PAPER_LIGHT)
	map_coordinates.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_footer.add_child(map_coordinates)
	map_expand_button = GuInkButton.new()
	map_expand_button.text = "↗"
	map_expand_button.custom_minimum_size = Vector2(32, 32)
	map_expand_button.add_theme_font_size_override("font_size", 20)
	map_expand_button.tooltip_text = "Mở địa đồ lớn [F2]"
	map_expand_button.pressed.connect(toggle_large_map)
	map_footer.add_child(map_expand_button)
	map_panel.resized.connect(_fit_map_dock)
	target_panel = _panel(root, Vector2(-155, 14), Vector2(310, 90), Control.PRESET_CENTER_TOP)
	var target_box := _vbox(target_panel)
	target_text = _label("", 14, IVORY)
	target_box.add_child(target_text)
	target_bar = _bar(GuPixelUI.VERMILION, 8)
	target_box.add_child(target_bar)
	target_hint = _label("", 12, GuPixelUI.JADE)
	target_box.add_child(target_hint)
	status_panel = _panel(root, Vector2(14, 14), Vector2(340, 148))
	var status_body := HBoxContainer.new()
	status_body.add_theme_constant_override("separation", 10)
	status_panel.add_child(status_body)
	var portrait_button := GuInkButton.new()
	portrait_button.custom_minimum_size = Vector2(54, 88)
	portrait_button.focus_mode = Control.FOCUS_NONE
	portrait_button.tooltip_text = "Nhân vật [F3]"
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		portrait_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	portrait_button.pressed.connect(toggle_character)
	status_body.add_child(portrait_button)
	var portrait := GuCharacterDoll.new()
	portrait_doll = portrait
	portrait.simulation = simulation
	portrait.compact = true
	portrait_button.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var status_box := _vbox(status_body)
	status_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_box.add_theme_constant_override("separation", 4)
	status_text = _label("", 13, IVORY)
	status_box.add_child(status_text)
	xp_bar = _bar(GuPixelUI.JADE, 4)
	xp_text = _label("", 10, MUTED)
	xp_text.hide()
	hp_bar = _bar(Color("a94f3d"), 28)
	status_box.add_child(hp_bar)
	hp_readout = _bar_readout(hp_bar)
	mana_bar = _bar(Color("597e87"), 28)
	status_box.add_child(mana_bar)
	mana_readout = _bar_readout(mana_bar)
	shield_text = _label("", 10, MUTED)
	status_box.add_child(shield_text)
	status_box.add_child(xp_bar)
	status_box.add_child(xp_text)
	hotbar = HBoxContainer.new()
	_place(hotbar, Vector2(-161, -110), Vector2(322, 94), Control.PRESET_CENTER_BOTTOM)
	hotbar.add_theme_constant_override("separation", 6)
	for i in range(4):
		var skill := SkillButton.new()
		skill.name = "Skill%d" % i
		skill.definition = authority.catalog.slot(i)
		skill.hotkey = GameBindings.skill_label(i)
		skill.mouse_entered.connect(_set_hovered_skill.bind(i))
		skill.mouse_exited.connect(_clear_hovered_skill.bind(i))
		skill.pressed.connect(func(): skill_requested.emit(i))
		skill.focus_mode = Control.FOCUS_NONE
		hotbar.add_child(skill)
		skill_buttons.append(skill)
	_build_skill_detail()
	bag_button = GuInkButton.new()
	bag_button.text = "Hành trang  [Tab]"
	bag_button.focus_mode = Control.FOCUS_NONE
	_place(bag_button, Vector2(-138, -84), Vector2(124, 34), Control.PRESET_BOTTOM_RIGHT)
	bag_button.pressed.connect(toggle_bag)
	settings_button = GuInkButton.new()
	settings_button.text = "Thiết lập  [Esc]"
	settings_button.focus_mode = Control.FOCUS_NONE
	_place(settings_button, Vector2(-138, -44), Vector2(124, 34), Control.PRESET_BOTTOM_RIGHT)
	settings_button.pressed.connect(func(): pause_requested.emit())
	character_button = GuInkButton.new()
	character_button.text = "Nhân vật [F3]"
	character_button.focus_mode = Control.FOCUS_NONE
	_place(character_button, Vector2(-268, -84), Vector2(124, 34), Control.PRESET_BOTTOM_RIGHT)
	character_button.pressed.connect(toggle_character)
	journal_button = GuInkButton.new()
	journal_button.text = "Nhiệm vụ [F11]"
	journal_button.focus_mode = Control.FOCUS_NONE
	_place(journal_button, Vector2(-268, -44), Vector2(124, 34), Control.PRESET_BOTTOM_RIGHT)
	journal_button.pressed.connect(toggle_journal)
	for button in [bag_button, settings_button, character_button, journal_button]:
		button.add_theme_font_size_override("font_size", 12)
		button.toggle_mode = true
	hint = _label("WASD đi · Shift chạy · 1–4 dùng Cổ · E tương tác · T địa đồ", 11, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(hint, Vector2(-310, -154), Vector2(620, 26), Control.PRESET_CENTER_BOTTOM)
	hint.add_theme_color_override("font_color", IVORY)
	var hint_background := StyleBoxFlat.new()
	hint_background.bg_color = Color(GuPixelUI.PAPER_LIGHT, 0.94)
	hint_background.border_color = GuPixelUI.INK_SOFT
	hint_background.set_border_width_all(1)
	hint_background.set_corner_radius_all(2)
	hint_background.content_margin_left = 7
	hint_background.content_margin_right = 7
	hint_background.content_margin_top = 5
	hint_background.content_margin_bottom = 5
	hint.add_theme_stylebox_override("normal", hint_background)
	toast_label = _label("", 17, IVORY)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(toast_label, Vector2(-330, 112), Vector2(660, 35), Control.PRESET_CENTER_TOP)
	capture_label = _label("Phong ấn Cổ  ·  giữ yên, tránh bị đánh", 13, GuPixelUI.PAPER_LIGHT)
	capture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(capture_label, Vector2(-200, -178), Vector2(400, 24), Control.PRESET_CENTER_BOTTOM)
	capture_bar = _bar(GuPixelUI.GOLD, 6)
	_place(capture_bar, Vector2(-170, -150), Vector2(340, 6), Control.PRESET_CENTER_BOTTOM)
	death_text = _label("", 25, GuPixelUI.PAPER_LIGHT)
	death_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(death_text, Vector2(-270, -45), Vector2(540, 80), Control.PRESET_CENTER)
	backdrop = ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.03, 0.55)
	_place(backdrop, Vector2.ZERO, root.size)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.hide()
	backdrop.modulate.a = 0.0
	backdrop.gui_input.connect(_backdrop_input)
	_build_bag()
	_build_character()
	_build_journal()
	# These menu buttons remain usable while browsing the side windows.
	for button in [bag_button, settings_button, character_button, journal_button]:
		root.move_child(button, -1)
	_build_pause()
	_build_studio()
	cultivation_button = GuInkButton.new()
	cultivation_button.text = "Cổ giới  [G / T / H]"
	_place(cultivation_button, Vector2(-202, 208), Vector2(188, 32), Control.PRESET_TOP_RIGHT)
	cultivation_button.add_theme_font_size_override("font_size", 12)
	cultivation_button.pressed.connect(func(): toggle_cultivation("travel"))
	root.move_child(cultivation_button, backdrop.get_index())
	cultivation_book = CultivationBook.new()
	root.add_child(cultivation_book)
	cultivation_book.setup(simulation)
	cultivation_book.command_requested.connect(func(command: String, args: Dictionary): cultivation_requested.emit(command, args))
	cultivation_book.close_requested.connect(func(): toggle_cultivation(cultivation_book.page))
	large_map = GuWorldMapWindow.new()
	root.add_child(large_map)
	large_map.setup(simulation)
	large_map.close_requested.connect(close_large_map)
	large_map.travel_requested.connect(func():
		cultivation_book.atlas_selection = large_map.atlas.selected
		close_large_map()
		toggle_cultivation("travel"))
	dialogue = NpcDialogue.new()
	root.add_child(dialogue)
	dialogue.setup(simulation)
	dialogue.close_requested.connect(close_dialogue)
	dialogue.action_requested.connect(func(command: String, id: String): dialogue_requested.emit(command,id))
	root.move_child(toast_label, -1)
	for label in [toast_label, capture_label, death_text]:
		label.add_theme_color_override("font_outline_color", GuPixelUI.INK)
		label.add_theme_constant_override("outline_size", 2)
	root.resized.connect(_fit_hud)
	_fit_hud()
	_fit_map_dock()
	update_hud(0.0)
	toast("Gặp Lâm An (!) phía tây trại • lại gần rồi nhấn E để trò chuyện.", false, 7.0)
	showing_intro = true

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = GuPixelUI.HAND_FONT
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", IVORY)
	theme.set_stylebox("panel", "PanelContainer", _frame("panel", 10))
	theme.set_stylebox("normal", "Button", _frame("slot", 7))
	theme.set_stylebox("hover", "Button", _frame("hover", 7))
	theme.set_stylebox("pressed", "Button", _frame("pressed", 7))
	theme.set_stylebox("disabled", "Button", _frame("disabled", 7))
	theme.set_color("font_color", "Button", IVORY)
	theme.set_color("font_disabled_color", "Button", GuPixelUI.MUTED)
	theme.set_stylebox("panel", "TooltipPanel", _frame("panel", 12))
	theme.set_color("font_color", "TooltipLabel", IVORY)
	theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, GuPixelUI.JADE, 2))
	return theme

func _frame(kind: String, padding: int) -> StyleBoxFlat:
	return GuPixelUI.frame(kind, padding)

func toggle_quest() -> void:
	quest_collapsed = not quest_collapsed
	quest_content.visible = not quest_collapsed
	quest_toggle.text = "+" if quest_collapsed else "−"
	quest_toggle.tooltip_text = "Mở nhiệm vụ" if quest_collapsed else "Thu gọn nhiệm vụ"
	quest_panel.size.y = 64 if quest_collapsed else 156

func _style(color: Color, border: Color, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(1)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _place(control: Control, point: Vector2, dimensions: Vector2, preset: int = Control.PRESET_TOP_LEFT) -> void:
	root.add_child(control)
	control.set_anchors_and_offsets_preset(preset)
	control.position = point
	# position setter resets anchors' effect until a resize; assign offsets explicitly.
	control.offset_left = point.x
	control.offset_top = point.y
	control.offset_right = point.x + dimensions.x
	control.offset_bottom = point.y + dimensions.y

func _panel(parent: Node, point: Vector2, dimensions: Vector2, preset: int = Control.PRESET_TOP_LEFT) -> PanelContainer:
	var panel := GuLacquerPanel.new()
	if parent == root:
		_place(panel, point, dimensions, preset)
	else:
		parent.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel

func _vbox(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	parent.add_child(box)
	return box

func _bar(color: Color, height: float) -> ProgressBar:
	var bar := GuVitalBar.new()
	bar.tint = color
	bar.damage_feedback = color.r > 0.55 or color.b > 0.35
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(GuPixelUI.PAPER_SHADE, GuPixelUI.INK_SOFT, 0))
	bar.add_theme_stylebox_override("fill", _style(color, color.darkened(0.22), 0))
	return bar

func _build_bag() -> void:
	bag = _panel(root, Vector2(BAG_LEFT, 54), Vector2(462, 704), Control.PRESET_TOP_RIGHT)
	bag.visible = false
	var box := _vbox(bag)
	_window_header(box, "HÀNH TRANG", "F4 / Tab", toggle_bag)
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	inventory_browser = GuInventoryBrowser.new()
	inventory_browser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inventory_browser)
	inventory_browser.setup(simulation)
	inventory_browser.feed_requested.connect(func(instance: String, food: String): feed_requested.emit(instance, food))
	inventory_browser.move_requested.connect(func(source: String, destination: int, version: int): inventory_move_requested.emit(source, destination, version))
	inventory_browser.discard_requested.connect(func(key: String, quantity: int, version: int): inventory_discard_requested.emit(key, quantity, version))
	inventory_browser.craft_requested.connect(func(recipe: String, batches: int, version: int): inventory_craft_requested.emit(recipe, batches, version))
	inventory_browser.use_seal_requested.connect(func(): inventory_seal_requested.emit())
	inventory_browser.open_gu_requested.connect(func(id: String): cultivation_book.selected_id = id; toggle_cultivation("gu"))
	inventory_browser.open_farm_requested.connect(func(): toggle_cultivation("farm"))
	bag_list = inventory_browser.details
	bag_rows = inventory_browser.rows
	materials_text = inventory_browser.capacity_label
	root.resized.connect(_fit_bag)
	_fit_bag()

func _fit_bag() -> void:
	if bag == null:
		return
	bag.offset_top = 54
	bag.offset_bottom = 54 + minf(704, maxf(240, root.size.y - 180))
	if character_panel != null:
		character_panel.offset_top = 54
		character_panel.offset_bottom = bag.offset_bottom

func _fit_hud() -> void:
	var compact := root.size.x < 1100
	var buttons: Array[Button] = [character_button, journal_button, bag_button, settings_button]
	var full_labels := ["Nhân vật [F3]", "Nhiệm vụ [F11]", "Hành trang [Tab]", "Thiết lập [Esc]"]
	var small_labels := ["Nhân vật [F3]", "Nhiệm vụ [J]", "Túi [Tab]", "Menu [Esc]"]
	for index in range(buttons.size()):
		var button := buttons[index]
		button.text = small_labels[index] if compact else full_labels[index]
		button.add_theme_font_size_override("font_size", 11)
		button.tooltip_text = full_labels[index]
		button.offset_left = -268 if index < 2 else -138
		button.offset_right = button.offset_left + 124
	if compact:
		target_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		target_panel.offset_left = 366
		target_panel.offset_right = 676
	else:
		target_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		target_panel.offset_left = -155
		target_panel.offset_right = 155
	target_panel.offset_top = 14
	target_panel.offset_bottom = 104
	# Long notices wrap inside the central lane, clear of status and map frames.
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	toast_label.offset_left = status_panel.get_global_rect().end.x + 12
	toast_label.offset_right = root.size.x - 218
	toast_label.offset_top = 112
	toast_label.offset_bottom = 170

func _fit_map_dock() -> void:
	if cultivation_button == null or map_panel == null: return
	cultivation_button.offset_top = map_panel.offset_top + map_panel.size.y + 8
	cultivation_button.offset_bottom = cultivation_button.offset_top + 32
	cultivation_button.offset_left = -206
	cultivation_button.offset_right = -14

func _window_header(box: VBoxContainer, title: String, shortcut: String, close_action: Callable) -> void:
	var header := HBoxContainer.new()
	box.add_child(header)
	var heading := _label(title, 22, GuPixelUI.INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_constant_override("separation", 12)
	header.add_child(heading)
	var close := GuInkButton.new()
	close.text = "×"
	close.tooltip_text = "Đóng [%s]" % shortcut
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(34, 34)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(close_action)
	header.add_child(close)

func _build_character() -> void:
	character_panel = _panel(root, Vector2(26, 54), Vector2(438, 704))
	character_panel.hide()
	var column := _vbox(character_panel)
	_window_header(column, "NHÂN VẬT", "F3", toggle_character)
	var scroll := ScrollContainer.new()
	scroll.name = "CharacterScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var box := _vbox(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_title = _label("", 17, IVORY)
	box.add_child(character_title)
	character_doll = GuCharacterDoll.new()
	character_doll.simulation = simulation
	character_doll.custom_minimum_size = Vector2(0, 270)
	character_doll.gu_selected.connect(_inspect_equipped_gu)
	box.add_child(character_doll)
	box.add_child(_label("THUỘC TÍNH", 13, GuPixelUI.JADE))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 16)
	stats.add_theme_constant_override("v_separation", 5)
	box.add_child(stats)
	for caption in ["Sinh lực", "Chân nguyên", "Khiên bảo hộ", "Kinh nghiệm", "Ngân lượng", "Di chuyển"]:
		var name_label := _label(caption, 14, MUTED)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(name_label)
		var value := _label("", 14, IVORY)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats.add_child(value)
		character_values[caption] = value
	_fit_bag()
	var tip := _label("Cổ khảm: click 1 / 2 / 3 / 4 bên hình nhân vật để xem và cho ăn trong hành trang.", 12, MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tip)
	var inspect := GuInkButton.new()
	inspect.text = "Xem hành trang  [F4]"
	inspect.focus_mode = Control.FOCUS_NONE
	inspect.pressed.connect(func():
		if not bag_open:
			toggle_bag())
	box.add_child(inspect)
	var atelier := GuInkButton.new()
	atelier.text = "Tạo diện mạo / xem chuyển động  [F6]"
	atelier.focus_mode = Control.FOCUS_NONE
	atelier.pressed.connect(toggle_studio)
	box.add_child(atelier)

func _build_studio() -> void:
	character_studio = GuCharacterStudio.new()
	character_studio.close_requested.connect(toggle_studio)
	character_studio.appearance_applied.connect(func(value: Dictionary): appearance_requested.emit(value))
	root.add_child(character_studio)
	character_studio.hide()

func _build_journal() -> void:
	journal_panel = _panel(root, Vector2(-340, -272), Vector2(680, 530), Control.PRESET_CENTER)
	journal_panel.hide()
	var box := _vbox(journal_panel)
	_window_header(box, "NHIỆM VỤ", "F11", toggle_journal)
	box.add_child(_label("VẠN THÚ SƠN   /   KHẢO NGHIỆM NHẬP MÔN", 14, GuPixelUI.JADE))
	var story := _label("Rời trại ngọc, vận dụng bốn Cổ để đối phó sói rừng.
Thu phục một Cổ và chăm sóc Cổ đang khảm để hoàn tất khảo nghiệm.", 14, IVORY)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(story)
	var instructions := ["Click chọn sói, dùng 1 / 4 để tấn công. 2 đỡ đòn; 3 né vồ.", "Hạ sinh lực sói xuống ≤30%, lại gần trong 3 ô rồi nhấn C.", "Mở hành trang, chọn Cổ chưa no và dùng đúng loại thức ăn."]
	for i in range(3):
		var block := PanelContainer.new()
		block.add_theme_stylebox_override("panel", _style(GuPixelUI.PAPER_LIGHT, GuPixelUI.PAPER_SHADE, 12))
		box.add_child(block)
		var content := _vbox(block)
		var objective := _label("", 16, IVORY)
		content.add_child(objective)
		journal_objectives.append(objective)
		var progress_bar := _bar(GuPixelUI.JADE, 5)
		content.add_child(progress_bar)
		journal_bars.append(progress_bar)
		var instruction := _label(instructions[i], 12, MUTED)
		instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(instruction)
	journal_reward = _label("", 14, GuPixelUI.GOLD.darkened(0.12))
	journal_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(journal_reward)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	journal_track = GuInkButton.new()
	journal_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_track.focus_mode = Control.FOCUS_NONE
	journal_track.pressed.connect(func():
		quest_tracked = not quest_tracked
		quest_panel.visible = quest_tracked
		_refresh_journal())
	actions.add_child(journal_track)
	var feed := GuInkButton.new()
	feed.text = "Mở hành trang để nuôi Cổ"
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed.focus_mode = Control.FOCUS_NONE
	feed.pressed.connect(func():
		toggle_journal()
		if not bag_open:
			toggle_bag())
	actions.add_child(feed)
	legacy_journal_nodes.assign(box.get_children().slice(1))
	journal_switch = CultivationBook.button(box.get_child(0),"Nhiệm vụ NPC",func(): show_npc_journal(not npc_journal_open))
	npc_quest_list = NpcQuestList.new()
	box.add_child(npc_quest_list)
	npc_quest_list.setup(simulation)
	npc_quest_list.quest_requested.connect(func(command: String,id: String): npc_quest_requested.emit(command,id))
	npc_quest_list.hide()

func show_npc_journal(value: bool) -> void:
	npc_journal_open = value
	for node in legacy_journal_nodes:
		node.visible = not value
	npc_quest_list.visible = value
	journal_switch.text = "Khảo nghiệm cũ" if value else "Nhiệm vụ NPC"
	if value:
		npc_quest_list.refresh()

func _inspect_equipped_gu(instance_id: String) -> void:
	if not bag_open:
		toggle_bag()
	inventory_browser.select_gu(instance_id)
	_record_window("bag", true)

func _refresh_character() -> void:
	var p := simulation.player
	character_title.text = "Cổ sư · Cấp %d%s" % [p["level"], " · Trọng thương" if p["dead"] else ""]
	character_values["Sinh lực"].text = "%.0f / %.0f" % [p["hp"], p["max_hp"]]
	character_values["Chân nguyên"].text = "%.0f / %.0f" % [p["mana"], p["max_mana"]]
	character_values["Khiên bảo hộ"].text = "%.0f · %.1fs" % [p["shield"], p["shield_left"]]
	character_values["Kinh nghiệm"].text = "%.0f / %.0f" % [xp_bar.value, xp_bar.max_value]
	character_values["Ngân lượng"].text = str(p["currency"])
	character_values["Di chuyển"].text = "Đi %.1f / chạy %.1f ô/s" % [LocalAuthority.PLAYER_SPEED, LocalAuthority.PLAYER_RUN_SPEED]
	character_doll.refresh_appearance()

func _refresh_journal() -> void:
	if npc_journal_open:
		npc_quest_list.refresh()
	var signature := "%s/%s" % [simulation.progress, quest_tracked]
	if signature == journal_signature:
		return
	journal_signature = signature
	var values := [int(simulation.progress["kills"]), int(simulation.progress["captures"]), int(simulation.progress["feeds"])]
	var goals := [3, 1, 1]
	for i in range(3):
		var done: bool = values[i] >= goals[i]
		journal_objectives[i].text = "%s  %s    %d / %d" % ["✓" if done else "○", ["Hạ sói rừng", "Thu phục Cổ", "Cho Cổ ăn"][i], mini(values[i], goals[i]), goals[i]]
		journal_objectives[i].add_theme_color_override("font_color", GuPixelUI.JADE if done else IVORY)
		journal_bars[i].max_value = goals[i]
		journal_bars[i].value = values[i]
	journal_reward.text = "ĐÃ HOÀN THÀNH · Đã nhận 200 ngân lượng." if simulation.progress["claimed"] else "PHẦN THƯỞNG · 200 ngân lượng
Tự nhận khi hoàn thành cả ba mục tiêu."
	journal_track.text = "Ẩn theo dõi" if quest_tracked else "Theo dõi nhiệm vụ"

func _bar_readout(bar: ProgressBar) -> Label:
	var label := _label("", 12, GuPixelUI.INK)
	bar.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_shadow_color", GuPixelUI.PAPER_LIGHT)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _build_skill_detail() -> void:
	skill_detail = _panel(root, Vector2(18, 365), Vector2(312, 180))
	# Informational only: this popover never steals a ground click or changes the aim.
	skill_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := _vbox(skill_detail)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	skill_title = _label("", 17, IVORY)
	skill_stats = _label("", 12, MUTED)
	skill_reason = _label("", 12, GuPixelUI.JADE)
	skill_description = _label("", 12, MUTED)
	skill_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [skill_title, skill_stats, skill_reason, skill_description]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	skill_detail.hide()

func _set_hovered_skill(slot: int) -> void:
	hovered_skill = slot

func _clear_hovered_skill(slot: int) -> void:
	if hovered_skill == slot:
		hovered_skill = -1

func update_skill_detail(slot: int, probe: Dictionary, error_text: String) -> void:
	skill_detail.visible = slot >= 0 and not paused and not has_open_window() and not bool(simulation.player["dead"])
	if not skill_detail.visible:
		return
	var definition := simulation.catalog.slot(slot)
	skill_title.text = "[%s]  %s" % [GameBindings.skill_label(slot), definition["full_name"]]
	skill_title.add_theme_color_override("font_color", Color(str(definition["color"])))
	var learned := simulation.inventory.slot_gu(slot)
	var actual_cooldown := float(definition["cooldown"]) * (maxf(.55, 1.0 / ExpeditionModel.strength(learned)) if slot == 2 else 1.0)
	skill_stats.text = "Chân nguyên %d  ·  Hồi %.0fs  ·  %s" % [int(probe.get("cost", 0)), actual_cooldown, "Bản thân" if float(definition["range"]) <= 0.0 else "Tầm %.0f ô" % float(definition["range"])]
	var ready := bool(probe.get("ok", false))
	var clipped := bool(probe.get("clipped", false))
	skill_reason.text = error_text if not ready else ("Đường bị chặn · lướt đến dấu ngắm trước vật cản" if clipped else "Sẵn sàng · " + ("lướt đến dấu ngắm" if slot == 2 else ("bảo vệ bản thân" if slot == 1 else "mục tiêu trong tầm")))
	skill_reason.add_theme_color_override("font_color", GuPixelUI.VERMILION if not ready or clipped else GuPixelUI.JADE)
	skill_description.text = str(definition["description"])

func _build_pause() -> void:
	pause_panel = _panel(root, Vector2(-240, -180), Vector2(480, 360), Control.PRESET_CENTER)
	pause_panel.visible = false
	var box := _vbox(pause_panel)
	box.add_child(_label("THIẾT LẬP", 25, IVORY))
	box.add_child(_label("WASD di chuyển · Shift chạy · 1–4 dùng Cổ · E tương tác\nTab túi · F3 nhân vật · G bảng Cổ · T địa đồ · H bí cảnh", 13, MUTED))
	var audio_row := HBoxContainer.new()
	audio_row.add_theme_constant_override("separation", 8)
	box.add_child(audio_row)
	audio_row.add_child(_label("Âm lượng", 14, IVORY))
	volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 5
	volume_slider.value = 75
	volume_slider.custom_minimum_size.y = 26
	volume_slider.value_changed.connect(func(value: float):
		volume_value.text = "%d%%" % roundi(value)
		volume_requested.emit(value / 100.0))
	audio_row.add_child(volume_slider)
	volume_value = _label("75%", 13, MUTED)
	volume_value.custom_minimum_size.x = 40
	audio_row.add_child(volume_value)
	var display_row := HBoxContainer.new()
	display_row.add_theme_constant_override("separation", 8)
	box.add_child(display_row)
	display_row.add_child(_label("Độ phân giải", 14, IVORY))
	resolution_picker = OptionButton.new()
	resolution_picker.name = "ResolutionPicker"
	resolution_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolution_picker.custom_minimum_size.y = 32
	for resolution in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		resolution_picker.add_item("%d × %d" % [resolution.x, resolution.y])
		resolution_picker.set_item_metadata(resolution_picker.item_count - 1, resolution)
	resolution_picker.select(1)
	resolution_picker.item_selected.connect(func(index: int): display_requested.emit(_selected_resolution(index), fullscreen_button.button_pressed))
	display_row.add_child(resolution_picker)
	fullscreen_button = CheckButton.new()
	fullscreen_button.name = "FullscreenButton"
	fullscreen_button.text = "Toàn màn hình"
	fullscreen_button.custom_minimum_size.y = 32
	fullscreen_button.toggled.connect(func(value: bool): display_requested.emit(_selected_resolution(resolution_picker.selected), value))
	box.add_child(fullscreen_button)
	var resume := GuInkButton.new()
	resume.text = "Tiếp tục  [Esc]"
	resume.custom_minimum_size.y = 32
	resume.pressed.connect(func(): pause_requested.emit())
	box.add_child(resume)
	mute_button = GuInkButton.new()
	mute_button.text = "Âm thanh: bật  [M]"
	mute_button.custom_minimum_size.y = 32
	mute_button.pressed.connect(func(): mute_requested.emit())
	box.add_child(mute_button)
	motion_button = GuInkButton.new()
	motion_button.text = "Giảm chuyển động: tắt"
	motion_button.custom_minimum_size.y = 32
	motion_button.pressed.connect(func(): motion_requested.emit())
	box.add_child(motion_button)
	box.add_child(_label("Tiến độ và thiết lập được lưu tự động trên máy này.", 12, MUTED))

func _selected_resolution(index: int) -> Vector2i:
	if index < 0 or index >= resolution_picker.item_count:
		return Vector2i(1280, 800)
	return Vector2i(resolution_picker.get_item_metadata(index))

func set_display_preferences(window_size: Vector2i, fullscreen: bool) -> void:
	for index in range(resolution_picker.item_count):
		if _selected_resolution(index) == window_size:
			resolution_picker.select(index)
			break
	fullscreen_button.set_pressed_no_signal(fullscreen)

func set_audio_volume(value: float) -> void:
	volume_slider.set_value_no_signal(roundf(clampf(value, 0.0, 1.0) * 100.0))
	volume_value.text = "%d%%" % roundi(volume_slider.value)

func has_open_window() -> bool:
	return bag_open or character_open or journal_open or studio_open or cultivation_open or dialogue_open or large_map_open

func _record_window(kind: String, opened: bool) -> void:
	window_order.erase(kind)
	if opened:
		window_order.append(kind)
		gameplay_window_opened.emit()
		if showing_intro:
			showing_intro = false
			toast_left = 0.0
	bag_button.set_pressed_no_signal(bag_open)
	character_button.set_pressed_no_signal(character_open)
	journal_button.set_pressed_no_signal(journal_open)

func close_top_window() -> void:
	if window_order.is_empty():
		return
	if window_order.back() == "bag" and inventory_browser.close_top_overlay(): return
	if window_order.back() == "cultivation" and cultivation_book.gu_workshop.confirmation.visible:
		cultivation_book.gu_workshop.close_overlays()
		return
	match window_order.back():
		"bag": toggle_bag()
		"character": toggle_character()
		"journal": toggle_journal()
		"studio": toggle_studio()
		"cultivation": toggle_cultivation(cultivation_book.page)
		"dialogue": close_dialogue()
		"map": close_large_map()

func toggle_large_map() -> void:
	if paused: return
	if large_map_open:
		close_large_map()
		return
	while not window_order.is_empty():
		close_top_window()
	large_map_open = true
	large_map.open_map()
	_record_window("map", true)
	_update_backdrop()

func close_large_map() -> void:
	if not large_map_open: return
	large_map_open = false
	large_map.hide()
	_record_window("map", false)
	_update_backdrop()

func toggle_bag() -> void:
	if paused:
		return
	close_large_map()
	if dialogue_open:
		close_dialogue()
	if cultivation_open:
		toggle_cultivation(cultivation_book.page)
	if studio_open:
		toggle_studio()
	if journal_open:
		toggle_journal()
	bag_open = not bag_open
	if not bag_open: inventory_browser.close_overlays()
	if bag_open:
		_refresh_bag()
	_record_window("bag", bag_open)
	_animate_bag()
	_update_backdrop()

func toggle_character() -> void:
	if paused:
		return
	close_large_map()
	if dialogue_open:
		close_dialogue()
	if cultivation_open:
		toggle_cultivation(cultivation_book.page)
	if studio_open:
		toggle_studio()
	if journal_open:
		toggle_journal()
	character_open = not character_open
	character_panel.visible = character_open
	if character_open:
		_refresh_character()
	_record_window("character", character_open)
	_update_backdrop()

func toggle_journal() -> void:
	if paused:
		return
	close_large_map()
	if dialogue_open:
		close_dialogue()
	if cultivation_open:
		toggle_cultivation(cultivation_book.page)
	if studio_open:
		toggle_studio()
	if not journal_open:
		if bag_open:
			toggle_bag()
		if character_open:
			toggle_character()
	journal_open = not journal_open
	journal_panel.visible = journal_open
	if journal_open:
		show_npc_journal(not simulation.quests.accepted.is_empty())
		_refresh_journal()
	_record_window("journal", journal_open)
	_update_backdrop()

func toggle_studio() -> void:
	if paused:
		return
	close_large_map()
	if dialogue_open:
		close_dialogue()
	if cultivation_open:
		toggle_cultivation(cultivation_book.page)
	if not studio_open:
		if bag_open:
			toggle_bag()
		if character_open:
			toggle_character()
		if journal_open:
			toggle_journal()
		character_studio.begin(simulation.player["appearance"])
	studio_open = not studio_open
	character_studio.set_open(studio_open)
	_record_window("studio", studio_open)
	_update_backdrop()

func refresh_appearance() -> void:
	portrait_doll.refresh_appearance()
	character_doll.refresh_appearance()

func set_paused(value: bool) -> void:
	paused = value
	pause_panel.visible = value
	settings_button.set_pressed_no_signal(value)
	for button in [bag_button, character_button, journal_button]:
		button.disabled = value
	if value:
		inventory_browser.close_overlays()
		large_map_open = false
		large_map.hide()
		close_dialogue()
		bag_open = false
		character_open = false
		journal_open = false
		studio_open = false
		cultivation_open = false
		cultivation_book.gu_workshop.close_overlays()
		cultivation_book.hide()
		character_studio.set_open(false)
		character_panel.hide()
		journal_panel.hide()
		window_order.clear()
		_record_window("", false)
		if bag_tween != null:
			bag_tween.kill()
		bag.hide()
	_update_backdrop()

func _animate_bag() -> void:
	if bag_tween != null:
		bag_tween.kill()
	if reduced_motion:
		bag.visible = bag_open
		bag.modulate.a = 1.0
		bag.offset_left = BAG_LEFT
		bag.offset_right = BAG_RIGHT
		return
	bag_tween = create_tween().set_parallel(true)
	if bag_open:
		bag.show()
		bag.modulate.a = 0.0
		bag.offset_left = BAG_LEFT + 22
		bag.offset_right = BAG_RIGHT + 22
	bag_tween.tween_property(bag, "modulate:a", 1.0 if bag_open else 0.0, 0.19)
	bag_tween.tween_property(bag, "offset_left", BAG_LEFT if bag_open else BAG_LEFT + 22.0, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bag_tween.tween_property(bag, "offset_right", BAG_RIGHT if bag_open else BAG_RIGHT + 22.0, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not bag_open:
		bag_tween.chain().tween_callback(bag.hide)

func _update_backdrop() -> void:
	if overlay_tween != null:
		overlay_tween.kill()
	var active := paused or has_open_window()
	# Gameplay hints should not cover the full-height workshop or pause panel.
	toast_label.visible = not studio_open and not paused and not large_map_open
	toast_label.offset_top = root.size.y - 26 if cultivation_open or dialogue_open else 112
	toast_label.offset_bottom = toast_label.offset_top + 35
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if reduced_motion:
		backdrop.visible = active
		backdrop.modulate.a = 1.0
		return
	if active:
		backdrop.show()
	overlay_tween = create_tween()
	overlay_tween.tween_property(backdrop, "modulate:a", 1.0 if active else 0.0, 0.15)
	if not active:
		overlay_tween.tween_callback(backdrop.hide)

func _backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and has_open_window():
		backdrop.accept_event()
		close_top_window()

func set_reduced_motion(value: bool) -> void:
	cultivation_book.gu_workshop.set_reduced_motion(value)
	dialogue.reduced_motion = value
	reduced_motion = value
	character_studio.reduced_motion = value
	motion_button.text = "Giảm chuyển động: %s" % ("bật" if value else "tắt")
	for skill in skill_buttons:
		skill.reduced_motion = value
	for gauge in [hp_bar, mana_bar, xp_bar, target_bar, capture_bar]:
		if gauge is GuVitalBar:
			gauge.reduced_motion = value
	if bag_tween != null:
		bag_tween.kill()
	bag.visible = bag_open
	bag.modulate.a = 1.0
	bag.offset_left = BAG_LEFT
	bag.offset_right = BAG_RIGHT
	_update_backdrop()

func _refresh_bag() -> void:
	bag_refresh = 0.0
	bag_version = simulation.inventory.version
	inventory_browser.refresh()

func update_hud(delta: float) -> void:
	if simulation == null:
		return
	var p := simulation.player
	var cell := Vector2(p["cell"])
	var facing := Vector2(p["facing"])
	map_coordinates.text = "X: %d   Y: %d\nHướng: %s" % [roundi(cell.x), roundi(cell.y), GuMinimap.direction_label(facing)]
	region_title.text = str(ExpeditionModel.REGIONS[simulation.expedition.region]["name"]).to_upper()
	var progress := simulation.progress
	quest_text.text = "%s  Hạ sói rừng       %d / 3\n%s  Thu phục Cổ       %d / 1\n%s  Cho Cổ ăn          %d / 1" % ["✓" if int(progress["kills"]) >= 3 else "○", mini(3, progress["kills"]), "✓" if int(progress["captures"]) >= 1 else "○", mini(1, progress["captures"]), "✓" if int(progress["feeds"]) >= 1 else "○", mini(1, progress["feeds"])]
	if bool(progress["claimed"]):
		quest_text.text += "\nĐã nhận thưởng. Khám phá di tích!"
	quest_title_label.text = "KHẢO NGHIỆM NHẬP MÔN"
	quest_reward_label.text = "Thưởng: 200 ngân lượng"
	var tracked := simulation.quests.tracked
	if tracked != "":
		var definition := QuestCatalog.quest(tracked)
		var destination := QuestCatalog.objective_location(tracked,simulation)
		quest_title_label.text = str(definition["title"]).to_upper()
		quest_text.text = "%s
%d / %d • %s" % [definition["objective"],simulation.quests.value(tracked,simulation),definition["goal"],"Đã đủ, hãy trả nhiệm vụ" if simulation.quests.ready(tracked,simulation) else "Đang thực hiện"]
		quest_reward_label.text = str(destination["name"]) + " • F11 / T xem đường"
	status_text.text = "Cổ sư · Cấp %d    %d bạc" % [p["level"], p["currency"]]
	var level := int(p["level"])
	var level_floor := 50 * (level - 1) * level
	xp_bar.max_value = float(100 * level)
	xp_bar.value = float(p["xp"]) - level_floor
	xp_bar.tooltip_text = "Kinh nghiệm %.0f / %.0f" % [xp_bar.value, xp_bar.max_value]
	xp_text.text = "Kinh nghiệm %.0f / %.0f  ·  %.0f%%" % [xp_bar.value, xp_bar.max_value, xp_bar.value / xp_bar.max_value * 100.0]
	hp_bar.max_value = float(p["max_hp"])
	hp_bar.value = _smooth_bar(hp_bar.value, float(p["hp"]), delta)
	mana_bar.max_value = float(p["max_mana"])
	mana_bar.value = _smooth_bar(mana_bar.value, float(p["mana"]), delta)
	hp_readout.text = "Sinh lực  %.0f / %.0f" % [p["hp"], p["max_hp"]]
	mana_readout.text = "Chân nguyên  %.0f / %.0f" % [p["mana"], p["max_mana"]]
	hp_bar.tooltip_text = "Sinh lực %.0f / %.0f  ·  Khiên %.0f" % [p["hp"], p["max_hp"], p["shield"]]
	mana_bar.tooltip_text = "Chân nguyên %.0f / %.0f" % [p["mana"], p["max_mana"]]
	var low_hp := float(p["hp"]) <= float(p["max_hp"]) * 0.3 and not bool(p["dead"])
	shield_text.text = "Khiên %.0f · %.1fs" % [p["shield"], p["shield_left"]] if float(p["shield"]) > 0 else ("Sinh lực thấp · về trại hồi phục" if low_hp else "Trại ngọc hồi sinh lực / chân nguyên")
	shield_text.add_theme_color_override("font_color", GuPixelUI.GOLD.darkened(0.12) if float(p["shield"]) > 0 else (GuPixelUI.VERMILION if low_hp else MUTED))
	for i in range(4):
		var item := simulation.inventory.slot_gu(i)
		var learned_rank := int(item["rank"])
		if skill_buttons[i].gu_rank != learned_rank:
			skill_buttons[i].gu_rank = learned_rank
			skill_buttons[i].queue_redraw()
		skill_buttons[i].cooldown_duration = float(simulation.catalog.slot(i)["cooldown"]) * (maxf(.55,1.0/ExpeditionModel.strength(item)) if i == 2 else 1.0)
		skill_buttons[i].update_state(simulation.cooldowns[i], float(simulation.inventory.slot_gu(i)["hunger"]), float(p["mana"]), float(p["max_mana"]), bool(p["dead"]))
	var target: Dictionary = simulation.mobs.get(world_view.selected_id, {})
	target_panel.visible = not target.is_empty() and not bool(target.get("dead", true))
	if target_panel.visible:
		target_text.text = "%s  ·  %.0f / %.0f HP" % [target["name"], target["hp"], target["max_hp"]]
		target_bar.max_value = float(target["max_hp"])
		target_bar.value = float(target["hp"])
		target_hint.text = _capture_hint(target)
		hint.text = "WASD · Shift chạy · 1–4 dùng Cổ · " + target_hint.text
	else:
		hint.text = "WASD · Shift chạy · 1–4 dùng Cổ · E tương tác · G Cổ · T địa đồ · H bí cảnh"
		if simulation.quests.has_unlock("field_medicine"):
			hint.text += " · R dược phương" + (" (%ds)" % ceili(simulation.journey.medicine_left) if simulation.journey.medicine_left > 0 else "")
	capture_label.visible = not simulation.capture.is_empty()
	capture_bar.visible = capture_label.visible
	if capture_bar.visible:
		capture_bar.value = 100.0 * (1.0 - float(simulation.capture["left"]) / 2.0)
	death_text.visible = bool(p["dead"])
	if death_text.visible:
		death_text.text = "Trọng thương\nTrở về trại sau %d giây" % ceili(float(p["respawn_left"]))
	toast_left = maxf(0.0, toast_left - delta)
	toast_label.modulate.a = minf(1.0, toast_left * 3.0)
	if toast_left <= 0.0 and not toast_queue.is_empty():
		_show_toast(toast_queue.pop_front())
	bag_refresh += delta
	if bag_open and bag_version != simulation.inventory.version:
		_refresh_bag()
	elif bag_open and bag_refresh > 0.5:
		bag_refresh = 0.0
		inventory_browser.refresh()
	if character_open:
		_refresh_character()
	if journal_open:
		_refresh_journal()

func _smooth_bar(current: float, actual: float, delta: float) -> float:
	if reduced_motion or delta <= 0.0 or bool(simulation.player["dead"]):
		return actual
	return lerpf(current, actual, 1.0 - exp(-16.0 * delta))

func _capture_hint(target: Dictionary) -> String:
	if bool(simulation.player["dead"]):
		return "Trọng thương · chờ hồi sinh"
	if not simulation.capture.is_empty():
		return "Đang phong ấn · giữ yên"
	if not bool(target["owned"]) or float(target["hp"]) > float(target["max_hp"]) * 0.3:
		return "[C] Bắt Cổ: hạ HP xuống ≤30%"
	if Vector2(simulation.player["cell"]).distance_to(target["cell"]) > 3.0:
		return "[C] Lại gần mục tiêu · tầm 3 ô"
	if not simulation.world.clear_segment(simulation.player["cell"], target["cell"]):
		return "[C] Vật cản che mục tiêu"
	if int(simulation.inventory.materials.get("seal", 0)) <= 0:
		return "[C] Hết phong ấn · hạ sói để nhận"
	if not simulation.inventory.can_add_gu():
		return "[C] Cần 1 ô trống trong túi"
	return "[C] Bắt Cổ · 2 giây · xác suất 70%"

func receive(event: Dictionary) -> void:
	cultivation_book.gu_workshop.receive(event)
	var slot := ["cast_moon", "shield", "dash", "cast_frost"].find(str(event["kind"]))
	if showing_intro and (slot >= 0 or event["kind"] == "capture_start"):
		showing_intro = false
		toast_left = 0.0
	if slot >= 0:
		skill_buttons[slot].flash_result(true)

func toast(message: String, error: bool = false, duration: float = 3.5) -> void:
	var entry := {"text": message, "error": error, "duration": duration}
	if error or toast_left <= 0.0:
		_show_toast(entry)
		return
	if toast_label.text.ends_with(message):
		return
	for pending in toast_queue:
		if pending["text"] == message:
			return
	if toast_queue.size() >= 4:
		toast_queue.pop_front()
	toast_queue.append(entry)
	# Keep onboarding readable, but make room promptly for a new action receipt.
	toast_left = minf(toast_left, 1.1)

func _show_toast(entry: Dictionary) -> void:
	showing_intro = false
	toast_error = bool(entry["error"])
	toast_label.text = ("!  " if toast_error else "◇  ") + str(entry["text"])
	toast_label.add_theme_color_override("font_color", Color("f0c5a0") if toast_error else Color("e0e4ca"))
	toast_left = float(entry["duration"])
	toast_label.modulate.a = 1.0

func toggle_cultivation(page: String = "travel") -> void:
	if paused:
		return
	if large_map_open and page == "travel":
		cultivation_book.atlas_selection = large_map.atlas.selected
	close_large_map()
	if dialogue_open:
		close_dialogue()
	if cultivation_open:
		if cultivation_book.page != page:
			cultivation_book.open_page(page)
			return
		cultivation_open = false
		cultivation_book.gu_workshop.close_overlays()
		cultivation_book.hide()
	else:
		while not window_order.is_empty():
			close_top_window()
		cultivation_open = true
		cultivation_book.show()
		cultivation_book.fit()
		cultivation_book.open_page(page)
	_record_window("cultivation", cultivation_open)
	_update_backdrop()

func open_dialogue(id: String) -> void:
	if paused: return
	while not window_order.is_empty():
		close_top_window()
	dialogue_open = true
	dialogue.begin(id)
	_record_window("dialogue",true)
	_update_backdrop()

func close_dialogue() -> void:
	if not dialogue_open: return
	dialogue_open = false
	dialogue.hide()
	_record_window("dialogue",false)
	_update_backdrop()
	dialogue_closed.emit()
