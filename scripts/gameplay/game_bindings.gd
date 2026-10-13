class_name GameBindings
extends RefCounted
## One source for keyboard skill lookup and all hotbar/socket labels.

const SKILL_KEYS: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const KEYPAD_KEYS: Array[int] = [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_KP_0]
const MOVE_KEYS: Dictionary = {KEY_W: Vector2.UP, KEY_A: Vector2.LEFT, KEY_S: Vector2.DOWN, KEY_D: Vector2.RIGHT}

static func skill_slot(code: int) -> int:
	var slot := SKILL_KEYS.find(code)
	return slot if slot >= 0 else KEYPAD_KEYS.find(code)

static func skill_label(slot: int) -> String:
	return str((slot + 1) % 10) if slot >= 0 and slot < SKILL_KEYS.size() else ""
