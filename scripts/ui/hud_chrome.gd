class_name GuHudChrome
extends Control
## One compact action dock; world stays visible and clickable outside its bounds.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var dock := Rect2(Vector2(floorf(size.x * 0.5) - 176, size.y - 118), Vector2(352, 114))
	draw_rect(dock, Color("292c25"))
	draw_rect(dock.grow(-2), Color("384034", 0.35))
	# Quiet green/brown pigment blooms keep the dark lacquer tied to the painted world.
	draw_circle(dock.position + Vector2(42, 26), 25, Color("8a7651", 0.055), true, -1, true)
	draw_circle(dock.position + Vector2(307, 75), 28, Color("789078", 0.045), true, -1, true)
	GuPixelUI.paper_grain(self, dock.grow(-3), 29)
	GuPixelUI.brush_frame(self, dock.grow(-1), Color("d2b982"), 29, 2.25)
	draw_line(dock.position + Vector2(13, 1), dock.position + Vector2(72, 1.5), Color("d7bd8c", 0.72), 1.1, true)
	draw_line(dock.position + Vector2(265, dock.size.y - 2), dock.position + Vector2(333, dock.size.y - 2.5), Color("c3a779", 0.55), 0.9, true)
	draw_rect(Rect2(dock.position + Vector2(163, -2), Vector2(26, 3)), Color("e0c58e"))
	draw_rect(Rect2(dock.position + Vector2(171, -3), Vector2(10, 5)), GuPixelUI.JADE)
