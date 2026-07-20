class_name PrepActivityDef extends Resource

# Authored activity instance. `panel_type` resolves through PrepActivityRegistry;
# adding another instance or id does not require an engine switch edit.
@export var id: String = ""
@export var panel_type: String = ""
@export var label: String = ""
@export var params: Dictionary = {}
