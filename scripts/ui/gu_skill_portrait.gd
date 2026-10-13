class_name GuSkillPortrait
extends Control
## Native board portrait, using precisely the same Gu illustration as the HUD.
var kind := "moon"
var rank_value := 1
var celebration := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(160, 136)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(false)

func celebrate(reduced_motion: bool = false) -> void:
	celebration = 0.0 if reduced_motion else 1.0
	set_process(celebration > 0)
	queue_redraw()

func _process(delta: float) -> void:
	celebration = maxf(0, celebration - delta / .48)
	queue_redraw()
	if celebration <= 0: set_process(false)

func _draw() -> void:
	var center := Vector2(size.x * .5, (size.y - 26) * .5)
	var radius := minf(size.x * .34, (size.y - 26) * .43)
	GuSkillArt.draw(self, kind, center, radius)
	if celebration > 0:
		draw_arc(center, radius * (1.05 + (1.0 - celebration) * .3), 0, TAU, 64, Color(GuPixelUI.JADE, celebration * .6), 1.6, true)
	var caption: String = GuSkillArt.CREATURES.get(kind, "Cổ linh")
	draw_string(GuPixelUI.HAND_FONT, Vector2(0, size.y - 10), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, GuPixelUI.JADE)
