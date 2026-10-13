class_name GuInkButton
extends Button
## Interactive paper tab with an inked edge; button behavior remains native.

# The ink occupies the outer 4 px. Native Button shaping measures both the
# Vietnamese text and these insets, including when a container sizes a tab.
const TEXT_INSET := Vector2(12, 8)

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var background := StyleBoxFlat.new()
		background.bg_color = GuPixelUI.PAPER
		if state == "hover": background.bg_color = GuPixelUI.PAPER_LIGHT
		elif state in ["pressed", "hover_pressed"]: background.bg_color = Color("c3c9a8")
		elif state == "disabled": background.bg_color = Color("d8c8a8")
		background.set_corner_radius_all(2)
		background.content_margin_left = TEXT_INSET.x
		background.content_margin_right = TEXT_INSET.x
		background.content_margin_top = TEXT_INSET.y
		background.content_margin_bottom = TEXT_INSET.y
		add_theme_stylebox_override(state, background)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_font_override("font", GuPixelUI.HAND_FONT)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, GuPixelUI.INK)
	add_theme_color_override("font_disabled_color", GuPixelUI.MUTED)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	toggled.connect(func(_active: bool): queue_redraw())
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var bounds := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	var active := toggle_mode and button_pressed
	var line := Color(GuPixelUI.INK_SOFT, 0.78)
	if disabled:
		line = Color(GuPixelUI.MUTED, 0.52)
	elif active:
		line = GuPixelUI.JADE
	elif is_hovered():
		line = GuPixelUI.INK
	GuPixelUI.brush_frame(self, bounds, line, int(size.x + size.y), 1.45 if active else 1.25, 0.95)
	var top := Vector2(6, 3)
	var shine_length := minf(size.x - 14, 25.0)
	if shine_length > 8:
		draw_line(top, top + Vector2(shine_length, 0.4), Color(GuPixelUI.PAPER_LIGHT, 0.7), 0.8, true)
	if active:
		draw_line(Vector2(8, size.y - 3), Vector2(size.x - 8, size.y - 3), Color(GuPixelUI.JADE, 0.75), 1.3, true)
