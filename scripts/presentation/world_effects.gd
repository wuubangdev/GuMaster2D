class_name WorldEffects
extends Node2D
## Event-driven illustrated spells. Simulation owns damage and resources;
## these clocks only stage the cast, travel and contact the player sees.

const MAX_EFFECTS: int = 48
const EFFECT_LIFETIMES := {
	"cast_moon": 0.52, "cast_frost": 0.64, "shield": 0.64, "dash": 0.38,
	"discovery": .8, "waygate": 1.0, "beast_strike": .45, "region_changed": 1.0, "realm_unlocked": 1.2, "gu_upgrade": .9, "gu_fusion": 1.2, "farm_harvest": .8, "animal_harvest": .8, "npc_quest_complete": 1.0, "farm_water": .5, "farm_plant": .5,
	"move": 0.65, "hit": 1.0, "player_hit": 1.0, "defeat": 0.7,
	"capture_success": 0.8, "capture_fail": 0.7, "level_up": 1.0, "respawn": 0.7,
}
var simulation: LocalAuthority
var player_view: ActorView
var actor_views: Dictionary = {}
var effects: Array[Dictionary] = []
var phase: float = 0.0
var reduced_motion: bool = false
var redraw_left: float = 0.0

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The same opacity resources apply to dash silhouettes. Solid-color spell
	# geometry has no source-sheet UVs and passes through this shader unchanged.
	material = GuConceptCharacterArt.material_for(GuCharacterAppearance.default_data())

func impact_delay_for(event: Dictionary) -> float:
	if event.get("kind", "") != "hit":
		return 0.0
	for index in range(effects.size() - 1, -1, -1):
		var active: Dictionary = effects[index]
		if active["kind"] in ["cast_moon", "cast_frost"] and active.get("target", "") == event.get("target", ""):
			return maxf(0.0, GuPixelEffectsArt.CONTACT_TIME - float(active["age"]))
	return 0.0

func receive(event: Dictionary) -> void:
	var kind := str(event["kind"])
	if not EFFECT_LIFETIMES.has(kind):
		return
	var effect := event.duplicate(true)
	effect["age"] = 0.0
	effect["life"] = float(EFFECT_LIFETIMES[kind])
	if kind in ["cast_moon", "cast_frost"]:
		var aim := WorldGrid.project(Vector2(event.get("to", event["at"])) - Vector2(event["at"]))
		effect["origin_offset"] = event.get("origin_offset", Vector2(-8 if aim.x < 0 else 8, -24))
	if event.has("harvest_action"):
		var clip := str(event["harvest_action"])
		effect["harvest_contact"]=GuCharacterAnimations.duration(clip)*float(GuCharacterActionMotion.HARVEST_CONTACT.get(clip,.5))
		effect["life"]=float(effect["life"])+float(effect["harvest_contact"])
	if kind == "dash" and player_view != null and player_view.character_view != null and player_view.character_view.has_method("capture_pose"):
		# Freeze the accepted visual pose. Afterimages never consult a later
		# action or rebuild gameplay state while drawing.
		effect["character_pose"] = player_view.character_view.capture_pose()
	if kind in ["hit", "player_hit"]:
		# Stagger simultaneous labels and show impact when the accepted spell
		# arrives. Authority HP already changed; no gameplay timer is delayed.
		var delay := impact_delay_for(event)
		effect["impact_delay"] = delay
		effect["life"] = float(effect["life"]) + delay
		effect["source_skill"] = ""
		for index in range(effects.size() - 1, -1, -1):
			if effects[index]["kind"] in ["cast_moon", "cast_frost"] and effects[index].get("target", "") == effect.get("target", "") and float(effects[index]["age"]) < GuPixelEffectsArt.CONTACT_TIME:
				effect["source_skill"] = effects[index]["kind"]
				break
		var occupied: Array[int] = []
		for active in effects:
			if active["kind"] == kind and active.get("target", "player") == effect.get("target", "player"):
				occupied.append(int(active.get("lane", 0)))
		var lane := 0
		while lane in occupied:
			lane += 1
		effect["lane"] = lane
	if effects.size() >= MAX_EFFECTS:
		effects.pop_front()
	effects.append(effect)

func _process(delta: float) -> void:
	phase += delta
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["age"] = float(effects[i]["age"]) + delta
		if effects[i].has("harvest_contact") and float(effects[i]["age"])<float(effects[i]["harvest_contact"]) and player_view!=null:
			if player_view.action_left<=0 or player_view.action_serial!=int(effects[i].get("action_serial",-1)):
				effects.remove_at(i)
				continue
		if effects[i]["kind"] in ["cast_moon", "cast_frost"]:
			if not effects[i].has("launch_offset") and float(effects[i]["age"]) >= float(effects[i].get("release_time",.08)):
				var hand: Vector2 = effects[i]["origin_offset"]
				if player_view != null and player_view.character_view != null and player_view.action == effects[i]["kind"]:
					hand = player_view.position - WorldGrid.project(effects[i]["at"]) + player_view.character_view.hand_position("R")
				effects[i]["launch_offset"] = hand
			if not effects[i].has("impact_point") and float(effects[i]["age"]) >= GuPixelEffectsArt.CONTACT_TIME:
				effects[i]["impact_point"] = _target_point(effects[i])
		if effects[i]["age"] >= effects[i]["life"]:
			effects.remove_at(i)
	redraw_left -= delta
	var capturing := simulation != null and not simulation.capture.is_empty()
	if not effects.is_empty() or capturing or redraw_left <= 0.0:
		redraw_left = 1.0 / 24.0
		queue_redraw()

func _target_point(effect: Dictionary) -> Vector2:
	var id := str(effect.get("target", ""))
	if actor_views.has(id):
		return Vector2(actor_views[id].position) + Vector2(0, -18)
	return WorldGrid.project(effect.get("to", effect["at"])) + Vector2(0, -18)

func _draw() -> void:
	if simulation == null:
		return
	var origin := WorldGrid.project(simulation.player["cell"])
	_draw_path(origin)
	if not simulation.capture.is_empty():
		_draw_capture(origin)
	for effect in effects:
		var at := WorldGrid.project(effect["at"])
		var ratio := clampf(float(effect["age"]) / float(effect["life"]), 0.0, 1.0)
		match str(effect["kind"]):
			"cast_moon", "cast_frost": _draw_cast(effect, at)
			"dash": _draw_dash(effect, at, ratio)
			"shield":
				_draw_skill_seal(effect, at)
				# ActorView owns the shield plates from unfurl through the guard loop.
				# Drawing a second shell here doubles every edge on the character.
				if player_view == null:
					GuPixelEffectsArt.draw(self, "shield_cast", at + Vector2(0, -24), 0.4 if reduced_motion else ratio, Vector2.RIGHT, Color(1, 1, 1, minf(1.0, (1-ratio)*3)))
			"hit", "player_hit": _draw_hit(effect, at)
			"move": _draw_move(at, ratio)
			"defeat":
				GuPixelEffectsArt.draw(self, "dust", at, 0.5 if reduced_motion else ratio, Vector2.RIGHT, Color(1, 1, 1, 1-ratio))
			"capture_success", "level_up", "respawn":
				var tint := Color("b4efd3") if effect["kind"] == "respawn" else Color.WHITE
				tint.a = minf(1.0, (1-ratio)*3)
				GuPixelEffectsArt.draw(self, "reward", at + Vector2(0, -23), 0.35 if reduced_motion else ratio, Vector2.RIGHT, tint)
				GuPixelEffectsArt.draw(self, "seal", at, 0.35 if reduced_motion else ratio, Vector2.RIGHT, tint)
			"discovery", "waygate", "region_changed", "realm_unlocked", "gu_upgrade", "gu_fusion", "farm_harvest", "animal_harvest", "npc_quest_complete", "farm_water", "farm_plant":
				_draw_cultivation(effect, at, ratio)
			"beast_strike": _draw_beast_strike(effect,at,ratio)
			"capture_fail":
				GuPixelEffectsArt.draw(self, "hit_spark", at + Vector2(0, -18), 0.4 if reduced_motion else ratio, Vector2.RIGHT, Color(1, .6, .5, 1-ratio))

static func cast_stage(age: float, release: float, life: float) -> Dictionary:
	# Presentation contract: gameplay has already accepted the cast; only its
	# visible release/contact are staged here. Keep the .28s contact invariant.
	var launch := clampf(release, .001, GuPixelEffectsArt.CONTACT_TIME-.001)
	if age < launch:
		return {"stage": "windup", "progress": clampf(age/launch,0,1)}
	if age < GuPixelEffectsArt.CONTACT_TIME:
		return {"stage": "flight", "progress": clampf((age-launch)/(GuPixelEffectsArt.CONTACT_TIME-launch),0,1)}
	if age < life:
		return {"stage": "contact", "progress": clampf((age-GuPixelEffectsArt.CONTACT_TIME)/maxf(.001,life-GuPixelEffectsArt.CONTACT_TIME),0,1)}
	return {"stage": "finished", "progress": 1.0}

static func flight_point(start: Vector2, end: Vector2, progress: float, frost: bool) -> Vector2:
	var point := start.lerp(end,clampf(progress,0,1))
	# Slight lifted thread for ice, with exact endpoints for hand and contact.
	return point + Vector2(0,-sin(clampf(progress,0,1)*PI)*minf(9,start.distance_to(end)*.07)) if frost else point

func _draw_cast(effect: Dictionary, at: Vector2) -> void:
	var frost: bool = effect["kind"] == "cast_frost"
	_draw_skill_seal(effect, at)
	var age := float(effect["age"])
	var release := float(effect.get("release_time",.08))
	var end: Vector2 = effect.get("impact_point", _target_point(effect))
	var start := at + Vector2(effect.get("launch_offset", effect["origin_offset"]))
	if not effect.has("launch_offset") and player_view != null and player_view.character_view != null and player_view.action == effect["kind"]:
		start = player_view.position + player_view.character_view.hand_position("R")
	var direction := end - start
	var impact := "ice_impact" if frost else "moon_impact"
	var frame := cast_stage(age,release,float(effect["life"]))
	var stage: String = frame["stage"]
	var progress: float = frame["progress"]
	if reduced_motion:
		# No false impact while winding up: hold a small identity at the hand,
		# then a stable contact silhouette only when the true contact beat arrives.
		if stage in ["windup","flight"]:
			GuPixelEffectsArt.draw(self,"frost_charge" if frost else "moon_charge",start,.65,direction,Color(1,1,1,.72))
		elif stage=="contact":
			GuPixelEffectsArt.draw(self,impact,end,.35,direction,Color(1,1,1,.65*(1-progress)))
		return
	if stage == "windup":
		GuPixelEffectsArt.draw(self,"frost_charge" if frost else "moon_charge",start,progress,direction)
	elif stage == "flight":
		var projectile := flight_point(start,end,progress,frost)
		GuPixelEffectsArt.draw(self,"ice_shard" if frost else "moon_blade",projectile,progress,direction)
		var wake := PackedVector2Array()
		for step in range(13):
			var t := lerpf(maxf(0,progress-.20),progress,float(step)/12)
			wake.append(flight_point(start,end,t,frost))
		GuVectorEffectsArt._line(self,wake,Vector2.ZERO,0,(GuVectorEffectsArt.ICE_LIGHT if frost else GuVectorEffectsArt.JADE_LIGHT)*Color(1,1,1,.32),1.3)
	elif stage == "contact":
		GuPixelEffectsArt.draw(self,impact,end,progress,direction,Color(1,1,1,minf(1.0,(1-progress)*2.2)))

func _draw_dash(effect: Dictionary, at: Vector2, ratio: float) -> void:
	_draw_skill_seal(effect, at)
	var end := WorldGrid.project(effect["to"])
	var direction := end-at
	if reduced_motion:
		GuPixelEffectsArt.draw(self, "dash_feather", end + Vector2(0, -12), .4, direction, Color(1, 1, 1, .8))
		return
	# Two short echoes follow the traversed segment, rather than stamping four
	# complete figures and feathers across the entire destination immediately.
	var travel := clampf(float(effect["age"])/.16,0,1)
	for i in range(2):
		var ghost := at.lerp(end,maxf(0,travel-.30+float(i)*.14))
		var alpha := (1-ratio)*(.10+i*.06)
		if effect.has("character_pose"):
			GuIllustratedCharacterArt.draw(self, effect["character_pose"], ghost, Color(.9, .86, .7, alpha))
		elif effect.has("character_texture"):
			var rect: Rect2 = effect["character_rect"]
			draw_texture_rect(effect["character_texture"], Rect2(rect.position+ghost, rect.size), false, Color(.52, .84, 1, alpha))
	GuPixelEffectsArt.draw(self, "dash_feather", at.lerp(end,travel)+Vector2(0,-13), ratio, direction, Color(1,1,1,.50*(1-ratio)))
	GuPixelEffectsArt.draw(self, "dash_wake", at.lerp(end,maxf(0,travel-.16))+Vector2(0,-17), ratio, direction, Color(1,1,1,.65*(1-ratio)))
	GuPixelEffectsArt.draw(self, "dust", at, ratio, Vector2.RIGHT, Color(1,1,1,.55))
	if float(effect["age"]) >= .16:
		GuPixelEffectsArt.draw(self, "dust", end, (float(effect["age"])-.16)/.22, Vector2.RIGHT, Color(1,1,1,.5))

func _draw_hit(effect: Dictionary, at: Vector2) -> void:
	var age := float(effect["age"]) - float(effect.get("impact_delay", 0))
	if age < 0:
		return
	var ratio := clampf(age, 0, 1)
	var player_damage: bool = effect["kind"] == "player_hit"
	var color := Color("ffc38f") if player_damage else Color("eeffe2")
	var amount := int(effect.get("amount", 0))
	var text := "-%d" % amount if amount > 0 else "Chặn"
	var lane := int(effect.get("lane", 0))
	var offset := Vector2(-12+(lane%2)*25, (-58 if player_damage else -44)-lane*18)
	if not reduced_motion:
		offset.y -= (1-pow(1-ratio, 2))*14
	color.a = minf(1, (1-ratio)*4)
	var font := ThemeDB.fallback_font
	draw_string_outline(font, at+offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(.05, .1, .09, color.a))
	draw_string(font, at+offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	if effect.get("source_skill", "").is_empty() and age < .24:
		GuPixelEffectsArt.draw(self, "hit_spark", at+Vector2(0, -22), .35 if reduced_motion else age/.24, Vector2.RIGHT, Color(1, .7, .55, .75) if player_damage else Color.WHITE)

func _draw_path(origin: Vector2) -> void:
	var previous := origin
	for cell in simulation.player["path"]:
		var destination := WorldGrid.project(cell)
		var count := maxi(1, ceili(previous.distance_to(destination)/7))
		for step in range(count):
			if step%2 == 0:
				var point := previous.lerp(destination, float(step)/count)
				draw_circle(point, 1.25, Color(.75, .94, .8, .45), true, -1.0, true)
		previous = destination

func _draw_move(at: Vector2, ratio: float) -> void:
	var radius := 5.0 if reduced_motion else 5.0+ratio*3.0
	var color := Color(.72,.90,.76,.65*(1-ratio))
	var ring := PackedVector2Array()
	for i in range(33):
		var angle := float(i)/32*TAU
		ring.append(at+Vector2(cos(angle)*radius,sin(angle)*radius*.38))
	draw_polyline(ring,color,1.1,true)
	draw_circle(at,.8,color,true,-1,true)

func _draw_capture(origin: Vector2) -> void:
	var target: Dictionary = simulation.mobs[simulation.capture["target"]]
	var end := WorldGrid.project(target["cell"]) + Vector2(0, -18)
	var hands := Vector2(0, -24)
	if player_view != null and player_view.character_view != null:
		hands = player_view.character_view.hand_position("L").lerp(player_view.character_view.hand_position("R"), .5)
	var start := origin+hands
	var tether := PackedVector2Array()
	for i in range(33):
		var ratio := float(i) / 32.0
		tether.append(start.lerp(end, ratio) + Vector2(0, -sin(ratio * PI) * 12))
	draw_polyline(tether, Color(.92, .77, .43, .13), 4.0, true)
	draw_polyline(tether, Color(.99, .87, .61, .6), 1.4, true)
	for i in range(3):
		var ratio := float(i + 1) / 4.0 if reduced_motion else fposmod(phase * .65 + float(i) / 3.0, 1.0)
		var point := start.lerp(end, ratio) + Vector2(0, -sin(ratio * PI) * 12)
		draw_circle(point, 1.7, Color("fff3bc"), true, -1.0, true)
	GuPixelEffectsArt.draw(self, "seal", end+Vector2(0, 18), .3 if reduced_motion else fposmod(phase*.6, 1))

func _draw_cultivation(effect: Dictionary, at: Vector2, ratio: float) -> void:
	if effect.has("harvest_contact"):
		var age := float(effect["age"])-float(effect["harvest_contact"])
		if age<0: return
		_draw_harvest_contact(effect,at,clampf(age/.8,0,1))
		return
	var farm: bool = str(effect["kind"]).begins_with("farm_")
	var tint := Color("a2ced2") if effect["kind"] == "farm_water" else Color("d9c38a")
	var progress := .4 if reduced_motion else ratio
	var alpha := clampf((1-ratio)*2,0,1)
	var radius := (8.0 if farm else 18.0) + progress * (8 if farm else 22)
	var points := PackedVector2Array()
	for index in range(49):
		var angle := index * TAU / 48
		points.append(at + Vector2(cos(angle),sin(angle)*.55)*radius)
	draw_polyline(points, Color(tint,alpha*.7),1.3,true)
	for index in range(5 if farm else 8):
		var angle := index*TAU/(5 if farm else 8)
		var center := at + Vector2(cos(angle)*radius*.8,sin(angle)*radius*.35 - progress*20)
		var slash := PackedVector2Array([center+Vector2(-2,3),center+Vector2(0,-3),center+Vector2(2,0)])
		draw_polyline(slash,Color(tint,alpha),1.1,true)

func _draw_skill_seal(effect: Dictionary, at: Vector2) -> void:
	# Three small brush runes replace the same rotating hexagon on every Gu.
	# Rank changes the number of marks, never the represented damage radius.
	var rank_value := clampi(int(effect.get("rank",1)),1,3)
	var age := float(effect["age"])
	var alpha := clampf(1-age/float(effect["life"]),0,1)*.42
	var kind: String = {"cast_moon":"moon","cast_frost":"frost","shield":"shield","dash":"dash"}.get(effect["kind"],"moon")
	var tint: Color = GuSkillArt.PALETTES[kind]
	for i in range(rank_value):
		var offset := Vector2(-4.0+(i-(rank_value-1)*.5)*8,6)
		var stroke := PackedVector2Array([Vector2(-2,-1),Vector2(0,-3),Vector2(2,0),Vector2(0,2)])
		GuVectorEffectsArt._line(self,stroke,at+offset,0,Color(tint,alpha),.9)

func _draw_beast_strike(effect: Dictionary, at: Vector2, ratio: float) -> void:
	var style := str(effect.get("style","melee"))
	var geometry: Dictionary = effect.get("geometry",{})
	var tint := Color("9bab79") if style in ["spit","cone"] else Color("c6ad83")
	var alpha := (1-ratio)*.85
	var progress := .32 if reduced_motion else ratio
	if geometry.is_empty():
		# Compatibility for older review recordings; actual attacks carry the
		# exact authority footprint produced by BeastAttackGeometry.
		GuPixelEffectsArt.draw(self,"hit_spark",at+Vector2(0,-12),progress,Vector2.RIGHT,Color(tint,alpha))
		return
	for polygon in BeastAttackGeometry.polygons(geometry):
		var projected := PackedVector2Array()
		for cell in polygon: projected.append(WorldGrid.project(cell))
		# The former warning footprint flashes once then disappears; no new
		# expanding area suggests damage outside the actual accepted attack.
		if ratio<.30:
			draw_polyline(projected,Color(tint,(1-ratio/.30)*.38),1.2,true)
	var origin := WorldGrid.project(geometry["origin"])
	var facing := WorldGrid.project(Vector2(geometry["facing"])).normalized()
	if style in ["spit","stomp","burst"]:
		var radius: float = geometry["radius"]
		for center in geometry["centers"]:
			var center_cell := Vector2(center)
			for i in range(5):
				var direction := Vector2.from_angle(i*TAU/5+.25)
				var outer := WorldGrid.project(center_cell+direction*radius*.78)
				var inner := WorldGrid.project(center_cell+direction*radius*.20)
				if style=="spit":
					var drop := inner.lerp(outer,progress)
					drop.y-=sin(progress*PI)*8
					var leaf := GuVectorEffectsArt._curve(Vector2(-2,2),Vector2(-5,-3),Vector2(3,-5),Vector2(3,-1))
					leaf.append(Vector2(-2,2))
					GuVectorEffectsArt._shape(self,leaf,drop,direction.angle(),Color(tint,alpha),Color.TRANSPARENT,.7)
				else:
					var crack := PackedVector2Array([inner,inner.lerp(outer,.45)+Vector2(2,-2),inner.lerp(outer,.70)+Vector2(-1,1),outer])
					GuVectorEffectsArt._line(self,crack,Vector2.ZERO,0,Color(tint,alpha),1.1)
					if not reduced_motion:
						var chip := inner.lerp(outer,progress)+Vector2(0,-sin(progress*PI)*11)
						GuVectorEffectsArt._shape(self,PackedVector2Array([Vector2(-2,1),Vector2(-1,-3),Vector2(3,-1),Vector2(1,2)]),chip,progress,Color(tint,alpha),Color.TRANSPARENT,.65)
	elif style=="charge":
		var aim := WorldGrid.project(geometry["aim"])
		for i in range(4):
			var center := origin.lerp(aim,(i+1)/4.0)
			GuPixelEffectsArt.draw(self,"dust",center,progress,Vector2.RIGHT,Color(tint,alpha*.7))
			GuVectorEffectsArt._line(self,PackedVector2Array([Vector2(-6,-1),Vector2(5,0)]),center,facing.angle(),Color(tint,alpha*.4),1.2)
	else:
		# Melee claw / cone strands begin at the monster's mouth or claw and
		# terminate inside the locked sector. The player can read their source.
		var half: float = geometry["half_angle"]
		var reach: float = geometry["range"]
		for i in range(3):
			var angle := Vector2(geometry["facing"]).angle()+(i-1)*half*.65
			var tip := WorldGrid.project(Vector2(geometry["origin"])+Vector2.from_angle(angle)*reach*.88)
			var start := origin.lerp(tip,.22)+Vector2(0,-8)
			var middle := origin.lerp(tip,.60)+Vector2(0,-16*(1-progress))
			var curve := GuVectorEffectsArt._curve(start,start.lerp(middle,.5),middle,tip+Vector2(0,-3))
			GuVectorEffectsArt._line(self,curve,Vector2.ZERO,0,Color(tint,alpha),2.1 if style=="melee" else 1.35)

func _draw_harvest_contact(effect: Dictionary, at: Vector2, progress: float) -> void:
	# A few leaf/chip marks at the resource; no expanding magic seal for work.
	var mining: bool = effect.get("harvest_action","")=="mine"
	var tint := Color("c7b7a0") if mining else Color("b1c58a")
	var alpha := (1-progress)*.85
	for i in range(4):
		var t := .25 if reduced_motion else progress
		var direction := Vector2.from_angle(-PI*.88+i*PI*.25)
		var center := at+Vector2(0,-5)+direction*t*17+Vector2(0,t*t*13)
		var points := PackedVector2Array([center+Vector2(-1.5,0),center+Vector2(0,-2),center+Vector2(2,.5),center+Vector2(0,1)])
		draw_colored_polygon(points,Color(tint,alpha))
