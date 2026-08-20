---
Type: register
Status: RESOLVED — `ANN-1`, `ANN-2`, `ANN-4` ruled 2026-08-20; `ANN-3` deferred to the native session; `ANN-5` records the build blocker
Last verified: 2026-08-20
Register: ANN-1..5
Tracker: SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Unmet-Reason Announcement Channel — Owner Rulings

Handoff: [Unmet-Reason Announcement Channel](../plans/unmet_reason_announcement_channel_handoff_2026-08-20.md)

Closes the planning phase of `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` — the
third of the three channels `[EPUX-07]` requires for a gated entry's unmet reason. The
focus half (`keyboard`, `controller`) shipped 2026-08-19 as `71d5f59c`. This register
rules the screen-reader half.

**It deliberately does not authorise a build.** See `ANN-5`.

---

## 1. Preflight — re-measured 2026-08-20

The handoff's §2 was measured 2026-08-19/20. Re-verified against `agent/integration`
`559643ba` before any ruling was taken, because the previous handoff on this line shipped
with a preflight that was already false.

| Check | Method | Result |
|---|---|---|
| Focus half present | `git merge-base --is-ancestor 71d5f59c agent/integration` | ✓ present — confirmed by **ancestry**, not row status |
| `accessibility_*` / `tts_speak` / `screen_reader` in `scripts/` | `grep -rnI` | **0 hits** — the engine stack is entirely untouched by this project |
| `accessibility` key in `project.godot` | `grep` | absent → engine default applies |
| `accessibility/general/accessibility_support` at runtime | `ProjectSettings.get_setting` | `0` = **Auto (When Screen Reader is Running)** |

So the handoff's central correction holds and is restated here as the premise of every
ruling below: **the channel is not missing, the content is.** Godot 4.6.3 ships a
complete accessibility stack; every property on every `Control` in this project is empty
and no code writes one. This is an adoption-and-mapping exercise against an existing
engine API, not the open-ended "design an announcement mechanism" the tracker row's own
prose implies.

### 1.1 Property surface, measured on a fresh `Button`

Probed under `4.6.3.stable.official.7d41c59c4`:

| Property | Exists | Default |
|---|---|---|
| `accessibility_name` | yes | `""` |
| `accessibility_description` | yes | `""` |
| `accessibility_live` | yes | `0` |
| `accessibility_described_by_nodes` | yes | `[]` |
| `accessibility_labeled_by_nodes` | yes | `[]` |
| `accessibility_controls_nodes` | yes | `[]` |
| `accessibility_flow_to_nodes` | yes | `[]` |
| `get_accessibility_element()` | present as a method | returns `RID(0)`, invalid — see §1.3 |
| `queue_accessibility_update()` | present as a method | — |

### 1.2 Two corrections to the handoff's §2 table

1. **`_accessibility_get_contextual_info()` does not answer `has_method()`.** It reports
   `false` on a plain `Button`. This is not a contradiction — it is an *overridable*
   virtual, present in the class API and callable by the engine once a subclass defines
   it, but un-overridden virtuals are not reported by `has_method()`. The consequence for
   this design is only that **it cannot be feature-detected at runtime**; it must be
   adopted by declaration, not by probing.
2. **`tooltip_text` does not populate the accessibility properties.** Measured: setting
   `tooltip_text` on a `Button` leaves `accessibility_name` and `accessibility_description`
   both `""`. This **narrows** the open question in §2.3 of the handoff without settling
   it: there is no *property-level* derivation, but the engine may still feed the tooltip
   into the accessibility element at element-build time via
   `DisplayServer.accessibility_update_set_tooltip`. That path cannot be observed here
   (§1.3).

### 1.3 Headless cannot observe this, and forcing the setting does not help

The handoff flagged that `--headless` builds no accessibility element. Measured further,
because the answer bears directly on `ANN-3`:

| Run | `accessibility_support` | `get_accessibility_element()` | `accessibility_screen_reader_active()` |
|---|---|---|---|
| Project default | `0` (Auto) | `RID(0)` — **invalid** | `-1` |
| Forced via a minimal project with `general/accessibility_support=1` | `1` (Always Active) | `RID(0)` — **invalid** | `-1` |

Both runs added the `Button` to a live scene tree and waited two frames. **Forcing
`Always Active` builds no accessibility element under `--headless`** — the dummy
`DisplayServer` has no accessibility backend, so the setting has nothing to drive.
Assigned property values read back correctly in both runs, which is the weak guarantee
§4 of this register relies on and §5 refuses to call coverage.

> Note the CLI trap: `godot --accessibility/general/accessibility_support=1` **silently
> does nothing** — the setting still read `0`. Overriding a project setting needs a real
> project file, which is why the second run used a throwaway project rather than a flag.

---

## 2. The rulings

### `ANN-1` — Channel: adopt Godot's native accessibility properties. **RULED**

The engine's own properties are the channel: `accessibility_name`,
`accessibility_description`, and the relationship properties, with
`_accessibility_get_contextual_info()` available where a per-entry override is warranted.

*Rejected:* a project-owned announcement service over `DisplayServer.tts_speak`. TTS is
not a screen reader — it **talks over** one — so a bespoke service would both duplicate
the platform and degrade the experience of the users it targets. It stays available if a
specific, demonstrated gap appears; it is not the default path.

*Consequence:* the project accepts the engine's accessibility model as its model. The
relationship properties (`accessibility_described_by_nodes`) map exactly onto "this entry
is explained by that reason label", which is the shape `[EPUX-04]` already put in the
shell — so adoption costs no new architecture.

### `ANN-2` — The mapping lives in the shell and binds all five availability surfaces. **RULED**

The reason → announcement mapping is shell-owned, alongside the focus fix. An adapter
supplies the reason and never the presentation.

This extends `[EPUX-04]` and `[RPD-15]` — both of which put disabled *treatment* in the
shell precisely so five adapters cannot drift into five different disabled treatments — to
a new property. It is taken **explicitly**, not inherited by analogy, because that is what
those rulings' own reasoning demands of any new member of the disabled-treatment family.

*Scope of "binds":* four of the five surfaces are unbuilt. Binding means **the shell
primitive exists and they inherit it**; nothing is retrofitted now, and no unbuilt surface
acquires work from this ruling. The five are the four `[EPUX-02]` surfaces — top-level
node menu, Explore subject picker, Explore per-subject activity list, Manage Roster panel
registry — plus prep readiness (`[RPD-15]`'s Begin Battle).

### `ANN-3` — `accessibility_support` stays at `Auto` for now. **DEFERRED to the native session**

Not ruled, and deliberately so. The handoff framed this as a trade-off between `Auto`
(costs nothing when no screen reader runs) and `Always Active` (makes the tree inspectable
for automated testing, at `updates_per_second = 60` for every player).

§1.3 **eliminates one half of that trade-off**: `Always Active` buys no inspectable tree
under `--headless`, so it offers nothing to CI. What it may still offer is a tree on a
**real display server without a screen reader running** — which would matter only to a
native automated check, and only on the same Windows host that `ANN-5` is already waiting
for.

So the question is not ripe: it is now entirely downstream of a session that has not
happened. `Auto` remains in effect meanwhile, which is the shipped behaviour and requires
no change. Revisit it in the native session, with the cost measured rather than assumed.

### `ANN-4` — Scope: gated entries only. **RULED**

This row's mandate is the unmet reason on disabled entries. It does not become a
project-wide accessibility pass over every screen.

A broader pass is legitimate work with its own validation burden and its own native-host
requirement; it gets its own row if wanted. The failure mode this ruling prevents is the
one the handoff names — a narrow row silently growing into a programme, and then blocking
its own consumers because the programme cannot be finished.

*Consumers unaffected by the narrow scope:* `PREP-V1-S01` and `B4-PREP-MAP-DEPLOYMENT`
slice 2d inherit the shell primitive either way.

### `ANN-5` — The build is blocked on a native screen-reader check. **BLOCKER RECORDED**

**No implementation commit may be made against this row until §2.3 of the handoff is
answered on a Windows host with a screen reader running.**

The unanswered question: **does Godot already expose `tooltip_text` to a screen reader?**

- If it **does**, this row shrinks to *verify the existing behaviour, then improve the
  wording* — because a gated entry's reason already lives in `tooltip_text` today
  (`MainMenu.gd:111` is the shipped example: New Game reads *"New Game (No Data Packs
  Installed)"* with *"…Install or select a campaign pack."* in its tooltip).
- If it **does not**, the mapping in §3 is required work.

§1.2 narrowed this — there is no property-level derivation — but did not settle it, and
§1.3 establishes that **this container structurally cannot settle it**. The owner has
confirmed the native check cannot be scheduled in this session, so it is recorded here as
an explicit blocker rather than guessed in either direction. A build planned on a guess is
the outcome the handoff warns against by name.

---

## 3. The design that follows (specified, not built)

Recorded so the native session can execute rather than re-derive. **Contingent on
`ANN-5`.**

### 3.1 The producer already exists — do not build a second one

`ENGINE-PREDICATE-UNMET-REASON-2026-07-26` is completed and `B3-REQ`/`F16` shipped it. On
disk in `scripts/autoloads/RequirementSystem.gd`:

- `evaluate(definition, context) -> {met, reasons, trace, errors}` — `reasons` is a list
  of **structured** reason dictionaries, not prose.
- `render_reason(reason, text_db) -> String` — renders one reason through a **text key**
  plus params, so reasons are localizable by construction.

This row **consumes** that. A second reason vocabulary is the duplicate-mechanism shape
`[EPUX-07]` refused when it insisted on *one* reason contract.

### 3.2 The `text_db` hazard — load-bearing, and easy to get silently wrong

`render_reason` falls back to **returning the raw text key** when `text_db` is `null` or
lacks `tr_key`:

```gdscript
func render_reason(reason: Dictionary, text_db: Node = null) -> String:
    var key := String(reason.text_key)
    if text_db != null and text_db.has_method("tr_key"):
        return text_db.call("tr_key", key, reason.params)
    return key
```

An announcement produced without a `text_db` would therefore announce something like
`req.objective` to a screen-reader user — a silent, plausible-looking failure that no
assertion on "is the string non-empty" would catch. **Confirm what the shell passes for
`text_db` before assuming an announcement can be produced anywhere in the tree**, and make
the raw-key fallback an explicit, tested failure at the announcement seam rather than an
accepted default. `[L10N]` binds here: an announcement assembled by concatenation in the
shell would bypass the localization path the visible label uses.

### 3.3 Where the shell change goes

Both traversals already carry the focus half and are the natural home:

- `scripts/ui/ModalScreen.gd` — `_collect_focusable_controls` (traversal) and
  `_first_focusable` / `_entry_focus_candidates` (entry focus). `_is_focus_disabled` is
  the existing disabled predicate.
- `scripts/shared/FocusNavigator.gd` — `_collect`, with `_is_unavailable` as its
  equivalent predicate. `PrepScreen` navigates through this class, not `ModalScreen`.

Expect the change to be small: populate `accessibility_description` (and where the label
alone is insufficient, `accessibility_name`) from the reason the adapter already supplies,
at the same point the disabled state is applied. `queue_accessibility_update()` exists for
the case where a reason changes while the entry is focused.

**The two predicates must stay aligned.** They are separate implementations of the same
concept in two files, and the focus ruling was shipped inverted in *both* — a divergence
here would reproduce that defect one surface at a time.

---

## 4. Test strategy, and an honest statement of its limit

`scripts/tests/test_shell_disabled_focus.gd` is the model. Its last check deliberately
asserts **engine** behaviour so a future Godot that changes those facts fails loudly
instead of silently reintroducing the defect. Do the same for whichever accessibility
facts this design leans on.

**What can be pinned headless:**

- the accessibility properties exist on `Control` and accept assignment (§1.1);
- `render_reason` with a real `text_db` does not return a raw key (§3.2);
- both disabled predicates agree on the same control.

**What cannot, and must not be presented as coverage:** that a reason is *announced*.
§1.3 measured that `--headless` builds no accessibility element at all — with the setting
forced to `Always Active` as well as at the default — so an assertion that anything is
announced has nothing to read. A test asserting `accessibility_description != ""` verifies
**that a string was assigned, not that anything consumes it**. That is a materially weaker
guarantee than it appears, and the suite should say so in a comment rather than let a
future reader mistake it for end-to-end coverage.

---

## 5. Definition-of-done note

DoD#1 does not bind this change: it alters no behaviour. When the build lands, it must
update, in the same commit:

- `AGENT/GDD/GDD_07_Screens_Panels.md` §Focus-grab subscribers (line 879) — already
  carries the focus half; the announcement channel belongs beside it.
- `AGENT/GDD/GDD_10_Roadmap.md` → *"Shell availability: disabled entries in the focus
  order"* (line 100), which currently states this gap as unserved.

---

## 6. Pointers

- Row: `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`, depends on
  `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`.
- Handoff: [`unmet_reason_announcement_channel_handoff_2026-08-20.md`](../plans/unmet_reason_announcement_channel_handoff_2026-08-20.md)
- Focus half: `AGENT/Session Notes/2026-08-19-23-04-42Z-shell-disabled-entry-focus.md`;
  implementation `71d5f59c`; suite `scripts/tests/test_shell_disabled_focus.gd`.
- Rulings consumed: `[EPUX-02]`, `[EPUX-04]`, `[EPUX-07]` in
  [`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md);
  `[RPD-10]`, `[RPD-15]` in
  [`responsive_prep_deployment_open_questions_2026-08-12.md`](responsive_prep_deployment_open_questions_2026-08-12.md).
- Reason producer: `scripts/autoloads/RequirementSystem.gd` (`evaluate`, `render_reason`).
- Consumers that inherit rather than reimplement: `PREP-V1-S01`,
  `B4-PREP-MAP-DEPLOYMENT` slice 2d.
