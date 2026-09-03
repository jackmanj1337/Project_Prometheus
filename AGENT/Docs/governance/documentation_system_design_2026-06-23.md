---
Role: topic
---

# Documentation Sorting / Storage / Retrieval — Design Register

**Date opened:** 2026-06-23
**Status:** Active — ratified design for the `AGENT/Docs/` reorganization.
**Audit input:** `documentation_system_audit_2026-06-23.md`
**Builds on:** `documentation_governance_2026-06-13.md` (DOC-003 status vocab, DOC-009 decision
schema), `documentation_lifecycle_2026-06-13.md`, `decision_index.md`, `check_docs.py`.

> This register records the decisions the owner ratified on 2026-06-23 for how `AGENT/Docs/`
> is sorted, stored, indexed, and retrieved. Each decision lists the options weighed and the
> ratified choice. Implementation proceeds incrementally against this register; the **bulk
> `git mv` step is confirmed with the owner before it runs** (no file is deleted — archive only).

---

## DSR-1 — Doc taxonomy + lifecycle vocabulary  *(ratified)*

**Decision:** Reuse the DOC-003 status vocabulary unchanged for section/file status. Add a
small **TYPE** taxonomy and formalize the **register-lifecycle triplet** already used de facto.

- **TYPE** (one per file, declared in header): `register · design · plan · guide ·
  decision-record · governance · playtest · handoff · reference`.
- **Register lifecycle:** `OPEN · RESOLVED · SUPERSEDED` (a register-level status, distinct
  from the per-section governance vocab; "RESOLVED" = all `[XXX-n]` items decided).
- **File status:** the existing governance vocab (`Implemented / Pending validation / Known
  issue / Target design / Planned / Deferred / Open decision / Historical / Superseded` + `Split`).

**Why:** governance already defines a good vocabulary; the only missing axis is *type* (for
sorting) and an explicit *register* status (for the catalog). No new section-level words.

## DSR-2 — Storage layout: full by-type  *(ratified — full by-type)*

**Decision:** Group `AGENT/Docs/` by type, with one `archive/` for historical/superseded
material. Tooling (`check_docs.py`, the new generator) stays at the `AGENT/Docs/` root.

```
AGENT/Docs/
  INDEX.md            # generated doc map (all live docs by type + archive section)
  REGISTERS.md        # generated registers catalog
  check_docs.py       # tooling (stays at root — CI/hook reference this path)
  gen_docs_index.py   # the generator (stays at root)
  guides/             # active operational runbooks
  governance/         # doc-system rules + this design/audit + consolidation governance
  decisions/          # decision_index.md + decision_record_*.md
  registers/          # all [XXX-n] open-question / decisions registers (OPEN + RESOLVED)
  design/             # design + vision docs
  plans/              # implementation plans
  handoffs/           # session handoff docs
  playtests/          # build notes, checklists, returned checklists, findings, triage
  archive/            # superseded / historical / executed (with a marker; never deleted)
    plans/  playtests/  consolidation/  evidence/  reference/
```

**Cost accepted:** moving the 8 active guides + governance + `decision_index.md` requires
repairing their live inbound references (README, GDD_00, `testing_guide`, feature-index
manual-coverage cells, etc.) and updating the hard-coded path lists in `check_docs.py`
(`_ACTIVE_GUIDE_FILES`, the banned/template lists) — all in the same commit as each move
(DoD#1). This is the heavier option but gives the cleanest taxonomy, which the owner chose.

**Naming:** unchanged — `snake_case_topic_YYYY-MM-DD.md`. Date = when the doc was opened.

## DSR-3 — Central manifest: generated from headers  *(ratified — generated)*

**Decision:** A generator script `gen_docs_index.py` scans every `AGENT/Docs/**/*.md` header
block and (re)writes two artifacts:

- **`REGISTERS.md`** — one row per register: `id-prefix · title · file · status
  (OPEN/RESOLVED/SUPERSEDED) · id-range · resolved-where`.
- **`INDEX.md`** — the doc map: live docs grouped by type, plus an archive section.

These become **generated artifacts** (a header warns "do not hand-edit"). `check_docs.py`
gains a guard: running the generator must produce **no diff** (i.e. the committed
INDEX/REGISTERS match the headers) — the same self-consistency pattern as check 11.

**Required machine-readable header** (drives the generator; new convention enforced by
check_docs):

```
---
Type: register            # one of the DSR-1 TYPE values
Status: RESOLVED 2026-06-23   # register lifecycle OR governance status
Last verified: 2026-06-23
Register: ICO-1..6        # (registers only) prefix + range
Resolved-in: 2026-06-23e  # (resolved registers) session note / commit
---
```

Existing prose `**Status:**` lines stay for human reading; the fenced header block above is
what the generator parses. **Why generated:** roadmap §H rotted precisely because it was
hand-maintained prose — a generator can't drift from the headers.

## DSR-4 — Supersession marking  *(ratified)*

**Decision:** Extend the existing `_is_historical()` hook. A superseded/archived doc carries,
in its **first 10 lines**, a blockquote marker:

```
> **Superseded** by [`<new-file>`](<relative/path>) — 2026-06-23. <one-line why>.
```

- `check_docs.py._is_historical()` regex extends to also match `Superseded` (today it matches
  only `Historical|ARCHIVED|Archived`).
- New check: any file under `archive/` MUST carry a `Historical`/`ARCHIVED`/`Superseded`
  marker, and a `Superseded by [..](path)` target path MUST exist. This makes "which decision
  is live" unambiguous from inside any dead doc.

## DSR-5 — Retrieval workflow  *(ratified)*

**Canonical answers:**
1. *"What's active / where do I start?"* → `AGENT/Docs/INDEX.md`.
2. *"Where was decision X made / is register Y open?"* → `REGISTERS.md` (feature `[XXX-n]`
   IDs) or `decisions/decision_index.md` (governance `DOC/RULE/SET/...` IDs); the two
   cross-link in their headers.
3. *"Is this doc still live?"* → its header `Status` + (if archived) its `Superseded by` marker.

**AGENTS.md rule (new, enforced):** "When you open a new register or doc, it is picked up by
`gen_docs_index.py`; run it and commit the regenerated `INDEX.md`/`REGISTERS.md` in the same
change" — paired with the DSR-3 no-diff check (DoD#2).

## DSR-6 — Topic/dated role and stable-ID routing  *(added 2026-08-23)*

Every live document declares `Role: topic` or `Role: dated` in front matter. Topic
documents are sorted by subject and corrected in place; dated documents are sorted by
when they were written and serve as input/evidence. Frozen archives and the retired
session-note tree are dated by their containing corpus and are not mass-rewritten.

Top-level GDD documents also declare a `Topic ID`. `gen_docs_index.py` extends the
existing `GDD_Feature_Index.md` mechanism with a generated stable-ID table: topic IDs
resolve to documents, and ruling IDs cited by a GDD section resolve to that exact heading
plus their dated evidence source. Cross-corpus topic links and GDScript rationale use the
stable ID, never a movable dated-document path.

Numbered GDD chapters receive a cohesion/split review when they exceed 1,200 lines. The
threshold triggers a decision; it does not force a mechanical split. Split on a durable
domain boundary when one exists, or add `Split review:` to front matter explaining why
the chapter remains one cohesive owner. This replaces the prior ad-hoc response to chapter
growth.

---

## Implementation order (one logical step per commit)

1. **This register + the audit** (docs-only; no moves). ← *this commit*
2. **Generator + checks scaffolding** on the *current flat layout*: add `gen_docs_index.py`,
   extend `_is_historical()` for `Superseded`, add the no-diff + archive-marker checks
   (disabled/relaxed until layout exists), generate the first `INDEX.md`/`REGISTERS.md`.
3. **Headers pass**: add the fenced `Type/Status/Register` header to every doc (edits, not
   moves). Regenerate. check_docs green.
4. **Bulk `git mv` into the by-type layout** — *confirmed with owner first*. Split by group
   (registers/, playtests/, archive/, then guides+governance+decisions with their ref repairs
   + `check_docs.py` path updates). Regenerate after each group. check_docs green per commit.
5. **Historical implementation closeout:** this originally required a session note and
   Session Notes index row. The session-note practice was retired 2026-08-23; commits and
   the canonical tracker now carry that outcome.

**Invariants every commit:** `check_docs.py` green; no `__pycache__`; `git mv` preserves
history; live inbound refs + GDD/roadmap pointers repaired in the same commit as the move
(DoD#1); nothing deleted (archive only).
</content>
