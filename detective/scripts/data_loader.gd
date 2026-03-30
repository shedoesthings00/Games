class_name StoryDataLoader
extends RefCounted


static func load_json(path: String) -> Variant:
	var f: Variant = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("No se puede abrir: %s" % path)
		return null
	var txt: String = (f as FileAccess).get_as_text()
	var data: Variant = JSON.parse_string(txt)
	if data == null:
		push_error("JSON inválido: %s" % path)
	return data
