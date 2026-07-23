Questions per item — let’s agree the goal before I write plans

  

R1 — Economy ownership (PP-FACTION-GOLD-ECONOMY)
1. What’s the actual gameplay goal — do enemy/green factions genuinely spend (AI buying/reinforcing), or is this only so the HUD can show a different faction’s gold in hotseat/observer views?
   This is primarily for the eventual hotseat/multiplayer plan, but future versions might have an AI that can spend resources to purchase reinforcements

2. What is the owner key? Faction id, or a broader owner_ref (faction | shop | campaign | unit | arena)? Do you want shops/treasury expressible now, or strictly faction wallets for v1? 
   Lets do the broader owner_ref

3. Is gold the only resource for now, or should the registry be multi-resource (bonus-EXP, materials) from the start? 
   Lets do three resources (gold, bonus-exp, and training points) to fully exercise the system. Should rewind charges be moved to the wallet system?

4. Migration: when an old save with one party_gold loads, which owner inherits it — “blue/player” by default? And does rewind/Retry treat all wallets as one atomic unit?
   Don't worry to much about save migration yet, but yes assume the blue/player faction inherits it. I am not sure what it implies for all the wallets to be one unit, but they should be included in rewind.

  R2 — Pack/save serialization dedup (PP-STRATEGIC-DATA-OWNERSHIP)
5. What’s the concrete symptom driving this — save-file bloat, slow load, or correctness (a save drifting from its pack)? That decides whether the answer is by-reference storage or something lighter.
   There is some concern about save file bloat and load speed going forward, but the idea is that these packs are supposed to be easy to edit/fork and redesign so the primary goal is to not have to change the same piece of information in multiple places for it to take effect.

6. Should a save store only deltas against its pack (pack owns canonical data, save owns mutations), or remain self-contained so it loads without the pack present?
   The pack should own the save. Possibly we should allow the export of separate save files without the rest of the pack for backup and cross device play, along with exporting the entire pack or a clean version of the pack without user save data. So just saving current state and mutations sounds good, but if it is significantly more complicated and doesn't gain much we might consider it. Requires more research.

7. What’s the compatibility contract when a save’s pack has been updated since the save was written — pin to pack version, or re-resolve against the current pack?
   The pack should write a version to the save when it is created and a future pack can check if it has loading rules for that version/version group.

  R3 — Engine-baked-data removal (PP-STRATEGIC-DATA-OWNERSHIP)
8. What’s the target end-state — does the base game ship as a first-class campaign pack (engine ships with zero content), or does a minimal default set stay engine-side? 
   The goal is that the engine compiles with zero content and is distributed with one or more zip files of data packs that authors and players can pick and choose from.

9. Where’s the line for “pack-ownable”? The boundary plan lists classes/weapons/items/maps as pack data — does that include the live balance numbers (which LEG-AUDIT-FE-NUMBERS is separately eyeing), or only structure?
   Live balance numbers and potentially even formulas where possible should be pack owned along with as much as is reasonable. This will require more research to decide what can be turned into data without implementing a full sandboxed scripting environment.

10. Is this a hard v1 requirement or a directional cleanup? (It’s the difference between a migration project and an opportunistic refactor.). 
    Yess this should be a hard requirement and should probably be considered soon as it will likely only grow in scope.

R4 — Rule-profile contract (B3-CAMPAIGN-RULES)
1. Is a “profile” just a named bundle of default values a pack points at, or can it also carry mandates/locks and per-node structure?
   This may need more explanation from you but the profile likely would effecitvely be a collection of recomended defaults that lives in the documentation or campaign editor GUI in a way that would be easy for authors to drop in. possibly as a pointer, possibly as a copy paste.

2. Where does the profile sit in the existing resolver — is it simply the source of the “campaign default” layer (below node/mid-map overrides), or a new layer of its own?
   It is probably the source of campaign defaults

3. Do packs select from engine-provided profiles by id, author their own profile documents, or both?
   Likely treat as authoring their own profile docs, but the authoring may effectively be copy pasting from docs that may be built into the pack, GUI editor, or distributed seperately

4. Scope for the first slice — reuse the existing CampaignRules fields as-is (profile = a .tres/JSON of those fields), or does this expand the rule set too?
   I am not sure, so likely reuse Campaign rules unless there are other reasons to expand or replace. 
