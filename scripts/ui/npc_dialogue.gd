class_name NpcDialogue
extends GuLacquerPanel
signal action_requested(command: String, quest_id: String)
signal close_requested
var simulation: LocalAuthority
var npc_id := ""
var title: Label
var role: Label
var speech: Label
var options: VBoxContainer
var portrait: GuIllustratedCharacterView
var portrait_host: Control
var reveal := 0.0
var phase := 0.0
var reduced_motion := false
var current_quest := ""
var current_topic := -1
var flash_text := ""
var objective_signature := ""

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	name = "NpcDialogue"
	var margins := StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		margins.set_content_margin(side,18)
	add_theme_stylebox_override("panel",margins)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	add_child(row)
	portrait_host = Control.new()
	portrait_host.custom_minimum_size = Vector2(110,180)
	portrait_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait_host)
	portrait = GuIllustratedCharacterView.new()
	portrait_host.add_child(portrait)
	portrait.configure(256,105)
	portrait.position = Vector2(55,145)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",7)
	row.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	title = CultivationBook.label("",23,GuPixelUI.JADE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	CultivationBook.button(header,"Tạm biệt [Esc]",func(): close_requested.emit())
	role = CultivationBook.label("",14,GuPixelUI.MUTED)
	body.add_child(role)
	speech = CultivationBook.label("",18)
	speech.custom_minimum_size.y = 88
	speech.mouse_filter = Control.MOUSE_FILTER_STOP
	speech.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			reveal = 100000
			speech.visible_characters = -1)
	body.add_child(speech)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation",5)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options)
	get_viewport().size_changed.connect(fit)
	hide()

func fit() -> void:
	var bounds := get_viewport_rect().size
	var dimensions := Vector2(minf(940,bounds.x-48),minf(390,bounds.y-100))
	position = Vector2((bounds.x-dimensions.x)*.5,bounds.y-dimensions.y-28)
	size = dimensions

func begin(id: String) -> void:
	npc_id = id
	current_quest = ""
	current_topic = -1
	flash_text = ""
	var data := QuestCatalog.npc(id)
	title.text = str(data["name"])
	role.text = str(data["role"]) + " • chạm lời thoại để hiện hết"
	portrait.set_appearance(GuCharacterAppearance.sanitize(data["appearance"]))
	show()
	fit()
	show_root()

func _process(delta: float) -> void:
	if not visible:
		return
	fit()
	if current_quest != "" and objective_signature != _objective_signature(current_quest):
		show_quest(current_quest)
	phase += delta if not reduced_motion else 0
	reveal += delta*45
	speech.visible_characters = -1 if reduced_motion else int(reveal)
	var speaking := speech.visible_characters >= 0 and speech.visible_characters < speech.get_total_character_count()
	portrait.present_smooth("channel" if speaking else "idle",phase*.65,Vector2(-.35,1),reduced_motion,delta)

func _clear(text: String) -> void:
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()
	speech.text = text
	speech.visible_characters = -1 if reduced_motion else 0
	reveal = 0

func show_root() -> void:
	current_quest = ""
	current_topic = -1
	_clear(flash_text if flash_text != "" else str(QuestCatalog.npc(npc_id)["greeting"]))
	flash_text = ""
	for definition in QuestCatalog.quests():
		var id := str(definition["id"])
		if npc_id not in [definition["giver"],definition["turn_in"]]: continue
		var status := simulation.quests.status(id,simulation)
		if status in ["locked","claimed"]: continue
		if status == "available" and definition["giver"] != npc_id: continue
		var prefix := "Nhận nhiệm vụ" if status == "available" else ("Trả nhiệm vụ" if status == "ready" and definition["turn_in"] == npc_id else "Tiến độ")
		CultivationBook.button(options,prefix + " • " + str(definition["title"]),func(): show_quest(id))
	var topics: Array = QuestCatalog.npc(npc_id)["topics"]
	for index in range(topics.size()):
		CultivationBook.button(options,str(topics[index]["label"]),func(): show_topic(index))

func show_topic(index: int) -> void:
	current_topic = index
	current_quest = ""
	_clear(str(QuestCatalog.npc(npc_id)["topics"][index]["text"]))
	CultivationBook.button(options,"Tôi còn muốn hỏi…",show_root)

func show_quest(id: String) -> void:
	current_quest = id
	objective_signature = _objective_signature(id)
	current_topic = -1
	var definition := QuestCatalog.quest(id)
	var status := simulation.quests.status(id,simulation)
	_clear(str(definition["offer"]) if status == "available" else str(definition["description"]))
	options.add_child(CultivationBook.label("%s • %d / %d" % [definition["objective"],simulation.quests.value(id,simulation),definition["goal"]],16,GuPixelUI.JADE))
	options.add_child(CultivationBook.label("Thưởng: " + QuestCatalog.reward_text(definition["reward"],definition.get("unlocks",[])),15,GuPixelUI.MUTED))
	if status == "available" and definition["giver"] == npc_id:
		CultivationBook.button(options,"Nhận nhiệm vụ",func(): action_requested.emit("accept",id))
	elif status == "ready" and definition["turn_in"] == npc_id:
		CultivationBook.button(options,"Hoàn thành & nhận thưởng",func(): action_requested.emit("claim",id))
	elif status in ["active","ready"]:
		var turn_in := str(QuestCatalog.npc(str(definition["turn_in"]))["name"])
		options.add_child(CultivationBook.label("Trả cho " + turn_in + (" • đã đủ điều kiện" if status == "ready" else " • chưa đủ mục tiêu"),15))
		CultivationBook.button(options,"Theo dõi nhiệm vụ này",func(): action_requested.emit("track",id))
	CultivationBook.button(options,"Quay lại",show_root)

func command_result(command: String, id: String) -> void:
	if command == "claim":
		flash_text = str(QuestCatalog.quest(id)["complete"])
		show_root()
	else:
		show_quest(id)

func _objective_signature(id: String) -> String:
	return simulation.quests.status(id,simulation) + str(simulation.quests.value(id,simulation))
