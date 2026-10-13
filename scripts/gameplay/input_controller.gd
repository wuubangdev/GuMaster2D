class_name GameInputController
extends Node

var manager: Node
var held_movement: Dictionary = {}
var sprint_held: bool = false

func movement_vector() -> Vector2:
	var direction := Vector2.ZERO
	for code in held_movement:
		direction += Vector2(GameBindings.MOVE_KEYS[code])
	return direction.normalized()

func update_movement() -> void:
	if manager.paused or manager.hud.has_open_window() or bool(manager.simulation.player["dead"]):
		clear_movement()
		return
	var direction := movement_vector()
	if not held_movement.is_empty() or manager.simulation.movement_direction != Vector2.ZERO:
		manager.simulation.set_move_direction(WorldGrid.unproject(direction), sprint_held)

func clear_movement() -> void:
	held_movement.clear()
	sprint_held = false
	manager.preview_held = false
	manager.simulation.set_move_direction(Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		# Use the event's viewport coordinates, also valid for replayed/networked input.
		manager.cursor_screen = event.position
		manager.pointer_in_world = false
		return
	if event is InputEventKey and GameBindings.MOVE_KEYS.has(event.physical_keycode):
		if not event.pressed:
			held_movement.erase(event.physical_keycode)
		elif not event.echo and not manager.paused and not manager.hud.has_open_window() and not bool(manager.simulation.player["dead"]):
			held_movement[event.physical_keycode] = true
		update_movement()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode == KEY_SHIFT:
		if not event.pressed:
			sprint_held = false
		elif not event.echo and not manager.paused and not manager.hud.has_open_window() and not bool(manager.simulation.player["dead"]):
			sprint_held = true
		update_movement()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.physical_keycode == KEY_ALT:
		if not event.pressed:
			manager.preview_held = false
		elif not event.echo and not manager.paused and not manager.hud.has_open_window() and not bool(manager.simulation.player["dead"]):
			manager.preview_held = true
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if manager.hud.has_open_window():
				manager.hud.close_top_window()
			else:
				manager.toggle_pause()
			get_viewport().set_input_as_handled()
		KEY_TAB, KEY_F4, KEY_I:
			manager.hud.toggle_bag()
			get_viewport().set_input_as_handled()
		KEY_F3:
			manager.hud.toggle_character()
			get_viewport().set_input_as_handled()
		KEY_F2:
			manager.hud.toggle_large_map()
			get_viewport().set_input_as_handled()
		KEY_F6:
			manager.hud.toggle_studio()
			get_viewport().set_input_as_handled()
		KEY_F11, KEY_J:
			manager.hud.toggle_journal()
			get_viewport().set_input_as_handled()
		KEY_G, KEY_T, KEY_H:
			manager.hud.toggle_cultivation({KEY_G: "gu", KEY_T: "travel", KEY_H: "farm"}[event.physical_keycode])
			get_viewport().set_input_as_handled()
		KEY_E:
			manager.interact()
			get_viewport().set_input_as_handled()
		KEY_R:
			manager.use_medicine()
			get_viewport().set_input_as_handled()
		KEY_M:
			manager.toggle_mute()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if manager.paused or manager.hud.has_open_window():
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		manager.remember_world_pointer(event.position)
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				var npc_id: String = manager.world_view.pick_npc(event.position) if event.button_index == MOUSE_BUTTON_LEFT else ""
				if npc_id != "":
					manager.talk_to_npc(npc_id)
					get_viewport().set_input_as_handled()
					return
				var selected: String = manager.world_view.pick_mob(event.position) if event.button_index == MOUSE_BUTTON_LEFT else ""
				if not selected.is_empty():
					manager.world_view.select_target(selected)
					if manager.simulation.world.is_safe(manager.simulation.player["cell"]):
						manager.hud.toast("Mục tiêu đã chọn. Dùng WASD hoặc click để rời trại, rồi nhấn 1.")
				else:
					var result: Dictionary = manager.simulation.move_to(manager.world_view.screen_to_cell(event.position))
					if bool(result.get("ok", false)):
						held_movement.clear()
						sprint_held = false
						manager.simulation.set_move_direction(Vector2.ZERO)
					manager.handle_result(result)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				manager.world_view.desired_zoom = minf(3.0, roundf(manager.world_view.desired_zoom) + 1.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				manager.world_view.desired_zoom = maxf(1.0, roundf(manager.world_view.desired_zoom) - 1.0)
	if event is InputEventKey and event.pressed and not event.echo:
		var slot := GameBindings.skill_slot(event.physical_keycode)
		if slot >= 0:
			if slot < manager.hud.skill_buttons.size():
				manager.use_skill(slot)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_C:
			manager.handle_result(manager.simulation.begin_capture(manager.world_view.selected_id))
			manager.flush_events()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F:
			manager.world_view.cycle_target()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and manager != null:
		clear_movement()
		manager.preview_held = false
		manager.pointer_in_world = false
