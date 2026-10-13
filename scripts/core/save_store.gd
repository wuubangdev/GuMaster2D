class_name SaveStore
extends RefCounted

const DEFAULT_PATH: String = "user://gu_master_profile.json"
var path: String
var last_error: String = ""

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func save_profile(profile: Dictionary) -> bool:
	last_error = ""
	var absolute := ProjectSettings.globalize_path(path)
	var parent := absolute.get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Không thể tạo tệp lưu"
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var copied := DirAccess.copy_absolute(absolute, absolute + ".bak")
		if copied != OK:
			last_error = "Không thể tạo bản dự phòng"
			return false
		if DirAccess.remove_absolute(absolute) != OK:
			last_error = "Không thể thay thế bản lưu"
			return false
	if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
		last_error = "Không thể hoàn tất lưu; còn bản .bak"
		return false
	return true

func load_profile() -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(candidate)) != OK:
				continue
			var decoded = parser.data
			if decoded is Dictionary and decoded.get("schema", 0) == 1 and decoded.get("inventory") is Dictionary and decoded.get("progress") is Dictionary:
				var validator := LocalAuthority.new()
				if validator.load_profile(decoded):
					return decoded
	return {}

func clear_profile() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var target := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(target)
