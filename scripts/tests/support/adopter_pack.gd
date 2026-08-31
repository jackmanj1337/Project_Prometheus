extends RefCounted
## Locates a sibling campaign-pack checkout for the authored-pack adopter proofs.
##
## WHY THIS EXISTS. Both proofs (test_shared_effect_pack_proof.gd and
## test_session7_pack_proof.gd) carried their own copy of a three-candidate path
## chain that resolved only against res:// and PWD, and printed a skip plus
## quit(0) when every candidate missed. The gated run --
## scripts/run-full-tests.sh -> the container's scripts/check-receipt.py -- runs
## the suite from a throwaway detached worktree under /tmp with cwd set to that
## tree, so every candidate DID miss on every gated run: the milestone-closing
## proofs skipped, exited 0, and run_tests.sh reported "PASS: all suites green".
## Measured and reproduced 2026-08-31 (SHARED-EFFECT-PROOF-GATE-ENFORCEMENT).
##
## Two halves to the fix. check-receipt.py now exports AGENT_SIBLING_REPO_ROOT,
## the real workspace root the sibling checkouts live under, which is the only
## candidate that can survive being run from a temporary tree. And an unreachable
## pack is no longer one outcome but two, because the difference decides whether
## a green run means anything:
##
##   FOUND    the pack is there; run the proof.
##   MISSING  the pack's REPOSITORY is checked out beside this one but the pack
##            itself is not in it -- an incomplete checkout, or one sitting on a
##            branch that does not carry the content. The environment was expected
##            to prove the adopter and could not: that is a FAILURE, not a skip,
##            and it is the exact shape of the second cause this row recorded
##            (the authored content living only on an unmerged pack branch).
##   ABSENT   the pack repository is not beside this one at all: CI's
##            single-repository checkout, or a bare clone. Skip, and say so
##            loudly.
##
## That is the same rule scripts/ci/check_pack_freshness.sh already applies to the
## same packs, and the same rule the note-index gate established: a thing that is
## absent skips; a thing that is present and wrong fails.

const FOUND := "found"
const MISSING := "missing"
const ABSENT := "absent"


## Every root a sibling checkout could live under, best first. The environment
## variable comes first precisely because it is the one the exact-tree run sets.
static func candidate_roots() -> Array[String]:
	var roots: Array[String] = []
	var declared := OS.get_environment("AGENT_SIBLING_REPO_ROOT")
	if not declared.is_empty():
		roots.append(declared.simplify_path())
	roots.append(ProjectSettings.globalize_path("res://..").simplify_path())
	var pwd := OS.get_environment("PWD")
	if not pwd.is_empty():
		roots.append(pwd.path_join("..").simplify_path())
		roots.append(pwd.path_join("repo").simplify_path())
	var unique: Array[String] = []
	for root in roots:
		if not unique.has(root) and DirAccess.dir_exists_absolute(root):
			unique.append(root)
	return unique


## Resolves `relative_path` -- "<pack repo>/packs/<pack>" -- against the candidate
## roots. Returns {state, path, detail}; `detail` is written to be printed
## verbatim, because a skip nobody can act on is how this hole survived.
static func locate(relative_path: String) -> Dictionary:
	var repo_dir := relative_path.get_slice("/", 0)
	var roots := candidate_roots()
	var repo_roots: Array[String] = []
	for root in roots:
		if DirAccess.dir_exists_absolute(root.path_join(repo_dir)):
			repo_roots.append(root)
		var candidate := root.path_join(relative_path).simplify_path()
		if DirAccess.dir_exists_absolute(candidate):
			return {"state": FOUND, "path": candidate, "detail": "resolved under %s" % root}
	if not repo_roots.is_empty():
		return {
			"state": MISSING,
			"path": "",
			"detail":
			(
				(
					"%s is checked out under %s but does not contain %s. "
					+ "This environment was expected to prove the adopter and cannot: "
					+ "the checkout is incomplete, or on a branch without the content."
				)
				% [repo_dir, ", ".join(repo_roots), relative_path.trim_prefix(repo_dir + "/")]
			)
		}
	return {
		"state": ABSENT,
		"path": "",
		"detail":
		(
			"%s is not checked out beside this repository, so %s cannot be reached. Roots searched: %s"
			% [repo_dir, relative_path, ", ".join(roots)]
		)
	}
