class_name ValidationGate extends RefCounted
# The three gates `[CEUI-S27]` ruled, named once so nothing invents a fourth.
#
# `CEUI-19` asked about *test* and *export* while the ratified runtime vocabulary is
# *activation* and *export*. Naming a Test launch an ACTIVATION (`[CEUI-S9]` call 1) is
# what makes the editor's gates the same gates the runtime already has, instead of a
# parallel pair somebody has to keep in step.
#
# Two of the three share a predicate on purpose. `[CEUI-S9]` ruled two export
# DESTINATIONS, not two validations: export-to-library and export-to-file differ only in
# where the artifact lands. They stay separate constants because a caller reports which
# one it is refusing, and collapsing them into one name would lose that sentence.

## A Test launch in the editor is an activation of the working copy, so this is also the
## gate the editor's Test button asks about.
const ACTIVATION := "activation"
const EXPORT_LIBRARY := "export_to_library"
const EXPORT_FILE := "export_to_file"
const GATES: Array[String] = [ACTIVATION, EXPORT_LIBRARY, EXPORT_FILE]


## The draft / release-complete axis, which belongs to the credits and localization
## registers (CRD-9, L10N-14), not to a second severity system. A working copy is a DRAFT:
## it activates with gaps a finished release may not ship with. This predicate is the only
## place that distinction is drawn.
static func is_release_complete(gate: String) -> bool:
	return gate == EXPORT_LIBRARY or gate == EXPORT_FILE


static func is_known(gate: String) -> bool:
	return gate in GATES
