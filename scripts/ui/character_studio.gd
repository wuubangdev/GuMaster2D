class_name GuCharacterStudio
extends PanelContainer
## A presentation-only workshop. Applying a look emits a validated cosmetic descriptor.

signal appearance_applied(appearance: Dictionary)
signal close_requested

const GOLD := GuPixelUI.INK
const IVORY := GuPixelUI.INK
const MUTED := GuPixelUI.MUTED
const ACTIONS: Array[String] = ["idle", "walk", "run", "attack", "defend", "cast", "channel", "dash", "hit", "death", "respawn", "gather", "mine"]
const ACTION_LABELS: Array[String] = ["Đứng", "Đi", "Chạy", "Tấn công", "Phòng thủ", "Thi triển", "Phong ấn", "Lướt", "Trúng đòn", "Trọng thương", "Hồi sinh", "Hái lượm", "Khai khoáng"]
const DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2(1, -1), Vector2.RIGHT, Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1)]
const DIRECTION_LABELS: Array[String] = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]

var appearance: Dictionary = GuCharacterAppearance.default_data()
var selectors: Dictionary = {}
var action_buttons: Array[Button] = []
var direction_buttons: Array[Button] = []
var action: String = "idle"
var direction_index: int = 4
var facing_angle: float = 180.0
var yaw_slider: HSlider
var yaw_label: Label
var playhead: float = 0.0
var playing: bool = true
var playback_rate: float = 1.0
var reduced_motion: bool = false
var opened: bool = false
var stage: StudioStage
var character_view: Node2D
var play_button: Button
var apply_button: Button
var rate_label: Label
var pose_label: Label
var result_label: Label
var appearance_label: Label
var initialized: bool = false

class StudioStage extends Control:
	# Fit the authored head and weapon envelope, not the padded SVG bounds.
	# A fixed stage scale keeps attacks from causing a distracting zoom.
	const CHARACTER_TOP := 66.0
	const CHARACTER_BOTTOM := 40.0
	const CHARACTER_WIDTH := 180.0
	func ground_position() -> Vector2:
		return Vector2(size.x * 0.5, size.y * 0.61)
	func character_scale() -> float:
		return maxf(0.1, minf(size.y * 0.82 / (CHARACTER_TOP + CHARACTER_BOTTOM), size.x * 0.82 / CHARACTER_WIDTH))
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var frame := GuPixelUI.frame("normal", 0)
		frame.bg_color = GuPixelUI.PAPER_LIGHT
		frame.border_color = GuPixelUI.INK_SOFT
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(3)
		draw_style_box(frame, Rect2(Vector2.ZERO, size))
		GuPixelUI.paper_grain(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), 13)
		var floor := ground_position()
		var radius := minf(154, size.x*.27)
		var platform := PackedVector2Array()
		var base := PackedVector2Array()
		for index in range(96):
			var angle := index * TAU / 96.0
			var point := floor + Vector2(cos(angle) * radius, sin(angle) * 23)
			platform.append(point)
			base.append(point + Vector2(0, 6))
		draw_colored_polygon(base, Color("9c825d"))
		draw_colored_polygon(platform, Color("c5b48a"))
		platform.append(platform[0])
		draw_polyline(platform, GuPixelUI.INK_SOFT, 1.3, true)
		var lip := PackedVector2Array()
		for index in range(49):
			var angle := index * PI / 48.0
			lip.append(floor + Vector2(cos(angle) * radius, sin(angle) * 23))
		draw_polyline(lip, Color("e3d1aa"), 1.5, true)
		for sign in [-1, 1]:
			var at := floor+Vector2(sign*(radius-24), -4)
			draw_colored_polygon(PackedVector2Array([at+Vector2(-5,0), at+Vector2(0,-3), at+Vector2(5,0), at+Vector2(0,3)]), GuPixelUI.GOLD)
		var shadow := PackedVector2Array()
		for index in range(64):
			var angle := index * TAU / 64.0
			shadow.append(floor + Vector2(cos(angle) * 39, sin(angle) * 8))
		draw_colored_polygon(shadow, Color(GuPixelUI.INK, 0.24))
		GuPixelUI.corners(self, Rect2(Vector2(8, 8), size-Vector2(16,16)), GuPixelUI.INK_SOFT)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", GuPixelUI.frame("panel", 18))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 3)
	header.add_child(titles)
	titles.add_child(_label("XƯỞNG NHÂN VẬT", 27, GOLD))
	titles.add_child(_label("Minh họa 2D · 8 hướng · phối đồ và vũ khí", 13, MUTED))
	var close := _button("×", Vector2(40, 40))
	close.add_theme_font_size_override("font_size", 22)
	close.tooltip_text = "Đóng [F6 / Esc]"
	close.pressed.connect(func(): close_requested.emit())
	header.add_child(close)
	column.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)
	var preview := VBoxContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.add_theme_constant_override("separation", 8)
	body.add_child(preview)
	stage = StudioStage.new()
	stage.clip_contents = true
	stage.custom_minimum_size = Vector2(300, 250)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(stage)
	character_view = GuIllustratedCharacterView.new()
	character_view.configure(256, 48)
	stage.add_child(character_view)
	stage.resized.connect(_layout_preview)
	pose_label = _label("", 14, GOLD)
	pose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(pose_label)
	var facing_row := HBoxContainer.new()
	facing_row.alignment = BoxContainer.ALIGNMENT_CENTER
	facing_row.add_theme_constant_override("separation", 5)
	preview.add_child(facing_row)
	for i in range(DIRECTIONS.size()):
		var button := _button(DIRECTION_LABELS[i], Vector2(35, 34))
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 18)
		button.tooltip_text = ["Bắc", "Đông bắc", "Đông", "Đông nam", "Nam", "Tây nam", "Tây", "Tây bắc"][i]
		button.pressed.connect(_select_direction.bind(i))
		facing_row.add_child(button)
		direction_buttons.append(button)
	var rotation := HBoxContainer.new()
	rotation.add_theme_constant_override("separation", 10)
	preview.add_child(rotation)
	rotation.add_child(_label("Hướng", 12, MUTED))
	yaw_slider = HSlider.new()
	yaw_slider.min_value = 0.0
	yaw_slider.max_value = 360.0
	yaw_slider.step = 45.0
	yaw_slider.value = facing_angle
	yaw_slider.custom_minimum_size = Vector2(120, 28)
	yaw_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yaw_slider.tooltip_text = "Chọn hướng nhìn của nhân vật"
	yaw_slider.value_changed.connect(_set_facing_angle)
	rotation.add_child(yaw_slider)
	yaw_label = _label("180°", 12, GOLD)
	yaw_label.custom_minimum_size.x = 40
	yaw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rotation.add_child(yaw_label)
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.custom_minimum_size = Vector2(330, 0)
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(inspector_scroll)
	var inspector := VBoxContainer.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.add_theme_constant_override("separation", 10)
	inspector_scroll.add_child(inspector)
	inspector.add_child(_label("DIỆN MẠO", 13, GOLD))
	for category in ["body", "outfit", "boots", "hat", "weapon", "hair"]:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		inspector.add_child(row)
		row.add_child(_label({"body": "Giới tính", "outfit": "Trang phục", "weapon": "Vũ khí", "hair": "Kiểu tóc", "boots": "Giày", "hat": "Nón"}[category], 12, MUTED))
		var selector := OptionButton.new()
		selector.custom_minimum_size = Vector2(280, 35)
		selector.focus_mode = Control.FOCUS_NONE
		for option in GuCharacterAppearance.catalog(category):
			selector.add_item(str(option["label"]))
			selector.set_item_metadata(selector.item_count - 1, str(option["id"]))
		selector.item_selected.connect(_change_appearance.bind(category))
		row.add_child(selector)
		selectors[category] = selector
	inspector.add_child(HSeparator.new())
	inspector.add_child(_label("CHUYỂN ĐỘNG", 13, GOLD))
	var action_grid := GridContainer.new()
	action_grid.columns = 3
	action_grid.add_theme_constant_override("h_separation", 5)
	action_grid.add_theme_constant_override("v_separation", 5)
	inspector.add_child(action_grid)
	for i in range(ACTIONS.size()):
		var button := _button(ACTION_LABELS[i], Vector2(91, 34))
		button.add_theme_font_size_override("font_size", 12)
		button.toggle_mode = true
		button.pressed.connect(_select_action.bind(i))
		action_grid.add_child(button)
		action_buttons.append(button)
	var playback := HBoxContainer.new()
	playback.add_theme_constant_override("separation", 8)
	inspector.add_child(playback)
	play_button = _button("Ⅱ  Dừng", Vector2(108, 34))
	play_button.pressed.connect(_toggle_play)
	playback.add_child(play_button)
	var restart := _button("↺  Phát lại", Vector2(110, 34))
	restart.pressed.connect(func():
		playhead = 0.0
		_present(0.0))
	playback.add_child(restart)
	rate_label = _label("Tốc độ  1.0×", 12, MUTED)
	inspector.add_child(rate_label)
	var rate := HSlider.new()
	rate.min_value = 0.25
	rate.max_value = 2.0
	rate.step = 0.25
	rate.value = playback_rate
	rate.custom_minimum_size.y = 24
	rate.value_changed.connect(func(value: float):
		playback_rate = value
		rate_label.text = "Tốc độ  %.2f×" % value)
	inspector.add_child(rate)
	column.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	var summary := VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 3)
	footer.add_child(summary)
	appearance_label = _label("", 14, IVORY)
	summary.add_child(appearance_label)
	result_label = _label("Thay đổi diện mạo rồi nhấn Áp dụng.", 12, MUTED)
	summary.add_child(result_label)
	var apply := _button("Áp dụng diện mạo", Vector2(194, 44))
	apply_button = apply
	apply.add_theme_color_override("font_color", GuPixelUI.JADE)
	apply.pressed.connect(func():
		appearance_applied.emit(appearance.duplicate(true))
		result_label.text = "Đã áp dụng cho nhân vật.")
	footer.add_child(apply)
	initialized = true
	if get_parent() is Control:
		get_parent().resized.connect(_fit_to_parent)
	_fit_to_parent()
	_sync_controls()
	set_open(opened)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, minimum: Vector2) -> Button:
	var button := GuInkButton.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	return button

func _fit_to_parent() -> void:
	if not get_parent() is Control:
		return
	var room: Vector2 = get_parent().size
	size = Vector2(minf(1110, room.x - 48), minf(740, room.y - 48))
	position = (room - size) * 0.5
	_layout_preview()

func _layout_preview() -> void:
	if character_view == null or stage == null:
		return
	character_view.position = stage.ground_position()
	character_view.scale = Vector2.ONE * stage.character_scale()

func begin(value: Dictionary) -> void:
	appearance = GuCharacterAppearance.sanitize(value)
	playhead = 0.0
	playing = true
	if initialized:
		_sync_controls()
		result_label.text = "Thay đổi diện mạo rồi nhấn Áp dụng."
		play_button.text = "Ⅱ  Dừng"

func set_open(value: bool) -> void:
	opened = value
	visible = value
	set_process(value)
	if character_view != null:
		character_view.set_active(value and playing)
		if value:
			_present()

func _sync_controls() -> void:
	if not initialized:
		return
	appearance = GuCharacterAppearance.sanitize(appearance)
	for category in selectors:
		var selector: OptionButton = selectors[category]
		for i in range(selector.item_count):
			if str(selector.get_item_metadata(i)) == str(appearance[category]):
				selector.select(i)
	_update_labels()
	character_view.set_appearance(appearance)
	_present()

func _change_appearance(index: int, category: String) -> void:
	appearance[category] = str(selectors[category].get_item_metadata(index))
	character_view.set_appearance(appearance)
	result_label.text = "Diện mạo đang xem · chưa áp dụng."
	_update_labels()
	_present()

func _select_action(index: int) -> void:
	action = ACTIONS[index]
	playhead = 0.0
	_present(0.0)

func direction_vector() -> Vector2:
	return Vector2.UP.rotated(deg_to_rad(facing_angle)).normalized()

func _select_direction(index: int) -> void:
	direction_index = index
	facing_angle = float(index) * 45.0
	if yaw_slider != null:
		yaw_slider.set_value_no_signal(facing_angle)
	_present(0.0)

func _set_facing_angle(value: float) -> void:
	facing_angle = fposmod(roundf(value / 45.0) * 45.0, 360.0)
	direction_index = int(roundf(facing_angle / 45.0)) % 8
	if yaw_slider != null:
		yaw_slider.set_value_no_signal(facing_angle)
	_present(0.0)

func _toggle_play() -> void:
	playing = not playing
	play_button.text = "Ⅱ  Dừng" if playing else "▶  Tiếp tục"
	character_view.set_active(opened and playing)
	_update_labels()

func _update_labels() -> void:
	var index := ACTIONS.find(action)
	var facing_text: String = ["Bắc", "Đông bắc", "Đông", "Đông nam", "Nam", "Tây nam", "Tây", "Tây bắc"][direction_index] if direction_index >= 0 else "Góc %.0f°" % facing_angle
	pose_label.text = "%s  ·  %s" % [ACTION_LABELS[index], facing_text]
	if yaw_label != null:
		yaw_label.text = "%.0f°" % facing_angle
	for i in range(action_buttons.size()):
		action_buttons[i].set_pressed_no_signal(i == index)
	for i in range(direction_buttons.size()):
		direction_buttons[i].set_pressed_no_signal(i == direction_index)
	appearance_label.text = "%s · %s · %s\n%s · %s · %s" % [GuCharacterAppearance.label("body", appearance["body"]), GuCharacterAppearance.label("outfit", appearance["outfit"]), GuCharacterAppearance.label("weapon", appearance["weapon"]), GuCharacterAppearance.label("hair", appearance["hair"]), GuCharacterAppearance.label("hat", appearance["hat"]), GuCharacterAppearance.label("boots", appearance["boots"])]

func _present(delta: float = -1.0) -> void:
	if character_view == null:
		return
	if delta < 0 or not playing:
		character_view.present(action, playhead, direction_vector(), reduced_motion)
	else:
		character_view.present_smooth(action,playhead,direction_vector(),reduced_motion,delta)
	_update_labels()

func _process(delta: float) -> void:
	if not opened or not playing:
		return
	playhead += delta * playback_rate
	_present(delta)
