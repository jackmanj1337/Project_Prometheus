# Session Note - 2026-08-13

## Branch context

- Branch: `agent/integration` (the docs line)
- Base branch: `agent/integration`
- Base SHA: `919c9d5e0c02eadd460f12383bf1ab49cd51b8aa` ("Close out the shop wireframe session")
- Coordination Work IDs: `UNBUILT-SCREEN-RESEARCH-SESSIONS-2026-08-12`,
  `LOCALIZATION-I18N-SCOPE-2026-08-12`, `LEG-INGAME-ATTRIBUTION-2026-07-20`

## What was done

Walked three owner-question registers to completion — `TSV-1..24`, `L10N-1..18` and
`CRD-1..10` — and merged the six 2026-08-12 research packets onto the docs line, where they
had never been.

**The packets were invisible.** All six — transaction surface, localization, credits,
non-modal text entry, campaign editor, prep/deployment — lived only on
`agent/from-integration/responsive-prep-deployment-research`, unmerged. `agent/integration`
had none of them. This is the failure mode `AGENTS.md` describes as "a plan on an unmerged
branch is invisible to anyone not standing on that branch", and it had a concrete
consequence, below.

### `TSV-1..24` — the transaction surface base packet

Eleven ruled, three restated from the album session, eight deferred to already-ratified
decisions, two mooted. **The register is `RESOLVED`, and the hold it placed on convoy/shop
presentation is lifted.**

**The packet had never been checked against the `EPUX` walk of 2026-07-25/26**, and argued
against ratified text three times:

- `TSV-8` recommended an engine-side risk classification for which actions confirm. `EPUX-06`
  had ratified confirmation **authored on the action** as a predicate, raise-only.
- `TSV-4` recommended an "Adjust to N" partial-commit recovery. `EPUX-21`'s live effective
  maximum and `EPUX-11`'s fail-before-commit make the case it recovers from unreachable.
- `TSV-20/21/22` were written for **per-receipt undo**. `EPUX-06`/`EPUX-28` ratified
  **whole-activity snapshot rollback**. Two mechanisms, not two descriptions of one.

The owner ruled EPUX stands in all three. `TSV-22` is retired outright: under snapshot
rollback there is no decaying window, so there is no expired-with-reason state to present.

**The provenance gap this closed.** `shop_transaction_wireframes_2026-08-12.md` and the shop
album both cite `TSV-1..9` as *ratified transaction vocabulary*, and the album marks those
frames as drawn-to-a-ruling rather than drawn-to-a-recommendation. **No such ruling existed on
any branch** — `[TSV-1]` in bracket form appeared only in the packet itself, whose header
still read "owner walk not started". The substance did trace to ratified `EPUX` decisions
under different ids, so the drawings stand; the citation did not. `TSV-1..9` are now
genuinely dispositioned. This is what the unmerged packet cost: nobody could check the
citation, because the cited document was not on the branch doing the citing.

**New from the walk**, none of it in the packet:

- Hide-versus-disable is **one connected author-facing system** driven by the availability
  predicate system, with author-written text available specifically so story elements can be
  concealed while the row still explains itself. **Transactional failure is exempt** —
  insufficient funds, full capacity and failed eligibility are always disabled-with-reason,
  never hidden. The author controls what stock exists; the engine controls affordability.
- **A store declares whether it offers a receipt, and one that does not has no reversal at
  all.** A deliberate authoring lever for high-stakes and story shops. It carries an unsolved
  obligation: the player must be able to tell which kind of store they are in *before*
  spending.
- **A player may auto-accept receipts.** This required marking a boundary inside `EPUX-06`:
  "raise-only" governs the per-action confirmation prompt, which stays author-controlled; the
  exit receipt is review-and-rewind, a separate mechanism. That sentence is now in the EPUX
  document, which is the one edit this walk owed an already-ratified doc.
- **Cancel has no meaning mid-panel**, because `TSV-1` removed the cart. The only boundary is
  the exit: no transactions leaves silently; any transaction gets confirm/revert, and
  **revert restores the entry snapshot and leaves the player still in the store**.

### `L10N-1..18` — localization scope

B everywhere except `L10N-13` (C). Five ruled with discussion, thirteen adopted as
recommended. **Register `RESOLVED`.**

Three answers were forced rather than chosen: pack-owned catalogues by `[ICO-1..6]`
self-containment; untranslated registry IDs by save durability; live locale change by the
responsive contract, which `[TSV-24]` had just extended to focus and selection in the same
session.

**This register jumped the queue for a reason.** Three of its five ruled questions are being
answered *by construction* right now — the responsive conversions are rewriting every scene,
and the expansion budget and direction assumptions harden into each one as it is written. So
both constraints were **propagated into `responsive_ui_redesign_2026-08-06.md` in the same
change** rather than left to be discovered:

- `~1.3×` text extent becomes **1.4×, proven against a generated pseudolocale** at every
  durable viewport. 1.3× is a real-world average; short labels, the ones with no slack,
  routinely exceed it.
- **Direction becomes declared component metadata**, defaulting to non-mirroring. Reading and
  navigation structure mirror under RTL; the tactical map, directional icons and numeric
  conventions do not.

At 360×640 the shop album measures 4.3 rows, so there is no room to absorb 1.4× by growing
layouts. Some source copy gets shorter instead.

### `CRD-1..10` — credits and attribution

B throughout; `CRD-8` and `CRD-9` ruled with discussion. **Register `RESOLVED`.**

`CRD-8` makes the **theme its own notice source**, because `[UUI-14]` expects authors to copy
Pack 0's theme assets into their packs and the obligation has to travel with the copy —
otherwise the provenance strands in the engine's notice set and the copy ships uncredited.

`CRD-9` fails public export on a missing required notice, but **only for obligations someone
recorded**, which makes `LEG-4`'s asset audit load-bearing rather than merely open. Until it
lands, a green validator is not proof of compliance.

Also ruled the trigger `[UBS-9]` left implicit: **existing PWA playtest hosting is not public
distribution**, so credits stays scheduled rather than blocking. That holds only while the
hosting stays unlisted — recorded as an explicit condition, because nothing in the code
enforces it and widening distribution moves this row to the front.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

Three commits on `agent/integration`. A `--no-ff` merge brought the six research packets onto
the docs line. `fddfc3d9` dispositioned `TSV-1..24` and added the `EPUX-06` boundary sentence.
`7591078d` walked `L10N` and `CRD` and propagated the two responsive constraints into the
redesign doc.

Landed on the docs line rather than a feature branch, for the same reason the shop wireframe
session did: the docs-guard hook refuses these edits on a feature branch.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` and `REGISTERS.md`, twice.
- `python3 AGENT/Docs/check_docs.py` — **PASS, all 43 checks green**, run after each register.
- `check_gdscript_style` — PASS, 320 tracked files (docs-only change; the Godot suite was
  correctly skipped by the pre-commit hook).
- `check_session_commit_claims.py --fix` — PASS, 703 post-bootstrap commits audited.
- Scene integrity, evidence matrices, session-claims: PASS on every commit.

No engine code changed, so no test-suite evidence is claimed.

## Next

**Owner decision, end of session: `SKF-1..12` and `DRC-1..33` are next session's two packets.**
Both are written and ready to walk; the convoy/shop presentation packet still has to be
*written* before it can be walked, so it comes after.

**Preparation this session did for that walk, and why it was needed.** Scheduling the two
surfaced the same defect a third time: **`DLUX-1..16` — the dialogue UX walk ratified
2026-08-09 — had never been merged**, despite its tracker row recording it as ready. Its
516-line packet sat on `agent/from-integration/dialogue-ux-research`, and that branch
*modifies the `DRC` packet and the dialogue register*. A `DRC` walk from the docs line would
have re-litigated questions `DLUX` had already settled, with no way to see it was doing so —
precisely what `TSV` did to `EPUX` today. **Merged onto the docs line**, resolving two
append-only conflicts (`CLAIMS.tsv`, session-note `INDEX.md`) as verified-lossless unions.

**The precedence check each packet owes before its walk** — this is now a standing obligation,
not a one-off:

| Packet | Diff against | Why |
|---|---|---|
| `SKF-1..12` | `CFB-1..18` (RESOLVED 2026-08-07), `CAU-1..10` (RESOLVED 2026-08-08) | `CFB` **is** the shared engine-action feedback vocabulary `[UBS-1]` asked for. It was written to stop exactly this trio producing three competing vocabularies, so `SKF` must consume it, not restate it. |
| `DRC-1..33` | `DLUX-1..16` (2026-08-09), `DLG-1..14`, `RCV-1..6`, `RCR-1..7` | `DRC` was written **2026-07-27**, before `DLUX` was walked. Anything `DLUX` settled is closed. |

Also fixed while scheduling: `DRC` carried no `Tracker:` line and `SKF` carried no `Register:`
line — the same half-specified pattern as the three references repointed earlier today. `DRC`
now points at `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23`, `SKF` declares `SKF-1..12`.

**After those two:** the `[UBS-6]` convoy/shop presentation packet, which must be written
first (convoy before shop). `NMTE-1..20` is written and unwalked and gates `CEUI-1..40`'s
search rows.

Build work now unblocked and still not started, carried forward from the album session:
the landscape predicate in the composition selector (`SHC-4`, the first deliberate override of
the width-derived size class by a height rule), the generated Explore submenu, `MapMenu.gd:75`
as a resource-list renderer, and opt-in abbreviation per call site. New from today: the
transaction-participant registry (`TSV-3` via `EPUX-24`), the shared selector contract
(`TSV-10`), the pending-items tray (`EPUX-11`), and deterministic stack expansion (`TSV-11`).

Still open and blocking the album's honesty: `SHP-1..5`, so every price drawn remains
illustrative.
