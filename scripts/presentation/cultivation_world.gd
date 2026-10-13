class_name CultivationWorld
extends Node2D
## Original vector field art; state comes from the cultivation simulation.
var simulation: LocalAuthority
var reduced_motion := false
var phase := 0.0
var refresh_left := 0.0
const INK := Color("393e32")
const SOIL := Color("76634b")
const JADE := Color("8dad84")
const LIGHT := Color("dddbac")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	if not reduced_motion:
		phase += delta
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = .1 if reduced_motion else 1.0 / 30.0
		queue_redraw()

func _draw() -> void:
	if simulation == null:
		return
	portal(WorldGrid.project(WorldGrid.SPAWN) + Vector2(0, 14), false)
	portal(WorldGrid.project(WorldGrid.SHRINE), true)
	if simulation.expedition.region != "realm":
		return
	for index in range(ExpeditionModel.PLOTS.size()):
		plot_art(WorldGrid.project(ExpeditionModel.PLOTS[index]), simulation.expedition.plots[index], index)
	for index in range(ExpeditionModel.PENS.size()):
		pen_art(WorldGrid.project(ExpeditionModel.PENS[index]), simulation.expedition.animals[index], index)

func portal(at: Vector2, shrine: bool) -> void:
	var pulse := 0.0 if reduced_motion else sin(phase * 1.5) * 1.5
	var radius := 21.0 if shrine else 15.0
	var color := Color("a9c9b3") if simulation.expedition.region != "ruins" else Color("d2b58d")
	for ring in range(2):
		var points := PackedVector2Array()
		for i in range(49):
			var angle := float(i) / 48 * TAU
			points.append(at + Vector2(cos(angle), sin(angle)*.6) * (radius + ring*5 + pulse))
		draw_polyline(points, Color(color, .45 if ring == 0 else .22), 1.1, true)
	for i in range(6):
		var point := at + Vector2(cos(i*TAU/6), sin(i*TAU/6)*.6)*(radius+3)
		draw_line(point+Vector2(-2,-3),point+Vector2(2,3),color,1.1,true)
	if simulation.interaction_npc() == "" and Vector2(simulation.player["cell"]).distance_to(WorldGrid.SHRINE if shrine else WorldGrid.SPAWN) <= 2.2:
		draw_sign(at + Vector2(0, 34), "E • Cổ trận" if shrine else "E • Dịch chuyển")

func plot_art(at: Vector2, state: Dictionary, index: int) -> void:
	var outline := PackedVector2Array([at+Vector2(-24,-14),at+Vector2(23,-16),at+Vector2(26,13),at+Vector2(-23,16),at+Vector2(-24,-14)])
	draw_colored_polygon(outline, SOIL.darkened(.15) if bool(state["watered"]) else SOIL)
	draw_polyline(outline,INK,1.4,true)
	for y in [-8,0,8]:
		draw_line(at+Vector2(-19,y),at+Vector2(19,y-1),Color("534d3c"),1.0,true)
	if state["crop"] == "":
		draw_string(GuPixelUI.HAND_FONT,at+Vector2(-5,5),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,LIGHT)
	else:
		var definition: Dictionary = ExpeditionModel.CROPS[state["crop"]]
		var growth := clampf(1 - float(state["left"]) / float(definition["time"]),0,1)
		var mature := bool(state["watered"]) and float(state["left"]) <= 0
		for sprout in range(4):
			var base := at + Vector2(-12 + (sprout%2)*23, -1 + (sprout/2)*10)
			var tip := base + Vector2(sin(phase*1.8+index+sprout)*1.1*(0 if reduced_motion else 1), -5 - growth*18)
			draw_line(base,tip,INK,2.4,true)
			draw_line(base,tip,JADE.darkened(.15),1.1,true)
			for leaf in range(2 + int(growth*2)):
				var middle := base.lerp(tip,.3+leaf*.17)
				var side := -1.0 if leaf%2 == 0 else 1.0
				var edge := middle+Vector2(side*(4+growth*5),-4-growth*2)
				var shape := PackedVector2Array([middle,middle+Vector2(side*3,-5),edge, middle+Vector2(side*4,0)])
				draw_colored_polygon(shape,JADE)
				draw_line(middle,edge,INK, .75,true)
			if growth > .65 and state["crop"] in ["flower", "fruit"]:
				if state["crop"] == "flower":
					for petal in range(5):
						draw_circle(tip+Vector2.from_angle(petal*TAU/5)*3,2.4,Color("e5cfad"),true,-1,true)
					draw_circle(tip,2,Color("d49b54"),true,-1,true)
				else:
					draw_circle(tip+Vector2(3,2),3.8,INK,true,-1,true)
					draw_circle(tip+Vector2(3,1.5),2.8,Color("b87450"),true,-1,true)
		if mature:
			draw_circle(at+Vector2(21,-15),3,LIGHT,true,-1,true)
	if Vector2(simulation.player["cell"]).distance_to(WorldGrid.unproject(at)) < 1.45:
		var caption := "E • Gieo hạt"
		if state["crop"] != "":
			caption = "E • Tưới" if not bool(state["watered"]) else ("E • Thu hoạch" if float(state["left"]) <= 0 else "%ds" % ceili(float(state["left"])))
		draw_sign(at + Vector2(0,29),caption)

func pen_art(at: Vector2, state: Dictionary, index: int) -> void:
	draw_rect(Rect2(at-Vector2(26,18),Vector2(52,36)),Color("99a580"))
	for y in [-18,18]:
		draw_line(at+Vector2(-27,y-8),at+Vector2(27,y-8),INK,2.4,true)
		draw_line(at+Vector2(-27,y-7),at+Vector2(27,y-7),Color("baa37b"),1.1,true)
		for x in [-26,-9,9,26]:
			draw_line(at+Vector2(x,y-13),at+Vector2(x,y+2),INK,3,true)
			draw_line(at+Vector2(x,y-12),at+Vector2(x,y+1),Color("bea57b"),1.4,true)
	if state["kind"] == "hen":
		var bob := 0.0 if reduced_motion else sin(phase*2 + index)*1.5
		var center := at+Vector2(-3,bob-1)
		draw_circle(center,10,INK,true,-1,true)
		draw_circle(center+Vector2(0,-1),8.6,Color("e2d8b1"),true,-1,true)
		draw_circle(center+Vector2(8,-7),5.5,INK,true,-1,true)
		draw_circle(center+Vector2(8,-7.5),4.4,Color("e2d8b1"),true,-1,true)
		draw_circle(center+Vector2(8,-13),2.7,Color("a55d45"),true,-1,true)
		draw_circle(center+Vector2(10,-9),1.1,INK,true,-1,true)
		draw_colored_polygon(PackedVector2Array([center+Vector2(13,-8),center+Vector2(18,-5),center+Vector2(12,-4)]),Color("b38c4f"))
		draw_arc(center+Vector2(-3,-1),5,0,PI,14,Color("847c60"),1,true)
		for x in [-4,2]:
			draw_line(center+Vector2(x,7),center+Vector2(x,12),INK,1.2,true)
	elif state["kind"] == "silkworm":
		for i in range(5):
			var point := at+Vector2(-10+i*5, -2+sin(i*.8+phase)*(.5 if not reduced_motion else 0))
			draw_circle(point,5.2,INK,true,-1,true)
			draw_circle(point+Vector2(0,-.7),4.3,Color("d0d6b1"),true,-1,true)
		draw_circle(at+Vector2(12,-4),1,INK,true,-1,true)
	else:
		draw_string(GuPixelUI.HAND_FONT,at+Vector2(-15,5),"Chuồng " + str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,INK)
	if bool(state["fed"]) and float(state["left"]) <= 0:
		draw_circle(at+Vector2(24,-22),3,LIGHT,true,-1,true)
	if Vector2(simulation.player["cell"]).distance_to(WorldGrid.unproject(at)) < 1.6:
		draw_sign(at+Vector2(0,32),"E • Chăm sóc")

func draw_sign(at: Vector2, caption: String) -> void:
	var width := GuPixelUI.HAND_FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_rect(Rect2(at+Vector2(-width*.5-4,-11),Vector2(width+8,16)),Color("dfd0ab"))
	draw_string(GuPixelUI.HAND_FONT,at+Vector2(-width*.5,1),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,INK)
