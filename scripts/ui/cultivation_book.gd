class_name CultivationBook
extends PanelContainer
## View/controller for the three cultivation pages. Never mutates the simulation.
signal command_requested(command: String, args: Dictionary)
signal close_requested

var simulation: LocalAuthority
var page: String = "travel"
var selected_id: String = "gu_1"
var tabs: Dictionary = {}
var content: VBoxContainer
var scroll: ScrollContainer
var summary: Label
var story: Label
var timers: Array[Dictionary] = []
var refresh_left := 0.0
var signature := ""
var release_pen := -1
var regional_atlas: RegionalAtlas
var atlas_selection := "camp"
var atlas_mode := "region"
var atlas_info: Label
var atlas_go: Button
var atlas_jump: Button
var gu_workshop: GuCultivationWorkshop

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	name = "CultivationBook"
	add_theme_stylebox_override("panel", GuPixelUI.frame("panel", 20))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var title := label("CỔ GIỚI  /  HÀNH TRÌNH TU LUYỆN", 25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	button(heading, "Đóng [Esc]", func(): close_requested.emit())
	story = label("", 15)
	box.add_child(story)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	box.add_child(navigation)
	for id in ["travel", "gu", "farm"]:
		var caption: String = {"travel": "01  Địa đồ [T]", "gu": "02  Bảng Cổ [G]", "farm": "03  Bí cảnh [H]"}[id]
		var tab := button(navigation, caption, func(): open_page(id))
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs[id] = tab
	summary = label("", 14, GuPixelUI.JADE)
	box.add_child(summary)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	gu_workshop = GuCultivationWorkshop.new()
	box.add_child(gu_workshop)
	gu_workshop.setup(simulation)
	gu_workshop.command_requested.connect(request)
	gu_workshop.selection_changed.connect(func(id: String): selected_id = id)
	gu_workshop.hide()
	get_viewport().size_changed.connect(fit)
	fit()
	hide()

func fit() -> void:
	var viewport := get_viewport_rect().size
	var dimensions := Vector2(minf(940, viewport.x - 48), minf(650, viewport.y - 64))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = (viewport - dimensions) * .5
	size = dimensions

func open_page(value: String) -> void:
	gu_workshop.close_overlays()
	release_pen = -1
	page = value
	fit()
	scroll.scroll_vertical = 0
	signature = ""
	refresh()

func _process(delta: float) -> void:
	if not visible or simulation == null:
		return
	var expected := Vector2(minf(940, get_viewport_rect().size.x - 48), minf(650, get_viewport_rect().size.y - 64))
	if not size.is_equal_approx(expected):
		fit()
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = .2
		refresh()
		for entry in timers:
			var left := float(entry["state"]["left"])
			entry["label"].text = "Sẵn sàng thu hoạch" if left <= 0 else "Đang lớn • còn %ds" % ceili(left)

func refresh() -> void:
	var state := simulation.expedition
	var current := "%s:%s:%d:%d:%d:%d:%s:%s" % [page, state.region, state.revision, simulation.inventory.version, int(simulation.player["currency"]), int(simulation.progress["kills"]), simulation.at_portal(), simulation.world.is_safe(simulation.player["cell"])]
	# Timer completion changes available buttons; do not rebuild on every tick.
	for entry in state.plots + state.animals:
		current += ":" + str(float(entry["left"]) <= 0.0)
	current += ":" + str(simulation.journey.revision) + ":" + str(simulation.quests.revision)
	current += ":" + str(simulation.combat_left > 0) + ":" + str(simulation.player["dead"])
	current += ":" + str(not simulation.capture.is_empty())
	current += ":" + selected_id + ":" + str(simulation.player["level"]) + ":" + str(simulation.player["max_hp"])
	var selected_gu := simulation.inventory.find_instance(selected_id)
	current += ":" + str(int(selected_gu.get("hunger", 0)))
	if signature == current:
		return
	signature = current
	for id in tabs:
		tabs[id].set_pressed_no_signal(id == page)
	story.text = str(ExpeditionModel.REGIONS[state.region]["name"]) + "   •   " + ("Chương II • Gieo lại linh mạch" if state.realm_unlocked else "Chương I • Mảnh Thanh Nang")
	scroll.visible = page != "gu"
	gu_workshop.visible = page == "gu"
	summary.visible = page != "gu"
	story.visible = page != "gu"
	if page == "gu":
		build_gu()
		return
	var old_scroll := scroll.scroll_vertical
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	timers.clear()
	summary.text = "%d bạc   /   %d linh thảo   /   %d nguyên thạch   /   %d cổ tinh   /   %d tơ tằm" % [simulation.player["currency"], amount("herb"), amount("stone"), amount("essence"), amount("silk")]
	match page:
		"travel": build_travel()
		"gu": build_gu()
		"farm": build_farm()
	scroll.set_deferred("scroll_vertical", old_scroll)

func build_travel() -> void:
	var modes := HBoxContainer.new()
	content.add_child(modes)
	for mode in ["region","routes"]:
		var item := button(modes,"Trong vùng • Bãi farm & trạm" if mode == "region" else "Sang vùng khác • Cổ trận",func(): atlas_mode = mode; signature = ""; scroll.scroll_vertical = 0; refresh())
		item.disabled = atlas_mode == mode
	if atlas_mode == "region":
		build_regional_atlas()
		return
	var atlas := Atlas.new()
	atlas.custom_minimum_size.y = 112
	atlas.current = simulation.expedition.region
	atlas.realm_open = simulation.expedition.realm_unlocked
	content.add_child(atlas)
	content.add_child(label("Dịch chuyển tại trại ngọc hoặc cổ trận. Rời giao chiến trước khi khởi hành.", 15))
	for id in ExpeditionModel.REGIONS:
		var row := section(str(ExpeditionModel.REGIONS[id]["name"]))
		row.add_child(label(str(ExpeditionModel.REGIONS[id]["subtitle"]) + "\n" + str(ExpeditionModel.REGIONS[id]["reward"]), 15, GuPixelUI.MUTED))
		var reason := ""
		if id == simulation.expedition.region:
			reason = "Đang ở đây"
		elif id == "ruins" and int(simulation.progress["kills"]) < 1:
			reason = "Cần hạ 1 sói ở Thanh Mao Sơn"
		elif id == "realm" and not simulation.expedition.realm_unlocked:
			reason = "Cần phục hồi cổ trận ở Tam Vương Cổ Địa"
		elif not simulation.at_portal():
			reason = "Hãy về trại hoặc đến cổ trận"
		var action := button(row, "Dịch chuyển" if reason == "" else reason, func(): request("travel", {"region": id}))
		action.disabled = reason != "" or blocked()
	if not simulation.expedition.realm_unlocked:
		var quest := section("Chương I • Mảnh Thanh Nang")
		quest.add_child(label("Cổ trận giữ dấu tích một bí cảnh bỏ hoang. Hạ sói cổ trận để gom cổ tinh, rồi phục hồi ấn ở trung tâm Tam Vương Cổ Địa.\nHạ sói %d / 3   •   Cổ tinh %d / 2   •   Phần thưởng: mở bí cảnh, 6 hạt giống, 3 linh quả." % [mini(3, int(simulation.progress["kills"])), amount("essence")], 16))
		button(quest, "Phục hồi tại cổ trận • tốn 2 cổ tinh", func(): request("unlock", {}))
	if not simulation.at_portal():
		button(content, "Dẫn đường về trại ngọc", func(): request("navigate", {"cell": WorldGrid.SPAWN}))
	if simulation.expedition.region == "ruins":
		button(content, "Dẫn đường đến cổ trận", func(): request("navigate", {"cell": WorldGrid.SHRINE}))

func build_gu() -> void:
	gu_workshop.present(selected_id)
	selected_id = gu_workshop.selected_id

func build_farm() -> void:
	var irrigation := button(content,"Tưới toàn bộ linh điền" if simulation.quests.has_unlock("irrigation") else "Linh mương • mở bằng quest Khơi lại dòng Thanh Nang",func(): request("irrigate",{}))
	irrigation.disabled = not simulation.quests.has_unlock("irrigation") or simulation.expedition.region != "realm" or blocked()
	if not simulation.expedition.realm_unlocked:
		var locked := section("Thanh Nang đang ngủ yên")
		locked.add_child(label("Truyền thuyết kể về Cổ sư giấu một khu vườn trong lòng Thanh Nang. Lần theo dấu tích ở Tam Vương Cổ Địa Cổ Trận để dựng lại điền viên của riêng bạn.", 20))
		button(locked, "Xem nhiệm vụ mở bí cảnh", func(): open_page("travel"))
		return
	var has_rank_two := simulation.inventory.gu.any(func(item: Dictionary): return int(item["rank"]) >= 2)
	content.add_child(label("Linh mạch hồi sinh • thu hoạch %d / 3 vụ • %s" % [mini(3, simulation.expedition.harvests), "đã luyện Cổ bậc II" if has_rank_two else "hãy luyện một Cổ bậc II"], 20, GuPixelUI.JADE))
	content.add_child(label("Điền viên • 6 ô đất / 2 chuồng\nGieo → tưới → thu sản vật và nhận lại hạt. Thú ăn 1 linh quả mỗi lượt. Thời gian chạy khi chơi, dừng khi tạm dừng/thoát.", 16))
	var onsite := simulation.expedition.region == "realm" and not blocked()
	if not onsite:
		content.add_child(label("Về Thanh Nang để chăm sóc. Bạn vẫn xem được thời gian phát triển từ vùng khác.", 16, GuPixelUI.VERMILION))
	var supply := HBoxContainer.new()
	content.add_child(supply)
	for crop in ExpeditionModel.CROPS:
		var definition: Dictionary = ExpeditionModel.CROPS[crop]
		var purchase := button(supply, "%s ×%d • mua %d bạc" % [definition["name"], amount(str(definition["seed"])), definition["price"]], func(): request("buy_seed", {"crop": crop}))
		purchase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		purchase.disabled = not onsite or int(simulation.player["currency"]) < int(definition["price"])
	for index in range(simulation.expedition.plots.size()):
		var plot := simulation.expedition.plots[index]
		var row := section("Ô đất %02d" % (index + 1))
		if plot["crop"] == "":
			var choices := HBoxContainer.new()
			row.add_child(choices)
			for crop in ExpeditionModel.CROPS:
				var definition: Dictionary = ExpeditionModel.CROPS[crop]
				var sow := button(choices, "Gieo " + str(definition["name"]), func(): request("plant", {"plot": index, "crop": crop}))
				sow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sow.disabled = not onsite or amount(str(definition["seed"])) < 1
		else:
			var definition: Dictionary = ExpeditionModel.CROPS[plot["crop"]]
			row.add_child(label("%s • thu %d %s" % [definition["name"], definition["yield"], ExpeditionModel.material_name(str(definition["product"]))], 17))
			if not bool(plot["watered"]):
				var water := button(row, "Tưới nước • miễn phí", func(): request("water", {"plot": index}))
				water.disabled = not onsite
			elif float(plot["left"]) > 0:
				add_timer(row, plot)
			else:
				var harvest := button(row, "Thu hoạch", func(): request("harvest", {"plot": index}))
				harvest.disabled = not onsite
	for index in range(simulation.expedition.animals.size()):
		var animal := simulation.expedition.animals[index]
		var row := section("Chuồng %d" % (index + 1))
		if animal["kind"] == "":
			var choices := HBoxContainer.new()
			row.add_child(choices)
			for kind in ExpeditionModel.ANIMALS:
				var definition: Dictionary = ExpeditionModel.ANIMALS[kind]
				var buy := button(choices, "%s • %d bạc" % [definition["name"], definition["price"]], func(): request("buy_animal", {"pen": index, "kind": kind}))
				buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				buy.disabled = not onsite or int(simulation.player["currency"]) < int(definition["price"])
		else:
			var definition: Dictionary = ExpeditionModel.ANIMALS[animal["kind"]]
			row.add_child(label("%s • mỗi lượt nhận %d %s" % [definition["name"], definition["yield"], ExpeditionModel.material_name(str(definition["product"]))], 17))
			if not bool(animal["fed"]):
				var feed := button(row, "Cho ăn • 1 linh quả (có %d)" % amount("fruit"), func(): request("feed_animal", {"pen": index}))
				feed.disabled = not onsite or amount("fruit") < 1
				var release := button(row, "Xác nhận thả • không hoàn bạc" if release_pen == index else "Thả vật nuôi để đổi loài…", func():
					if release_pen == index:
						request("release_animal", {"pen": index})
						release_pen = -1
					else:
						release_pen = index
						signature = ""
						refresh())
				release.disabled = not onsite
			elif float(animal["left"]) > 0:
				add_timer(row, animal)
			else:
				var collect := button(row, "Thu sản vật", func(): request("collect_animal", {"pen": index}))
				collect.disabled = not onsite
	var exchange := button(content, "Đổi 2 trứng linh kê → 3 nguyên thạch (có %d trứng)" % amount("egg"), func(): request("transmute", {}))
	exchange.disabled = not onsite or amount("egg") < 2


func blocked() -> bool:
	return bool(simulation.player["dead"]) or simulation.combat_left > 0 or not simulation.capture.is_empty()

func request(command: String, args: Dictionary) -> void:
	command_requested.emit(command, args)
	signature = ""
	refresh()

func amount(key: String) -> int:
	return int(simulation.inventory.materials.get(key, 0))

func cost_text(cost: Dictionary) -> String:
	var pieces := PackedStringArray()
	for key in cost:
		pieces.append("%s %d/%d" % [ExpeditionModel.material_name(key), int(simulation.player["currency"]) if key == "silver" else amount(key), cost[key]])
	return "   •   ".join(pieces) + "  (có/cần)"

func add_timer(parent: Node, state: Dictionary) -> void:
	var text := label("Đang lớn • còn %ds" % ceili(float(state["left"])), 16, GuPixelUI.JADE)
	parent.add_child(text)
	timers.append({"label": text, "state": state})

func section(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GuPixelUI.frame("slot", 12))
	content.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(label(title, 20))
	return box

static func label(text: String, font_size: int = 16, color: Color = GuPixelUI.INK) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(parent: Node, text: String, callback: Callable) -> Button:
	var node := GuInkButton.new()
	node.text = text
	node.custom_minimum_size = Vector2(maxf(110,GuPixelUI.HAND_FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+24), 34)
	node.add_theme_font_size_override("font_size", 16)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

class Atlas extends Control:
	var current := "forest"
	var realm_open := false
	func _draw() -> void:
		var points: Array[Vector2] = [Vector2(size.x * .16, 52), Vector2(size.x * .5, 52), Vector2(size.x * .84, 52)]
		for i in range(2):
			draw_line(points[i], points[i + 1], Color(GuPixelUI.INK_SOFT, .3), 2, true)
		for i in range(3):
			var at := points[i]
			var active: bool = current == ["forest", "ruins", "realm"][i]
			draw_circle(at, 26, GuPixelUI.JADE_LIGHT if active else GuPixelUI.PAPER_SHADE)
			draw_arc(at, 27, 0, TAU, 48, GuPixelUI.JADE if active else GuPixelUI.INK_SOFT, 1.5, true)
			if i == 0:
				for x in [-10, 0, 10]:
					draw_polyline(PackedVector2Array([at + Vector2(x-8,8),at + Vector2(x,-13),at + Vector2(x+8,8)]),GuPixelUI.JADE,2,true)
			elif i == 1:
				for x in [-11,11]:
					draw_rect(Rect2(at+Vector2(x-3,-12),Vector2(6,24)),GuPixelUI.INK_SOFT)
				draw_line(at+Vector2(-14,-14),at+Vector2(14,-14),GuPixelUI.INK_SOFT,3,true)
			else:
				draw_arc(at, 16, -.3, PI + .3, 32, GuPixelUI.JADE,2,true)
				for x in [-8,0,8]:
					draw_line(at+Vector2(x,10),at+Vector2(x,-8),GuPixelUI.JADE,1.5,true)
			var caption: String = ["THANH MAO SƠN", "TAM VƯƠNG", "THANH NANG" if realm_open else "BÍ CẢNH • CHƯA MỞ"][i]
			draw_string(GuPixelUI.HAND_FONT, at+Vector2(-95,48),caption,HORIZONTAL_ALIGNMENT_CENTER,190,15,GuPixelUI.INK)

func build_regional_atlas() -> void:
	regional_atlas = RegionalAtlas.new()
	regional_atlas.simulation = simulation
	regional_atlas.selected = atlas_selection
	content.add_child(regional_atlas)
	atlas_info = label("",16)
	content.add_child(atlas_info)
	var row := HBoxContainer.new()
	content.add_child(row)
	atlas_go = button(row,"Dẫn đường tới điểm đã chọn",func(): request("navigate",{"cell":WorldContent.cell(regional_atlas.current_site())}))
	atlas_jump = button(row,"Dịch chuyển nội vùng • 5 bạc",func(): request("waygate",{"id":regional_atlas.selected}))
	regional_atlas.site_selected.connect(func(id: String): atlas_selection = id; refresh_atlas_selection())
	refresh_atlas_selection()
	var listing := section("Bãi farm • chọn nơi phù hợp với nguyên liệu cần tìm")
	for camp in WorldContent.camps(simulation.expedition.region):
		var spec := Bestiary.species(camp["species"])
		var caption := "%s • Lv.%d • %s" % [camp["name"],spec["level"],ExpeditionModel.material_name(camp["resource"])]
		button(listing,caption,func(): atlas_selection = camp["id"]; regional_atlas.selected = atlas_selection; refresh_atlas_selection(); scroll.scroll_vertical = 0)

func refresh_atlas_selection() -> void:
	var site := regional_atlas.current_site()
	regional_atlas.selected = site["id"]
	atlas_selection = site["id"]
	var info := str(site["name"]) + " • "
	if site.has("species"):
		var spec := Bestiary.species(site["species"])
		info += str(site["description"]) + "\nRơi: " + QuestCatalog.reward_text(spec["loot"]) + " • hồi sinh %ds" % spec["respawn"]
	elif site.get("kind","") == "waypoint":
		info += "Đã ghi dấu" if site["id"] in simulation.journey.discovered else "Hãy đi đến trạm lần đầu để ghi dấu"
	else: info += "Vùng nghỉ và trò chuyện"
	atlas_info.text = info
	atlas_jump.visible = site.get("kind","") in ["waypoint","camp"]
	atlas_jump.disabled = blocked() or not simulation.quests.has_unlock("waygates") or not simulation.at_portal() or (site["id"] != "camp" and site["id"] not in simulation.journey.discovered)
	atlas_jump.tooltip_text = "Hoàn thành Đường qua rừng trúc; đứng tại cổ trận và chọn trạm đã khám phá."
	atlas_go.disabled = blocked()
	regional_atlas.queue_redraw()
