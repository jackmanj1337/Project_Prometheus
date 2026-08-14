# Session Note - 2026-08-14 (CEUI walk resumed)

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `6d4c483d99448eb2a8e959117f08117b7208b611`
- Coordination Work ID: `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`

## What was done

Resumed `S10`, the `CEUI` owner walk, from where the previous session paused (three rulings in,
resume point diff §3.2). **Nine further rulings, `[CEUI-S4]` through `[CEUI-S12]`.** Section A is
closed and every item the `S9` precedence diff marked urgent is answered.

**`[CEUI-S4]` — the web target (diff §3.2).** The diff framed a binary: capability-gated
affordances, or a declared lesser environment. The ruling is the second, **scoped to one axis and
mitigated in the build** — every web build ships a *standing* recommendation to export important
data frequently to durable storage, import is streamlined so that habit is cheap, and the residual
eviction risk is accepted because desktop exists and dedicated mobile builds are planned.

The session found the diff had **missed a built seam**. `TransferFileService` already solves the
web file-transfer problem — its header states it exactly ("on web `FileDialog` browses the
Emscripten virtual filesystem…"), it stages through `user://` into `JavaScriptBridge.download_buffer`
and imports through a short-lived `<input type=file>`, and it does so **without changing any
consumer's path-taking API**. Four screens already consume it. So `CEUI-33`'s import and
`CEUI-38`'s export are **not platform questions at all**; the editor is a fifth consumer. What *is*
absent on web is **live disk coupling** only — `CEUI-16`'s external-edit detection and the "Show
file"/"Open externally" actions.

**`[CEUI-S5]` — raw JSON.** `CEUI-22`'s recommended "read-only plus Open externally" would have
preserved `[DLUX-11]`'s ratified *"hand-edited JSON remains a first-class input to the same
validator"* on desktop and **silently retired it for every web author**. Ruled option B narrowed to
a **plain Notepad-level text view** of one record, revalidating on commit. The owner's second
rationale is load-bearing and changed the design: it is also the fallback when the structured
editor GUI fails on a record, so **it must be a peer view, not a tab inside the form that broke**.

**`[CEUI-S6]` — editor Undo is not a third primitive (diff §3.3, and §3.4 with it).** The proposed
chronological individually-reversible project history is **not adopted**. The model is the ordinary
document one — *open, change, save; an interruption reverts* — which is a **staged transaction**
scoped to the open document. Three scoping calls, all minimal for v1: **file-touching operations
(import, bake, asset delete) are excluded from Undo**, history is **session-scoped**, and `CEUI-14`
is therefore **document-local (option B), inverting the packet's recommendation and this session's
own initial recommendation**. `CEUI-15` names its target explicitly — the two-primitive staged
transaction, **not** `TSV-1..24`, whose consequence #1 forbids most of what `CEUI-15` describes.

**`[CEUI-S7]` — the content palette (diff §4.3) was a provenance defect, not an open question.**
The owner ruled it **2026-08-10**: none of A–D, but **option (E), generate it** — the editor
procedurally generates flat-colour RGBA panels so a new pack has working art immediately, and
curated look-and-feel ships as separately distributed UI element combinations. That ruling lived in
the tracker row and **in no document**. The diff's guess that "option A is the likely answer" was
**wrong**. Recorded here; the row's two stated-not-ratified assumptions were confirmed by the owner
and are now ratified. `FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31` is unblocked, and its two
target lines must be **rewritten to describe generation, never deleted** — deleting picks option A.

**`[CEUI-S8]` — id rename.** Opt-in, confirmed per rename, dialog naming how many records and
which, warning that the rewrite cannot be automatically undone. This is `CEUI-36`'s already-ruled
pattern, so the editor gets **one** "touches records you do not have open" interaction rather than
two. A `CEUI-37` recovery snapshot is taken immediately before the rewrite commits.

**`[CEUI-S9]` — the editor/library boundary (diff §4.4).** The owner ruled a **strict separation**:
the editor imports a *copy*, and playing it outside the editor requires an **explicit export back
to the library as its own version**. This makes `CL-ADV-01`'s "installed packs are immutable"
**structurally** true — the editor has no path that writes into the installed root. Test activates
the working copy under its own visible identity; editor entry is **quit-to-shell**; existing player
saves are unreachable by editing (`select_saved_campaign_source`: *"Paths never come from save
data"*), so the hazard runs the other way and `[CEUI-S3]`'s autosave sandboxing becomes a **test
obligation**; and the editor is **not** a sixth `EPUX-02` availability surface. Two consequences
recorded so they are not left implicit: **two export destinations** (library and file), and the
embedded session is **not** the developer-mode loose-folder path.

**`[CEUI-S10]` — export-back forks, and packs gain an author.** `PackManifest` carries no author
field, so the editor cannot detect ownership — the default is chosen on risk. Export-back **takes a
new id**; the manifest gains a **pack-level author defaulted from an editor-settings profile and
overridable at export**, so anonymous publication is supported. Two guardrails written: the field
is **never a trust signal** (no accounts, no verification, forgeable by construction), and
anonymity covers *your* authorship and **not** third-party per-asset attribution, which is a
licensing obligation. The field must be **optional** to avoid a `format_version` bump.

**`[CEUI-S11]`/`[CEUI-S12]` — Section A closed.** `CEUI-7`'s "collapse labels to icons at the
floor" clause is **retired** (`[CEUI-5]` deleted the floor behaviour) and **replaced** rather than
deleted, because `[L10N-7]`'s 1.4× extent still overflows a seven-action header at the only
viewport the editor has: **labels always, header scrolls on overflow**. That is the project's
second instance of the same overflow answer after `UBS-4`'s scrolling dialogue line — a third
surface should adopt it rather than invent a third behaviour. `CEUI-8` gains a **seventh
workspace, Localization** (Content, Maps, Graph, Assets, Localization, Test, Release), resolving
diff §4.2's finding that four ratified `L10N` obligations are authored work the packet mentions
zero times. `CEUI-1`/`3`/`4` confirmed as recommended, with tabs made explicit as independent
`[CEUI-S6]` transactions.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`. Six ruling commits, each with its ledger claim:
the web target and raw JSON view (`b78380e6`), editor Undo (`7c9e177b`), the generated authoring
floor and id-rename propagation (`fdec344b`), the editor/library boundary (`d0c6ff41`), export-back
forking and the author field (`d36e09b2`), and Section A's close.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS (44 checks) before every commit.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — PASS, ledger current.
- Pre-commit ran RNG guard, analyzer tests (12 OK), scene integrity (23 scenes), evidence
  matrices, and GDScript style (320 files) on each commit; Godot suite skipped as docs-only.
- No code changed this session. The code claims above were **read** from
  `scripts/resources/TransferFileService.gd`, `scripts/resources/CampaignPackRegistry.gd`,
  `scripts/resources/PackManifest.gd` and `scripts/autoloads/DataManager.gd` — not modified.

## Next

**Owner's choice: generate editor wireframes.** The shell is now fully specified for that — `CEUI-1`
composition, `CEUI-3` tabs, `CEUI-4` fixed docks, `CEUI-7` header, `CEUI-8`'s seven workspaces,
`[CEUI-5]`/`[CEUI-S2]`'s single Expanded state at a `1920×880` effective floor, and `[CEUI-S1]`'s
own scale column.

**What the wireframe session must treat as unsettled:** the workspace *interiors*. Sections B–F
residues are still open (`CEUI-9`–`12`, `17`–`21`, `23`–`31`, `33`–`36`, `39`, `40`) and so are the
twelve `NMTE` questions scheduled as `S11`. Draw the shell and the workspace frames; do not draw
Inspector or map-tool interiors as though ruled.

**Formally**, `UBS-8` lifts and the `UUI-15` album hold releases only when the whole `CEUI` walk
closes, which it has not. Wireframing the shell ahead of that is an owner decision, not a gate
being met — record it as such.

**Also owed:** a successor row for the separately distributed curated UI element combinations
(`[CEUI-S7]`), and `[L10N-16]`'s pseudolocale-capture boundary between the Localization and Test
workspaces (`[CEUI-S12]`).
