extends "res://tests/concept_character_visual_smoke.gd"
## GPU regression: owner/paper separation, solid ink, atlas-cell isolation,
## opacity, and subpixel coverage of fine lines at the 48px minification ratio.
class AtlasProbe extends Node2D:
	var atlas: Texture2D
	var source_rect := Rect2(2,32,64,64)
	func _draw() -> void:
		var uv := PackedVector2Array()
		for p in [source_rect.position,source_rect.position+Vector2(source_rect.size.x,0),source_rect.end,source_rect.position+Vector2(0,source_rect.size.y)]:
			uv.append(p/Vector2(atlas.get_size())+Vector2(18,0))
		draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(8,0),Vector2(8,8),Vector2(0,8)]),PackedColorArray([Color.WHITE]),uv,atlas)

func _atlas_material(atlas: Texture2D, baseline: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	if baseline:
		var old := Shader.new()
		old.code=FileAccess.get_file_as_string("res://artifacts/concept47_baseline/concept_cutout.gdshader")
		mat.shader=old
	else: mat.shader=GuConceptCharacterArt.SHADER
	mat.set_shader_parameter("directional_atlas",atlas)
	return mat

func _run() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2);return
	root.size=Vector2i(1280,800);root.content_scale_size=root.size
	review_root=Node2D.new();root.add_child(review_root)
	capture_prefix="concept47"
	var ink_ok := await _ink_probes()
	var edges_ok := await _edge_probes()
	var viewport := SubViewport.new()
	viewport.size=Vector2i(400,160);viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stripes := Image.create(192,144,false,Image.FORMAT_RGBA8)
	stripes.fill(Color.RED)
	for y in range(144):
		for x in range(192): stripes.set_pixel(x,y,Color(1,0,0,float(x%2)))
	var striped := ImageTexture.create_from_image(stripes)
	var cells := Image.create(192,144,false,Image.FORMAT_RGBA8)
	cells.fill(Color.RED)
	cells.fill_rect(Rect2i(96,0,96,144),Color.GREEN)
	var cell_texture := ImageTexture.create_from_image(cells)
	var phase_probes := []
	for baseline in [true,false]:
		for phase in range(16):
			var probe := AtlasProbe.new();probe.atlas=striped
			probe.source_rect=Rect2(10+phase/8.0,32,64,64)
			probe.position=Vector2(8+phase*20,8 if baseline else 40)
			probe.material=_atlas_material(striped,baseline)
			viewport.add_child(probe)
			phase_probes.append({"baseline":baseline,"point":Vector2i(probe.position)+Vector2i(3,3)})
	var cell_probes := []
	for opacity in [1.0,0.5]:
		var probe := AtlasProbe.new();probe.atlas=cell_texture
		# Last on-cell pixel covers x~94; its filter reaches the green cell.
		probe.source_rect=Rect2(35,32,64,64)
		probe.position=Vector2(10+cell_probes.size()*40,90)
		probe.material=_atlas_material(cell_texture,false)
		probe.modulate.a=opacity
		viewport.add_child(probe)
		cell_probes.append({"point":Vector2i(probe.position)+Vector2i(7,3),"opacity":opacity})
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := viewport.get_texture().get_image()
	var before_error := 0.0;var after_error := 0.0
	var phases := []
	for probe: Dictionary in phase_probes:
		var alpha := rendered.get_pixelv(probe["point"]).a
		var error := absf(alpha-.5)
		if probe["baseline"]: before_error+=error
		else: after_error+=error
		phases.append({"baseline":probe["baseline"],"alpha":alpha})
	before_error/=16;after_error/=16
	var isolated := true;var cell_samples := []
	for probe: Dictionary in cell_probes:
		var color := rendered.get_pixelv(probe["point"])
		# A transparent viewport stores premultiplied RGB.
		var expected := float(probe["opacity"])
		var passed := color.g<.012 and color.b<.012 and absf(color.a-expected)<.012 and absf(color.r-expected)<.012
		isolated=isolated and passed
		cell_samples.append({"rgba":[color.r,color.g,color.b,color.a],"opacity":expected,"passed":passed})
	var coverage_ok := after_error < before_error*.5
	var passed := ink_ok and edges_ok and isolated and coverage_ok
	var report := {"passed":passed,"ink_core":ink_ok,"owner_edges":edges_ok,"cell_isolation_and_opacity":isolated,"coverage_improved":coverage_ok,"baseline_mean_alpha_error":before_error,"current_mean_alpha_error":after_error,"coverage_samples":phases,"cell_samples":cell_samples,"note":"Controlled GPU stripe test; not a perceptual score or FPS benchmark.","shader_sha256":FileAccess.get_sha256("res://assets/shaders/concept_cutout.gdshader")}
	FileAccess.open("res://artifacts/concept47_filter_tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	rendered.save_png("res://artifacts/concept47_filter_probes.png")
	print("CHARACTER47_FILTER ",JSON.stringify(report))
	quit(0 if passed else 1)
