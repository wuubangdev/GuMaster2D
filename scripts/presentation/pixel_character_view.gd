class_name GuPixelCharacterView
extends Node2D
## Original baked 2D pixel art. Ground pivot stays fixed in every state.
## The simulation owns time and actions; this view never advances gameplay.

const MANIFEST_PATH: String = "res://assets/pixel/characters/manifest.json"
const CELL_SIZE: Vector2i = Vector2i(80, 80)
const GROUND_PIVOT: Vector2 = Vector2(40, 68)
const NATIVE_HEIGHT: float = 48.0
const DIRECTIONS: Array[String] = ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]

static var _manifest: Dictionary = {}

var sprite: Sprite2D
var appearance: Dictionary = GuCharacterAppearance.default_data()
var display_height: float = NATIVE_HEIGHT
var render_size: int = CELL_SIZE.x
var active: bool = true
var current_action: String = "idle"
var current_direction: int = 0
var current_frame: int = 0

var _configured: bool = false
var _atlas: Texture2D
var _entry: Dictionary = {}
var _frame_textures: Dictionary = {}
var _appearance_key: String = ""
var _time: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _reduced: bool = false


func _init() -> void:
	name = "PixelCharacterView"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	if not _configured:
		configure()


static func atlas_manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest


static func appearance_key(value: Dictionary) -> String:
	var clean := GuCharacterAppearance.sanitize(value)
	return "%s_%s_%s_%s" % [clean["body"], clean["outfit"], clean["hair"], clean["weapon"]]


static func direction_for(facing: Vector2) -> int:
	if facing.length_squared() < 0.0001:
		return 0
	return posmod(roundi(atan2(-facing.x, facing.y) / (PI / 4.0)), 8)


static func duration(action: String, weapon: String = "sword") -> float:
	return GuCharacterAnimations.duration(action, weapon)


func configure(_pixel_size: int = 256, height: float = 48.0) -> void:
	# Integer enlargement preserves hard native clusters in portraits and studio.
	var multiplier := maxi(1, roundi(height / NATIVE_HEIGHT))
	display_height = NATIVE_HEIGHT * multiplier
	if not _configured:
		_configured = true
		sprite = Sprite2D.new()
		sprite.name = "PixelCharacterImage"
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
	sprite.scale = Vector2.ONE * multiplier
	sprite.position = -GROUND_PIVOT * multiplier
	set_appearance(appearance)


func set_appearance(value: Dictionary) -> void:
	appearance = GuCharacterAppearance.sanitize(value)
	if not _configured:
		configure()
		return
	var key := appearance_key(appearance)
	if key != _appearance_key or _atlas == null:
		_appearance_key = key
		var manifest := atlas_manifest()
		_entry = manifest.get("appearances", {}).get(key, {})
		_frame_textures.clear()
		if _entry.is_empty():
			push_error("Pixel character identity missing from atlas: " + key)
			return
		_atlas = load(str(_entry["path"])) as Texture2D
	present(current_action, _time, _facing, _reduced)


func present(action: String, time: float, facing: Vector2, reduced: bool = false) -> void:
	if not _configured:
		configure()
	if _entry.is_empty():
		return
	var clips: Dictionary = atlas_manifest()["clips"]
	current_action = action if clips.has(action) else "idle"
	_time = maxf(0.0, time)
	_reduced = reduced
	if facing.length_squared() > 0.0001:
		_facing = facing
		current_direction = direction_for(facing)
	var clip: Dictionary = clips[current_action]
	var length := maxf(0.01, duration(current_action, str(appearance["weapon"])))
	var sample_time := _time
	if reduced and current_action in ["idle", "walk", "run", "defend", "channel"]:
		sample_time = 0.0
	var phase := fposmod(sample_time, length) / length if bool(clip["loop"]) else clampf(sample_time / length, 0.0, 0.999999)
	current_frame = clampi(floori(phase * int(clip["frames"])), 0, int(clip["frames"]) - 1)
	var ids: Array = _entry["frames"][current_action][current_direction]
	var id := int(ids[current_frame])
	if not _frame_textures.has(id):
		var frame := AtlasTexture.new()
		frame.atlas = _atlas
		var columns := int(_entry["columns"])
		var row := floori(float(id) / float(columns))
		frame.region = Rect2(Vector2((id % columns) * CELL_SIZE.x, row * CELL_SIZE.y), Vector2(CELL_SIZE))
		frame.filter_clip = true
		_frame_textures[id] = frame
	sprite.texture = _frame_textures[id]


func set_active(value: bool) -> void:
	# There is no render target or independent clock to keep alive when hidden.
	active = value


func hand_position(side: String = "R") -> Vector2:
	if sprite == null or _entry.is_empty():
		return Vector2(8, -18)
	var hands: Dictionary = _entry["hands"][current_action][current_direction][current_frame]
	var point: Array = hands.get(side, hands["R"])
	return sprite.position + Vector2(float(point[0]), float(point[1])) * sprite.scale


func current_frame_texture() -> Texture2D:
	return sprite.texture if sprite != null else null


func visual_rect() -> Rect2:
	if sprite == null:
		return Rect2()
	return Rect2(sprite.position, Vector2(CELL_SIZE) * sprite.scale)
