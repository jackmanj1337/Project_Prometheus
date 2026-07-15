extends RefCounted

const MANIFEST_NAME := "resource_manifest.json"


# Export-safe resource listing. In editor/headless runs we can still fall back
# to directory enumeration, but exported builds should resolve through the
# manifest because res:// directory listing is not reliable inside packed PCKs.
static func load_paths(dir_path: String) -> Array[String]:
	var manifest_paths := _load_manifest_paths(dir_path)
	if not manifest_paths.is_empty():
		return manifest_paths
	return _list_directory_paths(dir_path)


static func _load_manifest_paths(dir_path: String) -> Array[String]:
	var manifest_path := dir_path.path_join(MANIFEST_NAME)
	if not FileAccess.file_exists(manifest_path):
		return []
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		push_error("ResourceManifest: cannot open manifest: " + manifest_path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("ResourceManifest: manifest must be an array: " + manifest_path)
		return []
	var out: Array[String] = []
	for entry in parsed:
		if typeof(entry) != TYPE_STRING:
			push_error("ResourceManifest: manifest entry must be a string: %s" % manifest_path)
			continue
		out.append(dir_path.path_join(String(entry)))
	return out


static func _list_directory_paths(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for fname2 in files:
		out.append(dir_path.path_join(fname2))
	return out
