extends "res://tests/polish_visual_smoke.gd"
## Actual native framebuffer evidence for the illustrated 2D presentation.
## Casts reuse the real numeric InputEvents and authoritative fixture above;
## review sheets instantiate the same renderer used by world, HUD, F3 and F6.

class FeedbackCanvas extends Node2D:
	func _draw() -> void:
		for i in range(GuVectorEffectsArt.KINDS.size()):
			for sample in range(3):
				var at := Vector2((i%4)*320+65+sample*95,165+(i/4)*156)
				draw_set_transform(at,0,Vector2.ONE*1.5)
				GuVectorEffectsArt.draw(self,GuVectorEffectsArt.KINDS[i],Vector2.ZERO,[.18,.52,.85][sample],Vector2.RIGHT)

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		printerr("Illustrated review requires a native renderer and -- --test-mode.")
		quit(2)
		return
	_run.call_deferred()

func _capture(name: String, skill: int = 0, cast_age: float = 0.0) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var framebuffer := root.get_texture().get_image()
	assert(framebuffer.save_png("res://artifacts/%s.png" % name) == OK)
	var hero: GuIllustratedCharacterView = game.world_view.player_view.character_view
	var effects: Array[Dictionary] = []
	for effect in game.world_view.effects.effects:
		effects.append({"kind": effect["kind"], "age": effect["age"], "life": effect["life"], "origin_offset": str(effect.get("origin_offset", Vector2.ZERO)), "launch_offset": str(effect.get("launch_offset", Vector2.ZERO)), "has_exact_character_pose": effect.has("character_pose")})
	records.append({"file": name + ".png", "native_size": [framebuffer.get_width(), framebuffer.get_height()], "backend": DisplayServer.get_name(), "skill": skill, "cast_age": cast_age, "character_action": hero.current_action, "character_direction": hero.current_direction, "character_pose": str(hero.capture_pose()), "player_cell": str(game.simulation.player["cell"]), "target_cell": str(game.simulation.mobs["wolf_0"]["cell"]), "target_hp": game.simulation.mobs["wolf_0"]["hp"], "target_authority_dead": game.simulation.mobs["wolf_0"]["dead"], "target_presentation_dead": game.world_view.actors["wolf_0"].presentation_dead, "mana": game.simulation.player["mana"], "shield": game.simulation.player["shield"], "effects": effects, "source": "Actual native Godot window framebuffer; live illustrated renderer"})
	print("VECTOR_CAPTURE ", name, " skill=", skill, " age=", cast_age)

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	root.title = "GuMaster2D — Illustrated animation review"
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
	assert(game.world_view.player_view.character_view is GuIllustratedCharacterView, "Review records the actual illustrated world renderer")
	_fixture()
	await _capture("ink19_gameplay_1280")
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await process_frame
	game.world_view.camera.force_update_scroll()
	await _capture("ink19_gameplay_960")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	_key(KEY_F3)
	await process_frame
	assert(game.hud.character_doll.avatar is GuIllustratedCharacterView)
	await _capture("ink19_character_sheet")
	_key(KEY_ESCAPE)
	_key(KEY_F6)
	await process_frame
	var studio: GuCharacterStudio = game.hud.character_studio
	studio.set_process(false)
	assert(studio.character_view is GuIllustratedCharacterView)
	studio._select_direction(4)
	studio._select_action(0)
	studio.playhead = 0.0
	studio._present()
	await _capture("ink19_studio_male")
	studio.appearance = {"body": "male", "outfit": "jade", "weapon": "sword", "hair": "topknot", "boots": "leather", "hat": "bamboo"}
	studio._sync_controls()
	await _capture("ink20_studio_male_bamboo_hat_leather_boots")
	studio.appearance = {"body": "female", "outfit": "ivory", "weapon": "spear", "hair": "ponytail", "boots": "cloth", "hat": "sect"}
	studio._sync_controls()
	studio._select_action(3)
	studio._select_direction(3)
	studio.playhead = GuCharacterAnimations.duration("attack", "spear") * 0.44
	studio._present()
	await _capture("ink20_studio_female_sect_hat_spear")
	root.content_scale_size = Vector2i(960, 640)
	root.size = Vector2i(960, 640)
	await _capture("ink19_studio_960")
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	await process_frame
	_key(KEY_ESCAPE)
	await _directions_sheet()
	await _weapons_sheet()
	await _actions_sheet()
	await _feedback_sheet()
	_fixture()
	_accept(0)
	_step(0.20)
	await _capture("ink19_skill_moon_travel", 1, 0.20)
	_step(0.12)
	await _capture("ink19_skill_moon_impact", 1, 0.32)
	_fixture()
	_accept(1)
	_step(0.20)
	await _capture("ink19_skill_shield", 2, 0.20)
	_fixture()
	_accept(2)
	_step(0.08)
	await _capture("ink19_skill_dash", 3, 0.08)
	_fixture()
	_accept(3)
	_step(0.34)
	await _capture("ink19_skill_frost", 4, 0.34)
	_fixture(20.0)
	_accept(0)
	_step(0.20)
	assert(game.simulation.mobs["wolf_0"]["dead"] and not game.world_view.actors["wolf_0"].presentation_dead)
	await _capture("ink19_lethal_moon_travel", 1, 0.20)
	_step(0.12)
	assert(game.world_view.actors["wolf_0"].presentation_dead)
	await _capture("ink19_lethal_moon_contact", 1, 0.32)
	_fixture()
	game.world_view.set_reduced_motion(true)
	_accept(0)
	_step(0.20)
	await _capture("ink19_skill_reduced_motion", 1, 0.20)
	game.world_view.set_reduced_motion(false)
	var output := FileAccess.open("res://artifacts/ink19_visual_capture.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info()["string"], "screenshots": records.size(), "accepted_slots": accepted_slots, "source": "Native Godot framebuffer. Real numeric InputEvents accept casts; deterministic authority and presentation clocks choose beats. Review sheets contain the exact live illustrated renderer.", "samples": records}, "  "))
	output.close()
	print("VECTOR_VISUAL_SMOKE_COMPLETE ", records.size(), " screenshots; four numeric skills accepted; live illustrated renderer")
	game.queue_free()
	await process_frame
	quit()

func _sheet(title: String, subtitle: String) -> CanvasLayer:
	var sheet := CanvasLayer.new()
	sheet.layer = 100
	root.add_child(sheet)
	var background := ColorRect.new()
	background.color = Color("b8aa84")
	background.size = Vector2(1280, 800)
	sheet.add_child(background)
	_label(sheet, title, Vector2(20, 18), 1240, 26, Color("302b25"))
	_label(sheet, subtitle, Vector2(20, 58), 1240, 15, Color("4e4b3a"))
	return sheet

func _sheet_view(sheet: CanvasLayer, look: Dictionary, height: float, at: Vector2, action: String, phase: float, facing: Vector2) -> GuIllustratedCharacterView:
	var view := GuIllustratedCharacterView.new()
	sheet.add_child(view)
	view.configure(256, height)
	view.position = at
	view.set_appearance(look)
	view.present(action, GuCharacterAnimations.duration(action, str(look["weapon"])) * phase, facing)
	view.set_active(false)
	return view

func _directions_sheet() -> void:
	var sheet := _sheet("CỔ SƯ / TÁM HƯỚNG", "Đường nét cong · Mắt, tóc và lớp trang phục đổi theo góc nhìn · Cùng renderer trong bản đồ và F6")
	var names := ["Bắc", "Đông Bắc", "Đông", "Đông Nam", "Nam", "Tây Nam", "Tây", "Tây Bắc"]
	for row in range(2):
		var look := {"body": "male" if row == 0 else "female", "outfit": "jade" if row == 0 else "ivory", "weapon": "sword" if row == 0 else "spear", "hair": "topknot" if row == 0 else "ponytail"}
		for direction in range(8):
			_sheet_view(sheet, look, 96, Vector2(80 + direction * 160, 325 + row * 335), "idle", 0.0, Vector2.UP.rotated(direction * TAU / 8.0))
			_label(sheet, names[direction], Vector2(direction * 160, 343 + row * 335), 160, 14, Color("302b25"))
	await _capture("ink19_character_directions")
	var first_pixels := root.get_texture().get_image().get_data()
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var next_pixels := root.get_texture().get_image().get_data()
	assert(first_pixels==next_pixels,"Paused ink and paper must not shimmer with the frame clock")
	var stability := FileAccess.open("res://artifacts/ink19_style_stability.json",FileAccess.WRITE)
	stability.store_string(JSON.stringify({"revision":"ink19","renderer":"native","static_frames":12,"framebuffer_pixels_equal":first_pixels==next_pixels,"appearances":2,"facings":8},"  "))
	stability.close()
	print("INK_STYLE_STABILITY_OK native paused framebuffer identical across 12 frames")
	sheet.queue_free()
	await process_frame

func _feedback_sheet() -> void:
	var sheet := _sheet("MỰC / HIỆU ỨNG CỔ", "13 hiệu ứng · Pha 18% / 52% / 85% · Renderer dùng trực tiếp trong game")
	sheet.add_child(FeedbackCanvas.new())
	for i in range(GuVectorEffectsArt.KINDS.size()):
		_label(sheet,GuVectorEffectsArt.KINDS[i],Vector2((i%4)*320,206+(i/4)*156),320,14,Color("302b25"))
	await _capture("ink19_feedback_sheet")
	sheet.queue_free()
	await process_frame

func _weapons_sheet() -> void:
	var sheet := _sheet("NHỊP TẤN CÔNG / BA VŨ KHÍ", "Chuẩn bị → ra đòn → tiếp xúc → thu đòn · Các pha mẫu của renderer thực trong game")
	var phases := [0.0, 0.12, 0.28, 0.44, 0.66, 0.95]
	var names := ["Kiếm", "Thương", "Tay không"]
	for row in range(3):
		var weapon: String = ["sword", "spear", "unarmed"][row]
		var look := {"body": "female" if row == 1 else "male", "outfit": ["jade", "ivory", "crimson"][row], "weapon": weapon, "hair": "ponytail" if row == 1 else "topknot"}
		for column in range(phases.size()):
			_sheet_view(sheet, look, 96, Vector2(100 + column * 200, 285 + row * 215), "attack", phases[column], Vector2.RIGHT)
			_label(sheet, "%s · %.0f%%" % [names[row], phases[column] * 100], Vector2(column * 200, 301 + row * 215), 200, 14, Color("302b25"))
	await _capture("ink19_character_weapon_phases")
	sheet.queue_free()
	await process_frame

func _actions_sheet() -> void:
	var sheet := _sheet("CHUYỂN ĐỘNG / MƯỜI MỘT TRẠNG THÁI", "Đứng, đi, chạy, tấn công, thủ, thi triển, phong ấn, lướt, trúng đòn, trọng thương, hồi sinh")
	var actions := GuCharacterAnimations.clip_names()
	for index in range(actions.size()):
		var column := index % 6
		var row := index / 6
		var look := {"body": "female" if index % 2 else "male", "outfit": ["jade", "crimson", "ivory"][index % 3], "weapon": ["sword", "spear", "unarmed"][index % 3], "hair": "ponytail" if index % 2 else "topknot"}
		_sheet_view(sheet, look, 144, Vector2(140 + column * 200, 340 + row * 340), actions[index], 0.92 if actions[index] == "death" else 0.40, Vector2(1, 1))
		_label(sheet, GuCharacterAnimations.LABELS[actions[index]], Vector2(40 + column * 200, 358 + row * 340), 200, 14, Color("302b25"))
	await _capture("ink19_character_actions")
	sheet.queue_free()
	await process_frame
