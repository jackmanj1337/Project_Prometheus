---
Role: dated
Type: register
Status: RESOLVED — CUR-1..7 ruled 2026-08-13; resolves SHC-6
Last verified: 2026-08-13
Register: CUR-1..7
Tracker: SHOP-TRANSACTION-WIREFRAMES-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Shop Currency Presentation — Owner Questions

Raised by holding [`SHC-6`](shop_header_condensation_open_questions_2026-08-12.md) on
2026-08-13: a single wallet figure in the app bar assumes gold is accepted at every store.

**Walked and resolved 2026-08-13.** `CUR-1` and `CUR-4` took a hybrid the options did not
offer; the rest took the recommendation.

## The finding: only the UI assumes gold

The engine has never assumed a single universal currency. Verified in code, not inferred:

| Layer | What it already supports |
|---|---|
| `RegistryCatalog.gd:29` | `resource_types` is a **required** registry family — an open registry, so packs add currencies without an engine edit |
| `engine_data/registries/resource_types/` | `party_gold` and `unit_gold` ship as *entries*, not as built-in concepts. Each carries `label_key` (localized), `kind: "wallet"`, `primitive_handler`, `subjects`, `save_fields` |
| `CostSpec.gd` | Every cost carries its own `resource_id` **and** `scope`; `# Positive amounts spend a resource; negative amounts credit it` |
| `ResourceLedger.quote/commit` | Take an **array** of costs, so one operation can spend several resources against several wallets, and validate `scope in entry.subjects` per cost |
| `ResourceTransaction.gd:7` | `wallets_touched: Array[String]` — plural, by construction |
| `SaveData.gd:260-268` | Migrates legacy `party_gold` into `resources["party_gold"]` — the save model is already a **resource map** |
| `[SHP-1b]` (resolved 2026-06-23) | Prices are resource-keyed and extensible to N currencies, with an explicit instruction **not to enumerate the currency set** |

Against that, `MapMenu.gd:75` reads `format_party_gold(int(gs.party_gold))` and renders one
number. **The assumption lives in one UI call site.** This is the inverted-dependency
anti-pattern the project has recorded before: a generic engine capability narrowed by the
surface that presents it.

`multi_owner_economy_implementation_plan_2026-07-23.md` already rules the adjacent axis —
*whose* wallet — with "HUD resolves the locally viewed/acting controller's configured display
wallet" and "do not merge a storage-only state in which UI, rewards, headers or results still
read `party_gold`". That plan is about **owner**; this register is about **resource kind**.
They are orthogonal and both resolve into the same header slot, which is why the shop needs
an explicit answer rather than a default.

## What is not being asked

- Whether prices are resource-keyed. `[SHP-1b]` settled that.
- Which currencies exist. `[SHP-1b]` explicitly forbids enumerating them; that is pack data.
- Whose wallet is displayed. The multi-owner plan owns that.
- Whether v1 ships more than gold. It need not. These questions are about a UI that does not
  *assume* gold, so a pack that authors a second currency is not a redesign.

## Owner questions

### [CUR-1] Which wallets does the shop show?

- **A — All wallets the party holds.** For: complete. Against: unbounded; five currencies
  cannot fit the Compact app bar, and most are irrelevant to this shop.
- **B — Only the resources this shop's stock actually prices in.** Derived as the union of
  `resource_id` across the visible stock's costs and yields. For: bounded by the shop, needs
  no new authoring, cannot drift from the prices. Against: the set changes when the Buy/Sell
  tab or facet changes, so the header can change shape mid-visit.
- **C — One author-declared primary currency per shop.** For: always exactly one figure.
  Against: a new authored field that can disagree with the prices; wrong the moment an item
  costs two resources.
- **Recommendation: B**, computed once per **visit** from the shop's whole stock rather than
  per tab or facet, so the header does not reshape while browsing.

**Owner ruling (2026-08-13): a hybrid of B and C — authored primary, full wallet on demand.**

- The **shop declares a primary currency**, and the header shows that one figure.
- The figure is a **button**. Activating it opens a popup listing **everything the player
  holds that a transaction could spend** — currencies *and* inventory items that could be
  consumed or transformed.
- The popup **scrolls**, because that list is unbounded.

**Corrected 2026-08-13.** This first recorded the popup as wallet-only, filtered on
`RegistryEntry.kind == "wallet"`. The owner reversed it: the popup lists everything, inventory
included. That is the better answer, and it closes a gap the wallet-only version had opened —
a row can price something in "2 Iron Ore", and under the wallet-only rule the popup would have
been unable to tell the player how much ore they held.

Consequences of listing everything:

- **Grouping carries the distinction the filter used to.** Currencies first, then consumable
  and transformable holdings. `kind == "wallet"` is still the right predicate — for *ordering
  and labelling*, not for exclusion.
- **The list is unbounded, so it scrolls** and inherits the single-scroll rule: it ends in its
  own dismissal, nothing docks inside it.
- **Open sub-question, flagged not decided:** whether the list is *all* holdings or only those
  this shop's offers can actually consume. All-holdings is one list the player can learn;
  shop-scoped is shorter but changes shape per shop. Recommendation: all holdings, with the
  resources this shop prices in sorted to the top.

This keeps the single-figure layout at every size class while making the full position one
press away, and it does not make the header reshape with tab, facet or focus.

### [CUR-2] Is "accepted here" authored or derived?

- **A — Derived from the stock's costs.** For: no new schema, no validator, no drift; honours
  `[SHP-1b]`'s "do not enumerate". Against: a shop cannot advertise a currency it has nothing
  priced in.
- **B — Authored per shop.** For: explicit, and supports "we take favours" as flavour.
  Against: a second source of truth to validate against the prices it duplicates.
- **Recommendation: A.** A currency with nothing priced in it is not accepted in any sense the
  player can act on.

**Owner ruling (2026-08-13): A.** The accepted set stays derived from the stock's costs.

**This composes with `CUR-1` rather than contradicting it:** the authored primary is a
*display* designation, not a declaration of what the shop takes. Two rules follow, and both
need building:

1. **Validate the primary against the derived set.** A shop declaring a primary it prices
   nothing in is an authoring error and should warn, not fail silently.
2. **Default when unset.** The primary defaults to the resource the largest share of the
   shop's stock prices in, falling back to `party_gold`. A shop must not be *required* to
   declare one.

### [CUR-3] How does a row show a price in more than one resource?

The list shows final price only (`EPUX-17`), and a row is one line.

- **A — Primary term plus a count.** `Sunder … 6,864 g +1`. For: rows stay one shape.
  Against: "+1" is not a price.
- **B — Two terms inline, overflow to a count.** `6,864 g + 2 ◆`, and `6,864 g +2 more` at
  three or more. For: the common two-resource case is fully readable in the row.
  Against: row width at 360 px, where a long name plus two terms will truncate the name.
- **C — Kind count only, full breakdown in the detail.** `Sunder … 3 costs`. For: never
  truncates. Against: makes the list unscannable, which is what `EPUX-17` optimised for.
- **Recommendation: B.** The detail pane carries the full breakdown either way; the row needs
  to support comparison, and two terms covers the realistic authored case.

**Owner ruling (2026-08-13): B.** Two terms inline, overflow to a count beyond that. **The
primary term leads**, so the column the player scans is the shop's primary currency.

### [CUR-4] What does the Compact app bar show when the accepted set is larger than it?

`SHC-1` already put the subject in that bar.

- **A — Fixed count, then overflow.** Show up to two figures, then `+N`. For: predictable bar.
  Against: the hidden one may be the one that matters.
- **B — Show the resources the focused/selected item needs.** For: always the relevant
  figures. Against: the bar changes as focus moves, which is exactly the reflow `SHC-5`'s
  collapse already asks the bar to survive.
- **C — Wallet strip below the bar, present only when the set exceeds one.** For: single
  currency (the common case) costs nothing; multi-currency pays 37 px only when real.
  Against: reintroduces a band the walk just removed — though conditionally.
- **Recommendation: C**, with A's `+N` overflow inside the strip. It keeps the ruled
  single-currency layout untouched and makes the cost proportional to the pack's complexity
  rather than charged to every pack in advance.

**Owner ruling (2026-08-13): none of these — the `CUR-1` popup covers it.** Compact shows the
primary figure only and pops out to the full holdings list, exactly as every other size class
does. No conditional strip, no overflow count in the bar, no reshaping on focus.

This is strictly better than the recommendation: there is now **one** presentation at every
size class instead of a Compact special case, and the 37 px the walk removed stays removed
even for multi-currency packs. Per `UUI-5` the popup is bounded by the game-view rect — a
sheet at Compact, a centred card elsewhere.

**Abbreviation (owner, 2026-08-13):** the figure in the bar is **abbreviated**; the popup
carries the full count. The `SHC-6` objection to abbreviation — that rounding misleads exactly
where the decision is hardest — was correct *in a world with nowhere else to look*. The popup
is that place, and the detail pane's "If you buy" block still states exact before/after
figures, so no commit is ever made against a rounded number.

**Rule to build:** exact below 10,000, compact above (`12.3k`, `1.4M`). Below the threshold
the abbreviated and full forms are identical, so early-game values never lose precision and
the bar cannot blow out late-game. The threshold is the knob if this reads wrong in play.

### [CUR-5] What does the shortfall reason say when several resources are short?

`SHC-7` put affordability on the rows as disabled-with-reason.

- **A — Generic "cannot afford".** Against: with N currencies the player cannot tell which.
- **B — Name the first shortfall.** `Short 2,266 g`. For: fits a row. Against: fixing it
  reveals a second failure, which reads as the shop moving the goalposts.
- **C — Name every shortfall in the detail, the largest in the row.** For: the row stays one
  line and the detail is complete. Against: "largest" needs a comparison rule across
  resources that have no exchange rate.
- **Recommendation: C**, with "largest" meaning *most short relative to what is held*, and
  every shortfall listed in the detail. `ResourceTransaction` already returns resource-keyed
  `shortfalls`, so this is presentation over data that exists.

**Owner ruling (2026-08-13): C.** Largest shortfall in the row, every shortfall in the detail.
"Largest" is *most short relative to what is held*, because resources have no exchange rate
to compare across — `CUR-6` confirms there is deliberately no rate table to appeal to.

### [CUR-6] Is exchange or conversion between currencies a feature?

- **A — Yes, a money-changer surface with rates.** Against: a new system, new authoring, new
  balance surface, and a rate table nobody has asked for.
- **B — No engine feature; it is already expressible.** `CostSpec` credits on negative
  amounts, so "trade 3 ore for 500 gold" is one offer costing `+3 ore` and `−500 gold`. It
  appears in a normal shop list, quotes, commits and reverses like any other transaction.
- **C — No, and forbid it.** Against: nothing to forbid; the primitive is already general.
- **Recommendation: B.** Record it as a known-expressible pattern so nobody builds a
  conversion system for it. Worth one authored example in a demo pack.

**Owner ruling (2026-08-13): B.** No exchange feature. A money-changer is a normal shop whose
offers spend one resource and credit another, and it inherits quote, commit, atomicity and
visit-restore for free. **Action: author one example in a demo pack** so the pattern is
discoverable rather than folklore.

### [CUR-7] What happens when a cost is unit-scoped rather than party-scoped?

`unit_gold` ships today with `subjects = ["unit"]`.

- **A — Header always shows party wallets.** Against: an item priced in `unit_gold` is then
  affordable or not for reasons the header never shows.
- **B — Header shows the wallets the visible prices actually draw from**, resolved through
  the current subject, so a unit-scoped price displays that unit's wallet and switching
  shopper changes the figure. For: falls out of `CUR-1(B)` with no extra rule.
  Against: the figure changing on shopper switch needs to be legible as *whose* it is.
- **C — Suppress unit-scoped prices in shops.** Against: removes a shipped capability.
- **Recommendation: B**, with the wallet labelled by owner when it is not the party's —
  which is also what the multi-owner plan requires of every wallet display.

**Owner ruling (2026-08-13): B.** The header resolves the wallets the visible prices actually
draw from, through the current subject, and labels a wallet by owner when it is not the
party's. Under `CUR-1` this lands in the popup as well: a unit-scoped wallet is listed as that
unit's, not as an unattributed figure.

## Consequences of the ruled set

1. **`SHC-6` resolves: persistent and unabbreviated.** The header carries the shop's primary
   currency at full precision — no `2.4k` rounding — and it is a button to the full wallet.
   The premise that broke `SHC-6` is gone: the bar shows one figure because the shop names
   one, not because gold is assumed universal.
2. **`MapMenu.gd:75` is the whole migration.** `format_party_gold(gs.party_gold)` becomes a
   renderer that reads `label_key` off the registry entry and formats the shop's primary.
   Nothing else in the engine needs changing to stop assuming gold.
3. **No new authoring obligation.** Primary currency is optional with a derived default;
   the accepted set is derived; the wallet popup filters on a `kind` field that already
   exists. A pack that authors one currency writes exactly what it writes today.
4. **Every cost a row can name is answerable from the popup.** Because it lists holdings
   rather than wallets, a price of "2 Iron Ore" resolves in the same place as a price in
   gold. The detail pane's "If you buy" block still states held-versus-required for each
   cost, but it is no longer the *only* place an inventory-kind cost can be checked.
5. **The bar figure is abbreviated and the popup is authoritative.** Any surface that must
   not mislead — the price breakdown, the consequence preview, the shortfall — uses full
   precision. Abbreviation is confined to the glance.

## Next step

Redraw the album's Compact and landscape frames against `SHC-1..8` and `CUR-1..7`, including
a two-currency shop and the holdings popup open — cases the album has no frames for.
