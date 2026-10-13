class_name GuPixelEffectsArt
extends RefCounted
## Legacy atlas inspection remains available; live art uses smooth vector curves.
## Both render paths are immutable and never modify gameplay.

const MANIFEST_PATH := "res://assets/pixel/effects/manifest.json"
const PATH := "res://assets/pixel/effects/spells.png"
const CELL := Vector2(96, 96)
const PIVOT := Vector2(48, 48)
const CONTACT_TIME := 0.28
static var _manifest: Dictionary = {}
static var _texture: Texture2D

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest

static func texture() -> Texture2D:
	if _texture == null:
		_texture = load(PATH) as Texture2D
	return _texture

static func direction_index(direction: Vector2) -> int:
	return posmod(roundi(direction.angle() / (TAU / 8.0)), 8) if direction.length_squared() > 0.001 else 0

static func region(kind: String, frame: int, direction: Vector2 = Vector2.RIGHT) -> Rect2:
	var clip: Dictionary = manifest().get("clips", {}).get(kind, {})
	if clip.is_empty():
		return Rect2()
	var facing := direction_index(direction) if int(clip["directions"]) == 8 else 0
	var index := int(clip["indices"][facing][clampi(frame, 0, int(clip["frames"]) - 1)])
	var columns := int(manifest()["columns"])
	return Rect2(Vector2(index % columns, index / columns) * CELL, CELL)

static func draw(canvas: CanvasItem, kind: String, at: Vector2, ratio: float, direction: Vector2 = Vector2.RIGHT, tint: Color = Color.WHITE) -> void:
	GuVectorEffectsArt.draw(canvas, kind, at, ratio, direction, tint)

static func ground_shadow(canvas: CanvasItem, at: Vector2, width: int, tint: Color) -> void:
	GuVectorEffectsArt.ground_shadow(canvas, at, float(width), tint)
