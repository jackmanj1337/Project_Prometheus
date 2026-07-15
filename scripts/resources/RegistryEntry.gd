class_name RegistryEntry extends Resource

# Shared author-facing registry record. Runtime handlers remain engine-owned;
# content selects them by stable id and supplies validated parameters.
@export var id: String = ""
@export var family: String = ""
@export var label_key: String = ""
@export var owner_feature: String = ""
@export var version: int = 1
@export var kind: String = ""
@export var priority: int = 0
@export var primitive_handler: String = ""
@export var params_schema: Dictionary = {}
@export var subjects: Array[String] = []
@export var composition: Array[Dictionary] = []
@export var projection_support: bool = false
@export var save_fields: Array[String] = []
@export_multiline var docs_text: String = ""
@export var test_fixture: Dictionary = {}
