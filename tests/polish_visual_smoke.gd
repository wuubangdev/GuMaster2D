extends SceneTree
## Native evidence of accepted skills at deliberate presentation beats.
## Test fixtures position actors; numeric InputEvents alone accept each cast.

var game: GameManager
var records: Array[Dictionary] = []
var accepted_slots: Array[int] = []

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Presentation review requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	root.push_input(event, true)

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)

func _capture(name: String, skill: int = 0, cast_age: float = 0.0) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var framebuffer := root.get_texture().get_image()
	assert(framebuffer.save_png("res://artifacts/%s.png" % name) == OK)
	var effects: Array[Dictionary] = []
	for effect in game.world_view.effects.effects:
		effects.append({"kind": effect["kind"], "age": effect["age"], "life": effect["life"], "origin_offset": str(effect.get("origin_offset", Vector2.ZERO))})
	var hero := game.world_view.player_view.character_view
	records.append({"file": name + ".png", "native_size": [framebuffer.get_width(), framebuffer.get_height()], "skill": skill, "cast_age": cast_age, "sprite_action": hero.current_action, "sprite_frame": hero.current_frame, "player_cell": str(game.simulation.player["cell"]), "target_cell": str(game.simulation.mobs["wolf_0"]["cell"]), "target_rendered_position": str(game.world_view.actors["wolf_0"].position), "target_hp": game.simulation.mobs["wolf_0"]["hp"], "target_authority_dead": game.simulation.mobs["wolf_0"]["dead"], "target_presentation_dead": game.world_view.actors["wolf_0"].presentation_dead, "mana": game.simulation.player["mana"], "shield": game.simulation.player["shield"], "effects": effects, "source": "Actual native Godot window framebuffer"})
	print("POLISH_CAPTURE ", name, " skill=", skill, " age=", cast_age)

func _fixture(target_hp: float = 140.0) -> void:
	var sim := game.simulation
	sim.player.merge({"cell": Vector2(15, 20), "facing": Vector2.RIGHT, "path": [], "running": false, "dead": false, "hp": 200.0, "mana": 100.0, "shield": 0.0, "shield_left": 0.0}, true)
	sim.movement_direction = Vector2.ZERO
	for slot in range(sim.cooldowns.size()):
		sim.cooldowns[slot] = 0.0
	for mob in sim.mobs.values():
		mob["dead"] = true
		mob["respawn_left"] = 9999.0
	sim.mobs["wolf_0"].merge({"dead": false, "cell": Vector2(18, 20), "spawn": Vector2(18, 20), "facing": Vector2.LEFT, "slow_left": 0.0, "hp": target_hp, "state": "idle"}, true)
	sim.drain_events()
	game.world_view.effects.effects.clear()
	var player := game.world_view.player_view
	player.position = WorldGrid.project(sim.player["cell"])
	player.spawn_left = 0.0
	player.flash = 0.0
	player.action_left = 0.0
	player.move_blend = 0.0
	player._sync_character()
	for id in game.world_view.actors:
		var actor: ActorView = game.world_view.actors[id]
		actor.position = WorldGrid.project(sim.mobs[id]["cell"])
		actor.was_dead = bool(sim.mobs[id]["dead"])
		actor.presentation_dead = actor.was_dead
		actor.pending_hit_left = 0.0
		actor.death_age = 1.0
		actor.flash = 0.0
		actor.action_left = 0.0
		actor.move_blend = 0.0
		actor._process(0.0)
	game.world_view.select_target("wolf_0")
	game.world_view._camera_follow = player.position + Vector2(0, -24)
	game.world_view._process(0.0)
	game.world_view.camera.force_update_scroll()
	game.hud.toast_left = 0.0
	game.hud.update_hud(0.0)
	game.update_targeting()

func _step(seconds: float) -> void:
	var left := seconds
	while left > 0.000001:
		var delta := minf(left, 1.0 / 60.0)
		game.simulation.step(delta)
		game.flush_events()
		game.world_view.player_view._process(delta)
		for actor in game.world_view.actors.values():
			actor._process(delta)
		game.world_view.effects._process(delta)
		game.world_view.targeting._process(delta)
		game.world_view._process(delta)
		game.hud.update_hud(delta)
		for button in game.hud.skill_buttons:
			button._process(delta)
		left -= delta
	game.world_view.camera.force_update_scroll()
	game.update_targeting()

func _accept(slot: int) -> void:
	if slot == 2:
		var aim := InputEventMouseMotion.new()
		aim.position = game.world_view.cell_to_screen(Vector2(17, 19))
		root.push_input(aim, true)
		assert(game.pointer_in_world, "Dash aim belongs to the native playfield")
	_key(GameBindings.SKILL_KEYS[slot])
	assert(game.simulation.cooldowns[slot] > 0.0, "Numeric skill must be accepted before recording its effect")
	accepted_slots.append(slot + 1)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Presentation polish review"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	for button in game.hud.skill_buttons:
		button.set_process(false)
	_fixture()
	_accept(0)
	_step(0.20)
	await _capture("polish12_skill_moon_travel", 1, 0.20)
	_step(0.12)
	await _capture("polish12_skill_moon_impact", 1, 0.32)
	_fixture()
	_accept(1)
	_step(0.20)
	await _capture("polish12_skill_shield", 2, 0.20)
	_fixture()
	_accept(2)
	_step(0.08)
	await _capture("polish12_skill_dash", 3, 0.08)
	_fixture()
	_accept(3)
	_step(0.34)
	await _capture("polish12_skill_frost", 4, 0.34)
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await process_frame
	await process_frame
	game.world_view.camera.force_update_scroll()
	await _capture("polish12_skill_frost_960", 4, 0.34)
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	_fixture(20.0)
	_accept(0)
	_step(0.20)
	assert(game.simulation.mobs["wolf_0"]["dead"] and not game.world_view.actors["wolf_0"].presentation_dead, "A lethal cast commits defeat but keeps the target visible before contact")
	await _capture("polish12_lethal_moon_travel", 1, 0.20)
	_step(0.12)
	assert(game.world_view.actors["wolf_0"].presentation_dead, "The target begins its death animation after actual projectile contact")
	await _capture("polish12_lethal_moon_contact", 1, 0.32)
	_fixture()
	game.world_view.set_reduced_motion(true)
	_accept(0)
	_step(0.20)
	await _capture("polish12_skill_reduced_motion", 1, 0.20)
	game.world_view.set_reduced_motion(false)
	_fixture()
	_key(KEY_TAB)
	await create_timer(0.24).timeout
	assert(game.hud.bag_open, "The real bag hotkey opens the native inventory")
	await _capture("polish12_inventory_gu_1280")
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await process_frame
	await process_frame
	var browser := game.hud.inventory_browser
	_click(browser.filter_buttons[2].get_global_rect().get_center())
	await process_frame
	assert(browser.filter_kind == "material", "The visible material filter must accept native input")
	await _capture("polish12_inventory_material_960")
	var scroll := browser.get_parent() as ScrollContainer
	assert(scroll != null)
	scroll.scroll_vertical = 100000
	await process_frame
	await _capture("polish12_inventory_detail_960")
	_key(KEY_ESCAPE)
	await create_timer(0.24).timeout
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	await _contact_sheet()
	var output := FileAccess.open("res://artifacts/polish12_visual_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info()["string"], "screenshots": records.size(), "source": "Native Godot 2D framebuffer. Real numeric InputEvents accept casts; deterministic authority/presentation clocks choose beats. Contact sheet uses exact live character renderer.", "accepted_slots": accepted_slots, "samples": records}, "  "))
	output.close()
	print("POLISH_VISUAL_SMOKE_COMPLETE ", records.size(), " screenshots; four numeric skills accepted")
	game.queue_free()
	await process_frame
	quit()

func _label(parent: Node, text: String, position: Vector2, width: float, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size.x = width
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _contact_sheet() -> void:
	var sheet := CanvasLayer.new()
	sheet.layer = 100
	root.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color("192c2b")
	background.size = Vector2(1280, 800)
	sheet.add_child(background)
	_label(sheet, "DIỆN MẠO / NHỊP TẤN CÔNG", Vector2(20, 16), 1240, 24, Color("f3e8c1"))
	_label(sheet, "Sprite thật ở 2× nguyên • Tám hướng • Ba vũ khí, đủ tám khung tấn công", Vector2(20, 52), 1240, 15, Color("becdb0"))
	var names := ["Bắc", "Đông Bắc", "Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc"]
	for direction in range(8):
		var view := GuPixelCharacterView.new()
		sheet.add_child(view)
		view.configure(256, 96)
		view.position = Vector2(80 + direction * 160, 220)
		view.present("idle", 0.0, Vector2.UP.rotated(direction * TAU / 8.0))
		view.set_active(false)
		_label(sheet, names[direction], Vector2(direction * 160, 234), 160, 14, Color("efe5c7"))
	var weapons := ["sword", "spear", "unarmed"]
	var labels := ["TRƯỜNG KIẾM", "TRƯỜNG THƯƠNG", "QUYỀN PHÁP"]
	for row in range(3):
		_label(sheet, labels[row], Vector2(20, 272 + row * 160), 1240, 13, Color("dec992"))
		for frame in range(8):
			var view := GuPixelCharacterView.new()
			sheet.add_child(view)
			view.configure(256, 96)
			view.position = Vector2(80 + frame * 160, 396 + row * 160)
			view.set_appearance({"body": "female" if row == 1 else "male", "outfit": ["jade", "ivory", "crimson"][row], "hair": "ponytail" if row == 1 else "topknot", "weapon": weapons[row]})
			view.present("attack", GuCharacterAnimations.duration("attack", weapons[row]) * (float(frame) + 0.1) / 8.0, Vector2.RIGHT)
			view.set_active(false)
			assert(view.current_frame == frame, "The weapon timeline displays its actual requested atlas frame")
			_label(sheet, "Khung %d" % (frame + 1), Vector2(frame * 160, 411 + row * 160), 160, 13, Color("efe5c7"))
	await _capture("polish12_character_weapon_frames")
	sheet.queue_free()
	await process_frame
