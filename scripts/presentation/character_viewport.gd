class_name GuCharacterViewport
extends Node2D
## Transparent orthographic 3D -> 2D adapter. Origin is always the character's ground pivot.
## No own animation clock: callers drive sampled clips, including frozen portraits.
var viewport: SubViewport
var model: GuCharacterModel
var sprite: Sprite2D
var camera: Camera3D
var active: bool = true
var render_size: int = 256
var display_height: float = 100.0
var _configured: bool = false

func _init() -> void:
	name = "CharacterViewport"

func _ready() -> void:
	if not _configured:
		configure()
	_fit()

func configure(pixel_size: int = 256, height: float = 100.0) -> void:
	render_size = clampi(pixel_size,128,1024)
	display_height = height
	if _configured:
		viewport.size = Vector2i(render_size,render_size)
		_fit()
		return
	_configured = true
	viewport = SubViewport.new()
	viewport.name = "CharacterRender"
	viewport.size = Vector2i(render_size,render_size)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var stage := Node3D.new()
	stage.name = "Stage"
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_CLEAR_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("aebaca")
	settings.ambient_light_energy = .34
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	stage.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40,-35,0)
	key.light_color = Color("fff0d9")
	key.light_energy = 1.15
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 10.0
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,140,0)
	fill.light_color = Color("a1d4d3")
	fill.light_energy = .36
	stage.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20,165,0)
	rim.light_color = Color("b9c9dd")
	rim.light_energy = .28
	stage.add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.6
	camera.position = Vector3(0,2.95,5.3)
	stage.add_child(camera)
	camera.basis = Basis.looking_at(Vector3(0,.96,0)-camera.position)
	camera.current = true
	model = GuCharacterModel.new()
	stage.add_child(model)
	model.set_motion("idle",0,Vector2.DOWN)
	sprite = Sprite2D.new()
	sprite.name = "CharacterImage"
	sprite.centered = false
	sprite.texture = viewport.get_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	_fit()

func _fit() -> void:
	if camera == null or sprite == null or not camera.is_inside_tree():
		return
	var ratio := display_height / (1.97 * .94 * render_size / camera.size)
	sprite.scale = Vector2.ONE*ratio
	var ground := camera.unproject_position(Vector3.ZERO)
	sprite.position = -ground*ratio

func set_appearance(value: Dictionary) -> void:
	if not _configured:
		configure()
	model.set_appearance(value)
	if not active and is_visible_in_tree():
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func present(action: String, time: float, facing: Vector2, reduced: bool=false) -> void:
	if not _configured:
		configure()
	model.set_motion(action,time,facing,reduced)
	if not active and is_visible_in_tree():
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func set_active(value: bool) -> void:
	active = value
	if viewport != null:
		viewport.render_target_update_mode = (SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_ONCE) if is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func hand_position(side: String="R") -> Vector2:
	return camera.unproject_position(model.transform*model.hand_position(side))*sprite.scale+sprite.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and viewport != null:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active and is_visible_in_tree() else SubViewport.UPDATE_DISABLED
