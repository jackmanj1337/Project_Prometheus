class_name EditorAssetManager extends RefCounted
# `[CEUI-S36]`-`[CEUI-S39]`'s Assets workspace: the asset grid, the import transaction, the
# deletion flow, and `[CEUI-S38]`'s progressive disclosure. Headless state, like every other
# piece of the editor, so the rulings can be asserted without a viewport.
#
# THE ONE THING THIS FILE IS NOT ALLOWED TO DO IS TOUCH `EditorDocument`'s TRANSACTION.
# `[CEUI-S6]` call 1 excluded FILE OPERATIONS from Undo, and import, deletion and the
# export-time bakes all write or remove files. That exclusion is the single simplification
# the whole document model rests on: with it, Undo is a dictionary of cells; without it,
# Undo would have to be able to un-copy a file, and every layer of `EditorDocument` would
# have to answer for something on disk. So the import and deletion verbs here return a
# **PLAN** -- the files to write, the records that result -- and something else applies it,
# exactly as `EditorDocument.save()` returns bytes for `EditorPackWriter` to write.
#
# A COMMITTED PLAN MEANS THE OPEN DOCUMENT MUST BE RE-OPENED, and `reload_required` says so.
# That is the honest consequence of staying out of the transaction: an import that landed in
# the overlay would be undoable, and pressing Undo would leave a file on disk that no record
# names. Re-deriving the document from what was written is the only way the two agree.
#
# `[CEUI-S36]`: AN INCOMPLETE RIGHTS RECORD NEVER BLOCKS THE COMMIT. The import commits and
# the missing provenance surfaces as a validation ISSUE -- `RULE_RIGHTS_UNKNOWN`, declared
# to WARN in the draft and to FAIL at export and activation, which is `[CEUI-S27]`'s ratified
# draft-warns/release-fails model doing its job rather than a second enforcement point.
# Publication is still protected: nothing reaches the library or a zip with unknown rights.
# What is avoided is the state the strict reading creates -- a staged-but-uncommitted import
# that has to survive a session, be found again, and be reconciled with files that may have
# moved. `LEG-4`'s rule that an importer is never a licence-laundering step is satisfied by
# the GATE, not by a modal.
#
# THIS IS THE FIRST RULE IN THE CORPUS THAT ACTUALLY ESCALATES BETWEEN GATES.
# `ValidationRules` shipped the per-gate severity axis with the note that no engine rule used
# it yet, because retrofitting a gate axis into a flat severity field touches every call
# site. `RULE_RIGHTS_UNKNOWN` is the producer that axis was built for.
#
# NOTHING IS INFERRED, EVER (`[CEUI-S37]`). A licence is never derived from a filename or a
# source URL: a wrong inference here is a false legal claim. Classification -- what a file
# DECODES to -- is derived from its extension against `EntitySchemaRegistry`'s admitted
# table, which is a fact about bytes, not a claim about rights.
#
# BATCH PROVENANCE IS `[CEUI-S23]`'s BULK TABLE, NOT A SECOND SURFACE (`[CEUI-S37]`).
# `subjects_for()` publishes `EditorSubject` MEMBER addresses -- the keyed-member form exists
# because `assets` is an object keyed by the author's own ids and the index form cannot reach
# it -- so a multi-selection of assets opens the same table a multi-selection of records
# does. `review_batch()` is the ruled pre-commit review list naming which assets receive
# which values; it is a preview of the table's own edit, not a second way to make it.
#
# `[CEUI-S39]`: DELETION SHOWS USAGES AND NEVER CASCADES. `[CSA-12]`'s stored `used_by`
# relations DO NOT EXIST IN CODE (`grep -rn used_by scripts/` is empty), so usages are
# SCANNED for rather than read off a relation -- every record of every open document, for a
# string equal to the asset id. That is slower and it is correct today; a stored relation
# that nothing maintains would be worse than a scan, because it would be believed.

const RulesScript = preload("res://scripts/validation/ValidationRules.gd")
const ReportScript = preload("res://scripts/validation/ValidationReport.gd")
const SubjectScript = preload("res://scripts/editor/EditorSubject.gd")
const SchemasScript = preload("res://scripts/data/EntitySchemaRegistry.gd")
const RecoveryScript = preload("res://scripts/editor/EditorRecoverySnapshots.gd")

## The property of an `asset_registry` record that holds the assets. Named here and nowhere
## else, and it is a SCHEMA fact rather than a content family: `assets` is the one property
## the `asset_registry` schema declares as an object of asset records, and `_assets_property`
## finds it by that shape so a schema that renames it needs no edit here.
const ASSETS_PROPERTY_HINT := "assets"

## `[CEUI-S36]`. Warns while authoring, fails at both export gates and at activation.
const RULE_RIGHTS_UNKNOWN := "assets.rights_unknown"
## `[CEUI-S39]`'s intentional break: a reference the author chose to leave dangling. An
## ordinary validation issue, exactly as the ruling says -- not a refusal, and not a cascade.
const RULE_ASSET_REFERENCE_BROKEN := "assets.reference_broken"

## The three answers `[CEUI-S39]` offers, and there is deliberately no fourth. "Cascade" is
## not among them: deleting an asset never deletes what points at it.
const ON_DELETE_CANCEL := "cancel"
const ON_DELETE_REPLACE := "replace"
const ON_DELETE_BREAK := "break"

## Author-facing refusals.
const NO_REGISTRY_REASON := "Open an asset registry to manage its assets."
const UNKNOWN_ASSET_REASON := "That asset is not in this registry."
const UNSUPPORTED_MEDIA_REASON := "That file type is not one a campaign pack may carry, so it cannot be imported."
const DUPLICATE_ID_REASON := "An asset with that id is already in this registry."
## Why the commit and discard actions are unavailable with an empty stage. Held here rather
## than phrased in the screen: `[EPUX-04]` puts the reason with the availability authority,
## and the authority for "is there anything to import" is this model.
const NOTHING_STAGED_REASON := "There is nothing staged to import."
const NO_REPLACEMENT_REASON := "Choose the asset that should take this one's place."
## `[CEUI-S6]` excludes file operations from Undo, and `[CEUI-S39]` requires the warning to
## be said rather than implied.
const NOT_UNDOABLE_WARNING := "Deleting an asset removes its file. This cannot be undone from the editor."

## `[CEUI-S38]`'s named collapsible sections. Tabs were rejected because the loop these tools
## serve is *adjust a swap, look at the animation*, and a tab hides one from the other. The
## first three are ALWAYS VISIBLE -- they are not sections, and they are listed here so the
## surface has one ordered description of the detail workspace rather than two.
##
## The section INTERIORS (the swap editor, tint fallback, slot binding, the bake actions) are
## `EDITOR-SPRITE-COMPOSITION-2026-08-26`'s, which `[CEUI-S38]` overlaps by design. What this
## file owns is the disclosure: which sections exist, and which are open.
const ALWAYS_VISIBLE: Array[String] = ["preview", "cell_pivot", "animation"]
const SECTIONS: Array[String] = [
	"palette_frequency", "swap_editor", "tint_fallback", "slot_binding", "bake_actions"
]
const SECTION_LABELS: Dictionary = {
	"palette_frequency": "Palette frequency",
	"swap_editor": "Swap editor",
	"tint_fallback": "Tint fallback",
	"slot_binding": "Slot binding",
	"bake_actions": "Bake actions",
}


## The engine's rules plus the two this workspace produces. Declared here rather than in
## `ValidationRules.engine_rules()` because they are the EDITOR's checks: the engine never
## imports an asset, and a rule with no producer in the set every runtime validation reads
## is a rule that looks enforced and is not.
static func rules() -> ValidationRules:
	var declared := RulesScript.engine_rules()
	# The escalation `[CEUI-S36]` ruled, and the whole reason the gate axis exists.
	declared.declare(RULE_RIGHTS_UNKNOWN, RulesScript.SEVERITY_WARNING, RulesScript.SEVERITY_ERROR)
	declared.declare(
		RULE_ASSET_REFERENCE_BROKEN, RulesScript.SEVERITY_WARNING, RulesScript.SEVERITY_ERROR
	)
	return declared


## The media type a filename DECODES to, from `EntitySchemaRegistry`'s admitted table, or
## `""` for an extension a pack may not carry. A fact about bytes: this is the one thing
## about an imported file that may be derived, and `[CEUI-S37]` forbids deriving the other.
static func classify(filename: String) -> String:
	var extension := filename.get_extension().to_lower()
	return String(SchemasScript.MEDIA_TYPES_BY_EXTENSION.get(extension, ""))


var _document: EditorDocument = null
var _record_id: String = ""
var _schemas: EntitySchemaRegistry = null
var _recovery: EditorRecoverySnapshots = null
## Candidate imports, staged but not committed. `[CEUI-S36]` chose option A's stage ->
## preview -> atomic commit; what it refused was the staged state OUTLIVING the session, so
## this is deliberately in-memory and deliberately not persisted anywhere.
var _staged_imports: Array[Dictionary] = []
## `[CEUI-S38]`: section id -> expanded. Absent means collapsed. "Remember their state" is
## why this is captured and restored rather than defaulted on every rebuild.
var _expanded_sections: Dictionary = {}
## The grid selection, as asset ids. `[CEUI-S37]`'s "explicitly selected batch".
var _selection: Array[String] = []


## Points the manager at one `asset_registry` record of an open document.
func set_registry(
	document: EditorDocument, record_id: String, schemas: EntitySchemaRegistry
) -> void:
	var same := _document == document and _record_id == record_id
	_document = document
	_record_id = record_id
	_schemas = schemas
	if not same:
		_selection.clear()
		_staged_imports.clear()


## The screen owns one service per working copy. Keeping the service injected leaves this
## model usable in headless tests and keeps storage identity out of the asset vocabulary.
func set_recovery_snapshots(recovery: EditorRecoverySnapshots) -> void:
	_recovery = recovery


func recovery_snapshots() -> EditorRecoverySnapshots:
	return _recovery


func has_registry() -> bool:
	return (
		_document != null
		and _record_id != ""
		and _document.has_record(_record_id)
		and _assets_property() != ""
	)


## The property holding the assets, found by SHAPE: an object whose `additional_properties`
## is an object schema requiring the media-identity fields. The hint above is tried first so
## the ordinary case costs one lookup; the shape check is what makes a schema that renamed
## the property still work.
func _assets_property() -> String:
	if _schemas == null or _document == null:
		return ""
	var version := int(_document.value(_record_id, "schema_version", 1))
	var properties: Dictionary = _schemas.schema_for(_document.kind, version).get("properties", {})
	if _is_asset_map(properties.get(ASSETS_PROPERTY_HINT, null)):
		return ASSETS_PROPERTY_HINT
	for name in properties:
		if _is_asset_map(properties[name]):
			return String(name)
	return ""


static func _is_asset_map(spec: Variant) -> bool:
	if not (spec is Dictionary) or String((spec as Dictionary).get("type", "")) != "object":
		return false
	var member: Variant = (spec as Dictionary).get("additional_properties", null)
	if not (member is Dictionary) or String((member as Dictionary).get("type", "")) != "object":
		return false
	var required: Array = (member as Dictionary).get("required", []) as Array
	# `sha256` and `path` together are what makes a member an ASSET rather than any other
	# keyed object: one says it is a file, the other says which bytes.
	return required.has("sha256") and required.has("path")


# ---- `[CEUI-S38]` the grid ----


## Every asset, in key order. Object keys carry no authored order the way an array's indices
## do -- there is no editor action that moves an asset up -- so sorting is not overriding an
## authoring statement here, unlike in `EditorObjectiveOutline`.
##
## `{id, subject, record, decoded_type, byte_size, sha256, original_filename, source_refs,
## rights_known}`.
func assets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not has_registry():
		return out
	var property := _assets_property()
	var held: Variant = _document.value(_record_id, property, null)
	if not (held is Dictionary):
		return out
	var ids: Array = (held as Dictionary).keys()
	ids.sort()
	for id in ids:
		var record: Variant = (held as Dictionary)[id]
		if not (record is Dictionary):
			continue
		var fields: Dictionary = record
		var refs: Array = fields.get("source_refs", []) as Array
		(
			out
			. append(
				{
					"id": String(id),
					"subject": SubjectScript.for_member(_record_id, property, String(id)),
					"record": fields.duplicate(true),
					"decoded_type": String(fields.get("decoded_type", "")),
					"byte_size": int(fields.get("byte_size", 0)),
					"sha256": String(fields.get("sha256", "")),
					"original_filename": String(fields.get("original_filename", "")),
					"source_refs": refs.duplicate(),
					"rights_known": not refs.is_empty(),
				}
			)
		)
	return out


func has_asset(asset_id: String) -> bool:
	for entry in assets():
		if String(entry["id"]) == asset_id:
			return true
	return false


func asset(asset_id: String) -> Dictionary:
	for entry in assets():
		if String(entry["id"]) == asset_id:
			return entry
	return {}


## `[CEUI-S37]`'s "explicitly selected" batch. Selection is by id and never implicit: a
## filter that also selected would make "which assets does this edit touch" unanswerable,
## which is the same failure `[CEUI-S23]` avoided by routing one selection to one surface.
func select(asset_ids: Array) -> Array[String]:
	_selection.clear()
	for id in asset_ids:
		var asset_id := String(id)
		if has_asset(asset_id) and not _selection.has(asset_id):
			_selection.append(asset_id)
	return selection()


func clear_selection() -> void:
	_selection.clear()


func selection() -> Array[String]:
	return _selection.duplicate()


## `[CEUI-S37]`: the addresses `[CEUI-S23]`'s bulk table opens over. MEMBER subjects, because
## an asset's identity is the author's own key -- see `EditorSubject`'s header on why that is
## a different subject kind from an array index and not a special case of one.
func subjects_for(asset_ids: Array = []) -> Array[Dictionary]:
	var wanted: Array = asset_ids if not asset_ids.is_empty() else _selection
	var out: Array[Dictionary] = []
	for id in wanted:
		var entry := asset(String(id))
		if not entry.is_empty():
			out.append((entry["subject"] as Dictionary).duplicate(true))
	return out


## `[CEUI-S37]`'s PRE-COMMIT REVIEW LIST: which assets receive which values, named before the
## edit lands. It reads the values the caller is about to write; it does not write them --
## the write is the bulk table's, which is the whole point of not building a second surface.
##
## `{asset_id, field, from, to, changes}` per asset, in selection order.
func review_batch(fields: Dictionary, asset_ids: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var wanted: Array = asset_ids if not asset_ids.is_empty() else _selection
	for id in wanted:
		var entry := asset(String(id))
		if entry.is_empty():
			continue
		var record: Dictionary = entry["record"]
		var changes: Array[Dictionary] = []
		var names: Array = fields.keys()
		names.sort()
		for field in names:
			var before: Variant = record.get(field, null)
			if before == fields[field]:
				continue
			changes.append({"field": String(field), "from": before, "to": fields[field]})
		out.append({"asset_id": String(id), "changes": changes})
	return out


# ---- `[CEUI-S36]` the import transaction ----


## Stages one candidate. `candidate` carries `{id, source_path, original_filename, byte_size,
## sha256}` and MAY carry `source_refs`; nothing else is read, and nothing at all is inferred
## beyond the decoded type.
##
## Returns `{staged, reason}`. An unsupported media type is the only classification refusal,
## and it is a refusal about BYTES: a pack may not carry the file at all, so there is nothing
## for a later gate to warn about.
func stage_import(candidate: Dictionary) -> Dictionary:
	if not has_registry():
		return {"staged": false, "reason": NO_REGISTRY_REASON}
	var asset_id := String(candidate.get("id", ""))
	if asset_id == "" or has_asset(asset_id) or _is_staged(asset_id):
		return {"staged": false, "reason": DUPLICATE_ID_REASON}
	var filename := String(candidate.get("original_filename", ""))
	var decoded := classify(filename)
	if decoded == "":
		return {"staged": false, "reason": UNSUPPORTED_MEDIA_REASON}
	var entry: Dictionary = candidate.duplicate(true)
	entry["id"] = asset_id
	entry["decoded_type"] = decoded
	_staged_imports.append(entry)
	return {"staged": true, "reason": ""}


func staged_imports() -> Array[Dictionary]:
	return _staged_imports.duplicate(true)


func discard_staged_imports() -> void:
	_staged_imports.clear()


## `[CEUI-S36]`'s preview: classification and duplicates, before the atomic commit.
##
## A DUPLICATE IS REPORTED AND NOT REFUSED. Two records over one set of bytes is an
## authoring decision -- the same sheet under two logical ids is legitimate -- and the
## preview exists so the author makes it knowingly. `duplicate_of` names the asset already
## holding those bytes, whether it is in the registry or another candidate in this batch.
##
## `{id, decoded_type, duplicate_of, rights_known, byte_size}` per candidate.
func import_preview() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var by_hash: Dictionary = {}
	for entry in assets():
		var existing := String(entry["sha256"])
		if existing != "" and not by_hash.has(existing):
			by_hash[existing] = String(entry["id"])
	for candidate in _staged_imports:
		var digest := String(candidate.get("sha256", ""))
		var refs: Array = candidate.get("source_refs", []) as Array
		(
			out
			. append(
				{
					"id": String(candidate["id"]),
					"decoded_type": String(candidate["decoded_type"]),
					"byte_size": int(candidate.get("byte_size", 0)),
					"duplicate_of": String(by_hash.get(digest, "")),
					"rights_known": not refs.is_empty(),
				}
			)
		)
		if digest != "" and not by_hash.has(digest):
			by_hash[digest] = String(candidate["id"])
	return out


## Commits the staged import ATOMICALLY and returns the PLAN: the files to copy and the
## whole assets map that results. Nothing here writes, and nothing here stages onto the
## document -- see the header on why file operations stay out of the transaction.
##
## AN UNKNOWN RIGHTS RECORD DOES NOT APPEAR IN `reason` AND DOES NOT SET `committed` FALSE.
## That is `[CEUI-S36]` in one line: the import succeeds, and `validate()` raises the issue.
##
## `{committed, reason, files, assets, reload_required, imported_ids}`.
func commit_import(documents: Array = []) -> Dictionary:
	if not has_registry():
		return _import_refusal(NO_REGISTRY_REASON)
	if _staged_imports.is_empty():
		return _import_refusal(NOTHING_STAGED_REASON)
	var property := _assets_property()
	var held: Variant = _document.value(_record_id, property, null)
	var records: Dictionary = (held as Dictionary).duplicate(true) if held is Dictionary else {}
	var files: Array[Dictionary] = []
	var imported: Array[String] = []
	for candidate in _staged_imports:
		var asset_id := String(candidate["id"])
		# Re-checked at commit rather than trusted from stage time: the registry may have
		# gained the id since, and an atomic commit that overwrote it would destroy an asset
		# record the author never named.
		if records.has(asset_id):
			return _import_refusal(DUPLICATE_ID_REASON)
		var destination := (
			"assets/%s.%s"
			% [asset_id, String(candidate.get("original_filename", "")).get_extension().to_lower()]
		)
		var record := {
			"path": destination,
			"decoded_type": String(candidate["decoded_type"]),
			"byte_size": int(candidate.get("byte_size", 0)),
			"sha256": String(candidate.get("sha256", "")),
			"original_filename": String(candidate.get("original_filename", "")),
		}
		var refs: Array = candidate.get("source_refs", []) as Array
		if not refs.is_empty():
			record["source_refs"] = refs.duplicate()
		records[asset_id] = record
		files.append({"from": String(candidate.get("source_path", "")), "to": destination})
		imported.append(asset_id)
	var recovery := _capture_before_risk("asset_import", documents)
	if not bool(recovery["captured"]):
		return _import_refusal(String(recovery["reason"]))
	_staged_imports.clear()
	return {
		"committed": true,
		"reason": "",
		"files": files,
		"assets": records,
		"imported_ids": imported,
		"reload_required": true,
		"recovery_snapshot": recovery.get("snapshot", {}),
	}


func _import_refusal(reason: String) -> Dictionary:
	return {
		"committed": false,
		"reason": reason,
		"files": [] as Array[Dictionary],
		"assets": {},
		"imported_ids": [] as Array[String],
		"reload_required": false,
	}


func _is_staged(asset_id: String) -> bool:
	for candidate in _staged_imports:
		if String(candidate.get("id", "")) == asset_id:
			return true
	return false


# ---- `[CEUI-S39]` deletion ----


## Every place an asset id appears, scanned across the documents the caller supplies. See the
## header: `[CSA-12]`'s `used_by` relations do not exist, so this looks rather than asks.
##
## `documents` is `Array[EditorDocument]`. Each usage is `{document_id, record_id, path}`,
## where `path` is the dotted route to the value, so `[CEUI-S26]`'s object-and-field
## navigation has somewhere to send the author.
func usages_of(asset_id: String, documents: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in documents:
		var document: EditorDocument = entry
		if document == null:
			continue
		for record_id in document.record_ids():
			# The registry's own entry for the asset is not a USAGE of it. Counting it would
			# make every asset look referenced and the whole preview meaningless.
			var skip_registry := document == _document and record_id == _record_id
			for path in _find_value(document.record(record_id), asset_id, ""):
				if skip_registry and String(path).begins_with("%s." % _assets_property()):
					continue
				out.append(
					{"document_id": document.id, "record_id": record_id, "path": String(path)}
				)
	return out


## `[CEUI-S39]`'s dialog, as data: the usages, the three answers, and the warning that this
## cannot be undone. The SAME shape `[CEUI-S8]`'s id rename uses -- one pattern, two
## consumers -- which is why the choices are named here rather than in a surface.
##
## `snapshot_required` is `[CEUI-S40]`: a recovery snapshot is taken immediately before every
## risky operation. THE SNAPSHOT PRIMITIVE DOES NOT EXIST YET (`grep -rn snapshot
## scripts/editor/` finds only comments citing it), so this reports the obligation rather
## than pretending to satisfy it; `EDITOR-RECOVERY-SNAPSHOTS-2026-09-08` builds it.
func deletion_preview(asset_id: String, documents: Array = []) -> Dictionary:
	if not has_registry():
		return {"available": false, "reason": NO_REGISTRY_REASON}
	if not has_asset(asset_id):
		return {"available": false, "reason": UNKNOWN_ASSET_REASON}
	return {
		"available": true,
		"reason": "",
		"asset_id": asset_id,
		"usages": usages_of(asset_id, documents),
		"choices": [ON_DELETE_CANCEL, ON_DELETE_REPLACE, ON_DELETE_BREAK],
		"warning": NOT_UNDOABLE_WARNING,
		"snapshot_required": true,
	}


## The preview remains pure. The caller invokes this immediately before applying the chosen
## deletion plan, when the risky operation is actually about to begin.
func capture_before_deletion(asset_id: String, documents: Array = []) -> Dictionary:
	if not has_registry():
		return {"captured": false, "reason": NO_REGISTRY_REASON}
	if not has_asset(asset_id):
		return {"captured": false, "reason": UNKNOWN_ASSET_REASON}
	return _capture_before_risk("asset_deletion:%s" % asset_id, documents)


## The PLAN for a deletion, per the author's answer. Writes nothing, exactly as the import
## does not.
##
## IT NEVER CASCADES, AND `record_edits` IS WHY THE THREE ANSWERS ARE DIFFERENT PLANS RATHER
## THAN ONE PLAN WITH A FLAG. `REPLACE` rewrites references to `replacement_id` and removes
## the asset; `BREAK` removes the asset and leaves every reference standing, reporting each
## as an ordinary validation issue; `CANCEL` does nothing at all. Deleting what points at the
## asset is not among them, which is the ruling.
##
## `{applied, reason, files_to_remove, assets, record_edits, issues, reload_required}`.
func plan_deletion(
	asset_id: String, choice: String, documents: Array = [], replacement_id: String = ""
) -> Dictionary:
	if not has_registry():
		return _deletion_refusal(NO_REGISTRY_REASON)
	if not has_asset(asset_id):
		return _deletion_refusal(UNKNOWN_ASSET_REASON)
	if choice == ON_DELETE_CANCEL:
		return _deletion_refusal("")
	if choice == ON_DELETE_REPLACE and (replacement_id == "" or not has_asset(replacement_id)):
		return _deletion_refusal(NO_REPLACEMENT_REASON)
	if choice != ON_DELETE_REPLACE and choice != ON_DELETE_BREAK:
		return _deletion_refusal(UNKNOWN_ASSET_REASON)

	var entry := asset(asset_id)
	var property := _assets_property()
	var held: Variant = _document.value(_record_id, property, null)
	var records: Dictionary = (held as Dictionary).duplicate(true) if held is Dictionary else {}
	records.erase(asset_id)

	var usages := usages_of(asset_id, documents)
	var edits: Array[Dictionary] = []
	var report := ReportScript.create(rules())
	for usage in usages:
		if choice == ON_DELETE_REPLACE:
			var replacement: Dictionary = usage.duplicate(true)
			replacement["value"] = replacement_id
			edits.append(replacement)
			continue
		report.add(
			RULE_ASSET_REFERENCE_BROKEN,
			(
				"%s in %s still refers to the deleted asset '%s'."
				% [String(usage["path"]), String(usage["record_id"]), asset_id]
			),
			usage
		)
	return {
		"applied": true,
		"reason": "",
		"files_to_remove": [String((entry["record"] as Dictionary).get("path", ""))],
		"assets": records,
		"record_edits": edits,
		"issues": report,
		"reload_required": true,
	}


func _deletion_refusal(reason: String) -> Dictionary:
	return {
		"applied": false,
		"reason": reason,
		"files_to_remove": [] as Array[String],
		"assets": {},
		"record_edits": [] as Array[Dictionary],
		"issues": ReportScript.create(rules()),
		"reload_required": false,
	}


func _capture_before_risk(operation: String, documents: Array) -> Dictionary:
	# Older headless callers that do not need persistence retain the existing planning API;
	# the live editor always injects the service during working-copy adoption.
	if _recovery == null:
		return {"captured": true, "snapshot": {}}
	return _recovery.capture_before_risk(_document.id, _recovery_state(documents), operation)


func _recovery_state(documents: Array) -> Dictionary:
	var open_documents: Array[Dictionary] = []
	var seen: Dictionary = {}
	for entry in documents:
		if not (entry is EditorDocument):
			continue
		var document: EditorDocument = entry
		if seen.has(document.id):
			continue
		seen[document.id] = true
		(
			open_documents
			. append(
				{
					"id": document.id,
					"kind": document.kind,
					"title": document.title,
					"records": document.records(),
				}
			)
		)
	if not seen.has(_document.id):
		(
			open_documents
			. append(
				{
					"id": _document.id,
					"kind": _document.kind,
					"title": _document.title,
					"records": _document.records(),
				}
			)
		)
	return {"documents": open_documents}


# ---- validation ----


## `[CEUI-S36]`/`CSA-6`: one issue per asset whose rights are unrecorded. A WARNING while the
## author works and an ERROR at both export gates and at activation, which is the whole of
## how "an incomplete rights record never blocks the commit" stays compatible with "nothing
## reaches the library or a zip with unknown rights".
func validate() -> ValidationReport:
	var report := ReportScript.create(rules())
	for entry in assets():
		if bool(entry["rights_known"]):
			continue
		report.add(
			RULE_RIGHTS_UNKNOWN,
			"Asset '%s' records no source, so its rights are unknown." % String(entry["id"]),
			{"record_id": _record_id, "asset_id": String(entry["id"])}
		)
	return report


# ---- `[CEUI-S38]` progressive disclosure ----


## `{id, label, expanded}` in the ruled order. The always-visible three are not here: they
## are not disclosable, and listing them as sections that happen to start open would make
## them collapsible by anything that iterated this.
func sections() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in SECTIONS:
		(
			out
			. append(
				{
					"id": id,
					"label": String(SECTION_LABELS[id]),
					"expanded": bool(_expanded_sections.get(id, false)),
				}
			)
		)
	return out


## Refuses an id that is not one of the ruled sections. A silent accept would let a typo
## record a disclosure state nothing ever reads.
func set_section_expanded(section_id: String, expanded: bool) -> bool:
	if not SECTIONS.has(section_id):
		return false
	_expanded_sections[section_id] = expanded
	return true


func is_section_expanded(section_id: String) -> bool:
	return bool(_expanded_sections.get(section_id, false))


## `[CEUI-S38]`'s "remember their state", and `[TSV-24]`'s survive-recomposition rule. The
## SELECTION goes with it because `[CEUI-S37]`'s batch is an explicit act the author would
## have to redo; the staged imports deliberately do NOT, because a staged import that
## survived would be the state `[CEUI-S36]` refused to create.
func capture_state() -> Dictionary:
	return {"sections": _expanded_sections.duplicate(true), "selection": _selection.duplicate()}


func restore_state(state: Dictionary) -> void:
	_expanded_sections.clear()
	for id in state.get("sections", {}) as Dictionary:
		if SECTIONS.has(String(id)):
			_expanded_sections[String(id)] = bool((state["sections"] as Dictionary)[id])
	_selection.clear()
	for id in state.get("selection", []) as Array:
		if has_asset(String(id)) and not _selection.has(String(id)):
			_selection.append(String(id))


# ---- internals ----


## Every dotted path within `value` at which `needle` appears as a whole string. Whole
## string, not substring: an asset id that happened to be a prefix of a longer id would
## otherwise report a usage that does not exist, and a preview that overstates usages is one
## an author learns to click past.
func _find_value(value: Variant, needle: String, path: String) -> Array[String]:
	var out: Array[String] = []
	if value is String:
		if String(value) == needle:
			out.append(path)
		return out
	if value is Dictionary:
		for field in value as Dictionary:
			var child := String(field) if path == "" else "%s.%s" % [path, String(field)]
			out.append_array(_find_value((value as Dictionary)[field], needle, child))
		return out
	if value is Array:
		for index in range((value as Array).size()):
			out.append_array(_find_value((value as Array)[index], needle, "%s[%d]" % [path, index]))
	return out
