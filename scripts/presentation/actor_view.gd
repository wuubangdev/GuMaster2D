class_name ActorView
extends Node2D
## Presentation only: gait follows rendered distance; event poses never alter authority state.

var state: Dictionary = {}
var player_actor: bool = false
var selected: bool = false
var channeling: bool = false
var channel_facing: Vector2 = Vector2.ZERO
var reduced_motion: bool = false
var phase: float = 0.0
var stride: float = 0.0
var move_blend: float = 0.0
var flash: float = 0.0
var pending_hit_left: float = 0.0
var harvest_origin := Vector2.ZERO
var action_serial := 0
var action: String = ""
var action_left: float = 0.0
var action_duration: float = 0.3
var action_facing: Vector2 = Vector2.ZERO
var dash_start: Vector2
var dash_end: Vector2
var death_age: float = 0.0
var spawn_left: float = 0.0
var initialized: bool = false
var was_dead: bool = false
var presentation_dead: bool = false
var last_ai: String = "idle"
var idle_redraw_left: float = 0.0
var character_view: GuPixelCharacterView
var displayed_appearance: Dictionary = {}
var static_portrait: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if player_actor:
		character_view = GuIllustratedCharacterView.new()
		add_child(character_view)
		character_view.configure(256,48)
		_sync_character()
	else:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func set_static_appearance(value: Dictionary) -> void:
	static_portrait = true
	displayed_appearance = value.duplicate(true)
	if character_view != null:
		character_view.set_appearance(value)
		character_view.present("idle", 0, Vector2.DOWN, true)
		character_view.set_active(false)

func _sync_character(delta: float = 0.0, root_travel: Vector2 = Vector2.ZERO) -> void:
	if character_view == null or static_portrait:
		return
	var look: Dictionary = state.get("appearance", GuCharacterAppearance.default_data())
	if look != displayed_appearance:
		displayed_appearance = look.duplicate(true)
		character_view.set_appearance(look)
	var direction: Vector2 = current_pose()["direction"]
	var clip := "idle"
	var sample := phase
	if bool(state.get("dead", false)):
		clip = "death"
		sample = death_age
	elif spawn_left > 0.0:
		clip = "respawn"
		sample = (1-spawn_left/.4) * GuCharacterAnimations.duration(clip,str(look.get("weapon","sword")))
	elif action_left > 0.0:
		clip = {"cast_moon":"attack", "cast_frost":"cast", "shield":"defend", "dash":"dash", "gather":"gather", "mine":"mine"}.get(action,"idle")
		sample = (1-action_left/maxf(action_duration,.001))*GuCharacterAnimations.duration(clip,str(look.get("weapon","sword")))
	elif channeling:
		clip = "channel"
	elif flash > 0.0:
		clip = "hit"
		sample = (1-flash/.18)*GuCharacterAnimations.duration(clip,str(look.get("weapon","sword")))
	elif move_blend > .08:
		clip = "run" if bool(state.get("running",false)) else "walk"
		sample = stride / TAU * GuCharacterAnimations.duration(clip,str(look.get("weapon","sword")))
	if character_view is GuIllustratedCharacterView:
		character_view.present_smooth(clip,sample,direction,reduced_motion,delta,move_blend,stride/TAU,bool(state.get("running",false)),WorldGrid.project(state.get("facing",Vector2.DOWN)),root_travel)
	else:
		character_view.present(clip,sample,direction,reduced_motion)

func bind(actor: Dictionary, is_player: bool) -> void:
	state = actor
	player_actor = is_player
	position = WorldGrid.project(state["cell"])
	was_dead = bool(state.get("dead", false))
	presentation_dead = was_dead
	initialized = true

func receive(event: Dictionary) -> void:
	var kind := str(event["kind"])
	if kind=="farm_harvest" and GuCharacterActionMotion.harvesting(str(event.get("harvest_action",""))):
		action=str(event["harvest_action"])
		action_serial+=1
		action_duration=GuCharacterAnimations.duration(action)
		action_left=action_duration
		harvest_origin=Vector2(state["cell"])
		action_facing=WorldGrid.project(Vector2(event["at"])-harvest_origin)
	elif kind in ["cast_moon", "cast_frost", "shield", "dash"]:
		action_serial+=1
		action = kind
		action_duration = {"dash": 0.16, "cast_moon": 0.48, "cast_frost": 0.56, "shield": 0.48}[kind]
		if kind=="cast_moon" and state.get("appearance",{}).get("weapon","sword")=="sword": action_duration=GuCharacterActionMotion.SWORD_SECONDS
		action_left = action_duration
		action_facing = WorldGrid.project(Vector2(event["to"]) - Vector2(event.get("at", state["cell"]))) if kind in ["cast_moon", "cast_frost", "dash"] and event.has("to") else Vector2.ZERO
		if kind == "dash":
			dash_start = position
			dash_end = WorldGrid.project(event["to"])
	elif kind in ["hit", "player_hit"]:
		if GuCharacterActionMotion.harvesting(action): action_left=0
		pending_hit_left = maxf(0.0, float(event.get("visual_delay", 0)))
		if pending_hit_left <= 0:
			flash = 0.19
	elif kind == "respawn":
		position = WorldGrid.project(state["cell"])
		spawn_left = 0.4
	queue_redraw()

func _process(delta: float) -> void:
	if not initialized:
		return
	phase += delta
	flash = maxf(0.0, flash - delta)
	if pending_hit_left > 0:
		pending_hit_left = maxf(0.0, pending_hit_left - delta)
		if pending_hit_left == 0:
			flash = 0.19
	if GuCharacterActionMotion.harvesting(action) and Vector2(state["cell"]).distance_to(harvest_origin)>.03:
		action_left=0
	var dashing := action == "dash" and action_left > 0.0
	action_left = maxf(0.0, action_left - delta)
	spawn_left = maxf(0.0, spawn_left - delta)
	var dead := bool(state.get("dead", false)) and (player_actor or pending_hit_left <= 0.0)
	presentation_dead = dead
	if dead != was_dead:
		death_age = 0.0
		action_left = 0.0
		flash = 0.0
		pending_hit_left = 0.0
		move_blend = 0.0
		channeling = false
		if not dead:
			position = WorldGrid.project(state["cell"])
			spawn_left = 0.4
		was_dead = dead
	if dead:
		death_age += delta
	var previous := position
	if dashing:
		var t := 1.0 - action_left / action_duration
		position = dash_end if reduced_motion else dash_start.lerp(dash_end, 1.0 - pow(1.0 - t, 3.0))
	else:
		position = position.lerp(WorldGrid.project(state["cell"]), 1.0 - exp(-26.0 * delta))
	var travelled := WorldGrid.unproject(position - previous).length()
	var moving := not dead and not dashing and travelled > 0.0001
	var speed := clampf(travelled / maxf(delta, 0.001) / (3.0 if player_actor else 1.5), 0.0, 1.0) if moving else 0.0
	move_blend = lerpf(move_blend, speed, 1.0 - exp(-12.0 * delta))
	if moving:
		# Same model-space stride as the foot stance curve. Walking and running
		# keep the accumulated phase when switching pace.
		if player_actor:
			var gait_facing := WorldGrid.project(state.get("facing",Vector2.DOWN))
			var distance := GuConceptMotionFrames.stride("run" if bool(state.get("running",false)) else "walk",gait_facing)
			stride += travelled*32.0*TAU/maxf(.01,distance)
		else:
			# The stance foot retreats by exactly the rendered travel distance.
			stride += travelled*WorldGrid.CELL_SIZE.x*TAU/(BeastMotion.stride_length(move_blend)*BeastMotion.body_scale(state))
	var ai := str(state.get("state", "idle"))
	if not player_actor and last_ai == "windup" and ai == "chase" and not dead:
		action = "strike"
		action_duration = 0.2
		action_left = action_duration
	last_ai = ai
	_sync_character(delta,position-previous)
	if character_view != null:
		# Curved artwork follows authority interpolation continuously.
		character_view.position = Vector2.ZERO
		var hurt := minf(1.0, flash / .18) if not reduced_motion else 0.0
		character_view.modulate = Color(1, 1-hurt*.35, 1-hurt*.5)
	visible = player_actor or not dead or death_age < .65
	if not player_actor:
		modulate.a = 1.0-smoothstep(.45,.65,death_age) if dead else 1.0
	idle_redraw_left -= delta
	if visible and (moving or flash > 0.0 or action_left > 0.0 or (dead and death_age < 1.0) or spawn_left > 0.0 or idle_redraw_left <= 0.0):
		idle_redraw_left = 1.0 / 30.0
		queue_redraw()

func _draw() -> void:
	if not initialized:
		return
	if presentation_dead:
		_draw_fallen()
		return
	GuPixelEffectsArt.ground_shadow(self, Vector2(1, 2), 13 if player_actor else 18.0 * BeastMotion.body_scale(state), Color(.02, .05, .05, .36))
	var flinch := sin(flash / 0.19 * PI) * 2.5 if not reduced_motion and not player_actor else 0.0
	draw_set_transform(Vector2(roundf(flinch), 0) + position.round() - position)
	if player_actor:
		_player()
	elif state.get("wild",false):
		BeastArt.draw(self,state,phase,stride,move_blend,reduced_motion,flash,selected)
	else:
		# Starter wolves keep their existing gameplay stats/AI; only their art
		# uses the same articulated anatomy as wilderness wolves.
		var visual_state := state.duplicate()
		visual_state["species"] = "wolf"
		visual_state["windup_duration"] = .65
		if state.get("state","") == "windup":
			visual_state["attack_geometry"] = {"kind":"stomp","origin":state["cell"],"aim":state["cell"],"centers":[state["cell"]],"radius":1.45,"range":1.45,"half_angle":PI,"facing":state["facing"]}
		if action == "strike" and action_left > 0:
			visual_state["attack_age"] = .2-action_left
			visual_state["last_attack"] = {"style":"melee"}
		BeastArt.draw(self,visual_state,phase,stride,move_blend,reduced_motion,flash,selected)
	draw_set_transform(Vector2.ZERO)

func _draw_fallen() -> void:
	var t := clampf(death_age / 0.28, 0.0, 1.0)
	GuGlyphs.ellipse(self, Vector2.ZERO, Vector2(19, 7) * (1.0 if player_actor else BeastMotion.body_scale(state)), Color(0.07, 0.15, 0.12, 0.7))
	if player_actor:
		var rise := 0.0 if reduced_motion else minf(death_age, 1.0) * 10
		GuGlyphs.draw(self, "moon", Vector2(10, -28 - rise), 8, Color(0.7, 0.86, 0.75, 0.5))
	elif state.get("wild",false):
		BeastArt.draw(self,state,phase,stride,0,reduced_motion,0,false,true,death_age)
	else:
		BeastArt.draw(self,state,phase,stride,0,reduced_motion,0,false,true,death_age)

func current_pose() -> Dictionary:
	var progress := 1.0 - action_left / maxf(action_duration, 0.001)
	var direction := channel_facing if channeling and channel_facing.length_squared() > 0.001 else WorldGrid.project(state.get("facing", Vector2(1, -1)))
	if action_left > 0.0 and action_facing.length_squared() > 0.001:
		direction = action_facing
	return GuHumanoidRig.sample(direction, stride, move_blend, phase, action if action_left > 0.0 else "", progress, channeling, flash, reduced_motion)

func _player() -> void:
	# The sprite owns hands/weapon movement. Spell geometry lives in
	# WorldEffects; idle has no debug orb or stacked foot rings.
	if channeling:
		GuPixelEffectsArt.draw(self, "cast_spark", Vector2(0, -54), .4 if reduced_motion else fposmod(phase*.7, 1), Vector2.RIGHT, Color(1, .88, .6, .75))
	if float(state.get("shield", 0.0)) > 0.0:
		var opacity := .62 if reduced_motion else .58+sin(phase*2.2)*.07
		if action == "shield" and action_left > 0:
			GuPixelEffectsArt.draw(self, "shield_cast", Vector2(0,-24), .4 if reduced_motion else 1-action_left/action_duration,Vector2.RIGHT,Color(1,1,1,opacity))
		else:
			GuPixelEffectsArt.draw(self, "shield_loop", Vector2(0, -24), .4 if reduced_motion else fposmod(phase*.55, 1), Vector2.RIGHT, Color(1, 1, 1, opacity))

func _wolf() -> void:
	var motion := 0.0 if reduced_motion else move_blend
	var flip := 1.0 if WorldGrid.project(state.get("facing", Vector2.LEFT)).x >= 0 else -1.0
	var windup := clampf(1.0 - float(state.get("windup_left", 0.0)) / 0.65, 0.0, 1.0) if state.get("state", "") == "windup" else 0.0
	if windup > 0.0:
		var aim: Vector2 = WorldGrid.project(state.get("facing", Vector2.DOWN)).normalized()
		var reach := 43.0
		var wedge := PackedVector2Array([Vector2.ZERO, (aim.rotated(-.48)*reach).round(), (aim*reach).round(), (aim.rotated(.48)*reach).round()])
		draw_colored_polygon(wedge, Color(.92, .31, .18, .1+windup*.18))
		draw_polyline(PackedVector2Array([wedge[1], wedge[2], wedge[3]]), Color(1, .6, .35, .8), 1, false)
		draw_rect(Rect2(-1, -44, 2, 7), Color("ffcd87"))
		draw_rect(Rect2(-1, -35, 2, 2), Color("ffcd87"))
	var lunge := sin((1.0 - action_left / action_duration) * PI) * 10 if action == "strike" and action_left > 0.0 and not reduced_motion else 0.0
	draw_set_transform(Vector2(roundf(flip * lunge), 0) + position.round() - position)
	var wolf_action := "walk" if motion > .08 else "idle"
	var wolf_frame := int(fposmod(stride / TAU,1.0)*4) if motion > .08 else int(phase*.8)%4
	if windup > 0:
		wolf_action = "windup"
		wolf_frame = clampi(int(windup*4),0,3)
	elif action == "strike" and action_left > 0:
		wolf_action = "strike"
		wolf_frame = clampi(int((1.0-action_left/action_duration)*4),0,3)
	elif flash > 0:
		wolf_action = "hit"
		wolf_frame = clampi(int((1.0-flash/.18)*4),0,3)
	var tint := Color.WHITE if int(state.get("variant",0)) != 2 else Color("c6e2ce")
	if flash > .07 and not reduced_motion:
		tint = Color(1.35, 1.28, 1.1)
	GuPixelWolfArt.draw(self, wolf_action, WorldGrid.project(state.get("facing",Vector2.LEFT)), 0 if reduced_motion else wolf_frame,tint)
	draw_set_transform(Vector2.ZERO)
	if selected or float(state["hp"]) < float(state["max_hp"]):
		draw_rect(Rect2(-22, -45, 44, 4), Color(0.04, 0.10, 0.09, 0.9))
		draw_rect(Rect2(-22, -45, 44 * float(state["hp"]) / float(state["max_hp"]), 4), Color("ce9b69"))
		if float(state["hp"]) <= float(state["max_hp"]) * 0.3:
			draw_circle(Vector2(27, -43), 3, Color("a7dbc0"))
	if float(state.get("slow_left", 0.0)) > 0.0:
		GuGlyphs.draw(self, "frost", Vector2(0, -52), 6, Color("a4d6e8"))
