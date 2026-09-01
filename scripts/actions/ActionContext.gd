class_name ActionContext extends RefCounted

# Typed envelope shared by item, map-event, and future authored action callers.
var domain: String = ""
var subjects: Dictionary = {}
var target_refs: Dictionary = {}
var source_ref: Variant = null
var event_metadata: Dictionary = {}
var state_view: Variant = null
# UnitStateSink for the transaction this action joins. Present means "prepare
# into the journal"; absent means the caller owns no transaction and the
# primitive writes through immediately.
var effect_sink: Variant = null
var resource_sink: Variant = null
var rng_stream: Variant = null
var safe_point: String = ""
var dry_run: bool = false
var result_collector: Array = []
var validation_errors: Array[Dictionary] = []
var phase: String = "validate"
var transaction: Variant = null
var diagnostics: Array[Dictionary] = []
var knowledge_policy: String = "exact"
var requirement_context: Dictionary = {}
var participants: Array = []


func _init(request_domain: String = "", request_subjects: Dictionary = {}) -> void:
	domain = request_domain
	subjects = request_subjects.duplicate()
