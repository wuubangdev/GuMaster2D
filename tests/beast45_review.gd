extends SceneTree
var stage: Node2D
var tiles: Array[BeastTile]=[]
var title: Label
var captures: Array[String]=[]
const DIRECTIONS := ["Nam","Tây nam","Tây","Tây bắc","Bắc","Đông bắc","Đông","Đông nam"]
class BeastTile extends Node2D:
	var species: String="wolf"
	var heading:=Vector2.DOWN
	var clip: String="idle"
	var progress:=0.0
	var sample:=0.0
	var direction_index:=0
	func _draw() -> void:
		var spec:=Bestiary.species(species)
		var state:={"species":species,"cell":Vector2.ZERO,"spawn":Vector2.ZERO,"aim":heading,"facing":heading,"state":"idle","hp":spec["hp"],"max_hp":spec["hp"],"windup_left":0.0,"attack_age":100.0,"attack_index":0,"last_attack":{},"dead":false,"presentation_hide_label":true}
		if clip=="windup":state["state"]="windup";state["windup_left"]=float(spec["windup"])*(1-progress)
		if clip=="strike":state["state"]="recovery";state["attack_age"]=progress*.42;state["last_attack"]={"style":spec["style"]}
		if clip=="death":state["dead"]=true
		# Review crop intentionally isolates anatomy; warnings have their own plate.
		if clip=="windup":state["attack_geometry"]={"kind":"spit","origin":Vector2.ZERO,"aim":Vector2(0,20),"centers":[Vector2(0,20)],"radius":.1,"range":1,"half_angle":.9,"facing":heading}
		var shadow:=PackedVector2Array()
		for i in range(32):shadow.append(Vector2.from_angle(i*TAU/32)*Vector2(25,7))
		draw_colored_polygon(shadow,Color(.08,.09,.08,.25))
		BeastArt.draw(self,state,sample,sample*TAU,1 if clip=="walk" else 0,false,.15 if clip=="hit" else 0,false,clip=="death",progress*.65)
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():quit(2);return
	root.size=Vector2i(1920,1720);root.content_scale_size=Vector2i(1920,1720)
	root.position=Vector2i(-1800,-1200)
	_run.call_deferred()
func label(text: String, at: Vector2, size: Vector2, font_size: int) -> Label:
	var item:=Label.new();item.text=text;item.position=at;item.size=size
	item.add_theme_font_override("font",GuPixelUI.HAND_FONT);item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",Color("ead8b2"));stage.add_child(item)
	return item
func save(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var path:="res://artifacts/"+name+".png"
	root.get_texture().get_image().save_png(path);captures.append(path)
func _run() -> void:
	root.size=Vector2i(1920,1720);root.content_scale_size=Vector2i(1920,1720)
	root.position=Vector2i(-1800,-1200)
	stage=Node2D.new();root.add_child(stage)
	var background:=ColorRect.new();background.color=Color("394239");background.size=Vector2(1920,1720);stage.add_child(background)
	title=label("CỔ GIỚI / QUÁI THÚ 0.45",Vector2(28,16),Vector2(1860,40),28)
	label("8 loài · 8 hướng · phần thân có chiều cao · bàn chân chạm đất · hoạt ảnh theo khớp",Vector2(28,56),Vector2(1860,32),18)
	for row in range(Bestiary.all().size()):
		var species: String=Bestiary.all().keys()[row]
		for d in range(8):
			var tile:=Control.new();tile.position=Vector2(d*240,100+row*200);tile.size=Vector2(240,200);tile.clip_contents=true;stage.add_child(tile)
			var cell_bg:=ColorRect.new();cell_bg.color=Color("414a3e") if (d+row)%2==0 else Color("3b453a");cell_bg.size=tile.size-Vector2(2,2);tile.add_child(cell_bg)
			var art:=BeastTile.new();art.species=species;art.heading=Vector2.DOWN.rotated(d*PI/4);art.position=Vector2(120,133);art.scale=Vector2.ONE*(1.35 if Bestiary.species(species).get("elite",false) else 1.8);tile.add_child(art);tiles.append(art)
			var name:=Label.new();name.text=Bestiary.species(species)["name"]+" · "+DIRECTIONS[d];name.position=Vector2(8,179);name.add_theme_font_override("font",GuPixelUI.HAND_FONT);name.add_theme_font_size_override("font_size",12);name.add_theme_color_override("font_color",Color("e2d2af"));tile.add_child(name)
	for clip in ["idle","walk","windup","strike","hit","death"]:
		title.text="CỔ GIỚI / QUÁI THÚ 0.45 · "+clip
		for tile in tiles:tile.clip=clip;tile.progress=.74 if clip=="windup" else .5;tile.sample=.37;tile.queue_redraw()
		await save("beast45_"+clip)
	for clip in ["walk","attack"]:
		DirAccess.make_dir_recursive_absolute("res://artifacts/beast45_"+clip+"_motion")
		for frame in range(24):
			title.text="CỔ GIỚI / QUÁI THÚ 0.45 · %s %02d / 24" % [clip,frame+1]
			for tile in tiles:
				tile.sample=float(frame)/24
				if clip=="walk":tile.clip="walk";tile.progress=0
				elif frame<16:tile.clip="windup";tile.progress=float(frame)/16
				else:tile.clip="strike";tile.progress=float(frame-16)/8
				tile.queue_redraw()
			await save("beast45_"+clip+"_motion/frame%03d" % frame)
	FileAccess.open("res://artifacts/beast45_native.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":captures,"directions":8,"species":8,"states":6,"motion_frames":48,"native_renderer":"Godot 4.7.2"},"  "))
	print("BEAST45_NATIVE ",captures.size()," captures")
	quit()
