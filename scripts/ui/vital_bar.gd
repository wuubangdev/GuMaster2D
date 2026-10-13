class_name GuVitalBar
extends ProgressBar
## A delayed damage edge makes lost health legible without delaying the actual value.

var tint: Color = Color("ac574b")
var reduced_motion: bool = false
var damage_feedback: bool = true
var damage_tail: float = 0.0
var hold_left: float = 0.0
var previous_value: float = 0.0

func _ready() -> void:
	damage_tail = value
	previous_value = value
	value_changed.connect(_value_changed)

func _value_changed(amount: float) -> void:
	if not damage_feedback or reduced_motion:
		damage_tail = amount
		hold_left = 0.0
	elif amount < previous_value:
		damage_tail = maxf(damage_tail, previous_value)
		hold_left = 0.16
	else:
		damage_tail = maxf(amount, damage_tail)
	previous_value = amount
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if reduced_motion:
		damage_tail = value
	elif hold_left > 0.0:
		hold_left = maxf(0, hold_left - delta)
	elif damage_tail > value:
		damage_tail = maxf(value, damage_tail - (max_value - min_value) * delta * 1.8)
	else:
		return
	queue_redraw()

func _draw() -> void:
	var denominator := maxf(1, max_value - min_value)
	var width := maxf(0, size.x - 2)
	var fill_width := floorf(width * clampf((value - min_value) / denominator, 0, 1))
	var tail_width := floorf(width * clampf((damage_tail - min_value) / denominator, 0, 1))
	if tail_width > fill_width:
		draw_rect(Rect2(1 + fill_width, 1, tail_width - fill_width, maxf(1, size.y - 2)), tint.lightened(0.28))
	if fill_width > 0:
		draw_rect(Rect2(1, 2, fill_width, 1), tint.lightened(0.32))
		if size.y > 8:
			draw_rect(Rect2(1, size.y - 3, fill_width, 1), tint.darkened(0.32))
		for mark in range(7, int(fill_width), 13):
			draw_line(Vector2(mark, 3), Vector2(mark + 2, size.y - 3), Color(GuPixelUI.PAPER_LIGHT, 0.12), 0.7, true)
	GuPixelUI.brush_frame(self, Rect2(Vector2.ZERO, size), Color(GuPixelUI.INK_SOFT, 0.78), 4, 0.95)
