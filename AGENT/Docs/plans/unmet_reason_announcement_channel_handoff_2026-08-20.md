---
Role: dated
Type: plan
Status: Active — forward-looking handoff for the unmet-reason announcement channel
Last verified: 2026-08-20
Tracker: SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Unmet-Reason Announcement Channel — Session Handoff (2026-08-20)

Owns the next session on the third channel `[EPUX-07]` names and the shell does not yet
serve. Written immediately after the focus half shipped, from measurements taken the same
day, so the preflight is current rather than inherited.

---

## 1. Why this row exists

`[EPUX-07]` (owner ruling 2026-07-26, restated as `[RPD-15]` 2026-08-13 and promoted to
all five availability surfaces) requires a gated entry's unmet reason to be reachable by
**keyboard, controller, and screen reader**, and rejects option A — *"disable action
only"* — as **"inaccessible and opaque"** precisely because a reason reachable only by
pointer hover is not reachable at all.

`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` shipped **two of those three** on
2026-08-19 (`71d5f59c`, merged to `agent/integration`): disabled entries are back in the
focus order in both shell traversals, so keyboard and controller reach them. The third
channel has no producer. That is this row.

**Scope boundary.** This row is about the **channel** — how a reason reaches assistive
technology. It is *not* about the reason **string**, which already has a producer
(`ENGINE-PREDICATE-UNMET-REASON-2026-07-26`, completed; see §3), and *not* about reason
**placement** on screen, which `[EPUX-04]` put in the shell and which the availability
surfaces will build as they are built.

---

## 2. Preflight — MEASURED 2026-08-19/20, not read

> Read this section before planning anything. The last handoff on this line
> (`cadence_and_predicate_prerequisites_handoff_2026-08-18.md`) shipped with a preflight
> that was already false, and the session that inherited it nearly rebuilt a prerequisite
> that was three commits deep on `agent/integration`. Everything below was measured
> against `agent/integration` at `7dac8abc` + the focus merge, on Godot 4.6.3
> (`4.6.3.stable.official.7d41c59c4`).

### 2.1 The row's own framing is too pessimistic — correct it before planning

The tracker row and the 2026-08-19 session note both say, in effect, *"no accessibility
or announcement seam exists in the engine at all"* and that the session must decide
**where announcements come from**. **That is true of this project's code and false of the
engine.** Godot 4.6.3 ships a complete accessibility stack, and the project has simply
never touched it. Measured:

| Surface | Measured state |
|---|---|
| `Control.accessibility_name`, `accessibility_description` | **Exist.** Both default to `""` on a fresh `Button`. |
| `Control.accessibility_live` | **Exists** (live-region announcements). Defaults to `0`. |
| `Control.accessibility_described_by_nodes`, `accessibility_labeled_by_nodes`, `accessibility_controls_nodes`, `accessibility_flow_to_nodes` | **Exist.** Relationship wiring, i.e. a reason `Label` can be attached to the entry that it explains. |
| `Control._accessibility_get_contextual_info()` | **Exists** as an overridable virtual — the natural seam for "why is this disabled". |
| `DisplayServer.accessibility_screen_reader_active()` | **Exists.** Returns `-1` under `--headless` (see §2.3). |
| `DisplayServer.tts_speak()` / `tts_get_voices()` / … | **Exist** — a separate, lower-level TTS path. |
| `DisplayServer.accessibility_update_set_description` / `set_state_description` / `set_error_message` / `set_live` / `set_tooltip` | **Exist** — the per-element update API the `Control` properties feed. |
| `ProjectSettings` `accessibility/general/accessibility_support` | Value **`0`**, and **`project.godot` contains no accessibility key** — so this is the engine default, untouched by the project. |
| That setting's enum | `0 = Auto (When Screen Reader is Running)`, `1 = Always Active`, `2 = Disabled`. |

**The two corrections that change the session's shape:**

1. **`0` is `Auto`, not `Disabled`.** An earlier reading of this value as "off" was
   wrong. Accessibility is **already enabled automatically whenever a screen reader is
   running**. Nothing needs to be switched on for the channel to exist.
2. **The channel is not missing; the content is.** Every accessibility property on every
   `Control` in this project is empty, and no code writes one. So the session is an
   **adoption and mapping** exercise against an existing engine API — not the open-ended
   "design an announcement mechanism" the row's prose implies. Plan accordingly; the row
   is phased `1-planning-discussion` because there are genuine owner calls (§4), not
   because the mechanism is unknown.

### 2.2 What the shell does today

- Focus traversal includes disabled entries — `ModalScreen._collect_focusable_controls`
  and `FocusNavigator._collect`, both fixed 2026-08-19. Consumers inherit; do not
  reimplement.
- A gated entry's reason today lives in **`tooltip_text`**. `MainMenu`'s no-pack state is
  the shipped example: New Game is disabled, reads *"New Game (No Data Packs
  Installed)"*, and carries *"install or select…"* in its tooltip. **Pointer-only** as
  far as this project has established.
- No `accessibility_*` property is set anywhere in `scripts/`.

### 2.3 The one thing that could not be measured here — and it is load-bearing

**Does Godot already expose `tooltip_text` to a screen reader?** `DisplayServer` has
`accessibility_update_set_tooltip`, and if `Control` feeds `tooltip_text` into it by
default, then a gated entry's reason may **already** be announced and this row shrinks to
"verify, then improve the wording". If it does not, the reason is genuinely unreachable
and the mapping in §4 is required work.

**This cannot be settled in the container.** Under `--headless`,
`accessibility_screen_reader_active()` returns `-1` and `get_accessibility_element()` is
invalid, so no accessibility element is ever built and there is nothing to inspect. It
needs the **Windows host with a screen reader running** (Narrator is sufficient), which
is the same native-validation channel the roadmap already uses for input and visual
passes.

> **Do not plan the build before this is answered.** It is the difference between a
> verification task and a build task, and guessing wrong in either direction wastes the
> session. If the native check cannot be scheduled first, plan the session as *design +
> the parts that hold either way* (§5), not as a build.

---

## 3. The producer already exists — do not build a second one

`ENGINE-PREDICATE-UNMET-REASON-2026-07-26` is **completed**, and `B3-REQ`/`F16` shipped
its implementation on `agent/integration` (`87084353`, `9b7996f3`). On disk today:

- `RequirementSystem.evaluate(definition, context)` returns
  `{met, reasons, trace, errors}` — `reasons` is a list of **structured** reason
  dictionaries, not prose.
- `RequirementSystem.render_reason(reason, text_db)` renders one to a player-facing
  string through a **text key** plus params, so reasons are localizable by construction.

So the reason string has an owner, a structure, and a localization path. **This row
consumes that, it does not extend it.** A second reason vocabulary is exactly the
duplicate-mechanism shape `[EPUX-07]` refused when it insisted on *"one reason contract,
not two"*.

Two consequences worth carrying into the session:

- Whatever channel is chosen must accept a **rendered string plus its text key**, so the
  announcement is localized through the same path as the visible label. `[L10N]` binds
  here; an announcement assembled by string concatenation in the shell would bypass it.
- `render_reason` takes an optional `text_db`. Confirm what the shell passes before
  assuming an announcement can be produced anywhere in the tree.

---

## 4. Owner calls the session needs

None of these are ruled anywhere in the corpus. Each is stated with its trade-off; none
should be decided by the implementing agent.

1. **Native properties or a bespoke channel?** Adopt Godot's
   `accessibility_name` / `accessibility_description` / `_accessibility_get_contextual_info`
   (free platform integration; ties the project to the engine's accessibility model), or
   build a project-owned announcement service over `DisplayServer.tts_speak` (full
   control; re-implements what the platform already does, and TTS is not a screen reader
   — it talks over one). **Recommendation: the native properties**, with TTS considered
   only if a specific gap appears. The relationship properties
   (`accessibility_described_by_nodes`) map cleanly onto "this entry is explained by that
   reason label", which is the exact shape `[EPUX-04]` put in the shell.
2. **Where does the mapping live?** `[EPUX-04]` and `[RPD-15]` both put disabled
   *treatment* in the shell so five adapters cannot drift. The announcement is a disabled
   treatment. **Recommendation: the shell**, alongside the focus fix, so an adapter
   supplies only the reason and never the presentation — but this is the same ruling
   being extended to a new property, so take it explicitly rather than by analogy.
3. **`accessibility_support`: leave at `Auto`, or force `Always Active`?** `Auto` costs
   nothing when no screen reader runs; `Always Active` makes the tree inspectable for
   automated testing but pays the update cost (`updates_per_second = 60`) for every
   player. **Recommendation: leave `Auto` in the shipped project**, and if the test
   harness needs the tree, decide separately whether a test-only override is worth it.
4. **Does this bind all five availability surfaces uniformly, like the focus clause?**
   The five are the four `[EPUX-02]` names — top-level node menu, Explore subject picker,
   Explore per-subject activity list, Manage Roster panel registry — plus prep readiness
   (`[RPD-15]`'s Begin Battle). **Recommendation: yes, uniformly**, for the reason
   `[EPUX-04]` gives; but note four of the five are unbuilt, so "binds" means the shell
   primitive exists and they inherit it, not that anything is retrofitted now.
5. **Scope: gated entries only, or the shell generally?** This row's mandate is the unmet
   reason. A general accessibility pass over every screen is a much larger piece of work
   with its own validation burden. **Recommendation: gated entries only**, and open a
   separate row if the owner wants the broader pass — do not let this row silently become
   it.

---

## 5. Suggested session shape

Ordered so that the parts which hold under either answer to §2.3 come first.

1. **Preflight (30 min).** Re-verify §2's measurements against the current
   `agent/integration` tip. Confirm by **ancestry**, not row status, that the focus fix is
   present — `git merge-base --is-ancestor 71d5f59c agent/integration`. The lesson is
   recent and cost a session.
2. **Settle §4 with the owner.** Cheapest step, gates everything else.
3. **Answer §2.3.** Native Windows + screen reader. If it cannot be scheduled, record it
   as the explicit blocker and stop before building — a build planned on a guess here is
   the wasteful outcome.
4. **Then, and only then, build.** Expect the shell change to be small (populate two or
   three accessibility properties from the reason the adapter already supplies) and the
   test to be the hard part — see §6.
5. **DoD#1 in the same commit**: `GDD_07_Screens_Panels.md` §Focus-grab subscribers
   (which already carries the focus half and should carry this beside it) and the
   `GDD_10_Roadmap.md` entry *"Shell availability: disabled entries in the focus order"*,
   which currently states this gap as unserved and must be updated when it is served.

---

## 6. The trap to expect

**The existing suites structurally cannot catch a regression here.** `--headless` builds
no accessibility element at all (§2.3), so an assertion that a reason is *announced* has
nothing to read, and a test that only asserts `accessibility_description != ""` verifies
that a string was assigned — not that anything consumes it. That is a weaker guarantee
than it looks, and it should be *documented as* weaker rather than presented as coverage.

`scripts/tests/test_shell_disabled_focus.gd` is the model to follow for the part that
*can* be pinned: its last check deliberately asserts **engine** behaviour (a disabled
`BaseButton` takes focus, emits no `pressed`, is not a traversal dead end) so that a
future Godot which changes those facts fails loudly instead of silently reintroducing the
defect. Do the same for whichever accessibility facts the design leans on.

---

## 7. Pointers

- Row: `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19` (`planned`,
  `1-planning-discussion`), depends on `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`.
- Focus half: `AGENT/Session Notes/2026-08-19-23-04-42Z-shell-disabled-entry-focus.md`;
  implementation `71d5f59c`; suite `scripts/tests/test_shell_disabled_focus.gd`.
- Rulings: `[EPUX-02]`, `[EPUX-04]`, `[EPUX-07]` in
  `AGENT/Docs/design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`;
  `[RPD-10]`, `[RPD-15]` in
  `AGENT/Docs/registers/responsive_prep_deployment_open_questions_2026-08-12.md`.
- Reason producer: `scripts/autoloads/RequirementSystem.gd`
  (`evaluate`, `render_reason`).
- Consumers that inherit rather than reimplement: `PREP-V1-S01`,
  `B4-PREP-MAP-DEPLOYMENT` slice 2d.
