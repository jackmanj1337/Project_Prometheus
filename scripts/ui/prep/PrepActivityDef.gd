class_name PrepActivityDef extends Resource
# adopter-todo: PREP-V1-S01
# Paired with PrepActivityRegistry: these two reference each other and nothing
# else reaches either, which is why this check walks reachability from real entry
# points rather than counting direct references.

# Authored activity instance. `panel_type` resolves through PrepActivityRegistry;
# adding another instance or id does not require an engine switch edit.
@export var id: String = ""
@export var panel_type: String = ""
@export var label: String = ""
@export var params: Dictionary = {}
