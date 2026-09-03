class_name SaveRecovery
extends RefCounted
# Bounded, actionable diagnostics for a save whose campaign package cannot be
# activated (pack-save Slice 2, stage 2F).
#
# Two ideas live here and nowhere else:
#
#   1. CONTENT STATE. A stored save is either ready — its package resolved and
#      validated — or disabled: structurally sound, kept verbatim, but not
#      loadable until the player installs the package it names. A disabled save
#      is never rewritten, never migrated and never partially applied; only the
#      index row's content_state changes when it later resolves.
#   2. WORDING. Every failure the player can see is described from identity
#      fields alone: package id/version, content schema version and a shortened
#      fingerprint. No filesystem path, no engine error string and no unbounded
#      list ever reaches this text, so the same wording is safe on screen, in a
#      tooltip and in a headless assertion.
#
# Pure and engine-free: no autoloads, no FileAccess, no scene tree. SaveManager
# classifies, this file words the result, and the UI only renders it.

const STATE_READY := "ready"
const STATE_DISABLED := "disabled"

const REASON_MISSING := "missing"
const REASON_INCOMPATIBLE := "incompatible"
const REASON_FINGERPRINT_MISMATCH := "fingerprint_mismatch"
const REASON_MISSING_CONTENT := "missing_content"
const REASON_INVALID := "invalid"

const REASONS: Array[String] = [
	REASON_MISSING,
	REASON_INCOMPATIBLE,
	REASON_FINGERPRINT_MISMATCH,
	REASON_MISSING_CONTENT,
	REASON_INVALID,
]

const ACTION_MANAGE_CAMPAIGNS := "manage_campaigns"
const ACTION_RETRY := "retry"
const ACTION_BACK := "back"

const ACTION_LABELS := {
	ACTION_MANAGE_CAMPAIGNS: "Manage Campaigns",
	ACTION_RETRY: "Retry",
	ACTION_BACK: "Back",
}

# Installing or reinstalling a package is what clears these, so all three actions
# are offered in one order: fix it, re-check, leave.
const RECOVERABLE_ACTIONS: Array[String] = [ACTION_MANAGE_CAMPAIGNS, ACTION_RETRY, ACTION_BACK]

# A file that is not a readable save is never stored, so there is nothing to
# re-check and no package to install; offering either would be a false promise.
const UNREADABLE_ACTIONS: Array[String] = [ACTION_BACK]

# The player is told this on every failure path. Load and import both work on a
# deep copy and commit atomically, so a failure leaves bytes, progress, the
# installed catalogue and the save index exactly as they were.
const UNCHANGED_NOTICE := "No save data or progress was changed."

const _MAX_LISTED_VERSIONS := 4
const _FINGERPRINT_PREFIX := "sha256:"
const _FINGERPRINT_DIGITS := 8


static func is_reason(value: String) -> bool:
	return value in REASONS


# Maps a pure resolution status onto a recovery reason. Statuses that can
# continue have no diagnostic; the caller must not ask for one.
static func reason_for_status(status: String) -> String:
	match status:
		"missing":
			return REASON_MISSING
		"incompatible":
			return REASON_INCOMPATIBLE
		"fingerprint_mismatch":
			return REASON_FINGERPRINT_MISMATCH
		"invalid":
			return REASON_INVALID
		_:
			return ""


static func actions_for_reason(reason: String) -> Array[String]:
	if reason == REASON_INVALID:
		return UNREADABLE_ACTIONS.duplicate()
	return RECOVERABLE_ACTIONS.duplicate()


# The one record the UI renders. `lines` is already ordered and bounded; joining
# it is the whole of message().
static func describe(
	reason: String, saved_identity: Dictionary = {}, installed_identities: Array = []
) -> Dictionary:
	var normalized := reason if is_reason(reason) else REASON_INVALID
	var saved := _identity_fields(saved_identity)
	var installed := _installed_versions(installed_identities)
	return {
		"reason": normalized,
		"title": _title(normalized),
		"lines": _lines(normalized, saved, installed),
		"actions": actions_for_reason(normalized),
		"saved_identity": saved,
		"installed_versions": installed,
		"data_modified": false,
	}


static func message(diagnostic: Dictionary) -> String:
	var lines: Array = diagnostic.get("lines", [])
	var body: Array[String] = []
	for line in lines:
		body.append(String(line))
	return "%s\n%s" % [String(diagnostic.get("title", "")), "\n".join(body)]


# One line for a row tooltip or a list entry: why it cannot load, nothing else.
static func summary(diagnostic: Dictionary) -> String:
	var lines: Array = diagnostic.get("lines", [])
	if lines.is_empty():
		return String(diagnostic.get("title", ""))
	return "%s %s" % [String(diagnostic.get("title", "")), String(lines[0])]


static func short_fingerprint(value: String) -> String:
	if not value.begins_with(_FINGERPRINT_PREFIX):
		return "unknown"
	var digest := value.substr(_FINGERPRINT_PREFIX.length())
	if digest.length() <= _FINGERPRINT_DIGITS:
		return digest
	return "%s…" % digest.left(_FINGERPRINT_DIGITS)


static func _title(reason: String) -> String:
	match reason:
		REASON_MISSING:
			return "Campaign package not installed."
		REASON_INCOMPATIBLE:
			return "No upgrade path for this save's campaign package."
		REASON_FINGERPRINT_MISMATCH:
			return "The installed campaign package does not match this save."
		REASON_MISSING_CONTENT:
			return "The campaign package is missing content this save needs."
		_:
			return "This save could not be read."


static func _lines(reason: String, saved: Dictionary, installed: Array[String]) -> Array[String]:
	if reason == REASON_INVALID:
		return [
			"The file is not a readable campaign save, or it is damaged.",
			"It was not stored. " + UNCHANGED_NOTICE,
		]
	var lines: Array[String] = [_saved_line(saved)]
	match reason:
		REASON_MISSING:
			lines.append("No version of this package is installed.")
			lines.append("Install it from Manage Campaigns, then choose Retry.")
		REASON_INCOMPATIBLE:
			lines.append(_installed_line(installed))
			lines.append("No installed version declares an upgrade from the saved version.")
		REASON_FINGERPRINT_MISMATCH:
			lines.append("Saved content fingerprint: %s" % saved["content_fingerprint"])
			lines.append("Reinstall the exact package version this save was made with.")
		REASON_MISSING_CONTENT:
			lines.append("Some campaigns, units or items this save refers to are not in it.")
			lines.append("Reinstall or update the package, then choose Retry.")
	lines.append("The save is kept as-is until then. " + UNCHANGED_NOTICE)
	return lines


static func _saved_line(saved: Dictionary) -> String:
	return (
		"This save needs %s v%s (content schema %d)."
		% [saved["package_id"], saved["package_version"], saved["content_schema_version"]]
	)


static func _installed_line(installed: Array[String]) -> String:
	if installed.is_empty():
		return "Installed versions: none."
	if installed.size() <= _MAX_LISTED_VERSIONS:
		return "Installed versions: %s." % ", ".join(installed)
	var shown := installed.slice(0, _MAX_LISTED_VERSIONS)
	return (
		"Installed versions: %s and %d more."
		% [", ".join(shown), installed.size() - _MAX_LISTED_VERSIONS]
	)


static func _identity_fields(identity: Variant) -> Dictionary:
	var source: Dictionary = identity if identity is Dictionary else {}
	var package_id := String(source.get("package_id", ""))
	var package_version := String(source.get("package_version", ""))
	var campaign_id := String(source.get("campaign_id", ""))
	return {
		"package_id": "unknown" if package_id.is_empty() else package_id,
		"package_version": "unknown" if package_version.is_empty() else package_version,
		"campaign_id": campaign_id,
		"content_schema_version": int(source.get("content_schema_version", 0)),
		"content_fingerprint": short_fingerprint(String(source.get("content_fingerprint", ""))),
	}


static func _installed_versions(identities: Variant) -> Array[String]:
	var versions: Array[String] = []
	if not identities is Array:
		return versions
	for identity in identities:
		if not identity is Dictionary:
			continue
		var version := String(identity.get("package_version", ""))
		if not version.is_empty() and not versions.has(version):
			versions.append(version)
	versions.sort()
	return versions
