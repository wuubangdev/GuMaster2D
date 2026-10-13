extends SceneTree
## One world unit per pixel for both the live character and every beast.
const DIRECTIONS := ["Nam", "Tây nam", "Tây", "Tây bắc", "Bắc", "Đông bắc", "Đông", "Đông nam"]
var stage: Node2D
var tiles: Array[BeastTile] = []
var captures: Array[String] = []

class BeastTile extends Node2D:
	var species := "wolf"
	var heading := Vector2.DOWN
	var walking := false
	var progress := 0.0
	func _draw() -> void:
		var spec := Bestiary.species(species)
		var mob := {"species": species, "facing": heading, "state": "idle", "hp": spec["hp"], "max_hp": spec["hp"], "attack_age": 100.0, "presentation_hide_label": true}
		GuPixelEffectsArt.ground_shadow(self, Vector2(1, 2), 18.0 * BeastMotion.body_scale(mob), Color(.02, .05, .05, .36))
		BeastArt.draw(self, mob, progress, progress * TAU, 1.0 if walking else 0.0, false, 0.0, false)

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	root.size = Vector2i(1920, 1530)
	root.content_scale_size = root.size
	root.position = Vector2i(-1800, -1100)
	_run.call_deferred()

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/production49_beast_%s.png" % name
	var error := root.get_texture().get_image().save_png(path)
	assert(error == OK, "Native beast review capture failed")
	captures.append(path)

func _run() -> void:
	root.size = Vector2i(1920, 1530)
	root.content_scale_size = root.size
	stage = Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(root.size)
	background.color = Color("b5b694")
	stage.add_child(background)
	var heading := Label.new()
	heading.text = "TỶ LỆ TRONG GAME  •  Nhân vật 48 đơn vị  /  Quái cùng tỷ lệ"
	heading.position = Vector2(24, 18)
	heading.add_theme_font_override("font", GuPixelUI.HAND_FONT)
	heading.add_theme_font_size_override("font_size", 24)
	stage.add_child(heading)
	for row in range(Bestiary.all().size()):
		var species: String = Bestiary.all().keys()[row]
		for direction in range(8):
			var tile := Control.new()
			tile.position = Vector2(direction * 240, 66 + row * 180)
			tile.size = Vector2(240, 178)
			tile.clip_contents = true
			stage.add_child(tile)
			var fill := ColorRect.new()
			fill.color = Color("d1cba4") if (row + direction) % 2 == 0 else Color("c6c49d")
			fill.size = tile.size - Vector2(2, 2)
			tile.add_child(fill)
			var face := Vector2.DOWN.rotated(direction * PI / 4)
			var player := GuIllustratedCharacterView.new()
			player.position = Vector2(58, 117)
			tile.add_child(player)
			player.configure(256, 48)
			player.set_appearance(GuCharacterAppearance.default_data())
			player.present("idle", 0, face)
			var beast := BeastTile.new()
			beast.species = species
			beast.heading = face
			beast.position = Vector2(158, 117)
			tile.add_child(beast)
			tiles.append(beast)
			var name := Label.new()
			name.text = "%s · %s" % [Bestiary.species(species)["name"], DIRECTIONS[direction]]
			name.position = Vector2(8, 151)
			name.add_theme_font_override("font", GuPixelUI.HAND_FONT)
			name.add_theme_font_size_override("font_size", 12)
			tile.add_child(name)
	await capture("idle")
	for sample in [0.2, 0.45, 0.7]:
		for beast in tiles:
			beast.walking = true
			beast.progress = sample
			beast.queue_redraw()
			var player: GuIllustratedCharacterView = beast.get_parent().get_child(1)
			player.present("walk", sample * GuCharacterAnimations.duration("walk"), beast.heading)
		await capture("walk_%02d" % roundi(sample * 100))
	FileAccess.open("res://artifacts/production49_beast_review.json", FileAccess.WRITE).store_string(JSON.stringify({"captures": captures, "world_scale": 1.0, "player_height": 48, "species": Bestiary.all().size(), "directions": 8}, "  "))
	print("PRODUCTION49_BEAST_REVIEW ", captures.size(), " native sheets")
	quit()
