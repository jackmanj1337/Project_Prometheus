class_name ActionContext extends RefCounted

# Typed envelope shared by item, map-event, and future authored action callers.
var domain: String = ""
var subjects: Dictionary = {}
var target_refs: Dictionary = {}
var source_ref: Variant = null
var event_metadata: Dictionary = {}
var state_view: Variant = null
var resource_sink: Variant = null
var rng_stream: Variant = null
var safe_point: String = ""
var dry_run: bool = false
var result_collector: Array = []
var validation_errors: Array[Dictionary] = []


func _init(request_domain: String = "", request_subjects: Dictionary = {}) -> void:
	domain = request_domain
	subjects = request_subjects.duplicate()
