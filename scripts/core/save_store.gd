class_name SaveStore
extends RefCounted
## Atomic replacement with last-known-good backup. No wall-clock rewards.
static func save(data: Dictionary, path: String = "user://save.json") -> bool:
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema": 1, "payload": data}))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path + ".bak")
		if DirAccess.rename_absolute(path, path + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(temp_path, path) == OK

static func load_save(path: String = "user://save.json") -> Dictionary:
	for candidate: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK:
			continue
		var parsed: Variant = parser.data
		if parsed is Dictionary and int(parsed.get("schema", 0)) == 1 and parsed.get("payload") is Dictionary:
			return parsed.payload
	return {}
