---
Role: dated
Type: playtest
Status: Ready - feature round
Last verified: 2026-09-23
---

# v0.8.1 Windows Tester Checklist

v0.8.1 is **v0.8.0 with its round made testable**. v0.8.0 shipped the authored
combat-relationship system and then handed you a checklist that asked for three things
the build could not do: a magic triangle no shipping content could fire, a fixture the
bundle did not carry, and a campaign editor whose own size gate refused to open it at
any window size. None of those were your fault to find and all three are fixed here.

Container tests and browser gates are supplemental. This pass is for native Windows
display, GPU, window-manager, input, visual, accessibility and playability evidence,
plus the judgement calls in Section 7. Return this checklist, the diagnostics ZIP and
defect screenshots.

**Tuning is out of scope and always will be** (owner ruling 2026-09-05). Do not report
whether +5 damage is too much, whether a chapter is too hard, or how the damage curve
feels. Those variables belong to the campaign author, not the engine. Report whether
the number the game *shows* you is the number it *used*, and whether you could tell
*why* — that is what this round is measuring.

---

## Section 0 — Start in this order

1. Verify `BUILD_INFO.json` and `SHA256SUMS.txt`. Launch the supplied release
   executable once and keep the supplied Godot user-data location unchanged.
2. Confirm the Main Menu version label reads **v0.8.1**. If it reads anything else,
   stop and report — the build stamp and the label are meant to agree.
3. With a clean profile and no saves, use **Main Menu → Manage Library → New Game** to
   confirm the empty state; open **Load Game** and verify its empty state is clear.
4. From **Main Menu → Manage Library**, import `free-roam.zip`. Do not edit or re-zip
   any supplied archive.
5. Read `screenshot-album-reference/README.md` beside this checklist before starting
   Section 2. Labelled reference images are in that folder, captured from this exact
   build in a real browser; the file to compare against is named in each check. The map
   art in them is software-rendered and will not match your build — judge the forecast
   panel.

### The controls you will need

Several checks below cannot be reached without these, and **nothing on screen exposes
them as a button** — the map surface is keyboard and controller driven. This table is
the shipped input map, not a suggestion.

| Action | Key | Pad | Notes |
|---|---|---|---|
| Move cursor | `WASD` / arrows | d-pad | |
| Confirm | `Z` / `Enter` / `Space` | 0 | on an open attack forecast this **commits the attack** |
| Cancel / back | `X` / `Esc` | 1 | |
| **Unit details** | `I` | 3 | **only while a unit is selected** — hovering is not enough |
| **Map menu** | `M` | 6 | End Turn, Settings and **Suspend & Quit** live here; **only while the cursor is free**, i.e. no unit selected |
| More Info | `F` | 2 | cycles the entries on the attack forecast and the character sheet |
| Settings | `O` | — | |
| Next / previous unit | `Tab` / `Shift+Tab` | 10 / 9 | |
| Danger zone | `Q` | 8 | |
| Peek range | `E` | 4 | |
| Zoom in / out / reset | `=` / `-` / `0` | — / — / 7 | |

**Changing a unit's weapon** is not on that table because it is not a global action:
select the unit, move it (or press Confirm on its own tile to stay put), and choose
**Equip** on the action menu. The option only appears when the unit is carrying two or
more weapons its class can actually use. Section 2 needs it once.

If you cannot find a surface a check asks for, look here before recording it as blocked.

---

## Section 1 — What changed since v0.8.0, in plain terms

Read this before testing. It is the round's premise, not a checklist.

**Three things the last round asked for and could not get.**

| v0.8.0 asked you to | Why you could not | Now |
|---|---|---|
| Confirm a magic triangle among Fire / Thunder / Wind | Those three are **deliberately neutral to each other**; the checklist was wrong, not the game | Chapter 3 fields a light-tome enemy, so the magic triangle fires for the first time |
| Restore `campaign_backup_v2.zip` | It was not in the bundle | It ships, and the packager now refuses a bundle whose checklist names a file it does not carry |
| Open the campaign editor | Its size gate measured the fixed 1280×720 design canvas, so no window could satisfy it | The editor opts out of that canvas while it is open and measures the real window |

**Also new to see.**

| Change | Where you meet it |
|---|---|
| Weapon **effectiveness** fires for the first time | Chapter 1 and Chapter 3 — see Section 2 |
| **Two relationship rows in one forecast column** | Chapter 3's Bridge Fighter — nobody has ever seen this, including us |
| The stat breakdown explains a **live combat condition** | Section 3 — it used to say "No active bonuses" under a condition-modified stat |
| Conditions have a **name and a remaining duration** on screen | Section 3 |
| Every confirmation says **which button Enter presses** | Sections 3 and 5 |
| Arrows, bullets and dashes render as **characters, not boxes** | Everywhere — the shipped font had none of them |
| A campaign pack can ship **its own UI font** | `free-roam.zip` now does |
| The campaign editor draws on **its own background** | Section 6 — the main menu used to show through it |
| Internal rule ids no longer leak into **More Info** | Section 2 |

**Numbers the base campaign authors.** Weapon triangle advantage is **+10 Hit, +2 Dmg**
and disadvantage is **-10 Hit, -2 Dmg**. Effectiveness multiplies might by **×3**, and
the `giantkiller` rule by **×4**. These are unchanged from v0.8.0; what changed is that
content can now reach them.

**The authored magic cycle, stated once so nothing below is ambiguous.** The campaign
authors **anima beats light, light beats dark, dark beats anima**. Fire, Thunder and
Wind are all *anima*: they are **neutral to each other by design**, and a Fire-versus-
Thunder forecast correctly shows **no row at all**. Only `light` or `dark` on one side
makes the magic triangle fire, and only a promoted class may hold either.

---

## Section 2 — The forecast readout (first-party content)

This section uses only `free-roam.zip` — no internal content. A row reads:

```
<glyph> <Relationship name>  <the terms it contributed>
```

for example `▼ Weapon Triangle  -10 Hit, -2 Dmg`. The glyph is ▲ when the relationship
helps that side's strike, ▼ when it hurts it, ± when it does both at once and ■ when it
applies something with no number attached. Rows are coloured: green helps, red hurts.

- [ ] **The glyphs are glyphs.** Before anything else: the arrows above must draw as
  **arrows**, not as empty rectangles or question marks. The v0.8.0 build had no font
  coverage for them at all. If you see boxes anywhere in the game — arrows, bullets,
  em dashes, ✓, ∞ — screenshot it and say where.

**A relationship shows on both sides of the panel.** The same weapon triangle that
penalises the attacker is a bonus for the defender, so one forecast carries two rows —
one under each combatant. That is the first thing to look at.

- [ ] **Compare against `screenshot-album-reference/01-weapon-triangle-both-sides.png`.**
  On the **Prologue — Drill Yard**, attack the Training Dummy with **Unit_02** (Iron
  Sword). The dummy carries an Iron Lance. The panel shows
  **▼ Weapon Triangle  -10 Hit, -2 Dmg** in red under Unit_02, and
  **▲ Weapon Triangle  +10 Hit, +2 Dmg** in green under the dummy.
- [ ] **Compare against `screenshot-album-reference/02-no-relationship.png`.** Attack the
  same dummy with **Unit_01** (Iron Lance) instead. Lance against lance is no
  relationship: **no interaction row appears at all** and the panel is shorter. A row
  reading "Neutral", or an empty line where a row would be, is a defect.
- [ ] **The numbers add up.** In the first check, the Hit and Dmg figures at the top of
  each column already include that side's row. If a row says -2 Dmg and the total did not
  move by 2, that is the most serious defect this round can produce — screenshot the whole
  panel.

### The magic triangle — Chapter 3, and the neutral case in Chapter 1

The v0.8.0 checklist asked you to confirm that Fire, Thunder, Wind, Light and Dark all
oppose one another. **That was wrong** and this round replaces it. Three of the five
deliberately do not oppose each other; see Section 1 for the authored cycle.

- [ ] **The neutral case.** On **Chapter 1 — First Blood**, attack **E2_Mage** (Thunder)
  with **Unit_04** (Fire). Anima against anima: **no interaction row**, exactly like
  lance-versus-lance. Confirm the panel shows none.
- [ ] **The triangle fires.** On **Chapter 3 — The Commander**, attack the **Chapel
  Bishop** (Gleam, a *light* tome) with **Unit_04** (Fire). Fire beats light, so the
  panel shows **▲ Weapon Triangle  +10 Hit, +2 Dmg** under Unit_04 and
  **▼ Weapon Triangle  -10 Hit, -2 Dmg** under the Bishop. This is the only matchup in
  the shipping campaign where the magic triangle fires at all — the Bishop is the only
  promoted unit in it, and only a promoted class may hold light or dark.

### Weapon effectiveness — no longer out of scope

v0.8.0 told you not to test this because nothing could trigger it. Two weapons now can.

- [ ] **Player side.** On **Chapter 1 — First Blood**, select **Unit_01**, choose
  **Equip** and switch from the Iron Lance to the **Horseslayer**, then attack
  **E3_Cavalier**. The panel shows exactly one row under Unit_01:
  **▲ Weapon Effectiveness  ×3 Might**. Lance against lance means no triangle row, so
  effectiveness is on its own. **If you skip the Equip step you will see no row** — the
  Iron Lance is what Unit_01 starts with.
- [ ] **Confirm the multiplier is real.** Note Unit_01's Dmg against E3_Cavalier with the
  Iron Lance and with the Horseslayer. The second must be substantially higher, and the
  row is the only thing on screen explaining why.

### Two rows in one column

- [ ] **The two-row forecast.** On **Chapter 3 — The Commander**, attack the **Bridge
  Fighter** with **Unit_06** (Knight, Iron Lance). The Bridge Fighter carries a **Hammer**
  — an axe that is effective against armoured units, and Unit_06 is armoured. The panel
  must show:

  | Column | Rows |
  |---|---|
  | Unit_06 (attacker) | **▼ Weapon Triangle  -10 Hit, -2 Dmg** |
  | Bridge Fighter (defender) | **▲ Weapon Triangle  +10 Hit, +2 Dmg** *and* **▲ Weapon Effectiveness  ×3 Might** |

  **This is the only fight in the shipping campaign that puts two relationship rows in
  one column, and no human has ever seen it.** Screenshot it whichever way it goes, and
  answer 7.5 about it.

### The rest of the panel

- [ ] **More Info.** Click a forecast row. The explanation names the relationship and
  describes *this* fight. **It must not contain snake_case internal ids** — no
  `Matched: sword_vs_lance`, no rule names with underscores. That line was visible in
  v0.8.0 and has been moved behind the editor and debug builds. If you see one, quote it.
- [ ] **Keyboard and controller.** Every interaction row is reachable and its More Info
  openable without a mouse. **The mechanism is the More Info cycle (`F` / pad button 2),
  not focus traversal** — the forecast panel takes no focus at all, so `Tab` and the
  arrow keys will do nothing and that is by design. Press `F` repeatedly: it steps
  through every entry on the panel in order (attacker, then HP/Damage/Hit/Crit, then
  that side's interaction rows, then the defender the same way) and wraps. The check is
  that the cycle **visits every interaction row** and that each row's text matches what
  clicking it with a mouse gives you. The panel states this itself — "Click any value,
  or press F, for details. Enter attacks." Note that `Enter` on an open forecast
  **commits the attack**; it does not open anything, and the hint now says so.
- [ ] **Scaling and clipping.** Repeat the two-row check at 1280×720, 1920×1080 and a
  window under 600 px wide, and at menu/content scale 0.5 and 2. The rows must not clip,
  truncate mid-number, or overlap the Hit/Dmg/Crit figures. **Two rows in one column is
  the tallest the panel has ever been** — this is the case most likely to overflow.
- [ ] **The pack brought its own letters.** `free-roam.zip` declares its own UI font, so
  the whole interface changes typeface while that campaign is active and returns to the
  default face when you leave it. Confirm it changes, that it changes *back*, and that
  nothing turns into boxes in either state.

---

## Section 3 — The authored-relationship proof (internal pack)

⚠️ **`proving-grounds-internal-fe.zip` is INTERNAL-ONLY CONTENT.** It must not be
redistributed, posted, streamed or included in any public build or video. It exists to
prove the system can express a relationship the engine has never heard of. Delete your
copy when the round closes.

Import it through **Manage Library** exactly as any other pack. It installs alongside
`free-roam.zip`; both may be present.

This pack authors **five** relationships, and the interesting one is a weapon that sits
at two places in the hierarchy at once: the **Hallowed Scythe** is an *axe* for weapon
rank, weapon experience and the physical triangle, and *light* for the magic triangle.
The engine has no concept of "hallowed" anywhere in its code.

**The A/B is already set up for you.** The party carries two level-3 fighters with
identical stats — **Hallowed Bearer** (Hallowed Scythe) and **Free Company Axeman**
(Iron Axe). Chapter 6, *The Hallowed Ground*, pins both onto the field. Their only
difference is the weapon.

- [ ] Play the campaign to **Chapter 6**. Both units must be present and deployable;
  record it as blocked if either is missing rather than editing the pack.
- [ ] **Confirm they are still identical.** Open both unit panels and record the figures
  below. They level and take damage across five chapters, so if they have drifted apart,
  say so — the comparison below stops being attributable to the weapon and everything
  after it is void.

  | | Hallowed Bearer | Free Company Axeman |
  |---|---:|---:|
  | Max HP / current HP | | |
  | Str / Skill / Spd | | |
  | Def / Res | | |
  | Level | | |

- [ ] **Compare against `screenshot-album-reference/03-hallowed-rites-bearer.png`.** Attack a
  **Revenant** with the Hallowed Bearer. The panel shows **▲ Hallowed Rites  +5 Dmg** in
  green, and the reference reads **Dmg 15**.
- [ ] **Compare against `screenshot-album-reference/04-undead-frailty-control.png`.** Attack the
  **same Revenant** with the Free Company Axeman. It shows **▲ Undead Frailty  +1 Dmg**
  instead, no Hallowed Rites row, and the reference reads **Dmg 12**.
- [ ] **The suppression.** Notice what the bearer's forecast does *not* say: no **Undead
  Frailty** row, even though the target is undead and the axeman got one. The hallowed
  relationship deliberately suppresses it. **Judgement needed — see 7.3.**
- [ ] **Record both readings.** The bearer's Dmg must be strictly greater than the
  axeman's against the same target.

  | | Hit | Dmg | Crit | Rows shown |
  |---|---:|---:|---:|---|
  | Hallowed Bearer → Revenant | | | | |
  | Free Company Axeman → Revenant | | | | |

### The condition, and the surface that used to lie about it

Landing a Hallowed Bearer hit applies **Hallowed Sear** to the target: **-3 Resistance
for 2 phases**. In v0.8.0 the effect was real and *nothing on screen named it* — the
stat breakdown, whose whole job is to explain where a number came from, printed "No
active bonuses" directly underneath the changed value. Both halves are fixed here.

- [ ] **The condition is named.** Land a hit with the Hallowed Bearer, then open the
  Revenant's **Unit Details** (`I`, with the unit selected). The condition appears **by
  name** with its remaining duration — something of the form
  **Hallowed Sear  -3  (2 phases)**. Quote exactly what you see, including the wording
  for the duration.
- [ ] **The stat breakdown agrees with the stat.** Click the Revenant's **Resistance**.
  The breakdown must list the condition as a row and its arithmetic must reach the
  displayed effective value. **"No active bonuses" under a stat the condition has
  changed is the defect this check exists to catch** — if you see it, screenshot both the
  stat and the breakdown.
- [ ] **It ticks down and expires.** Confirm the remaining duration decreases at phase
  start and that the condition disappears when it runs out, with Resistance returning to
  its unmodified value.
- [ ] **Suspend & Quit mid-chapter, Continue, and re-check.** Hallowed Sear's remaining
  duration, its name, and the two units' stats all survive the round trip. **The
  confirmation dialog must tell you which button Enter presses** — read it before you
  press anything and record what it says.
- [ ] **The magic side.** The pack also authors a five-way elemental relationship
  (±15 Hit, ±3 Dmg) separate from the base triangle. If a chapter fields mages, confirm a
  row reading **Elemental Magic Triangle** and that it is a *different row* from Weapon
  Triangle rather than replacing it.

---

## Section 4 — Native diagnostics and window evidence

- [ ] The session header identifies v0.8.1, the executable, Windows platform, GPU,
  displays, DPI/refresh, live window mode/size and content scale.
- [ ] **Export Diagnostics** or `Ctrl+Shift+F12` produces a readable diagnostics ZIP
  containing logs, settings, pack manifests, save-slot documents and its contents
  manifest. Return it with this checklist.
- [ ] The diagnostics log records the resolved interaction rows for fights you ran.
  Do not transcribe them into this checklist — the build measures, you judge.
- [ ] A popup/confirmation dialog is fully visible and usable with keyboard or
  controller; fullscreen/normal-size recovery leaves no stale clipping or lost focus.
- [ ] **Every confirmation names its Enter key.** End Turn, Suspend & Quit and the
  AI-suspend prompt each carry a "Press Enter to …" line and focus the **affirmative**
  button. The one deliberate exception is quitting to the menu with unsaved map progress,
  which focuses **Cancel** because it throws work away. Report any dialog that says
  nothing about Enter, or that focuses a button its text does not name.
- [ ] Below 600 px wide, Settings labels stack above controls without clipping; slider
  trough, fill, endcaps and thumb remain visible at 0%, 50% and 100%.

---

## Section 5 — Saves, packs and identity

Two fixes here are about *two builds of the same pack version* being installed at once,
which the Campaign Library has allowed since the fingerprint change.

**The fixtures this section needs are in `tester-fixtures-v0.8.1.zip`.** Extract it
beside the executable before starting. v0.8.0's checklist named a fixture the bundle did
not carry; the packager now refuses to assemble a bundle whose checklist does that, so if
you are reading this, the files below are present.

- [ ] **Suspend/resume rollback.** Suspend & Quit inside a battle, then Continue.
  Content, party and node all return. Previously, a resume that activated a save's
  content and *then* refused could leave the failed save's pack active over your
  previous session — if any refusal message appears, record what was active afterwards.
- [ ] **New Game remembers the build.** Import `free-roam.zip`, start a New Game,
  return to the Library, and confirm the campaign it pre-selects next time is the one
  you actually used.
- [ ] **Two builds of one version.** Import `fingerprint-collision-a.zip` and
  `fingerprint-collision-b.zip`. They declare the **same pack id and the same version**
  and differ only in content, which is exactly the case the library rows have to
  disambiguate. Confirm both install, that both appear as separate rows, and that each
  row shows a short fingerprint that tells them apart. v0.8.0 could not reach this check
  at all: the two migration packs it offered differ in version, so they never collided.
- [ ] Empty-profile Load Game is clear; the changed-save confirmation restores focus,
  cancel preserves the original row and bytes, and import stays reachable.
- [ ] Restore `campaign_backup_v2.zip`. Its slots revalidate, share the expected pack
  identity and return to the correct campaign/Prep node.
- [ ] Import `migration-v1.zip` and `migration-v2.zip` and exercise the saves supplied
  with them. Refusals name missing or mismatched content in player-facing language, not
  only an internal id.
- [ ] A save carrying a condition (Hallowed Sear is the easy one) reloads with that
  condition intact; a save naming a condition the active pack does not define is
  refused with a readable message rather than loading half-formed.

---

## Section 6 — The campaign editor (it can be opened now)

The editor shipped in v0.7.19 and has still never been in front of a human: v0.8.0's
size gate measured the fixed 1280×720 design canvas instead of your window, so it
refused to open at 1280×720, 1920×1080 and 3840×2160 alike. It now measures the real
window, and it needs **1920×880** of it.

- [ ] **It opens.** At a window of 1920×1080 or larger, Campaign Editor opens from the
  Main Menu. At 1600×900 it should still refuse, and the message should quote **your**
  window size rather than 1280×720. Try both and record what each says.
- [ ] **It has its own background.** The editor draws on an opaque backdrop. In v0.8.0
  the scene had no background node at all, so the live main menu — title, frame and all
  five buttons — was legible straight through the editor's document area. If you can see
  anything of the menu behind the editor, screenshot it.
- [ ] Do not audit it feature by feature — **try to author something small and report
  what stopped you.** Thirty minutes is enough. Its workspaces (tree, inspector, map
  canvas, graph, assets, test) should all be reachable.
- [ ] Create or open a pack, change one value, and save. Confirm the tab shows unsaved
  state until the save actually lands — a clean tab over bytes the disk never took is
  the specific defect that round fixed.
- [ ] Force a failure if you can (read-only folder, disk full, invalid value) and
  confirm the pack on disk is either fully updated or fully unchanged, never partial,
  and that Undo still works afterwards.
- [ ] Author an interaction profile if the editor exposes one, and report plainly
  whether you could work out how to without reading any documentation.
- [ ] **Leaving the editor leaves your screen alone.** Open the editor and close it, then
  look at the main menu. Nothing should have changed size, and no black bars should have
  appeared. The editor temporarily changes how the window is scaled and is supposed to
  put it back exactly as it found it.

---

## Section 7 — Judgement calls

These are the questions only a person can answer. **Answer in prose. There are no right
answers, and "I could not tell" is a real and useful result.** None of them is about
tuning.

**7.1 — Did you notice the rows at all?** Play normally for a while before hunting for
them. Did the named relationship rows register as information you used to make a
decision, or as decoration you scrolled past? Say honestly if you ignored them.

**7.2 — Could you tell *why* a number changed?** When Hit or Dmg differed from what you
expected, did the panel tell you the reason without you clicking anything? If you had
to click More Info to understand, say so — the row is supposed to carry the answer.

**7.3 — Is a *missing* row readable?** The bearer's forecast omits Undead Frailty
because Hallowed Rites suppresses it. Nothing on screen says so. Did that read as
correct, as a bug, or did you simply not notice? This is the single design question
this round most needs answered.

**7.4 — Do the names carry their meaning?** "Weapon Triangle", "Weapon Effectiveness",
"Undead Frailty", "Hallowed Rites", "Elemental Magic Triangle" are all author-chosen and
can be anything. Did they read as the game's own language, or as internal labels leaking
onto the screen?

**7.5 — How many rows is too many, and did the two-row column read?** The panel grows
one row per relationship. **Chapter 3's Bridge Fighter is the first shipping fight to
put two rows under one combatant** — Weapon Triangle and Weapon Effectiveness together —
and nobody has ever seen it in play. Did you read it as two separate reasons, or as one
blurred block? At what number of rows did the forecast stop being scannable? The
internal pack authors five, so you can push it further there.

**7.6 — Did the condition explain itself?** Hallowed Sear now has a name, a duration and
a row in the stat breakdown. Having seen it, could you have worked out what was
happening to that unit's Resistance without being told in advance? If you had to reason
backwards from the arithmetic, say so.

**7.7 — Is the game any good right now?** The standing question every round. Answer it
about playability, feel, clarity and polish — not difficulty.

---

## Section 8 — Return package and closeout

- [ ] Return the completed checklist, the diagnostics ZIP, screenshots for every
  defect, and any save or fixture needed to explain a failure.
- [ ] State Windows version, GPU/display, build stamp, which sections you ran, where
  you stopped, and anything you could not reproduce.
- [ ] Confirm you have deleted your copy of the internal FE pack.
- [ ] Native acceptance stays pending until this evidence is reviewed. Do not mark it
  passed from the automated gates — those are supplemental and prove nothing about a
  real display.

**If you run out of time, do Sections 2, 3 and 7 and skip the rest.** Those three are
the reason this round exists. Within Section 2, the two-row forecast and the magic
triangle are the two checks no one has ever run.
