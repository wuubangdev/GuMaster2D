class_name PropView
extends Node2D
## Original sprite regions stay at native 1:1 scale. Every frame shares the
## ground pivot (48,88), including roof segments and tiny lantern flames.

const PROP_ART_PATH := "res://assets/pixel/environment/props.png"
const MANIFEST_PATH := "res://assets/pixel/environment/manifest.json"
const FRAME_SIZE := Vector2i(96, 96)
const PIVOT := Vector2(48, 88)
static var _shared_atlas: Texture2D
static var _shared_frames: Dictionary = {}

var art_atlas: Texture2D
var art_source := Rect2()
var art_bounds := Rect2()
var kind: String = "tree"
var variant: int = 0
var cell: Vector2
var phase: float = 0.0
var reduced_motion: bool = false
var redraw_left: float = 0.0
var _frame_name: String = ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = GuCultivationPalette.environment()
	if kind in ["bamboo","ruin_column"]:
		material = null
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_prepare_art()
	set_process(kind in ["lantern", "altar"])

func configure(data: Dictionary) -> void:
	kind = str(data["kind"])
	variant = int(data["variant"])
	cell = data["cell"]
	position = WorldGrid.project(cell).round()
	phase = float(variant) * 0.24
	_prepare_art()
	queue_redraw()

static func _load_art() -> void:
	if _shared_atlas == null and ResourceLoader.exists(PROP_ART_PATH):
		_shared_atlas = load(PROP_ART_PATH) as Texture2D
	if _shared_frames.is_empty() and FileAccess.file_exists(MANIFEST_PATH):
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if manifest is Dictionary:
			for frame in manifest.get("props", {}).get("frames", []):
				_shared_frames[str(frame["name"])] = frame

func _select_frame() -> String:
	match kind:
		"tree":
			if cell == Vector2(6, 21): return "hut_0"
			if cell == Vector2(16, 22): return "hut_1"
			return "tree_%d" % posmod(variant, 5)
		"rock":
			if cell == Vector2(9, 18): return "well"
			if cell == Vector2(21, 21): return "crates"
			return "rock_%d" % posmod(variant, 4)
		"wall":
			var house_side := 0 if cell.x < 12 else 1
			var house_start := 8 if house_side == 0 else 14
			return "house_%d_%d" % [house_side, clampi(int(cell.x) - house_start, 0, 2)]
		"pillar": return "pillar_%d" % posmod(variant, 2)
		"monolith": return "monolith"
		"fence": return "fence"
		"lantern": return "lantern_%d" % (0 if reduced_motion else posmod(int(phase * 6.0), 4))
		"altar": return "altar_%d" % (0 if reduced_motion else posmod(int(phase * 5.0), 4))
	return "rock_0"

func _prepare_art() -> void:
	if kind in ["bamboo","ruin_column"]:
		art_source = Rect2()
		art_bounds = Rect2(-30,-90,60,98)
		return
	_load_art()
	art_atlas = _shared_atlas
	_frame_name = _select_frame()
	var frame: Dictionary = _shared_frames.get(_frame_name, {})
	if frame.is_empty():
		art_source = Rect2()
		art_bounds = Rect2()
		return
	var region: Array = frame["region"]
	var bounds: Array = frame["bounds"]
	art_source = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	art_bounds = Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))

func uses_painted_art() -> bool:
	return false

func uses_pixel_art() -> bool:
	return art_atlas != null and art_source.has_area()

func _process(delta: float) -> void:
	if not reduced_motion:
		phase += delta
	var next := _select_frame()
	if next != _frame_name:
		_prepare_art()
		queue_redraw()

func _draw() -> void:
	if kind in ["bamboo","ruin_column"]:
		_draw_overland_prop()
		return
	if not uses_pixel_art():
		return
	draw_texture_rect_region(art_atlas, Rect2(-PIVOT, Vector2(FRAME_SIZE)), art_source, Color.WHITE, false, false)

func _draw_overland_prop() -> void:
	var ink := Color("45503d")
	if kind == "bamboo":
		for i in range(3):
			var foot := Vector2(-9+i*9,2-i%2*3)
			var tip := foot+Vector2(-7+i*7,-57-i%2*22)
			draw_line(foot,tip,ink,5,true)
			draw_line(foot+Vector2(1,0),tip+Vector2(1,0),Color("8b9b6d"),2.7,true)
			for j in range(1,5):
				var joint := foot.lerp(tip,j/5.0)
				draw_line(joint-Vector2(2,0),joint+Vector2(3,0),Color("c0c09a"),1,true)
				if j < 2: continue
				var end := joint+Vector2((13+i*3)*(1 if j%2 else -1),-13)
				draw_line(joint,end,ink,1,true)
				for k in range(3):
					var leaf := joint.lerp(end,.35+k*.22)
					var side := 1 if k%2 else -1
					draw_colored_polygon(PackedVector2Array([leaf,leaf+Vector2(side*9,-9),leaf+Vector2(side*4,3)]),Color("6e8156"))
	else:
		var height := 38+variant*9
		var outer := PackedVector2Array([Vector2(-15,1),Vector2(-13,-height+4),Vector2(-3,-height-5),Vector2(8,-height),Vector2(13,-height+2),Vector2(16,1),Vector2(7,7),Vector2(-10,6)])
		draw_colored_polygon(outer,Color("96917a"))
		outer.append(outer[0]); draw_polyline(outer,ink,1.5,true)
		draw_colored_polygon(PackedVector2Array([Vector2(-13,-height+4),Vector2(-3,-height-5),Vector2(8,-height),Vector2(13,-height+2),Vector2(4,-height+9)]),Color("c6b799"))
		draw_line(Vector2(4,-height+9),Vector2(6,5),Color("797c66"),2,true)
		for y in range(12,height-9,12): draw_polyline(PackedVector2Array([Vector2(-9,-y),Vector2(-2,-y-3),Vector2(0,-y+2)]),Color("565f4e"),1,true)
		draw_polyline(PackedVector2Array([Vector2(11,-5),Vector2(4,-9),Vector2(7,-15),Vector2(2,-19)]),Color("697958"),2,true)
