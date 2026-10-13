class_name NpcQuestList
extends ScrollContainer
signal quest_requested(command: String, id: String)
var simulation: LocalAuthority
var content: VBoxContainer
var signature := ""
var category := "all"

func setup(authority: LocalAuthority) -> void:
	simulation = authority
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	add_child(content)

func refresh() -> void:
	var next := JSON.stringify(simulation.quests.to_data()) + str(simulation.progress) + str(simulation.expedition.harvests) + str(simulation.expedition.realm_unlocked) + str(simulation.inventory.version) + str(simulation.journey.revision) + category
	if next == signature: return
	signature = next
	var old_scroll := scroll_vertical
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var tabs := HBoxContainer.new()
	content.add_child(tabs)
	for value in ["all","main","side"]:
		var tab := CultivationBook.button(tabs,{"all":"Tất cả","main":"Chính tuyến","side":"Nhiệm vụ phụ"}[value],func(): category = value; refresh())
		tab.disabled = category == value
	content.add_child(CultivationBook.label("CỔ GIỚI • %d NHIỆM VỤ" % QuestCatalog.quests().size(),18,GuPixelUI.JADE))
	for definition in QuestCatalog.quests():
		if category != "all" and definition.get("category","main") != category: continue
		var id := str(definition["id"])
		var status := simulation.quests.status(id,simulation)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",GuPixelUI.frame("slot",10))
		content.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",6)
		panel.add_child(box)
		var caption: String = {"locked":"Chưa mở","available":"Có thể nhận","active":"Đang làm","ready":"Chờ trả","claimed":"Đã nhận thưởng"}[status]
		box.add_child(CultivationBook.label(("Chính • " if definition.get("category","main") == "main" else "Phụ • ") + str(definition["title"]) + " • " + caption,20))
		if status == "locked":
			var names := PackedStringArray()
			for requirement in definition["requires"]:
				names.append(str(QuestCatalog.quest(requirement)["title"]))
			box.add_child(CultivationBook.label("Hoàn thành: " + ", ".join(names),15,GuPixelUI.MUTED))
			continue
		box.add_child(CultivationBook.label(str(definition["description"]),16))
		box.add_child(CultivationBook.label("%s • %d/%d" % [definition["objective"],simulation.quests.value(id,simulation),definition["goal"]],16,GuPixelUI.JADE))
		box.add_child(CultivationBook.label("Thưởng: " + QuestCatalog.reward_text(definition["reward"],definition.get("unlocks",[])),14,GuPixelUI.MUTED))
		if status == "claimed": continue
		var row := HBoxContainer.new()
		box.add_child(row)
		if status != "available":
			var track := CultivationBook.button(row,"Đang theo dõi" if simulation.quests.tracked == id else "Theo dõi",func(): quest_requested.emit("track",id))
			track.disabled = simulation.quests.tracked == id
		var destination := QuestCatalog.objective_location(id,simulation)
		CultivationBook.button(row,"Tìm " + str(destination["name"]),func(): quest_requested.emit("navigate",id))
	scroll_vertical = old_scroll
