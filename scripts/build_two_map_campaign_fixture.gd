extends SceneTree
# Rebuilds the committed player-facing ZIP from its readable source directory.

const SOURCE := "res://test_fixtures/campaign_packs/two_map_skirmish"
const OUTPUT := "res://test_fixtures/campaign_packs/two-map-skirmish-1.0.zip"


func _init() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)
	var packer := ZIPPacker.new()
	if packer.open(output_path) != OK:
		push_error("Could not open campaign fixture ZIP for writing")
		quit(1)
		return
	var files: Array[String] = []
	_collect_files(ProjectSettings.globalize_path(SOURCE), files)
	files.sort()
	for path in files:
		var relative := path.trim_prefix(ProjectSettings.globalize_path(SOURCE) + "/")
		packer.start_file("two_map_skirmish/" + relative)
		var file := FileAccess.open(path, FileAccess.READ)
		packer.write_file(file.get_buffer(file.get_length()))
		packer.close_file()
	packer.close()
	print("Built %s from %d source files" % [OUTPUT, files.size()])
	quit()


func _collect_files(path: String, output: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_collect_files(child, output)
		else:
			output.append(child)
		name = directory.get_next()
	directory.list_dir_end()
