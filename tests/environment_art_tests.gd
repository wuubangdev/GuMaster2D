extends RefCounted
## Presentation integration checks deliberately leave WorldGrid authority intact.

static func run(tree: SceneTree, check: Callable) -> void:
	var world := WorldGrid.new()
	var blocked_before := world.blocked.duplicate(true)
	var props_before := world.props.duplicate(true)
	var ground := GroundView.new()
	ground.world = world
	tree.root.add_child(ground)
	await tree.process_frame
	check.call(ground.uses_painted_art() and ground.art_atlas != null and ground.art_atlas.get_width() >= 1024 and ground.art_atlas.get_image().has_mipmaps(), "Environment ground consumes the actual imported raster art atlas with portable mipmaps")
	check.call(ground.terrain_points.size() == 4 and ground.terrain_uv.size() == 4 and ground.get_child_count() == 1 and ground.get_child(0) is Polygon2D, "Painted ground is one continuous world diamond rather than hundreds of separately edged tiles")
	var normalized_uv := ground.terrain_uv == PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	var projected_corners := true
	for index in range(ground.terrain_points.size()):
		var cell := WorldGrid.unproject(ground.terrain_points[index])
		projected_corners = projected_corners and cell.is_finite() and (cell.x == -0.5 or cell.x == 27.5) and (cell.y == -0.5 or cell.y == 27.5)
	check.call(normalized_uv and projected_corners, "Continuous terrain UVs cover all logical grid cells at their original projected boundaries")
	var style_valid := true
	var distinct_styles := false
	var signatures: Dictionary = {}
	for y in range(WorldGrid.SIZE):
		for x in range(WorldGrid.SIZE):
			var style := GroundView.terrain_style_at(Vector2(x, y))
			var total := 0.0
			for value in style.values():
				style_valid = style_valid and is_finite(float(value)) and float(value) >= 0 and float(value) <= 1
				total += float(value)
			style_valid = style_valid and absf(total - 1.0) < 0.0001
			signatures[hash(style)] = true
	distinct_styles = signatures.size() > 5
	check.call(style_valid and distinct_styles, "Grass, stone, earth and woodland-edge surface weights remain finite, normalized and distinct over the whole world")
	var path := GroundView.terrain_style_at(Vector2(12, 23))
	var shoulder := GroundView.terrain_style_at(Vector2(14, 23))
	var meadow := GroundView.terrain_style_at(Vector2(18, 23))
	check.call(float(path["stone"]) > 0.99 and float(shoulder["dirt"]) > 0.5 and float(meadow["grass"]) > 0.95, "Main road has a real stone center, blended earth shoulder and grass outside its edge")
	var shader_bound: bool = ground.ground_material != null and ground.ground_material.get_shader_parameter("terrain_art") == ground.art_atlas
	check.call(shader_bound, "Terrain renderer binds the imported art atlas to the continuous-surface shader")

	var views: Array[PropView] = []
	var painted_kinds: Array[String] = ["tree", "rock", "pillar", "monolith"]
	var resource_shared := true
	var art_bounds_valid := true
	var ground_pivots := true
	var painted_count := 0
	var sources: Dictionary = {}
	var shared_texture: Texture2D
	for index in range(8):
		var view := PropView.new()
		view.configure({"kind":painted_kinds[index % painted_kinds.size()], "variant":index / painted_kinds.size(), "cell":Vector2(4 + index, 5 + index % 2)})
		tree.root.add_child(view)
		views.append(view)
		ground_pivots = ground_pivots and view.position.is_equal_approx(WorldGrid.project(view.cell)) and view.rotation == 0 and view.scale.is_equal_approx(Vector2.ONE)
		if view.uses_painted_art():
			painted_count += 1
			shared_texture = view.art_atlas if shared_texture == null else shared_texture
			resource_shared = resource_shared and shared_texture == view.art_atlas
			sources[hash(view.art_source)] = true
			art_bounds_valid = art_bounds_valid and view.art_bounds.position.is_finite() and view.art_bounds.size.is_finite() and view.art_bounds.position.y < 0 and view.art_bounds.end.y >= 0 and view.art_bounds.end.y < 12 and view.art_bounds.size.x <= 148.01
			art_bounds_valid = art_bounds_valid and Rect2(Vector2.ZERO, Vector2(view.art_atlas.get_size())).encloses(view.art_source)
	check.call(painted_count == 8 and sources.size() == 4, "Trees have two painted silhouettes and rocks/ancient stone props use their separate actual atlas regions")
	check.call(resource_shared and shared_texture != null and shared_texture.get_image().has_mipmaps(), "Repeated environmental props share one raster atlas with portable runtime mipmaps")
	check.call(art_bounds_valid and ground_pivots, "Cropped prop artwork preserves finite bounds, grounded feet and the existing Y-sort anchor")
	var alpha_valid := shared_texture != null
	if shared_texture != null:
		var image := shared_texture.get_image()
		alpha_valid = image != null and image.detect_alpha() != Image.ALPHA_NONE
		if image != null:
			for point in [Vector2i.ZERO, Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
				alpha_valid = alpha_valid and image.get_pixelv(point).a < 0.05
	check.call(alpha_valid, "Painted props contain real transparent alpha with clear outer atlas corners")
	var clipped_samples := 0
	if shared_texture != null:
		var image := shared_texture.get_image()
		var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
		for row in range(2):
			for column in range(2):
				var origin := Vector2i(column, row) * cell_size
				for offset in range(0, cell_size.x, 2):
					for point in [Vector2i(offset, 0), Vector2i(offset, cell_size.y - 1), Vector2i(0, offset), Vector2i(cell_size.x - 1, offset)]:
						if image.get_pixelv(origin + point).a > 0.25:
							clipped_samples += 1
	check.call(shared_texture != null and clipped_samples <= 4, "Painted prop silhouettes leave transparent quadrant borders so atlas selection cannot cut off trees or roots (%d opaque edge samples)" % clipped_samples)

	var tree_view := views[0]
	tree_view.modulate.a = 0.12
	check.call(tree_view.modulate.a < 0.13 and not tree_view.is_processing() and tree_view.get_child_count() == 0, "Painted foliage remains one fadeable canvas item and adds no idle processing or nested Y-sort nodes")
	var lantern := PropView.new()
	lantern.configure({"kind":"lantern", "variant":0, "cell":WorldGrid.SPAWN})
	tree.root.add_child(lantern)
	lantern.reduced_motion = true
	var previous_phase := lantern.phase
	lantern._process(0.25)
	check.call(is_equal_approx(lantern.phase, previous_phase), "Reduced motion freezes ambient prop flicker without changing its visual ground anchor")
	check.call(world.blocked == blocked_before and world.props == props_before and world.is_walkable(WorldGrid.SPAWN) and world.is_safe(WorldGrid.SPAWN), "Art construction preserves navigation solids, prop definitions and exact safe-zone authority")
	lantern.queue_free()
	for view in views:
		view.queue_free()
	ground.queue_free()
	await tree.process_frame
