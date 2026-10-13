extends RefCounted
## Illustrated presentation acceptance verifies the actual SVG import, exact
## continuous pose and live view ownership independently of the retained atlas.

const ACTIONS := ["idle", "walk", "run", "attack", "defend", "cast", "channel", "dash", "hit", "death", "respawn"]
const LOOPING := ["idle", "walk", "run", "defend", "channel"]
const FX_KINDS := ["moon_blade", "moon_impact", "ice_shard", "ice_impact", "shield_cast", "shield_loop", "dash_wake", "dash_feather", "cast_spark", "hit_spark", "dust", "seal", "reward"]

static func run(tree: SceneTree, check: Callable) -> bool:
	if not _assets(check):
		return false
	await _pose_contract(tree, check)
	await _live_views(tree, check)
	return true

static func _assets(check: Callable) -> bool:
	var manifest := GuIllustratedCharacterArt.manifest()
	var parts: Dictionary = manifest.get("parts", {})
	check.call(not parts.is_empty(), "The illustrated character library supplies a packaged SVG part manifest")
	if parts.is_empty():
		return false
	var imported := true
	var resolution := true
	var curved_parts := 0
	var antialiased_parts := 0
	var unique_art := {}
	var path_expression := RegEx.new()
	path_expression.compile("\\bd=[\"']([^\"']+)[\"']")
	var curve_expression := RegEx.new()
	curve_expression.compile("[CcQqSsTtAa]")
	for key: String in parts:
		var part: Dictionary = parts[key]
		var path := str(part.get("path", ""))
		var texture := GuIllustratedCharacterArt.part_texture(key)
		imported = imported and path.ends_with(".svg") and FileAccess.file_exists(path) and texture != null
		if texture == null or not FileAccess.file_exists(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		var has_curve := false
		for match_value: RegExMatch in path_expression.search_all(source):
			has_curve = has_curve or curve_expression.search(match_value.get_string(1)) != null
		curved_parts += int(has_curve)
		unique_art[source] = true
		var bounds: Array = part.get("rect", [])
		resolution = resolution and bounds.size() == 4
		if bounds.size() == 4:
			resolution = resolution and texture.get_size() == Vector2(float(bounds[2]), float(bounds[3])) * 8.0
		var image := texture.get_image()
		imported = imported and image != null
		if image == null:
			continue
		image.convert(Image.FORMAT_RGBA8)
		var pixels := image.get_data()
		for index in range(3, pixels.size(), 4):
			if pixels[index] > 0 and pixels[index] < 255:
				antialiased_parts += 1
				break
	check.call(imported, "Every illustrated layer loads from its actual packaged SVG source and exposes imported image data")
	check.call(resolution, "Imported SVG layers retain eight texels per design unit for enlarged portraits and the character workshop")
	check.call(curved_parts >= 12 and unique_art.size() >= 24, "The source library contains distinct curved artwork for the character rather than enlarged pixel cells")
	check.call(antialiased_parts >= 12, "Actual imported SVG edges contain intermediate alpha coverage for smooth curved silhouettes")
	check.call(FX_KINDS.all(func(kind: String) -> bool: return kind in GuVectorEffectsArt.KINDS), "The live vector effect library covers every projectile, impact, shield, feather, capture and reward cue")
	return imported

static func _finite(value: Variant) -> bool:
	if value is Vector2:
		return value.is_finite() and absf(value.x) < 160.0 and value.y > -180.0 and value.y < 100.0
	if value is float:
		return is_finite(value)
	if value is Array:
		for item in value:
			if not _finite(item):
				return false
	if value is Dictionary:
		for item in value.values():
			if not _finite(item):
				return false
	return true

static func _geometry(snapshot: Dictionary) -> String:
	# Geometry excludes phase/time/appearance metadata: changing a timestamp or
	# cosmetic label alone cannot satisfy continuous-motion acceptance.
	return str(snapshot.get("pose", {}))

static func _pose_contract(tree: SceneTree, check: Callable) -> void:
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256, 48)
	await tree.process_frame
	check.call(view.illustration != null and view.illustration.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR and view.sprite != null and not view.sprite.visible, "The visible character canvas uses linear-filtered illustrated layers while the compatibility pixel sprite stays hidden")
	var finite := true
	var anchors := true
	var weapon_bounds := true
	var limbs := true
	var clips := true
	var pivots := true
	var identities := {}
	var directions := {}
	var original_position := Vector2(17, 9)
	view.position = original_position
	for body in GuCharacterAppearance.catalog("body"):
		for outfit in GuCharacterAppearance.catalog("outfit"):
			for weapon in GuCharacterAppearance.catalog("weapon"):
				for hair in GuCharacterAppearance.catalog("hair"):
					var look := {"body": body["id"], "outfit": outfit["id"], "weapon": weapon["id"], "hair": hair["id"]}
					view.set_appearance(look)
					identities[GuPixelCharacterView.appearance_key(view.appearance)] = true
					for direction in range(8):
						for action: String in ACTIONS:
							for sample in range(13):
								view.present(action, GuCharacterAnimations.duration(action, str(weapon["id"])) * sample / 12.0, Vector2.DOWN.rotated(direction * TAU / 8.0))
								var snapshot := view.capture_pose()
								var pose: Dictionary = snapshot.get("pose", {})
								finite = finite and not pose.is_empty() and _finite(pose)
								clips = clips and view.current_action == action
								pivots = pivots and view.position == original_position
								directions[view.current_direction] = true
								for side in ["L", "R"]:
									var arm: Array = pose.get("arm_" + side, [])
									anchors = anchors and arm.size() == 3
									if arm.size() != 3:
										continue
									var source_hand: Vector2 = snapshot["source_pose"]["grip_"+side]
									anchors = anchors and view.hand_position(side).is_equal_approx(source_hand*float(snapshot.get("scale",1.0))) and view.visual_rect().grow(.001).has_point(view.hand_position(side))
									limbs = limbs and Vector2(arm[0]).distance_to(arm[1]) > .1 and Vector2(arm[1]).distance_to(arm[2]) > .1
								if str(weapon["id"]) != "unarmed" and pose.get("arm_R", []).size() == 3:
									# These are the actual sharp endpoints in the authored SVGs,
									# rotated around the visible grip, not a padded atlas cell.
									var weapon_tip := GuConceptCharacterArt.weapon_tip(snapshot)
									weapon_bounds = weapon_bounds and weapon_tip.is_finite() and view.visual_rect().grow(.001).has_point(weapon_tip)
	check.call(identities.size() == 36 and directions.size() == 8 and clips, "Every selectable appearance supports all eight facings and eleven actual illustrated action states")
	check.call(finite and limbs, "All appearance, facing and action timelines retain finite bounded joints and connected nonzero arm segments")
	check.call(anchors, "Every live spell hand exactly follows its continuous drawn arm endpoint and stays inside the displayed visual envelope")
	check.call(weapon_bounds, "The actual rotated sword and spear tips stay inside the visual envelope for every appearance, facing and action phase")
	check.call(pivots, "Animation sampling never shifts the character's gameplay ground pivot")
	view.set_appearance(GuCharacterAppearance.default_data())
	var smooth := true
	for action in ["idle", "walk", "run", "attack", "cast"]:
		var duration := GuCharacterAnimations.duration(action)
		view.present(action, duration * .035, Vector2.RIGHT)
		var first := _geometry(view.capture_pose())
		var frame := view.current_frame
		view.present(action, duration * .085, Vector2.RIGHT)
		smooth = smooth and frame == view.current_frame and first != _geometry(view.capture_pose())
	check.call(smooth, "Idle, walk, run, attack and cast geometry changes continuously inside one old eight-frame atlas bucket")
	var reduced_stable := true
	for action: String in LOOPING:
		var duration := GuCharacterAnimations.duration(action)
		view.present(action, duration * .02, Vector2(1, -1), true)
		var first := _geometry(view.capture_pose())
		view.present(action, duration * .73, Vector2(1, -1), true)
		reduced_stable = reduced_stable and first == _geometry(view.capture_pose())
	check.call(reduced_stable, "Reduced motion holds breathing, locomotion, guard and channel geometry still while preserving the current facing")
	var weapon_signatures := {}
	for weapon in GuCharacterAppearance.catalog("weapon"):
		var look := GuCharacterAppearance.default_data()
		look["weapon"] = weapon["id"]
		view.set_appearance(look)
		var signature := ""
		for phase in [.18, .44, .78]:
			view.present("attack", GuCharacterAnimations.duration("attack", str(weapon["id"])) * phase, Vector2.RIGHT)
			signature += _geometry(view.capture_pose())
		weapon_signatures[signature] = true
	check.call(weapon_signatures.size() == 3, "Sword, spear and unarmed strikes use different real arm and weapon geometry through anticipation, contact and recovery")
	view.set_appearance(GuCharacterAppearance.default_data())
	view.configure(384, 144)
	view.present("cast", .31, Vector2.LEFT)
	var portrait := view.capture_pose()
	var right_arm: Array = portrait["pose"]["arm_R"]
	check.call(view.hand_position("R").is_equal_approx(Vector2(portrait["source_pose"]["grip_R"])*float(portrait["scale"])), "Portrait enlargement scales the actual source-art hand anchor with its illustrated geometry")
	var before := _geometry(view.capture_pose())
	var detached := view.capture_pose()
	detached["appearance"]["body"] = "female"
	detached["pose"]["arm_R"][2] = Vector2(999, 999)
	check.call(_geometry(view.capture_pose()) == before and view.appearance["body"] == "male", "Captured afterimage snapshots are independent deep copies of the live cosmetic and pose data")
	view.queue_free()
	await tree.process_frame

static func _key(tree: SceneTree, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	tree.root.push_input(event, true)
	event = event.duplicate() as InputEventKey
	event.pressed = false
	tree.root.push_input(event, true)

static func _live_views(tree: SceneTree, check: Callable) -> void:
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	await tree.process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro = false
	check.call(game.world_view.player_view.character_view is GuIllustratedCharacterView and game.hud.portrait_doll.avatar is GuIllustratedCharacterView and game.hud.character_doll.avatar is GuIllustratedCharacterView, "Gameplay, HUD portrait and F3 sheet display the same actual illustrated character renderer")
	_key(tree, KEY_F6)
	await tree.process_frame
	var studio := game.hud.character_studio
	check.call(studio.opened and studio.character_view is GuIllustratedCharacterView, "The real F6 hotkey opens a workshop containing the same illustrated renderer as gameplay")
	await _stage_geometry(tree, studio, check)
	_key(tree, KEY_ESCAPE)
	await tree.process_frame
	var profile := game.simulation.to_profile().duplicate(true)
	var inventory := game.simulation.inventory.to_data().duplicate(true)
	var hero: GuIllustratedCharacterView = game.world_view.player_view.character_view
	hero.present("attack", .38, Vector2.UP)
	hero.present("cast", .23, Vector2.LEFT)
	game.world_view.effects._process(.10)
	check.call(game.simulation.to_profile() == profile and game.simulation.inventory.to_data() == inventory, "Sampling illustrated animation and vector effects cannot alter authoritative position, resources, equipment, inventory or saves")
	var origin: Vector2 = game.simulation.player["cell"]
	var event := {"kind": "dash", "at": origin, "to": origin + Vector2.RIGHT}
	var event_before := event.duplicate(true)
	game.world_view.receive(event)
	var effect: Dictionary = game.world_view.effects.effects.back()
	check.call(effect.get("character_pose", {}) == hero.capture_pose() and event == event_before, "An accepted dash captures the exact illustrated pose for its afterimage without modifying the source event")
	game.world_view.set_reduced_motion(true)
	check.call(game.world_view.effects.reduced_motion and game.world_view.camera.offset == Vector2.ZERO, "Reduced-motion vector presentation retains combat identities while suppressing camera shake")
	game.queue_free()
	await tree.process_frame

static func _stage_geometry(tree: SceneTree, studio: GuCharacterStudio, check: Callable) -> void:
	var original_size := tree.root.size
	var original_scale := tree.root.content_scale_size
	studio.set_process(false)
	studio._select_action(3)
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		tree.root.content_scale_size = dimensions
		tree.root.size = dimensions
		await tree.process_frame
		await tree.process_frame
		var visible_geometry := true
		for weapon in GuCharacterAppearance.catalog("weapon"):
			studio.appearance = {"body": "female" if str(weapon["id"]) == "spear" else "male", "outfit": "ivory" if str(weapon["id"]) == "spear" else "jade", "weapon": weapon["id"], "hair": "ponytail" if str(weapon["id"]) == "spear" else "topknot"}
			studio._sync_controls()
			for direction in range(8):
				studio._select_direction(direction)
				for phase in [0.0, .25, .44, .66, .95]:
					studio.playhead = GuCharacterAnimations.duration("attack", str(weapon["id"])) * phase
					studio._present()
					var view: GuIllustratedCharacterView = studio.character_view
					var snapshot := view.capture_pose()
					var pose: Dictionary = snapshot["pose"]
					var factor: Vector2 = view.scale * float(snapshot["scale"])
					var stage_rect := Rect2(Vector2.ZERO, studio.stage.size)
					var head_center: Vector2 = view.position + Vector2(pose["head"]) * factor
					visible_geometry = visible_geometry and stage_rect.has_point(head_center)
					var head_key := "head_%s_%s_%d" % [studio.appearance["body"], studio.appearance["hair"], view.current_direction]
					var rect: Array = GuIllustratedCharacterArt.manifest()["parts"][head_key]["rect"]
					var head_rect := Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
					for corner in [head_rect.position, Vector2(head_rect.end.x, head_rect.position.y), head_rect.end, Vector2(head_rect.position.x, head_rect.end.y)]:
						var transformed: Vector2 = view.position + (Vector2(pose["head"]) + Vector2(corner).rotated(float(pose["head_rotation"]))) * factor
						visible_geometry = visible_geometry and stage_rect.has_point(transformed)
					if str(weapon["id"]) != "unarmed":
						var blade_tip := Vector2(0, -38 if str(weapon["id"]) == "sword" else -42)
						var tip: Vector2 = view.position + (Vector2(pose["arm_R"][2]) + blade_tip.rotated(float(pose["weapon_angle"]))) * factor
						visible_geometry = visible_geometry and stage_rect.has_point(tip)
		check.call(visible_geometry, "The actual F6 head silhouette and rotated weapon tip fit the stage through eight attack directions and all three weapons at %dx%d" % [dimensions.x, dimensions.y])
	tree.root.content_scale_size = original_scale
	tree.root.size = original_size
	await tree.process_frame
	await tree.process_frame
