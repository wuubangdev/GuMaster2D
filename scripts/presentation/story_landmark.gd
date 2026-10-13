class_name StoryLandmark
extends Node2D
## Shared ink geometry for inhabited corners. Collision footprint lives in WorldGrid.
var kind := ""
var simulation: LocalAuthority
var reduced_motion := false
var phase := 0.0
var elapsed := 0.0
const INK := Color("454637")
const WOOD := Color("9b8259")
const EDGE := Color("ccb486")
const JADE := Color("637c59")

func setup(data: Dictionary, authority: LocalAuthority) -> void:
	kind = data["kind"]
	simulation = authority
	position = WorldGrid.project(data["cell"])
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _process(delta: float) -> void:
	var offset := WorldGrid.project(simulation.player["cell"]) - position
	var occluded := offset.y < 5 and Rect2(-43,-90,86,90).has_point(offset+Vector2(0,-22))
	modulate.a = move_toward(modulate.a,.24 if occluded else 1,delta*5)
	if reduced_motion:
		if phase != 0:
			phase = 0
			queue_redraw()
		return
	elapsed += delta
	if elapsed >= 1.0/15:
		phase += elapsed
		elapsed = 0
		queue_redraw()

func shape(points: Array, fill: Color, line: Color = INK, width: float = 1.2) -> void:
	var vertices := PackedVector2Array()
	for point in points:
		vertices.append(Vector2(point[0],point[1]))
	draw_colored_polygon(vertices,fill)
	vertices.append(vertices[0])
	draw_polyline(vertices,line,width,true)

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,.3))
	draw_circle(Vector2.ZERO,28,Color(.15,.16,.1,.23),true,-1,true)
	draw_set_transform(Vector2.ZERO)
	match kind:
		"camp_awning": awning()
		"herbal_table": herbal_table()
		"survey_table": survey_table()
		"tool_shed": tool_shed()
		"waypost": waypost()
		"ruin_banner": ruin_banner()

func table() -> void:
	for x in [-22,22]:
		draw_line(Vector2(x,-13),Vector2(x,7),INK,4,true)
		draw_line(Vector2(x,-13),Vector2(x,6),WOOD,2,true)
	shape([[-29,-20],[22,-23],[30,-10],[-25,-7]],WOOD)
	draw_line(Vector2(-24,-10),Vector2(26,-13),EDGE,1,true)

func awning() -> void:
	for x in [-29,29]:
		draw_line(Vector2(x,5),Vector2(x,-63),INK,4,true)
		draw_line(Vector2(x,4),Vector2(x,-61),WOOD,2,true)
	var sway := sin(phase*1.4)*1.5
	shape([[-38,-58],[-23,-78],[24,-79],[39,-57+sway],[21,-52],[0,-55],[-20,-52]],JADE)
	draw_polyline(PackedVector2Array([Vector2(-31,-58),Vector2(-13,-62),Vector2(5,-59),Vector2(30,-59)]),EDGE,1,true)
	for x in [-17,0,17]:
		draw_line(Vector2(x,-74),Vector2(x+4,-56),Color("465f49"),1,true)
	shape([[-23,-17],[20,-19],[22,-2],[-22,1]],Color("a8986d"))
	draw_rect(Rect2(-17,-23,23,10),Color("d6c79d"))
	draw_line(Vector2(-14,-20),Vector2(3,-20),INK,1,true)
	for x in [13,20]:
		draw_circle(Vector2(x,-22),4,INK,true,-1,true)
		draw_circle(Vector2(x,-22),3,Color("c4b995"),true,-1,true)

func herbal_table() -> void:
	table()
	for index in range(3):
		var at := Vector2(-17+index*17,-22-index%2*3)
		draw_circle(at,6,INK,true,-1,true)
		draw_circle(at+Vector2(0,-1),5,Color("b9a77f"),true,-1,true)
		for leaf in range(3):
			var tip := at+Vector2((leaf-1)*6,-14-abs(leaf-1)*2)
			draw_line(at,tip,INK,1.7,true)
			draw_line(at,tip,JADE.lightened(.25),.8,true)
	shape([[-25,-45],[-22,-52],[22,-52],[24,-44]],Color("d5c294"))
	draw_string(GuPixelUI.HAND_FONT,Vector2(-20,-45),"DƯỢC THẢO",HORIZONTAL_ALIGNMENT_CENTER,42,8,INK)
	for x in [-28,27]:
		draw_line(Vector2(x,2),Vector2(x,-53),INK,2,true)

func survey_table() -> void:
	table()
	shape([[-18,-20],[14,-22],[21,-13],[-13,-10]],Color("daceaa"),Color("a99d78"),.7)
	draw_arc(Vector2(1,-16),7,0,TAU,24,JADE,1,true)
	draw_line(Vector2(-6,-18),Vector2(9,-15),INK,.8,true)
	shape([[22,-28],[27,-34],[32,-26],[26,-22]],Color("bd9871"))
	for i in range(3):
		draw_line(Vector2(-26+i*4,-27),Vector2(-22+i*4,-21),EDGE,1.2,true)

func tool_shed() -> void:
	shape([[-25,3],[-25,-42],[26,-41],[25,3]],WOOD)
	for x in [-17,-7,4,15]:
		draw_line(Vector2(x,-37),Vector2(x,0),INK,.8,true)
	shape([[-34,-40],[-1,-65],[35,-39]],JADE)
	shape([[-25,-41],[0,-58],[26,-40]],JADE.lightened(.1),JADE,1)
	shape([[-12,2],[-12,-27],[8,-27],[8,2]],Color("555a44"))
	for x in [17,25]:
		draw_line(Vector2(x,6),Vector2(x-4,-30),INK,2.6,true)
		draw_line(Vector2(x,5),Vector2(x-4,-30),EDGE,1.1,true)
	draw_line(Vector2(11,-29),Vector2(24,-31),INK,3,true)
	draw_circle(Vector2(-22,0),7,INK,true,-1,true)
	draw_circle(Vector2(-22,-1),5.5,Color("bdab7e"),true,-1,true)

func waypost() -> void:
	draw_line(Vector2(0,7),Vector2(0,-44),INK,4,true)
	draw_line(Vector2(0,6),Vector2(0,-43),WOOD,2,true)
	shape([[-22,-43],[18,-43],[26,-36],[18,-30],[-22,-30]],Color("c4b088"))
	draw_string(GuPixelUI.HAND_FONT,Vector2(-20,-33),"CỔ TRẬN ↑",HORIZONTAL_ALIGNMENT_CENTER,39,9,INK)

func ruin_banner() -> void:
	draw_line(Vector2(0,5),Vector2(0,-70),INK,3,true)
	var sway := sin(phase*1.1)*2
	shape([[1,-65],[25+sway,-62],[21+sway,-27],[15,-33],[8,-25],[1,-30]],Color("a98d66"))
	draw_arc(Vector2(12,-49),7,0,TAU,30,INK,1,true)
	draw_line(Vector2(7,-53),Vector2(17,-44),INK,1,true)
