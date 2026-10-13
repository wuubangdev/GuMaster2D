extends SceneTree
## Native-rendered art review. Every figure uses the same ActorView as the game.

const FRAMES := 72
const STEP := 1.0 / 24.0
var actors: Array[ActorView] = []
var snapshots: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func label_at(text: String, at: Vector2, width: float, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)

func _run() -> void:
	assert("--test-mode" in OS.get_cmdline_user_args())
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Character motion review"
	var background := ColorRect.new()
	background.color = Color("111f26")
	background.size = Vector2(1280, 800)
	root.add_child(background)
	label_at("CỔ SƯ  /  TẠO HÌNH & CHUYỂN ĐỘNG", Vector2(30, 30), 1220, 27, Color("e2d4ae"))
	label_at("Model 3D có xương · áo Thanh Ngọc / Xích Vân · kiếm / thương    /    Cùng model trong game và F6", Vector2(30, 74), 1220, 16, Color("9eada7"))
	label_at("TÁM HƯỚNG NHÌN", Vector2(30, 132), 1220, 13, Color("bea16a"))
	var names := ["Bắc", "Đông Bắc", "Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc"]
	for i in range(8):
		var direction := Vector2.UP.rotated(i * TAU / 8)
		var actor := ActorView.new()
		actor.bind({"cell": Vector2.ZERO, "facing": WorldGrid.unproject(direction), "dead": false}, true)
		root.add_child(actor)
		actor.set_process(false)
		actor.character_view.model.blend_transitions = false
		actor.position = Vector2(80 + i * 160, 341)
		actor.state["cell"] = WorldGrid.unproject(actor.position)
		actor.scale = Vector2.ONE * 1.75
		actors.append(actor)
		label_at(names[i], Vector2(i * 160, 363), 160, 15, Color("c5c9b8"))
	label_at("ĐỘNG TÁC & PHẢN HỒI", Vector2(30, 421), 1220, 13, Color("bea16a"))
	var actions := ["", "walk", "cast_moon", "shield", "dash", "cast_frost", "channel", "hit"]
	var titles := ["Đứng nghỉ", "Di chuyển", "Nguyệt quang · 1", "Bạch ngọc · 2", "Bạch hạc · 3", "Băng tằm · 4", "Phong ấn · C", "Nhận đòn"]
	for i in range(8):
		var actor := ActorView.new()
		actor.bind({"appearance":{"body":"female" if i%2 else "male","outfit":"crimson" if i%2 else "jade","hair":"ponytail" if i%2 else "topknot","weapon":"spear" if i==5 else "sword"}, "cell": Vector2.ZERO, "facing": Vector2(1, 0), "dead": false, "shield": 1.0 if i == 3 else 0.0}, true)
		root.add_child(actor)
		actor.set_process(false)
		actor.character_view.model.blend_transitions = false
		actor.position = Vector2(80 + i * 160, 654)
		actor.state["cell"] = WorldGrid.unproject(actor.position)
		actor.scale = Vector2.ONE * 1.75
		actors.append(actor)
		label_at(titles[i], Vector2(i * 160, 680), 160, 14, Color("c5c9b8"))
	label_at("Godot Compatibility • Hình và chuyển động render thật • Bản model 0.8", Vector2(30, 750), 1220, 13, Color("718780"))
	# Still contact sheet uses readable peak poses; the GIF advances real actor timers.
	for i in range(16):
		var actor := actors[i]
		if i < 8:
			continue
		_set_action(actor, actions[i - 8])
		actor.stride = 1.1
		actor.action_left = actor.action_duration * 0.68 if not actor.action.is_empty() else 0.0
		actor.flash = 0.1 if i == 15 else 0.0
		actor._sync_character()
		actor.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/windows_character_sheet.png") == OK)
	DirAccess.make_dir_recursive_absolute("res://artifacts/character_motion")
	for frame in range(FRAMES):
		for i in range(16):
			var actor := actors[i]
			var fixed_position := actor.position
			if i >= 8 and frame % 24 == 0:
				_set_action(actor, actions[i - 8])
			actor._process(STEP)
			actor.position = fixed_position
			if i == 9:
				actor.stride += 0.52
				actor.move_blend = 1.0
			actor._sync_character()
			actor.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/character_motion/frame_%03d.png" % frame) == OK)
		snapshots.append({"frame": frame, "walk_stride": actors[9].stride, "moon_left": actors[10].action_left, "dash_left": actors[12].action_left, "frost_left": actors[13].action_left, "hit_left": actors[15].flash})
	var file := FileAccess.open("res://artifacts/character_samples.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames": FRAMES, "sample_rate": 24, "source": "ActorView; real Godot renderer; controlled poses for review", "samples": snapshots}, "  "))
	file.close()
	print("CHARACTER_CAPTURE ", FRAMES, " frames and 8 directions OK")
	quit()

func _set_action(actor: ActorView, kind: String) -> void:
	actor.action = ""
	actor.action_left = 0.0
	actor.flash = 0.0
	actor.channeling = kind == "channel"
	actor.move_blend = 1.0 if kind == "walk" else 0.0
	if kind in ["cast_moon", "shield", "dash", "cast_frost"]:
		actor.receive({"kind": kind, "to": actor.state["cell"]})
	elif kind == "hit":
		actor.receive({"kind": "player_hit"})
