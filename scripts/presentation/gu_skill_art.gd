class_name GuSkillArt
extends RefCounted
## Original vector illustrations of the four living Gu currently in the catalog.
## One source is shared by the hotbar, inventory and cultivation portrait.

const KINDS: Array[String] = ["moon", "shield", "dash", "frost"]
const CREATURES := {"moon": "Nguyệt điệp", "shield": "Ngọc giáp trùng", "dash": "Hạc vũ linh trùng", "frost": "Băng tằm"}
const PALETTES := {"moon": Color("aec5a6"), "shield": Color("dedbb8"), "dash": Color("d9dfcc"), "frost": Color("abc7c9")}
static var _textures: Dictionary = {}

static func supports(kind: String) -> bool:
	return kind in KINDS

static func texture(kind: String) -> Texture2D:
	if not supports(kind):
		return null
	if not _textures.has(kind):
		_textures[kind] = load("res://assets/gu/illustrated/" + kind + ".svg")
	return _textures[kind] as Texture2D

static func draw(canvas: CanvasItem, kind: String, center: Vector2, radius: float, tint: Color = Color.WHITE) -> void:
	var illustration := texture(kind)
	if illustration == null or radius <= 0 or tint.a <= .001:
		return
	# Source art occupies 80% of its square; the visible creature uses the
	# requested radius, with a transparent gutter for clean filtering.
	var extent := radius * 2.5
	canvas.draw_texture_rect(illustration, Rect2(center - Vector2.ONE * extent * .5, Vector2.ONE * extent), false, tint)
