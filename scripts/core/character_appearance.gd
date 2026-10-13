class_name GuCharacterAppearance
extends RefCounted
## Saved cosmetic identity. It never changes equipment, damage or character stats.

const DEFAULT: Dictionary = {"body": "male", "outfit": "jade", "weapon": "sword", "hair": "topknot", "boots": "cloth", "hat": "none"}
const LEGACY_CATEGORIES: Array[String] = ["body", "outfit", "weapon", "hair"]
const OPTIONS: Dictionary = {
	"body": [{"id": "male", "label": "Nam"}, {"id": "female", "label": "Nữ"}],
	"outfit": [{"id": "jade", "label": "Thanh Ngọc"}, {"id": "crimson", "label": "Xích Vân"}, {"id": "ivory", "label": "Bạch Vũ"}],
	"weapon": [{"id": "sword", "label": "Trường kiếm"}, {"id": "spear", "label": "Trường thương"}, {"id": "unarmed", "label": "Tay không"}],
	"hair": [{"id": "topknot", "label": "Búi tóc"}, {"id": "ponytail", "label": "Tóc đuôi ngựa"}],
	"boots": [{"id": "cloth", "label": "Giày vải"}, {"id": "leather", "label": "Ủng da"}],
	"hat": [{"id": "none", "label": "Không đội"}, {"id": "bamboo", "label": "Nón lá"}, {"id": "sect", "label": "Quan mây"}]
}

static func default_data() -> Dictionary:
	return DEFAULT.duplicate(true)

static func catalog(category: String) -> Array:
	return OPTIONS.get(category, []).duplicate(true)

static func validate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	# Four-field descriptors are the exact schema used by existing local saves
	# and callers. Accept them at the boundary, then normalize before storage.
	var categories: Array = DEFAULT.keys() if value.size() == DEFAULT.size() else LEGACY_CATEGORIES if value.size() == LEGACY_CATEGORIES.size() else []
	if categories.is_empty():
		return false
	for category in categories:
		if not value.get(category) is String:
			return false
		var found := false
		for option in OPTIONS[category]:
			if value[category] == option["id"]:
				found = true
				break
		if not found:
			return false
	return true

static func sanitize(value: Variant) -> Dictionary:
	if not validate(value):
		return default_data()
	var normalized := default_data()
	normalized.merge(value, true)
	return normalized

static func restore_saved(value: Variant, accessory_value: Variant = {}) -> Dictionary:
	# The profile keeps its original four-field appearance for old game builds;
	# accessories live in a separate optional object. Restore each cosmetic slot
	# independently so an unknown catalog ID cannot invalidate progression.
	if not value is Dictionary or not accessory_value is Dictionary:
		return {}
	for required in LEGACY_CATEGORIES:
		if not value.has(required):
			return {}
	for key in value.keys():
		if not DEFAULT.has(key):
			return {}
	for key in accessory_value.keys():
		if key not in ["boots", "hat"]:
			return {}
	var restored := default_data()
	for category in DEFAULT:
		if value.has(category):
			if _known_id(category, value[category]):
				restored[category] = value[category]
	for category in ["boots", "hat"]:
		if accessory_value.has(category):
			if _known_id(category, accessory_value[category]):
				restored[category] = accessory_value[category]
	return restored

static func _known_id(category: String, value: Variant) -> bool:
	if not value is String:
		return false
	for option in OPTIONS.get(category, []):
		if value == option["id"]:
			return true
	return false

static func label(category: String, id: String) -> String:
	for option in OPTIONS.get(category, []):
		if option["id"] == id:
			return str(option["label"])
	return ""
