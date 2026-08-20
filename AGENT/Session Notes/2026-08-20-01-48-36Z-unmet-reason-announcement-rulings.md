# Session Note - 2026-08-20

## Branch context

- Branch: `agent/integration` (docs line — plan and register docs are fenced here by the
  pre-commit docs-guard and cannot ride a feature branch)
- Base branch: `agent/integration`
- Base SHA: `559643ba` (`Claim the handoff commit`)
- Coordination Work ID: `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`

## What was done

Executed the session the 2026-08-20 handoff hands off: the **screen-reader channel** for a
gated entry's unmet reason — the third of the three channels `[EPUX-07]` requires, and the
one the focus fix (`71d5f59c`, 2026-08-19) could not deliver.

**Outcome: the planning phase is closed, the build is not started, and that is the
correct result.** Four owner calls ruled, one deferred with its trade-off measured away,
and one blocker recorded. New register `ANN-1..5` at
`AGENT/Docs/registers/unmet_reason_announcement_channel_2026-08-20.md`.

### Preflight held — and the handoff's central correction survived re-measurement

The handoff's §2 was re-verified before any ruling was taken, because the *previous*
handoff on this line shipped with a preflight that was already false. All four checks
held: `71d5f59c` is an ancestor of `agent/integration` (confirmed by **ancestry**, not row
status), `grep` for `accessibility_*` / `tts_speak` / `screen_reader` across `scripts/`
returns **0 hits**, `project.godot` carries no accessibility key, and the setting reads
`0` = **Auto**.

So the premise stands: **the channel is not missing, the content is.** Godot 4.6.3 ships
the whole stack and this project has never written one property. That makes the row an
adoption-and-mapping exercise, not the "design an announcement mechanism" its own tracker
prose still implies.

### The rulings

- **`ANN-1` — native properties, not a bespoke TTS service.** `accessibility_name` /
  `accessibility_description` / the relationship-node properties. TTS is **not** a screen
  reader — it talks *over* one — so a project-owned service would duplicate the platform
  and degrade the experience of the users it targets.
- **`ANN-2` — the mapping lives in the shell and binds all five availability surfaces.**
  Extends `[EPUX-04]`/`[RPD-15]`, which put disabled *treatment* in the shell so five
  adapters cannot drift. Taken **explicitly** rather than by analogy. Four of the five are
  unbuilt, so "binds" means the primitive exists and they inherit it — nothing retrofitted.
- **`ANN-3` — `accessibility_support` deferred, and the deferral is the interesting part**
  (below).
- **`ANN-4` — gated entries only.** Not a project-wide accessibility pass; that gets its
  own row if wanted.
- **`ANN-5` — build blocked** on a native screen-reader check (below).

### Measured: forcing `Always Active` buys nothing, so `ANN-3`'s trade-off half-dissolved

The handoff framed `accessibility_support` as `Auto` (free) vs `Always Active` (makes the
tree inspectable for **automated testing**, at `updates_per_second = 60` for every
player). That second clause is what made it a real trade-off, so it was measured rather
than accepted:

| Run | setting | `get_accessibility_element()` | `screen_reader_active()` |
|---|---|---|---|
| default | `0` Auto | `RID(0)` **invalid** | `-1` |
| minimal project with `general/accessibility_support=1` | `1` Always Active | `RID(0)` **invalid** | `-1` |

Both added the control to a live tree and waited two frames. **`Always Active` builds no
accessibility element under `--headless`** — the dummy `DisplayServer` has no
accessibility backend, so the setting has nothing to drive. The CI-testability argument is
therefore **false**, and with it the only reason to pay the cost.

What survives is narrower: `Always Active` might yield an inspectable tree on a **real
display server with no screen reader running**, which would matter only to a native
automated check — on the same Windows host `ANN-5` is already waiting for. So the question
is not ripe, it is downstream of a session that has not happened, and `Auto` (the shipped
behaviour, no change needed) holds meanwhile. Deferred rather than ruled on a guess.

> CLI trap worth carrying: `godot --accessibility/general/accessibility_support=1`
> **silently does nothing** — the setting still read `0`. Overriding a project setting
> needs a real project file. The second run used a throwaway minimal project; had the flag
> been trusted, the "measurement" would have been two identical default runs reported as a
> comparison.

### Two corrections to the handoff's own measured table

1. **`_accessibility_get_contextual_info()` answers `has_method()` with `false`.** Not a
   contradiction — un-overridden virtuals are not reported — but the consequence binds the
   design: it **cannot be feature-detected at runtime** and must be adopted by
   declaration.
2. **`tooltip_text` does not populate the accessibility properties.** Measured: setting it
   leaves both `accessibility_name` and `accessibility_description` at `""`. This
   **narrows** the open question without settling it — there is no *property-level*
   derivation, but the engine may still feed the tooltip into the element at build time
   via `accessibility_update_set_tooltip`, which is exactly what cannot be observed here.

### The blocker, and why nothing was built

`ANN-5`: **does Godot already expose `tooltip_text` to a screen reader?** If yes, the row
shrinks to *verify, then improve the wording* — a gated entry's reason lives in
`tooltip_text` today (`MainMenu.gd:111` is the shipped example). If no, the mapping is
required work. It needs a Windows host with a screen reader; the owner confirmed that
cannot be scheduled now, so it is recorded as an explicit blocker rather than guessed.

The design is specified in §3 of the register anyway, so the native session executes
instead of re-deriving.

### One hazard found in the producer that a test would not catch

`RequirementSystem.render_reason` **falls back to returning the raw text key** when
`text_db` is `null` or lacks `tr_key`. An announcement produced without a `text_db` would
read `req.objective` aloud to a screen-reader user — a plausible-looking string that any
"is it non-empty" assertion passes. Recorded in §3.2 as something the build must make an
explicit tested failure at the seam, not an accepted default.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

One docs-only commit: the `ANN-1..5` register plus the regenerated `INDEX.md` /
`REGISTERS.md` (check 18 requires the regeneration in the same change), and this note.
No engine code changed — deliberately, per `ANN-5`.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` → wrote `INDEX.md`, `REGISTERS.md`.
- `python3 AGENT/Docs/check_docs.py` → **PASS, 46/46**. Check `[46]` (uncatalogued
  registers) passes and `REGISTERS.md:13` now carries the `ANN-1..5` row — verified by
  reading the regenerated diff, not by trusting the PASS, per the 2026-08-18 lesson.
- Godot probes run under `4.6.3.stable.official.7d41c59c4`; results tabulated in §1 of the
  register.
- DoD#1 does not bind: no behaviour changed. The GDD/roadmap updates it *will* owe are
  named with line numbers in §5 of the register
  (`AGENT/GDD/GDD_07_Screens_Panels.md:879`, `AGENT/GDD/GDD_10_Roadmap.md:100`), both
  anchors verified to exist.

## Next

**Blocked, with a bounded unblocking action.** The next action is not a build: it is the
native check in `ANN-5` — run a build on the Windows host with Narrator active, focus the
disabled New Game entry in the no-pack state, and record whether its tooltip is announced.
That one observation decides whether this row is a verification task or a build task.

If it returns *"not announced"*, §3 of the register is the build spec: populate
`accessibility_description` from the adapter-supplied reason at the point the disabled
state is applied, in **both** `ModalScreen` and `FocusNavigator` — they hold separate
implementations of the same disabled predicate (`_is_focus_disabled` / `_is_unavailable`),
and the focus ruling was shipped inverted in *both*, so a divergence here reproduces that
defect one surface at a time.
