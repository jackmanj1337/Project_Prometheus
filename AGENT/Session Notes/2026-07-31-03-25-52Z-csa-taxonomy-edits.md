# Session Note - 2026-07-31-03-25-52Z-csa-taxonomy-edits

## Branch context

- Branch: `agent/from-integration/campaign-sprite-authoring-register`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `FIX-CSA-TAXONOMY-EDITS-2026-07-31`

## What was done

Applied the three edits the closed CSA register owed
`campaign_asset_taxonomy_and_format_2026-07-01.md`. The walk widened twice, both
times because the superseded clause turned out to have propagated.

### The three owed edits (as specified)

1. **`[CSA-33]`(c)** — deleted the `res://`→`user://` first-run seed-copy clause.
   Replaced with the actual model: the program ships no campaign pack, packs are
   distributed alongside the executable, and they arrive by **explicit
   user-initiated import**. "No packs installed" is stated as the ordinary
   first-run state.
2. **`[CSA-28]`(d)** — deleted the shipped-default icon atlas clause.
   **Judgment call, owner-confirmed:** the Icons **row was kept**, not deleted as
   the tracker note said. Whether an author packs their own icons as an atlas or
   drops in single files is a real format decision that survives `[CSA-28]`(d)
   intact; only the "we ship a default set" half was subject-less. Added a
   `> No shipped default art set` block covering `[CSA-28]`(c)/(e).
3. **`[CSA-2]`** — deleted the `.tres` authoring-path carve-out for the built-in
   default content palette. There is no default pack, so every pack is pure JSON
   with no privileged authoring route.

### Also applied to the same document

- **`[CSA-7]`** — rewrote the frame-metadata section. Arbitrary **two-point
  rects** are now *the* form with an **optional per-frame pivot defaulting to
  bottom-centre**; the uniform grid survives as an editor-generated convenience.
  This supersedes the old rule on **both** halves (grid-preferred for authored
  sheets, frame-table reserved for a shipped default set).
- Repointed the stale `B6-SPRITE-IMPORTER` / `[IMP-1..6]` author-workflow
  references at the CSA register, noting the scope is an **asset manager**, it
  lives in **our** editor, and `IMP-EDITOR-PLUGIN` is retired.
- Replaced the "importer stays HELD until asset sourcing is decided" sequencing
  note — asset sourcing is decided and the engine-side rows are ungated.

### Scope widening 1 — the clause had a second home

`ui_theme_and_asset_resolution_2026-07-03.md` carried the same shipped-default
assumption in **four** places, one of them **inside a chain the document declares
locked**: resolution order step 4 was *"Shipped default theme, copied into
`user://` on first run"*. A locked contract with a dead rung is worse than an
unlocked one, so:

- deleted that step, and added the `[CSA-27]` **per-pack player theme override**
  above the pack default (an override below the value it overrides is worthless);
- reworded `icon_atlas_default` as the active pack's fallback atlas, plus a note
  that `*_default` means *fallback within the active pack*, never art we ship;
- deleted the "`.tres` for the shipped default" clause on `UiThemeDef`;
- closed its open questions 1 (default theme authoring) and 2 (icon atlas source)
  — both were already answered by the CSA close.

### Scope widening 2 — a third home

`ui_ux_asset_inventory_and_reuse_2026-07-02.md` — closed two open questions the
CSA walk had already answered: animation scope (`[CSA-10]`, no animation
required) and icon authoring source (text-only; there is no default campaign to
ship an atlas for).

## Deliberately NOT done — spun out

`FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31`. Two more documents still assert
the `[ICO-5]` first-run seed copy:

- `AGENT/Docs/design/campaign_save_expectations_and_foundations_2026-06-23.md:59`
- `AGENT/Docs/registers/campaign_content_overlay_open_questions_2026-06-23.md:54,127,128,163`
  (including a `seed_user_content()` sketch)

**Left alone on purpose.** `[ICO-1..6]` is a ratified foundation the CSA register
explicitly says not to re-open, and this supersession is owned by the
zero-content track, not by CSA. That is an owner call, not a doc edit.

**Verified while flagging it:** `seed_user_content()` has **no implementation
anywhere in `scripts/`** — it was never built. So this is a stale contract rather
than live behaviour: cheap to retire, and correspondingly easy to overlook.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated; no INDEX/REGISTERS row
  changed (titles and statuses were untouched), so nothing to commit there.
- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 43 checks green.
- Confirmed **no automated check depends on the deleted prose**: check 32
  (campaign asset boundary) operates on `scripts/` and `data/campaign_packs`, not
  on this document's text.
- Pre-commit: gdscript style PASS (257 files); Godot suite skipped, docs-only.
- `python3 coordination/check_tasks.py` — OK, 216 tasks valid.

## Correction — the seed deletion was too broad

Caught while scoping the next session's web-export work, **after** `5344b96a` had
landed. That commit replaced the seed-copy clause with a flat *"the program ships
no campaign pack at all … never by a seed copy"*.

**That is right for desktop and wrong for web.** `[CSA-35]` (resolved C) requires
the **web build to package exactly one first-party/generated/CC0 pack inside the
bundle** and seed it `res://`→`user://` on first run — because on web there is no
"alongside", the browser gets one bundle, and `user://` is browser storage a cache
clear wipes. The register even says the two channels *deliberately* differ.

So the mechanism I deleted the description of is the one the web channel needs.
`c2f28e06` restates the section as a **per-channel split** and fences the
surviving seed path to web only, so it does not get generalised back into a
desktop default-content path. **What is retired is the general "default campaign"
seed model, not seed-copying as such** — a distinction that matters for
`FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31`, whose reference now carries the
same warning.

*Why it slipped:* `[CSA-33]`(c) was framed as a clause deletion, and I applied it
as one without checking whether another resolved item depended on the mechanism.
`[CSA-35]` is fourteen sections away in the same register.

## Commits claimed

- `5344b96a468f67e3e79f0a1f82712b9892f9e3f8` — Apply the CSA-decided deletions to the ratified asset design docs
- `c2f28e066182d543b2a29670d52df440f875f8e6` — Correct the pack-arrival clause: web bundles a pack, desktop does not

## Next

**Owner set the next session's topic: check the web export blockers** —
`INVESTIGATE-WEB-EXPORT-BLOCKERS-2026-07-31`. Measure the actual export
(`scripts/export-web.sh`, `serve-web-local.sh` both exist) rather than reading
docs. Five candidates to confirm or dismiss are on the row; the likely largest is
that **no first-party/generated/CC0 demo pack exists yet**, which is a content
problem rather than a code one.

Then:

1. **`FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31`** — owner has now made the
   call (retire it), so this is execution. **Read its web carve-out first.**
2. The ungated engine-side CSA slices remain ready: sidecar schema + validator,
   runtime slicer, `AssetResolver` semantic groups + fallbacks, `art_asset@1`
   with source/licence, `Unit`→`AnimatedSprite2D`.

**Lesson worth keeping:** a superseded clause propagates. Three documents carried
this one, and the instance that mattered most was inside a chain marked "locked".
Grep the whole `design/` tree for the ratified phrase before calling a
contract edit done.
