class_name EditorWorkingCopy extends RefCounted
# `[CEUI-S9]`'s working copy: the imported COPY of an installed pack that the campaign
# editor edits, and the only tree the editor may write into.
#
# WHY THIS IS A SEPARATE ROOT AND NOT A SUBDIRECTORY OF THE LIBRARY. `[CEUI-S9]` makes
# `CL-ADV-01`'s *"installed packs are immutable"* STRUCTURALLY true rather than a policy
# the editor must remember: the editor has no path that writes into the installed root.
# A drafts directory living under `user://campaign_packs/` would make that a matter of
# careful path arithmetic -- one `path_join` away from writing a draft over a release.
# Drafts therefore live under their own root, `user://campaign_drafts/`, and
# `contains()` is the predicate every write on the editor side is checked against. The
# installed root is opened READ-only here and by nothing else in `scripts/editor/`.
#
# THE COPY HAS ITS OWN IDENTITY, AND THAT IS CALL 1 OF THE RULING. A Test launch
# activates the working copy, and `active_package_identity()` must visibly BE the working
# copy -- never the installed `<id>/<version>` it was copied from. So the copy's manifest
# is rewritten at import with a FORKED id (`PackManifest.forked_from` records where it
# came from), and `identity()` answers with the same keys `DataManager` publishes, so the
# two cannot drift into describing different things. A save produced in the editor then
# carries provenance that is true.
#
# WHY THE FORK HAPPENS AT IMPORT AND NOT AT EXPORT. `[CEUI-S10]` rules that export-BACK
# forks the id, and that is a different act with its own row (`[CEUI-S41]`). The id minted
# here is the DRAFT's, and it exists at import because the alternative is a working copy
# that shares an installed pack's identity for its whole editing life and only becomes
# distinguishable at the end -- which is exactly the masquerade call 1 forbids, deferred.
#
# THE VERSION IS CARRIED UNCHANGED. It belongs to the content, and the draft's content
# starts out as a copy of it. Bumping it here would invent an authoring decision the
# author has not made and `[CEUI-S10]` places at export.

const RegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")

## Drafts are not packages. Nothing discovers this root as a library, which is the point:
## a working copy is playable only through the editor's own Test launch.
const DEFAULT_DRAFTS_ROOT := "user://campaign_drafts"

const MANIFEST_PATH := "manifest.json"

## Provenance `PackManifest` has nowhere to put. The manifest carries `forked_from` (a
## pack id) and nothing else about the source, but a draft has to remember which BUILD it
## came from -- id, version and content fingerprint -- or an export-back cannot say what
## it is a fork of. A sidecar rather than a manifest field because `format_version` is 1
## and the parser rejects unsupported versions, the same reasoning `[CEUI-S10]` used.
const DRAFT_PATH := "draft.json"

## `[CEUI-S3]`/`[CEUI-S9]` call 3: the editor's own session state lives INSIDE the draft,
## so an editor Test session has somewhere to write that is not the player's slot root.
## The hazard the ruling names runs this way round -- the editor writing into player
## saves -- and a sandbox that is a sibling of the content it belongs to cannot be
## pointed at `user://saves` by a path mistake.
const SESSION_DIR := ".session"
const SESSION_SAVES_DIR := "saves"

## How a minted draft id is built. `PackManifest._valid_id` admits lowercase letters,
## digits, `_` and `-` only; an installed id is already valid and the suffix is decimal.
const DRAFT_ID_INFIX := "-draft-"

## How many same-second collisions are disambiguated before an import refuses. Bounded so
## a drafts root that is unwritable cannot turn into an unbounded probe loop.
const DRAFT_ID_MAX_ATTEMPTS := 64


class Result:
	extends RefCounted
	var imported := false
	var errors: Array[String] = []
	## Populated on success. Same keys as `DataManager.active_package_identity()`, plus
	## the source the copy was taken from.
	var identity: Dictionary = {}
	var path := ""


var _drafts_root: String
var _storage_root: String
## The tree this working copy actually lives in. Derived from the drafts root at import,
## and taken as given by `adopt()` -- which is why it is a field rather than arithmetic:
## a reopened copy is addressed by the path it was found at, and recomputing that from the
## drafts root silently produced a path nothing was at.
var _root := ""
var _draft_id := ""
var _package_version := ""
var _content_fingerprint := ""
var _content_schema_version := 0
var _source: Dictionary = {}


## `storage_root` is read from and never written to. It is a constructor argument rather
## than a constant so a test can point the import at a fixture library without the editor
## gaining a way to choose a different one at runtime.
func _init(
	drafts_root: String = DEFAULT_DRAFTS_ROOT,
	storage_root: String = RegistryScript.DEFAULT_STORAGE_ROOT
) -> void:
	_drafts_root = drafts_root.trim_suffix("/")
	_storage_root = storage_root.trim_suffix("/")


## Imports a COPY of one installed build and adopts it as this working copy.
##
## `content_fingerprint` selects WHICH build, because the library can hold two under one
## version number. Omitting it takes whatever is installed there, which is the right
## answer only when there is one -- the same caveat `CampaignPackRegistry.find` carries.
func import_from_installed(
	package_id: String, package_version: String, content_fingerprint: String = ""
) -> Result:
	var result := Result.new()
	if package_id.is_empty() or package_version.is_empty():
		result.errors.append("A working copy needs the installed package's id and version")
		return result
	var source_path := RegistryScript.resolve_installed_path(
		_storage_root, package_id, package_version, content_fingerprint
	)
	if source_path.is_empty():
		result.errors.append(
			"No campaign package is installed as '%s' version '%s'" % [package_id, package_version]
		)
		return result
	var draft_id := _free_draft_id(package_id)
	if draft_id.is_empty():
		result.errors.append("Too many working copies of '%s' already exist" % package_id)
		return result
	var destination := _drafts_root.path_join(draft_id)
	var copy_error := _copy_tree(source_path, destination)
	if copy_error != OK:
		_remove_tree(destination)
		result.errors.append(
			"Cannot copy the installed campaign package: %s" % error_string(copy_error)
		)
		return result
	# The manifest is rewritten BEFORE anything reads the copy back, so no window exists
	# in which a draft on disk carries the installed pack's identity.
	if not _write_forked_manifest(destination, draft_id, package_id, result.errors):
		_remove_tree(destination)
		return result
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(destination, errors)
	if catalogue == null:
		_remove_tree(destination)
		result.errors.append_array(errors)
		result.errors.append("The copied campaign package could not be read back")
		return result

	_draft_id = draft_id
	_root = destination
	_package_version = package_version
	_content_schema_version = catalogue.format_version
	# The copy's OWN fingerprint, computed from the copy rather than carried over.
	#
	# IT WILL EQUAL THE SOURCE'S AT IMPORT, AND THAT IS CORRECT. `content_fingerprint()`
	# hashes the catalogue's kind/id/document rows and nothing else -- not the manifest,
	# not paths -- so a fresh copy has identical content and hashes identically. What
	# makes the working copy a distinct identity is the forked `package_id`, and the
	# fingerprint starts diverging the first time a document is saved. Computing it here
	# rather than copying the source's is what makes that divergence automatic.
	_content_fingerprint = catalogue.content_fingerprint()
	_source = {
		"package_id": package_id,
		"package_version": package_version,
		"content_fingerprint": content_fingerprint,
		"path": source_path,
	}
	_write_draft_sidecar(destination)
	result.imported = true
	result.path = destination
	result.identity = identity()
	return result


## Adopts a working copy already on disk -- the reopen path, and how a test builds one
## without an installed library. Returns false and adopts nothing when the tree does not
## read as a pack.
func adopt(draft_path: String) -> bool:
	var root := draft_path.trim_suffix("/")
	if not contains(root):
		return false
	var manifest_errors: Array[String] = []
	var manifest_raw: Variant = _read_json(root.path_join(MANIFEST_PATH), manifest_errors)
	if manifest_raw == null:
		return false
	var manifest := PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	if manifest == null:
		return false
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(root, errors)
	if catalogue == null:
		return false
	_draft_id = manifest.id
	_root = root
	_package_version = manifest.version
	_content_schema_version = catalogue.format_version
	_content_fingerprint = catalogue.content_fingerprint()
	var sidecar_errors: Array[String] = []
	var sidecar: Variant = _read_json(root.path_join(DRAFT_PATH), sidecar_errors)
	_source = sidecar.get("source", {}).duplicate(true) if sidecar is Dictionary else {}
	return true


func is_open() -> bool:
	return not _draft_id.is_empty() and not _root.is_empty()


func drafts_root() -> String:
	return _drafts_root


func path() -> String:
	return _root


## The identity a Test launch activates under, in `DataManager.active_package_identity()`'s
## own keys so the two can be compared field for field rather than by eye.
func identity() -> Dictionary:
	if not is_open():
		return {}
	return {
		"package_id": _draft_id,
		"package_version": _package_version,
		"content_schema_version": _content_schema_version,
		"content_fingerprint": _content_fingerprint,
		"path": path(),
		# `[CEUI-S11]`'s header and `EW-6`'s status bar name the draft; the shell reads
		# `label` and falls back to `id`, so this is what an author sees.
		"label": _draft_id,
		"source": _source.duplicate(true),
	}


## Where an editor Test session's saves go. `[CEUI-S9]` call 3's hazard is the editor
## writing into player slots, and the answer is a root that is not the player's.
func session_save_dir() -> String:
	if not is_open():
		return ""
	return path().path_join(SESSION_DIR).path_join(SESSION_SAVES_DIR)


## The containment predicate every editor-side write is checked against. Compares
## normalized paths so `..` cannot walk out of the drafts root and back into the library.
func contains(candidate: String) -> bool:
	if candidate.is_empty():
		return false
	var root := _normalize(_drafts_root)
	var target := _normalize(candidate)
	return target == root or target.begins_with(root + "/")


## True for anything under the INSTALLED library. Not the negation of `contains()` -- a
## path can be neither -- and it is asked separately so a refusal can say which rule it
## broke. `[CEUI-S9]`: the editor has no path that writes here.
func is_installed_path(candidate: String) -> bool:
	if candidate.is_empty():
		return false
	var root := _normalize(_storage_root)
	var target := _normalize(candidate)
	return target == root or target.begins_with(root + "/")


## The working copy's own content, as `EditorDocument` wants it: `id -> document` for one
## catalogue kind. This is the source the editor opens documents from, and it is read from
## the DRAFT, so an author never has the installed pack's bytes in front of them.
func records(kind: String) -> Dictionary:
	var out: Dictionary = {}
	var catalogue := load_catalogue()
	if catalogue == null:
		return out
	for entry in catalogue.entries:
		if String(entry["kind"]) != kind:
			continue
		var document: Variant = catalogue.get_document(kind, String(entry["id"]))
		if document is Dictionary:
			out[String(entry["id"])] = (document as Dictionary).duplicate(true)
	return out


## The kinds this working copy actually holds, so a caller can open what is there without
## enumerating content families -- `[CEUI-S21]` forbids that list existing in the editor,
## and this answers it from the pack instead.
func kinds() -> Array[String]:
	var seen: Dictionary = {}
	var out: Array[String] = []
	var catalogue := load_catalogue()
	if catalogue == null:
		return out
	for entry in catalogue.entries:
		var kind := String(entry["kind"])
		if not seen.has(kind):
			seen[kind] = true
			out.append(kind)
	out.sort()
	return out


func load_catalogue() -> Tier2Catalogue:
	if not is_open():
		return null
	var errors: Array[String] = []
	return Tier2Catalogue.load_campaign_pack(path(), errors)


## The live `RegistryCatalog` the shell's content tree wants. `CampaignEditorShell.refresh`
## takes one and has been passed null since slice 1, deliberately: `[CEUI-S13]` makes the
## editor reachable only where no campaign is active, so `RegistryManager`'s live
## catalogue holds the engine baseline. The catalogue worth showing is the WORKING COPY's,
## and this is where it comes from.
##
## Built from the adapter's registry entries rather than from a second parse of the
## registry families: the adapter already knows how a pack's registry documents become
## `RegistryEntry` resources, and a second interpretation of that is how the editor and
## the runtime start disagreeing about what a pack contains.
func registry_catalogue() -> RegistryCatalog:
	var catalogue := RegistryCatalogScript.new()
	if not is_open():
		return catalogue
	for handler_id in RegistryCatalogScript.builtin_primitive_handlers():
		catalogue.register_primitive_handler(handler_id)
	var adapted = CampaignTier2RuntimeAdapter.load(path())
	for entry in adapted.registry_entries:
		catalogue.register_entry(entry)
	return catalogue


## `[CEUI-S25]`'s incremental pass for one document kind, as `EditorDocument.commit_edit`
## wants it: a Callable taking the document and returning a report.
##
## IT IS THE PRODUCTION VALIDATOR, NOT A SECOND ONE. `DLUX-15` and `CL-ADV-02` oblige the
## editor to SCHEDULE the validators the runtime uses rather than maintain its own reading
## of them, and `CampaignTier2Validators.registry()` is the same table
## `Tier2Catalogue.load_and_validate` runs at install and activation. So a record the
## editor calls valid is a record the pack loader will accept, by construction.
##
## An unregistered kind gets a report saying so rather than an empty one: "no validator"
## and "nothing wrong" are different answers, and only the second may look clean.
static func document_validator(kind: String) -> Callable:
	return func(document: EditorDocument) -> ValidationReport:
		var report := ValidationReport.create()
		var validators: Dictionary = CampaignTier2Validators.registry()
		var validator: Variant = validators.get(kind)
		if not validator is Callable or not (validator as Callable).is_valid():
			report.add(
				ValidationRules.RULE_TIER2_MISSING_VALIDATOR,
				"Tier2Catalogue: '%s' has no registered validator" % kind,
				{"kind": kind, "id": ""}
			)
			return report
		for record_id in document.record_ids():
			var errors: Array[String] = []
			# The entry is synthetic because the edit has not been written yet, so no
			# catalogue path exists for a record the author only just created. Validators
			# read `kind` and `id` off it and nothing else.
			(validator as Callable).call(
				document.record(String(record_id)),
				{"kind": kind, "id": String(record_id), "path": ""},
				errors
			)
			report.adopt_errors(
				ValidationRules.RULE_TIER2_DOCUMENT, errors, {"kind": kind, "id": String(record_id)}
			)
		return report


## A draft id that is valid, distinct from the pack it forked, and legible to the author
## who will see it in the header and the status bar.
##
## THE SUFFIX IS A TIMESTAMP, NOT RANDOM. Two reasons. An author looking at three drafts of
## one pack can tell which is the newest, which eight random hex digits do not tell them;
## and raw engine RNG is something this project routes through `RngService` so that a
## run is reproducible -- minting an id is not gameplay randomness, but the lint that
## enforces the rule is right to have no way of knowing that.
##
## Two imports of one pack inside the same second mint the same id, so `_free_draft_id`
## disambiguates against what is on disk. It probes ONE candidate directory at a time
## rather than listing the drafts root: a listing there would be a second discovery
## mechanism over a root deliberately kept out of the library.
static func mint_draft_id(source_id: String) -> String:
	return "%s%s%d" % [source_id, DRAFT_ID_INFIX, int(Time.get_unix_time_from_system())]


func _free_draft_id(source_id: String) -> String:
	var base := mint_draft_id(source_id)
	var candidate := base
	var attempt := 1
	while DirAccess.dir_exists_absolute(_drafts_root.path_join(candidate)):
		attempt += 1
		if attempt > DRAFT_ID_MAX_ATTEMPTS:
			return ""
		candidate = "%s-%d" % [base, attempt]
	return candidate


func _write_forked_manifest(
	destination: String, draft_id: String, source_id: String, errors: Array[String]
) -> bool:
	var manifest_path := destination.path_join(MANIFEST_PATH)
	var read_errors: Array[String] = []
	var raw: Variant = _read_json(manifest_path, read_errors)
	if not raw is Dictionary:
		errors.append_array(read_errors)
		errors.append("The copied campaign package has no readable manifest")
		return false
	var manifest: Dictionary = raw
	manifest["id"] = draft_id
	# `forked_from` is the ORIGINAL pack's id, which is what `[CEUI-S10]` means by fork
	# history. A draft forked from a draft therefore still names the release at the root
	# of the chain rather than the intermediate copy.
	var inherited := String(manifest.get("forked_from", ""))
	manifest["forked_from"] = inherited if not inherited.is_empty() else source_id
	# A working copy is by definition unfinished. `[CEUI-S41]` lands an export-back as a
	# draft too, so this is the same statement made one step earlier.
	manifest["authoring_status"] = "draft"
	# Migration edges name a destination package id, and `PackManifest.parse` refuses a
	# manifest whose edges point at another pack. The copy is another pack now, so a
	# chain carried across would make the draft unreadable the moment it was parsed.
	manifest["save_migrations"] = []
	return _write_json(manifest_path, manifest, errors)


func _write_draft_sidecar(destination: String) -> void:
	var errors: Array[String] = []
	_write_json(
		destination.path_join(DRAFT_PATH),
		{
			"draft_id": _draft_id,
			"content_fingerprint": _content_fingerprint,
			"source": _source.duplicate(true),
		},
		errors
	)


static func _normalize(value: String) -> String:
	return value.simplify_path().trim_suffix("/")


static func _read_json(path_value: String, errors: Array[String]) -> Variant:
	var handle := FileAccess.open(path_value, FileAccess.READ)
	if handle == null:
		errors.append("Cannot read '%s'" % path_value)
		return null
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	if parsed == null:
		errors.append("'%s' is not valid JSON" % path_value)
	return parsed


static func _write_json(path_value: String, value: Variant, errors: Array[String]) -> bool:
	var parent := path_value.get_base_dir()
	if not parent.is_empty() and DirAccess.make_dir_recursive_absolute(parent) != OK:
		errors.append("Cannot create '%s'" % parent)
		return false
	var handle := FileAccess.open(path_value, FileAccess.WRITE)
	if handle == null:
		errors.append("Cannot write '%s'" % path_value)
		return false
	# Sorted keys and real indentation: a draft is a tree an author may open in their own
	# editor, and a one-line re-serialization would present every save as a whole-file
	# change to whatever is watching it.
	handle.store_string(JSON.stringify(value, "\t", true))
	handle.close()
	return true


static func _copy_tree(source: String, destination: String) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(destination)
	if made != OK:
		return made
	var dir := DirAccess.open(source)
	if dir == null:
		return DirAccess.get_open_error()
	for file_name in dir.get_files():
		var copied := DirAccess.copy_absolute(
			source.path_join(file_name), destination.path_join(file_name)
		)
		if copied != OK:
			return copied
	for sub_name in dir.get_directories():
		var error := _copy_tree(source.path_join(sub_name), destination.path_join(sub_name))
		if error != OK:
			return error
	return OK


static func _remove_tree(target: String) -> void:
	var dir := DirAccess.open(target)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(target.path_join(file_name))
	for sub_name in dir.get_directories():
		_remove_tree(target.path_join(sub_name))
	DirAccess.remove_absolute(target)
