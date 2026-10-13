class_name SkillButton
extends Button

var definition: Dictionary = {}
var hotkey: String = ""
var remaining: float = 0.0
var cooldown_duration: float = 0.0
var gu_rank: int = 1
var unavailable: bool = false
var status: String = "Sẵn sàng"
var hover_blend: float = 0.0
var pulse_left: float = 0.0
var pulse_ok: bool = true
var reduced_motion: bool = false
var last_signature: String = ""
var hotkey_label: Label
var name_label: Label
var status_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(76, 94)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hotkey_label = _caption(hotkey, 11, GuPixelUI.INK)
	hotkey_label.position = Vector2(8, 8)
	hotkey_label.size = Vector2(16, 22)
	var badge := GuPixelUI.frame("slot", 0)
	badge.bg_color = GuPixelUI.PAPER_LIGHT
	hotkey_label.add_theme_stylebox_override("normal", badge)
	name_label = _caption(str(definition.get("name", "")), 11, GuPixelUI.PAPER_LIGHT)
	status_label = _caption("", 10, Color("c3c29a"))
	resized.connect(_layout_captions)
	_layout_captions()

func _caption(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GuPixelUI.HAND_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	add_child(label)
	return label

func _layout_captions() -> void:
	if name_label == null: return
	name_label.position = Vector2(8, 53)
	name_label.size = Vector2(size.x - 16, 18)
	status_label.position = Vector2(8, 73)
	status_label.size = Vector2(size.x - 16, 16)

func update_state(cooldown: float, hunger: float, mana: float, max_mana: float, dead: bool) -> void:
	if remaining > 0.01 and cooldown <= 0.01:
		flash_result(true)
	remaining = cooldown
	unavailable = dead or hunger <= 0.0 or mana < ceili(max_mana * float(definition["mana"]) / 100.0)
	status = "Trọng thương" if dead else ("Cổ đói" if hunger <= 0.0 else ("Hồi %.1fs" % cooldown if cooldown > 0.01 else ("Thiếu khí" if unavailable else "Sẵn sàng")))
	var signature := "%s/%s" % [status, unavailable]
	if signature != last_signature:
		last_signature = signature
		if status_label != null:
			status_label.text = "%.0f%% khí" % float(definition["mana"]) if status == "Sẵn sàng" else status
			status_label.add_theme_color_override("font_color", Color("e3a17e") if unavailable else Color("c3c29a"))
		queue_redraw()

func flash_result(accepted: bool) -> void:
	pulse_ok = accepted
	pulse_left = 0.35
	queue_redraw()

func _process(delta: float) -> void:
	var previous := hover_blend
	var target := 1.0 if is_hovered() else 0.0
	hover_blend = target if reduced_motion else move_toward(hover_blend, target, delta * 9.0)
	var active := pulse_left > 0.0
	pulse_left = maxf(0.0, pulse_left - delta)
	if active or not is_equal_approx(previous, hover_blend):
		queue_redraw()

func _draw() -> void:
	if definition.is_empty():
		return
	var color := Color(str(definition["color"]))
	var cooling := remaining > 0.01
	var bounds := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	var outline := Color("c4aa78").lerp(color.darkened(0.19), hover_blend)
	if pulse_left > 0:
		outline = outline.lerp(Color("d4dfb0") if pulse_ok else Color("ed9b6e"), pulse_left / 0.35)
	var frame := GuPixelUI.frame("normal", 0)
	frame.bg_color = Color("302f27").lerp(Color("414436"), hover_blend) if not is_pressed() else Color("4a503e")
	frame.border_color = outline
	frame.set_corner_radius_all(2)
	GuPixelUI.brush_fill(self, bounds, frame.bg_color, 24, 0.45)
	GuPixelUI.brush_frame(self, bounds, outline, int(size.x + 17), 1.35 + hover_blend * 0.35)
	var well := GuPixelUI.frame("normal", 0)
	well.bg_color = Color("242a25")
	well.border_color = Color("5b6049")
	GuPixelUI.brush_fill(self, Rect2(5, 5, size.x - 10, 45), well.bg_color, 8, 0.35)
	GuPixelUI.brush_frame(self, Rect2(5, 5, size.x - 10, 45), Color("65705a", 0.82), 8, 0.9)
	draw_line(Vector2(10, 49), Vector2(size.x - 10, 49), Color(color, 0.3), 1, true)
	var center := Vector2(size.x / 2 + 3, 28 + (1 if is_pressed() else 0))
	var tint := color.darkened(0.62) if unavailable or cooling else color
	GuPixelUI.icon(self, str(definition["kind"]), center, 16, tint)
	if cooling:
		var veil := GuPixelUI.frame("normal", 0)
		veil.bg_color = Color(0.08, 0.07, 0.055, 0.72)
		veil.border_width_left = 0
		veil.border_width_right = 0
		veil.border_width_top = 0
		veil.border_width_bottom = 0
		draw_style_box(veil, Rect2(5, 5, size.x - 10, 45))
		draw_string(GuPixelUI.HAND_FONT, center + Vector2(-25, 6), "%.1f" % remaining, HORIZONTAL_ALIGNMENT_CENTER, 50, 18, GuPixelUI.PAPER_LIGHT)
		var progress := 1.0 - clampf(remaining / maxf(.001, cooldown_duration if cooldown_duration > 0 else float(definition["cooldown"])), 0.0, 1.0)
		draw_line(Vector2(9, 47), Vector2(9 + (size.x - 18) * progress, 47), color, 2, true)
	else:
		draw_line(Vector2(9, 47), Vector2(size.x - 9, 47), Color(color, 0.19), 1.5, true)
	if gu_rank > 1:
		draw_string(GuPixelUI.HAND_FONT, Vector2(size.x-22,24), "II" if gu_rank == 2 else "III", HORIZONTAL_ALIGNMENT_LEFT,-1,11,GuPixelUI.PAPER_LIGHT)
	if pulse_left > 0.0 and not pulse_ok:
		draw_line(Vector2(10, 90), Vector2(size.x - 10, 90), Color("ed9b6e"), 1.5, true)
