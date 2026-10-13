class_name GroundView
extends Node2D
## Native 32px tiles sit on logical square cells. None of the meadow details
## change navigation; cropped plants and shallow puddles remain walkable.

const TERRAIN_ART_PATH := "res://assets/pixel/environment/terrain.png"
const TILE_SIZE := 32
const ATLAS_COLUMNS := 8
const TILE_COUNT := 48
const OVERSCAN := 12
static var _shared_art_atlas: Texture2D

var world: WorldGrid
var art_atlas: Texture2D
var tiles: TileMapLayer
var phase: float = 0.0
var reduced_motion: bool = false
var _water_frame: int = -1
var _water_cells: Array[Vector2i] = []
var _tile_window := Rect2i()
var _window_refresh := 0.0
var _fences: Dictionary = {}
const STREAM_MARGIN := 6
const STREAM_STEP := 8

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_atlas = load_art_atlas()
	_build_tiles()
	queue_redraw()

static func load_art_atlas() -> Texture2D:
	if _shared_art_atlas == null and ResourceLoader.exists(TERRAIN_ART_PATH):
		_shared_art_atlas = load(TERRAIN_ART_PATH) as Texture2D
	return _shared_art_atlas

func uses_painted_art() -> bool:
	return false

func uses_pixel_art() -> bool:
	return art_atlas != null and tiles != null

static func _is_road(cell: Vector2i) -> bool:
	return (cell.x >= 10 and cell.x <= 14 and cell.y >= 9 and cell.y <= 27) or (cell.y >= 16 and cell.y <= 20 and cell.x >= 4 and cell.x <= 23)

static func surface_kind(cell: Vector2i) -> String:
	if cell.x >= 8 and cell.x <= 16 and cell.y >= 9 and cell.y <= 13:
		return "stone"
	if (cell.x >= 11 and cell.x <= 13 and cell.y >= 9 and cell.y <= 27) or (cell.y >= 17 and cell.y <= 19 and cell.x >= 4 and cell.x <= 23):
		return "stone"
	if _is_road(cell):
		return "dirt"
	return "grass"

static func terrain_style_at(cell: Vector2) -> Dictionary:
	var kind := surface_kind(Vector2i(roundi(cell.x), roundi(cell.y)))
	return {"grass": 1.0 if kind == "grass" else 0.0, "stone": 1.0 if kind == "stone" else 0.0, "dirt": 1.0 if kind == "dirt" else 0.0, "rock": 0.0}

static func tile_at(cell: Vector2i) -> int:
	var kind := surface_kind(cell)
	var seed := posmod(cell.x * 171 + cell.y * 79 + cell.x * cell.y * 13, 97)
	if kind == "grass":
		if cell.x in [4, 5] and cell.y >= 20 and cell.y <= 23:
			return 47
		if cell in [Vector2i(21, 13), Vector2i(22, 14), Vector2i(18, 14)]:
			return 40
		if seed < 9 and cell.x > 3 and cell.x < 24 and cell.y > 4 and cell.y < 25:
			return 46
		return posmod(seed, 8)
	var neighbors: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var edges: int = 0
	for index in range(neighbors.size()):
		var adjacent := surface_kind(cell + neighbors[index])
		if adjacent == "grass":
			edges |= 1 << index
	return (24 if kind == "stone" else 8) + edges

func _build_tiles() -> void:
	if world == null or art_atlas == null:
		return
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = art_atlas
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for index in range(TILE_COUNT):
		source.create_tile(Vector2i(index % ATLAS_COLUMNS, index / ATLAS_COLUMNS))
	tile_set.add_source(source, 0)
	tiles = TileMapLayer.new()
	tiles.name = "PixelTerrain"
	tiles.material = GuCultivationPalette.environment()
	tiles.show_behind_parent = true
	tiles.tile_set = tile_set
	tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# TileMap coordinates use a top-left origin; simulation cells use ground centers.
	tiles.position = Vector2(-TILE_SIZE / 2, -TILE_SIZE / 2)
	add_child(tiles)
	_refresh_visible_tiles()

func visible_cell_rect() -> Rect2i:
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var viewport := get_viewport_rect()
	var first := WorldGrid.unproject(inverse*viewport.position)
	var last := WorldGrid.unproject(inverse*viewport.end)
	var low := Vector2i(floori(minf(first.x,last.x)/STREAM_STEP)*STREAM_STEP-STREAM_MARGIN,floori(minf(first.y,last.y)/STREAM_STEP)*STREAM_STEP-STREAM_MARGIN)
	var high := Vector2i(ceili(maxf(first.x,last.x)/STREAM_STEP)*STREAM_STEP+STREAM_MARGIN,ceili(maxf(first.y,last.y)/STREAM_STEP)*STREAM_STEP+STREAM_MARGIN)
	return Rect2i(low,high-low).intersection(Rect2i(-OVERSCAN,-OVERSCAN,WorldGrid.SIZE+OVERSCAN*2,WorldGrid.SIZE+OVERSCAN*2))

func _refresh_visible_tiles() -> void:
	var next := visible_cell_rect()
	if next == _tile_window: return
	# Only the viewport and a margin occupy TileMap cells. Distant rivers no
	# longer mark whole-map rendering quadrants dirty five times per second.
	for cell in tiles.get_used_cells():
		if not next.has_point(cell): tiles.erase_cell(cell)
	_water_cells.clear()
	var wanted_fences := {}
	for y in range(next.position.y,next.end.y):
		for x in range(next.position.x,next.end.x):
			var cell := Vector2i(x,y)
			var index := region_tile_at(cell)
			if not _tile_window.has_point(cell): tiles.set_cell(cell,0,Vector2i(index%ATLAS_COLUMNS,index/ATLAS_COLUMNS))
			if index == 40: _water_cells.append(cell)
			if x >= 0 and x < WorldGrid.SIZE and y >= 0 and y < WorldGrid.SIZE and (x == 0 or y == 0 or x == WorldGrid.SIZE-1 or y == WorldGrid.SIZE-1):
				wanted_fences[cell] = true
				if not _fences.has(cell):
					var fence := PropView.new()
					fence.configure({"cell":Vector2(cell),"kind":"fence","variant":0})
					add_child(fence)
					_fences[cell] = fence
	for cell in _fences.keys():
		if not wanted_fences.has(cell):
			_fences[cell].queue_free()
			_fences.erase(cell)
	_tile_window = next
	_water_frame = -1

func _process(delta: float) -> void:
	if tiles == null:
		return
	_window_refresh -= delta
	if _window_refresh <= 0:
		_window_refresh = .08
		_refresh_visible_tiles()
	if not reduced_motion:
		phase += delta
	var frame := 0 if reduced_motion else posmod(int(phase * 5.0), 6)
	if frame == _water_frame:
		return
	_water_frame = frame
	for cell in _water_cells:
		var index := 40 + frame
		tiles.set_cell(cell, 0, Vector2i(index % ATLAS_COLUMNS, index / ATLAS_COLUMNS))

func _draw() -> void:
	if world == null:
		return
	# Exact safe-radius boundary, dotted with hard one-pixel clusters.
	var center := WorldGrid.project(WorldGrid.SPAWN)
	for step in range(80):
		if step % 4 > 1:
			continue
		var angle := float(step) / 80.0 * TAU
		var p := center + (Vector2(cos(angle), sin(angle)) * 64.0).round()
		draw_rect(Rect2(p, Vector2.ONE), Color("7d9977"), true)
	# A small inset seal marks camp without covering the player's silhouette.
	for offset in [Vector2(-3, 3), Vector2(-2, 4), Vector2(-1, 5), Vector2(0, 6), Vector2(1, 5), Vector2(2, 4), Vector2(3, 3)]:
		draw_rect(Rect2(center + offset, Vector2.ONE), Color("829e7c"), true)

func region_tile_at(cell: Vector2i) -> int:
	if cell.x >= 27 or cell.y >= 28:
		var kind := world.terrain_at(cell)
		var variant := posmod(cell.x*31+cell.y*17,8)
		if kind == "water": return 40
		if kind in ["stone","dirt"]:
			var edges := 0
			var neighbors := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
			for i in range(neighbors.size()):
				if world.terrain_at(cell+neighbors[i]) == "grass": edges |= 1 << i
			return (24 if kind == "stone" else 8)+edges
		return variant
	if world.region == "forest":
		return tile_at(cell)
	var variation := posmod(cell.x * 31 + cell.y * 17, 8)
	if world.region == "ruins":
		if (cell.x >= 10 and cell.x <= 14) or (cell.y >= 10 and cell.y <= 13) or (cell.y >= 18 and cell.y <= 20):
			return 24
		return 8 if (cell.x + cell.y) % 5 != 0 else variation
	if cell.x >= 9 and cell.x <= 18 and cell.y >= 14 and cell.y <= 19:
		return 8
	if cell.x >= 11 and cell.x <= 13 and cell.y >= 10:
		return 24
	return variation
