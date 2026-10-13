class_name GuPixelWolfArt
extends RefCounted
## Shared, original, nearest-filtered wolf atlas; no per-actor image allocation.
const PATH := "res://assets/pixel/creatures/forest_wolf.png"
const ACTIONS := ["idle", "walk", "windup", "strike", "hit", "death"]
static var _texture: Texture2D

static func direction_index(facing: Vector2) -> int:
	return posmod(roundi((facing.angle() - Vector2.DOWN.angle()) / (TAU / 8.0)), 8) if facing.length_squared() > 0.001 else 0

static func texture() -> Texture2D:
	if _texture == null:
		_texture = load(PATH)
	return _texture

static func draw(canvas: CanvasItem, action: String, direction: Vector2, frame: int, tint: Color = Color.WHITE) -> void:
	var row := maxi(0, ACTIONS.find(action))
	var column := direction_index(direction) * 4 + clampi(frame, 0, 3)
	canvas.draw_texture_rect_region(texture(), Rect2(-32,-52,64,64), Rect2(column*64,row*64,64,64),tint)
