extends FileDialog
# Thin lifecycle guard for external-file pickers. The platform owns filename
# editing and picker chrome; this node only remembers/restores game focus.

var _restore_focus: Control


func _ready() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	if not file_selected.is_connected(_on_selected):
		file_selected.connect(_on_selected)
	if not dir_selected.is_connected(_on_selected):
		dir_selected.connect(_on_selected)
	if not canceled.is_connected(_on_cancelled):
		canceled.connect(_on_cancelled)


func begin_save(suggested_name: String) -> void:
	current_file = suggested_name.get_file()
	_remember_focus()
	popup_centered_ratio(0.75)


func _on_visibility_changed() -> void:
	if visible:
		_remember_focus()


func _remember_focus() -> void:
	if _restore_focus == null:
		_restore_focus = get_viewport().gui_get_focus_owner()


func _on_cancelled() -> void:
	call_deferred("_restore_caller_focus")


func _on_selected(_path: String) -> void:
	_restore_focus = null


func _restore_caller_focus() -> void:
	if is_instance_valid(_restore_focus) and _restore_focus.is_visible_in_tree():
		_restore_focus.grab_focus()
	_restore_focus = null
