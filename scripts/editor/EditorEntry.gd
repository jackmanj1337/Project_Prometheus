class_name EditorEntry extends RefCounted
# The two ruled entry points' shared precondition, and the Test launch's activation.
#
# `[CEUI-S13]`/`[CEUI-S22]` RULE TWO ENTRIES AND ONE PRECONDITION. The main menu, and the
# library's *Edit a copy*. Both are pre-campaign shell contexts, which is the whole reason
# the editor never shows a "this will end your run" confirmation: it is offered only where
# there is no run. What `[CEUI-S13]` protects is that precondition, and `[CEUI-S22]` says
# so explicitly when it amends the ruling to two entries.
#
# THE PRECONDITION IS ASSERTED, NEVER ASSUMED, AND THAT IS A BUILD GATE. `[CSA-28]` clause
# (f) ruled that quit-to-shell deactivates. That IS now built --
# `CampaignManager.quit_to_shell()` calls `DataManager.reset_to_boot_content_baseline()`,
# which deactivates, and three production paths reach it. But "the way back to the menu
# deactivates" and "nothing is active when the editor opens" are different statements, and
# only the second is what `[CEUI-S9]` call 1 needs. A package still active when a working
# copy is activated over it is the provenance failure that ruling exists to prevent, so
# entry ASKS rather than trusting the path it was reached by.
#
# IT REFUSES; IT DOES NOT DEACTIVATE. Deactivating here would be the entry transition
# `[CEUI-S13]` deliberately removed -- ending someone's run as a side effect of opening a
# tool, with no confirmation, because the confirmation was ruled away on the grounds that
# the situation cannot arise. If it arises anyway, that is a defect on the path that got
# here, and quietly ending a campaign would hide it.
#
# THE SANDBOX IS PART OF ENTRY, NOT OF THE TEST SESSION. `[CEUI-S3]` ruled autosave
# sandboxed and `[CEUI-S9]` call 3 restates it as a TEST OBLIGATION: the hazard is the
# editor session writing into player slots. `SaveManager.save_dir` is a plain field, so the
# sandbox is a matter of setting it before a session can run and restoring it after --
# which means it belongs to whatever owns the editor's lifetime, not to the session that
# would otherwise be the thing responsible for not corrupting the saves around it.

## Why entry is refused when content is live. Author-facing: `[EPUX-07]` requires a gated
## entry to carry its reason, and this is the reason.
const ACTIVE_PACKAGE_REASON := (
	"Close the active campaign before opening the editor. "
	+ "The editor works on its own copy and never edits a campaign that is loaded."
)

## Why a Test launch is refused with no working copy. Distinct from the shell's own
## `NO_WORKING_COPY_REASON`, which gates the header button; this one answers a caller that
## reached the activation anyway.
const NO_WORKING_COPY_REASON := "Import a campaign working copy before testing it."


## Whether the editor may be opened, and why not when it may not.
##
## `data_manager` is passed rather than looked up so this is assertable headlessly and so a
## caller cannot accidentally ask a different DataManager than the one it will activate on.
## A null manager ALLOWS entry: no content can be active when nothing owns content, and
## refusing there would make the editor unreachable in exactly the configuration that is
## safest.
static func precondition(data_manager: Node) -> Dictionary:
	var identity := active_identity(data_manager)
	var active_id := String(identity.get("package_id", ""))
	if active_id.is_empty():
		return {"allowed": true, "reason": "", "active_package_id": ""}
	return {"allowed": false, "reason": ACTIVE_PACKAGE_REASON, "active_package_id": active_id}


static func active_identity(data_manager: Node) -> Dictionary:
	if data_manager == null or not data_manager.has_method("active_package_identity"):
		return {}
	var identity: Variant = data_manager.call("active_package_identity")
	return identity if identity is Dictionary else {}


## `[CEUI-S9]` call 1: a Test launch activates THE WORKING COPY, as a dev source with its
## own distinct identity.
##
## The identity is verified AFTER activation rather than trusted. `activate_campaign_package`
## reads the pack's own manifest, so the only way the runtime could come up claiming the
## installed pack's identity is if the copy's manifest still said so -- which is precisely
## the failure this ruling names, and the cheapest place to catch it is the moment it would
## first be true.
static func activate_for_test(data_manager: Node, working_copy: EditorWorkingCopy) -> Dictionary:
	if working_copy == null or not working_copy.is_open():
		return {"activated": false, "reason": NO_WORKING_COPY_REASON}
	if data_manager == null or not data_manager.has_method("activate_campaign_package"):
		return {"activated": false, "reason": "No content service is available to test with."}
	var expected := working_copy.identity()
	var gate := precondition(data_manager)
	if not bool(gate["allowed"]):
		return {"activated": false, "reason": String(gate["reason"])}
	var ok: bool = data_manager.call(
		"activate_campaign_package",
		working_copy.path(),
		String(expected["package_id"]),
		String(expected["package_version"])
	)
	if not ok:
		return {"activated": false, "reason": "The campaign working copy could not be loaded."}
	var live := active_identity(data_manager)
	if String(live.get("package_id", "")) != String(expected["package_id"]):
		# Nothing may be left running under an identity that is not the working copy's:
		# a save taken from here would claim provenance it does not have.
		if data_manager.has_method("deactivate_campaign_package"):
			data_manager.call("deactivate_campaign_package")
		return {
			"activated": false,
			"reason": "The campaign working copy activated under another package's identity."
		}
	return {"activated": true, "reason": "", "identity": live}


## Ends a Test session. Separate from `quit_to_shell()` on purpose: that function also
## resets map state and changes scene, which is the PLAYER's route back to the menu. The
## editor's Test session ends inside the editor, and the only thing it owes is that the
## working copy stops being active content.
static func deactivate_after_test(data_manager: Node) -> void:
	if data_manager != null and data_manager.has_method("deactivate_campaign_package"):
		data_manager.call("deactivate_campaign_package")


## Points a save service at the working copy's own sandbox and answers the directory it
## had. `[CEUI-S9]` call 3's obligation in one call, with the previous value returned so
## the caller can put it back -- an editor session that left `save_dir` pointing into a
## draft would send the next PLAYER save there, which is the same failure in the mirror.
static func sandbox_saves(save_manager: Node, working_copy: EditorWorkingCopy) -> String:
	if save_manager == null or working_copy == null or not working_copy.is_open():
		return ""
	var previous := String(save_manager.get("save_dir"))
	var sandbox := working_copy.session_save_dir()
	DirAccess.make_dir_recursive_absolute(sandbox)
	save_manager.set("save_dir", sandbox)
	return previous


static func restore_saves(save_manager: Node, previous: String) -> void:
	if save_manager == null or previous.is_empty():
		return
	save_manager.set("save_dir", previous)
