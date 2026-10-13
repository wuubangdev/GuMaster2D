class_name GuCharacterDoll
extends Control
## Frozen view of the same illustrated character as the world; no gameplay clock.

const CONCEPT_ATLAS_PATH := "res://assets/characters/character-concept-01.png"
const CONCEPT_ART_REGION := Rect2(8, 126, 500, 842)

signal gu_selected(instance_id: String)
var simulation: LocalAuthority
var avatar: Node2D
var concept_art: TextureRect
var appearance_signature: String = ""
var slots: Array[GuItemSlot] = []
var captions: Array[Label] = []
var compact: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = compact
	avatar = GuIllustratedCharacterView.new()
	avatar.configure(192 if compact else 384, 80 if compact else 144)
	add_child(avatar)
	avatar.set_active(false)
	if not compact:
		concept_art = TextureRect.new()
		concept_art.name = "ApprovedConceptPortrait"
		var atlas := AtlasTexture.new()
		atlas.atlas = load(CONCEPT_ATLAS_PATH)
		atlas.region = CONCEPT_ART_REGION
		concept_art.texture = atlas
		concept_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		concept_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		concept_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		concept_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		concept_art.hide()
		add_child(concept_art)
	visibility_changed.connect(_visibility_changed)
	refresh_appearance()
	if not compact:
		for i in range(4):
			var item := simulation.inventory.slot_gu(i)
			var definition := simulation.catalog.slot(i)
			var slot := GuItemSlot.new()
			add_child(slot)
			slot.size = Vector2(74, 72)
			slot.set_entry({"type": "gu", "title": definition["full_name"], "kind": definition["kind"], "color": definition["color"], "slot": i}, false)
			slot.pressed.connect(func(): gu_selected.emit(str(item["instance_id"])))
			slots.append(slot)
			var caption := Label.new()
			caption.text = str(definition["name"])
			caption.add_theme_font_size_override("font_size", 11)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(caption)
			captions.append(caption)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if avatar == null:
		return
	avatar.scale = Vector2.ONE
	avatar.position = Vector2(size.x / 2, size.y + 26 if compact else size.y - 24)
	if concept_art != null:
		var art_height := minf(size.y - 12.0, 270.0)
		var art_size := Vector2(art_height * CONCEPT_ART_REGION.size.x / CONCEPT_ART_REGION.size.y, art_height)
		concept_art.size = art_size
		concept_art.position = Vector2((size.x - art_size.x) * 0.5, (size.y - art_size.y) * 0.5)
	for i in range(slots.size()):
		var x := 8.0 if i % 2 == 0 else size.x - 82.0
		var y := 18.0 if i < 2 else 142.0
		slots[i].position = Vector2(x, y)
		captions[i].position = Vector2(x - 8, y + 78)
		captions[i].size = Vector2(90, 20)
	queue_redraw()

func refresh_appearance() -> void:
	if avatar == null:
		return
	var appearance: Dictionary = GuCharacterAppearance.sanitize(simulation.player.get("appearance", {})) if simulation != null else GuCharacterAppearance.default_data()
	var signature := str(appearance)
	if signature == appearance_signature:
		return
	appearance_signature = signature
	avatar.set_appearance(appearance)
	avatar.present("idle", 0.0, Vector2.DOWN, true)
	avatar.set_active(false)
	if concept_art != null:
		var uses_approved_concept := appearance == GuCharacterAppearance.default_data() and concept_art.texture != null
		concept_art.visible = uses_approved_concept
		avatar.visible = not uses_approved_concept

func _visibility_changed() -> void:
	if avatar != null:
		avatar.set_active(false)
		if is_visible_in_tree():
			refresh_appearance()
			avatar.present("idle", 0.0, Vector2.DOWN, true)

func _draw() -> void:
	var bounds := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	if not compact:
		GuPixelUI.paper_panel(self, bounds, 7)
	else:
		GuPixelUI.paper_grain(self, bounds, 7)
		var center := Vector2(size.x / 2, size.y - 24)
		var shadow := PackedVector2Array()
		for index in range(64):
			var angle := index * TAU / 64.0
			var wobble := 1.0 + 0.045 * sin(index * 5.0)
			shadow.append(center + Vector2(cos(angle) * 39, sin(angle) * 9) * wobble)
		draw_colored_polygon(shadow, Color(GuPixelUI.INK, 0.2))
		var medallion := Vector2(size.x / 2, size.y * 0.47)
		var radius := minf(size.x, size.y) * 0.39
		draw_circle(medallion, radius + 3.0, Color(GuPixelUI.INK, 0.82), true, -1, true)
		draw_circle(medallion, radius + 1.2, GuPixelUI.GOLD, true, -1, true)
		draw_circle(medallion, radius - 1.0, Color(GuPixelUI.PAPER_LIGHT, 0.94), true, -1, true)
		draw_arc(medallion, radius + 1.7, 0.18, TAU - 0.12, 32, Color(GuPixelUI.PAPER_LIGHT, 0.62), 0.8, true)
