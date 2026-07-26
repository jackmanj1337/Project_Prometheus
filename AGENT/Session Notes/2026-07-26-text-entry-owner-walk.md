# Session Note - 2026-07-26 (text-entry owner walk)

Third and final text-entry session of 2026-07-26. Continues
`2026-07-26-text-entry-companions.md`. **The walk is COMPLETE — TEXT-01..TEXT-15 are
all ratified**, and `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26` is closed.

## What was done

Ran the owner walk over all fifteen questions in the EPUX style, in four batches
ordered by dependency, and wrote the rulings back into each packet's **Decision
status** section per the EPUX convention.

### Rulings

- **TEXT-01 = B.** Platform keyboard where one exists, ours as fallback, **ours
  built first**, Steam path added later as a packaging step.
- **TEXT-02 = A, as revised by TEXT-13** — and **the two questions were merged and
  ruled once**. Grid QWERTY first **as the default on the merits**, daisywheel
  second as opt-in.
- **TEXT-03 = C architecture / A content.** Registry now, one ASCII layout.
- **TEXT-04 = C now, A when Steam is scheduled**, **plus keep the seam strong** —
  the `system` presenter slot exists from day one with no backend behind it.
- **TEXT-05 = B**, and **TEXT-14a folds into the same setting** rather than adding
  a second control: one setting, defaulting to input-device detection, **touch and
  gamepad routing to our native keyboard**. That default is also what keeps Deck
  Verified answerable without special-casing the Deck.
- **TEXT-06 = A.** No v1 feature may *require* free text except naming. Keyboard
  still built — convenience, not dependency — and does not reopen EPUX-09/15/27.
  DoD#2 applies.
- **TEXT-07 = A.** Validate length/charset, record the boundary, no word filter
  while v1 has no transmission path.
- **TEXT-08 = a split answer**, departing from the packet's single option B. Own
  **grid**; **wheel** on `jesuisse/godot-radial-menu-control` (MIT, Godot 4,
  gamepad-aware) which the original survey missed.
- **TEXT-09 = B.** Validator takes Unicode letters/marks/digits; keyboard ships
  ASCII. They differ deliberately — clipboard paste and hand-written pack JSON
  bypass the keyboard.
- **TEXT-10 = A**, with all three deliverables required. See the severity finding
  below.
- **TEXT-11 = import path, not save path.** Generated ids cannot produce
  `CON`/`NUL`; externally-renamed files still arrive.
- **TEXT-12 = A, plus a clause the question did not ask for.** Ids generated on
  creation, **and identity comes from the file's internal manifest, not its
  filename.**
- **TEXT-12a = the manifest rule covers save files too**, since the ratified
  cloud-sync decision already makes manual export/import the v1 primary.
- **TEXT-14 = A, with the registry's unit being an entry MODE, not a layout.**
  `hardware` is a first-class registered presenter, not the absence of one — which
  settles "now or later" on merit rather than principle, because TEXT-01 and
  TEXT-05 both already commit to swapping between in-game/system/hardware.
- **TEXT-15 = B.** Reserve a `candidate_select` action; build no keypad.

### The walk reordered one question, correctly

The packet proposed taking **TEXT-06 first, as the gate**. The owner deferred it to
the **end**, so it could be ruled with the keyboard's real build cost visible rather
than in the abstract. That ordering was better and is worth reusing: decide what a
capability costs before deciding whether features may depend on it.

### TEXT-10 severity investigation — the owner asked, and it escalated

Measured against `godot --headless` 4.6.3:

- **`[url]` is inert in this codebase.** `UnitDetailsScreen._on_entry_clicked`
  parses `category:key` and only moves a selector — no `OS.shell_open()`, no
  navigation. **The phishing concern from the companion packet is withdrawn.**
- **`[img]` is an arbitrary-code-execution primitive.**
  `[img]user://evil.tres[/img]` in a `bbcode_enabled` RichTextLabel **executed the
  resource's embedded script `_init()`**, verified by marker file, because `[img]`
  resolves through `ResourceLoader.load()`.
- **A raw PNG under `user://` does not load** ("Resource file not found") for want
  of an `.import` file. So legitimate images fail and malicious resources succeed —
  there is no legitimate `[img]` use with pack content to preserve.
- **The chain needs a `.tres` on disk, which `CampaignArchivePreflight` denies.**
  Preflight admits only indexed JSON and `png/ogg/wav/ttf/otf`. **That makes
  `_safe_archive_path()` and the approved-extension allow-list load-bearing
  security controls, not hygiene** — and nothing in the code said so, which is why
  the ruling requires a regression test pinning it.

Realistic attack today is social ("place this file, then import my pack"), not pack
import alone.

## Commits claimed

- `e132411251c568613da719784561eb8ae078ff6a` — docs: record the TEXT-01..15 owner rulings across all three packets

Container repo (not claimable here): `3611562` closed the research row and added the
spin-out rows; `3cc2658` extended it earlier in the day.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py`; `python3 AGENT/Docs/check_docs.py` — **PASS**, 41 checks green.
- Pre-commit on `e132411`: unit suite 12 OK, scene-integrity PASS, session-claims PASS,
  evidence-matrices PASS, gdformat/gdlint PASS (238 files). Godot suite skipped — docs-only.
- Container: `coordination/check_tasks.py` — **OK, 170 tasks valid, no conflicts.**
- Severity probes run against 4.6.3.stable.official.7d41c59c4; probe scripts were
  session-scratchpad only and are deliberately not committed.

## Next

**Seven implementation rows spun out.** One is unblocked and should go first:

- `HARDEN-BBCODE-INJECTION-2026-07-26` — **phase 0-unblock, claims no contested
  path.** Escape brackets at every bbcode render site plus the preflight regression
  test. The escape alone breaks the RCE chain.
- `HARDEN-PACK-DISPLAYNAME-VALIDATION-2026-07-26` — split out of the above because
  `CampaignTier2Validators.gd` is already claimed by `IMPL-ZERO-CONTENT-FAMILIES`
  (which claims all of `scripts/resources/`) and `IMPL-RULE-PROFILES`. Defence in
  depth only.
- `RULE-MINIMISE-FREE-TEXT-2026-07-26` — the TEXT-06 rule plus its DoD#2 check.
  Take **before** the registry, so the registry cannot silently reopen the cuts.
- `RELEASE-CHECKLIST-DECK-OSK-2026-07-26` — a checklist line whose entire purpose is
  to survive until Steam is scheduled.
- `TEXT-ENTRY-MODE-REGISTRY-2026-07-26` — registry + grid + hardware presenters,
  `system` seam, one ASCII layout, one setting. Needs a Menu Scale 200% pass per
  presenter and interacts with `BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND`.
- `TEXT-ENTRY-WHEEL-PRESENTER-2026-07-26` — backlog, deliberately second.
- `MANIFEST-IDENTITY-SAVES-PACKS-2026-07-26` — declares real dependencies on
  `IMPL-PACK-SAVE-SCHEMA`, `-LOAD-MIGRATION`, `-EXPORTS` and
  `V053-PLAYTEST-TRIAGE-2026-07-22` rather than racing them for `SaveManager.gd`.

Still not on the v1 critical path: EPUX-09, EPUX-15 and EPUX-27 were already cut and
TEXT-06 now ratifies that nothing may require free text, so the keyboard unblocks
future work rather than current work. The exception is the two hardening rows, which
are live today and independent of everything above.

Carried forward unverified, in both packets: **no study compares a daisywheel to a
grid on a controller** (the ~2x is modelled; throughput is unmeasured in either
direction), and **no Windows-host pass was possible** for reserved names, `MAX_PATH`,
or emoji glyph coverage — every filesystem measurement is Linux.
