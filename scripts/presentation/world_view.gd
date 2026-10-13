class_name WorldView
extends Node2D

var simulation: LocalAuthority
var player_view: ActorView
var cultivation: CultivationWorld
var ground: GroundView
var npcs: Dictionary = {}
var active_npc := ""
var environment_details: EnvironmentDetails
var landmarks: Array[StoryLandmark] = []
var overland: OverlandView
var cull_left := 0.0
var actors: Dictionary = {}
var props: Array[PropView] = []
var _prop_nodes: Dictionary = {}
var effects: WorldEffects
var targeting: TargetingView
var camera: Camera2D
var selected_id: String = ""
var desired_zoom: float = 2.0
var _camera_follow := Vector2.ZERO
var reduced_motion: bool = false
var shake_left: float = 0.0

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	y_sort_enabled = true
	ground = GroundView.new()
	ground.world = authority.world
	ground.z_index = -10
	add_child(ground)
	cultivation = CultivationWorld.new()
	cultivation.simulation = authority
	cultivation.z_index = -5
	add_child(cultivation)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_view = ActorView.new()
	player_view.bind(authority.player, true)
	add_child(player_view)
	for id in authority.mobs:
		var actor := ActorView.new()
		actor.bind(authority.mobs[id], false)
		add_child(actor)
		actors[id] = actor
	effects = WorldEffects.new()
	effects.simulation = authority
	effects.player_view = player_view
	effects.actor_views = actors
	effects.z_index = 10
	add_child(effects)
	targeting = TargetingView.new()
	targeting.simulation = authority
	targeting.actor_views = actors
	targeting.z_index = 12
	add_child(targeting)
	camera = Camera2D.new()
	_camera_follow = player_view.position + Vector2(0, -24)
	camera.position = _camera_follow.round()
	camera.zoom = Vector2.ONE * desired_zoom
	add_child(camera)
	camera.make_current()
	camera.force_update_scroll()
	_build_story_world()
	_refresh_visible_world()

func _process(delta: float) -> void:
	if simulation == null:
		return
	cull_left -= delta
	if cull_left <= 0:
		cull_left = .2
		_refresh_visible_world()
	shake_left = maxf(0.0, shake_left - delta)
	var shake := Vector2(sin(shake_left * 180), cos(shake_left * 145)) * shake_left * 14.0 if not reduced_motion else Vector2.ZERO
	_camera_follow = _camera_follow.lerp(player_view.position + Vector2(0, -24), 1.0 - exp(-9.0 * delta))
	# Register to display pixels, not whole world pixels. At 2x/3x zoom this
	# allows one-pixel camera steps while preserving crisp integer-scaled tiles.
	camera.zoom = Vector2.ONE * clampf(roundf(desired_zoom), 1.0, 4.0)
	camera.position = (_camera_follow*camera.zoom).round()/camera.zoom
	camera.offset = (shake*camera.zoom).round()/camera.zoom
	player_view.channeling = not simulation.capture.is_empty()
	if player_view.channeling:
		var target: Vector2 = simulation.mobs[simulation.capture["target"]]["cell"]
		player_view.channel_facing = WorldGrid.project(target - Vector2(simulation.player["cell"]))
	if not selected_id.is_empty() and bool(simulation.mobs.get(selected_id, {}).get("dead", true)):
		selected_id = ""
	targeting.selected_id = selected_id
	for id in actors:
		actors[id].selected = id == selected_id
	for prop in props:
		var offset := player_view.position - prop.position
		if offset.length_squared() > 900*900:
			prop.modulate.a = 1.0
			continue
		var bounds := prop.art_bounds.grow(4)
		var occludes := prop.position.y >= player_view.position.y and prop.kind in ["tree","wall","pillar","monolith","lantern","altar","bamboo","ruin_column"] and (bounds.has_point(offset + Vector2(0,-21)) or bounds.has_point(offset + Vector2(0,-43)) or bounds.has_point(offset + Vector2(0,-7)))
		# The existing silhouette spans head, torso and boots. Fade foreground props
		# against those anchors so posts cannot hide planted feet or the face.
		prop.modulate.a = move_toward(prop.modulate.a, 0.12 if occludes else 1.0, delta * 5)

func screen_to_cell(point: Vector2) -> Vector2:
	return WorldGrid.unproject(get_global_transform_with_canvas().affine_inverse() * point)

func cell_to_screen(cell: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * WorldGrid.project(cell)

func pick_mob(point: Vector2) -> String:
	var local := get_global_transform_with_canvas().affine_inverse() * point
	var best := ""
	var closest := INF
	for id in actors:
		if bool(simulation.mobs[id]["dead"]):
			continue
		var offset: Vector2 = local - actors[id].position
		var bounds := Rect2(-32,-47,64,54)
		if simulation.mobs[id].get("wild",false):
			var extent := 48.0 if Bestiary.species(simulation.mobs[id]["species"]).get("elite",false) else 35.0
			bounds = Rect2(Vector2(-extent,-13-extent),Vector2.ONE*extent*2)
		if bounds.has_point(offset) and offset.length() < closest:
			closest = offset.length()
			best = str(id)
	return best

func select_target(id: String) -> void:
	if simulation.mobs.has(id) and not bool(simulation.mobs[id]["dead"]):
		selected_id = id
		targeting.selection_left = 0.28

func cycle_target() -> void:
	var candidates: Array[Dictionary] = []
	var viewport_rect := get_viewport_rect().grow(-8)
	for id in actors:
		var mob: Dictionary = simulation.mobs[id]
		var distance := Vector2(simulation.player["cell"]).distance_to(mob["cell"])
		if not bool(mob["dead"]) and distance <= 8.0 and viewport_rect.has_point(cell_to_screen(mob["cell"])):
			candidates.append({"id": str(id), "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return a["id"] < b["id"] if is_equal_approx(a["distance"], b["distance"]) else a["distance"] < b["distance"])
	if candidates.is_empty():
		selected_id = ""
		return
	var ids: Array[String] = []
	for candidate in candidates:
		ids.append(candidate["id"])
	select_target(ids[(ids.find(selected_id) + 1) % ids.size()])

func receive(event: Dictionary) -> void:
	if event["kind"] in ["waygate","respawn"]:
		selected_id = ""
		targeting.slot = -1
		targeting.probe = {}
		targeting.selected_id = ""
		targeting.hovered_id = ""
		effects.effects.clear()
		shake_left = 0
		camera.offset = Vector2.ZERO
		player_view.move_blend = 0
		player_view.action_left=0
		player_view.action_serial+=1
		player_view.position = WorldGrid.project(simulation.player["cell"])
		_camera_follow = player_view.position+Vector2(0,-24)
		camera.position = _camera_follow
		camera.force_update_scroll()
		ground._refresh_visible_tiles()
		_refresh_visible_world()

	if event["kind"] == "region_changed":
		rebuild_region()
	# Remote farming UI keeps its existing resource feedback. Animate a reach
	# only when the actor is actually beside the crop.
	var local_harvest: bool = event.has("harvest_action") and Vector2(event["at"]).distance_to(simulation.player["cell"])<=1.8
	# The accepted event chooses the current facing/pose before its VFX snapshot.
	if event["kind"] in ["cast_moon", "cast_frost", "shield", "dash", "player_hit", "respawn"] or local_harvest:
		player_view.receive(event)
		player_view._sync_character()
	var visual_event := event.duplicate(true)
	if event["kind"]=="cast_moon":
		visual_event["release_time"]=GuCharacterActionMotion.release_seconds(str(simulation.player.get("appearance",{}).get("weapon","sword")))
	if local_harvest:
		visual_event["action_serial"]=player_view.action_serial
	if not local_harvest: visual_event.erase("harvest_action")
	if player_view.character_view != null and event["kind"] in ["dash", "cast_moon", "cast_frost"]:
		var view := player_view.character_view
		visual_event["origin_offset"] = view.hand_position("R")
		visual_event["character_texture"] = view.current_frame_texture()
		visual_event["character_rect"] = view.visual_rect()
	effects.receive(visual_event)
	if event["kind"] == "hit" and actors.has(event.get("target", "")):
		var impact_event := event.duplicate(true)
		impact_event["visual_delay"] = effects.impact_delay_for(event)
		actors[event["target"]].receive(impact_event)
	if event["kind"] == "player_hit" and int(event.get("amount", 0)) > 0:
		shake_left = 0.14

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	ground.reduced_motion = value
	cultivation.reduced_motion = value
	player_view.reduced_motion = value
	effects.reduced_motion = value
	targeting.reduced_motion = value
	if overland != null: overland.reduced_motion = value
	for npc in npcs.values():
		npc.reduced_motion = value
	if environment_details != null:
		environment_details.reduced_motion = value
	for landmark in landmarks:
		landmark.reduced_motion = value
	for actor in actors.values():
		actor.reduced_motion = value
	for prop in props:
		prop.reduced_motion = value
	if value:
		camera.offset = Vector2.ZERO

func rebuild_region() -> void:
	player_view.action_left=0
	player_view.action_serial+=1
	_clear_story_world()
	selected_id = ""
	targeting.slot = -1
	targeting.probe = {}
	targeting.selected_id = ""
	targeting.hovered_id = ""
	effects.effects.clear()
	for actor in actors.values():
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	for prop in props:
		remove_child(prop)
		prop.queue_free()
	props.clear()
	_prop_nodes.clear()
	remove_child(ground)
	ground.queue_free()
	ground = GroundView.new()
	ground.world = simulation.world
	ground.z_index = -10
	add_child(ground)
	for id in simulation.mobs:
		var actor := ActorView.new()
		actor.bind(simulation.mobs[id], false)
		add_child(actor)
		actors[id] = actor
	player_view.bind(simulation.player, true)
	player_view.action = ""
	player_view.action_left = 0
	player_view.move_blend = 0
	player_view.channeling = false
	_camera_follow = player_view.position + Vector2(0,-24)
	camera.position = _camera_follow
	camera.offset = Vector2.ZERO
	camera.reset_smoothing()
	camera.force_update_scroll()
	ground._refresh_visible_tiles()
	_build_story_world()
	set_reduced_motion(reduced_motion)
	_refresh_visible_world()

func _build_story_world() -> void:
	overland = OverlandView.new()
	overland.simulation = simulation
	overland.z_index = -4
	add_child(overland)
	environment_details = EnvironmentDetails.new()
	environment_details.z_index = -8
	add_child(environment_details)
	environment_details.setup(simulation)
	for data in simulation.world.landmarks:
		var landmark := StoryLandmark.new()
		add_child(landmark)
		landmark.setup(data,simulation)
		landmarks.append(landmark)
	for id in QuestCatalog.npcs(simulation.expedition.region):
		var npc := NpcView.new()
		add_child(npc)
		npc.setup(id,simulation)
		npcs[id] = npc

func _clear_story_world() -> void:
	if overland != null:
		remove_child(overland)
		overland.queue_free()
		overland = null
	active_npc = ""
	for node in npcs.values() + landmarks:
		remove_child(node)
		node.queue_free()
	npcs.clear()
	landmarks.clear()
	if environment_details != null:
		remove_child(environment_details)
		environment_details.queue_free()
		environment_details = null

func talk_to_npc(id: String) -> void:
	active_npc = id
	for key in npcs:
		npcs[key].talking = key == id

func pick_npc(point: Vector2) -> String:
	var local := get_global_transform_with_canvas().affine_inverse() * point
	var nearest := ""
	var distance := INF
	for id in npcs:
		var offset: Vector2 = local-npcs[id].position
		if Rect2(-17,-50,34,65).has_point(offset) and offset.length() < distance:
			nearest = id
			distance = offset.length()
	return nearest

func _cull_remote_actors() -> void:
	var radius := _visible_radius()
	for id in actors:
		var actor: ActorView = actors[id]
		var near := Vector2(simulation.mobs[id]["cell"]).distance_to(simulation.player["cell"]) <= radius
		if near and not actor.is_processing(): actor.position = WorldGrid.project(simulation.mobs[id]["cell"])
		actor.set_process(near)
		if not near: actor.hide()
	for id in npcs:
		var near := QuestCatalog.cell(id).distance_to(simulation.player["cell"]) <= radius
		npcs[id].visible = near
		npcs[id].set_process(near)

func _visible_radius() -> float:
	# Include the full viewport diagonal, camera easing and tall canopy overhang.
	# This also covers large monitors/zoom one without a fixed-radius pop-in.
	return get_viewport_rect().size.length() / (2.0 * clampf(roundf(desired_zoom),1,4) * WorldGrid.CELL_SIZE.x) + 6.0

func _refresh_visible_world() -> void:
	if simulation == null: return
	_cull_remote_actors()
	_stream_props()

func _stream_props() -> void:
	var center: Vector2 = simulation.player["cell"]
	var radius := _visible_radius()
	# A retained outer band avoids rebuilding props when crossing a bucket edge.
	for key in _prop_nodes.keys():
		var node: PropView = _prop_nodes[key]
		if node.cell.distance_to(center) > radius + 6.0:
			props.erase(node)
			_prop_nodes.erase(key)
			remove_child(node)
			node.queue_free()
	for data in simulation.world.props_near(center,radius):
		var key: int = data["stream_id"]
		if _prop_nodes.has(key): continue
		var prop := PropView.new()
		prop.configure(data)
		prop.reduced_motion = reduced_motion
		add_child(prop)
		props.append(prop)
		_prop_nodes[key] = prop
