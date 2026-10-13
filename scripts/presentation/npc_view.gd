class_name NpcView
extends Node2D
## Friendly actor using the approved articulated rig, with a planted ground pivot.
var npc_id := ""
var simulation: LocalAuthority
var character: GuIllustratedCharacterView
var talking := false
var reduced_motion := false
var phase := 0.0
var elapsed := 0.0
var facing := Vector2.DOWN
var marker := ""
var nearby := false
var prompt_visible := false
var animation_samples := 0

func setup(id: String, authority: LocalAuthority) -> void:
	npc_id = id
	simulation = authority
	position = WorldGrid.project(QuestCatalog.cell(id))
	var data := QuestCatalog.npc(id)
	var vector: Array = data["facing"]
	facing = Vector2(vector[0],vector[1]).normalized()
	character = GuIllustratedCharacterView.new()
	add_child(character)
	character.configure(256,48)
	character.set_appearance(GuCharacterAppearance.sanitize(data["appearance"]))
	character.present("idle",0,facing)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _process(delta: float) -> void:
	if simulation == null or character == null:
		return
	elapsed += delta
	if elapsed < 1.0 / (30.0 if talking else 18.0):
		return
	var dt := elapsed
	elapsed = 0
	if not reduced_motion:
		phase += dt
	var difference := Vector2(simulation.player["cell"]) - QuestCatalog.cell(npc_id)
	nearby = difference.length() <= 1.8
	prompt_visible = nearby and simulation.interaction_npc() == npc_id and bool(simulation.can_talk(npc_id)["ok"])
	if (talking or nearby) and difference.length() > .2:
		facing = difference.normalized()
	var action := "channel" if talking and fmod(phase,3.6) < 2.3 else "idle"
	character.present_smooth(action,phase*.65,facing,reduced_motion,dt)
	animation_samples += 1
	marker = simulation.quests.npc_marker(npc_id,simulation)
	queue_redraw()

func _draw() -> void:
	if character == null:
		return
	# Shadow does not move with the head/arms; only the rig joints animate.
	draw_set_transform(Vector2(0,1),0,Vector2(1,.32))
	draw_circle(Vector2.ZERO,12,Color(0.1,.13,.09,.25),true,-1,true)
	draw_set_transform(Vector2.ZERO)
	var name_text := str(QuestCatalog.npc(npc_id)["name"])
	var width := GuPixelUI.HAND_FONT.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_rect(Rect2(-width*.5-4,7,width+8,16),Color(.12,.18,.13,.83))
	draw_string(GuPixelUI.HAND_FONT,Vector2(-width*.5,20),name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,GuPixelUI.PAPER_LIGHT)
	if marker != "":
		var at := Vector2(0,-76)
		var tint := GuPixelUI.JADE_LIGHT if marker == "?" else GuPixelUI.PAPER_LIGHT
		draw_circle(at,8,GuPixelUI.INK,true,-1,true)
		draw_arc(at,8,0,TAU,28,tint,.9,true)
		if marker == "…":
			for x in [-3,0,3]: draw_circle(at+Vector2(x,0),.9,tint,true,-1,true)
		else:
			var text_width := GuPixelUI.HAND_FONT.get_string_size(marker,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			draw_string(GuPixelUI.HAND_FONT,at+Vector2(-text_width*.5,5),marker,HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
	if prompt_visible and not talking:
		draw_string(GuPixelUI.HAND_FONT,Vector2(-37,35),"E • Trò chuyện",HORIZONTAL_ALIGNMENT_CENTER,74,9,GuPixelUI.PAPER_LIGHT)
