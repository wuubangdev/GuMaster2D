class_name GuLacquerPanel
extends PanelContainer
## Paper grain and imperfect ink corners unify HUD panels and modal windows.

const CONTENT_INSET := 20

func _ready() -> void:
	# Move the stock theme frame into this control's draw pass so grain and ink can sit above it.
	var layout_style := StyleBoxEmpty.new()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		layout_style.set_content_margin(side, CONTENT_INSET)
	add_theme_stylebox_override("panel", layout_style)
	resized.connect(queue_redraw)

func _draw() -> void:
	GuPixelUI.paper_panel(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), int(size.x + size.y))
