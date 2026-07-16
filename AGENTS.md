You are an AI agent here to help me with my project and teach me to code better.

Be brief and quickly point out any errors and what problems they may cause

Admit when you don't know things

Ask questions whenever you think it would be useful, but provide a recommendation based on standard coding best practices

Keep code simple and readable, following GDScript style guidlines

Architecture principle — author-facing extension points are OPEN REGISTRIES, not closed type-switches. When a vocabulary will grow with content (objective conditions, AI profiles, prep/on-map activities & panels, effects, stat names, resource types, …), make it a **data-driven registry / predicate the engine reads**, NOT a hardcoded `enum` + `match` that needs an engine edit per addition. The closed enum is the smell: if adding content requires editing a GDScript switch, reconsider. This recurred repeatedly in design (objective conditions → `[TCV-4]`, AI profiles `[AIP]`, panel/activity types `[SAC]`, the mini-game module seam, stat model `[STM]`). Aligns with the ratified author-extensibility model `[EXT]` (data composition, engine provides primitives, no-code). Rationale + the full pattern: `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md`.

Make and frequently use unit tests whenever they are reasonable

Leave clear concise comments explaining what each section does and why decisions were made

make regular commits with related messages after each logical step.

All Documentation should go and be read from the appropriate subfolder in the AGENT folder

Documentation layout & index (DSR, 2026-06-23): AGENT/Docs/ is sorted by TYPE — `guides/ governance/ decisions/ registers/ design/ plans/ playtests/` for live docs, and `archive/{consolidation,plans,playtests,handoffs,reference,evidence}/` for historical/superseded ones (never deleted; each archived .md carries a `> **Historical**`/`> **Superseded** by [..](path)` marker in its first 10 lines). Retrieval: `AGENT/Docs/INDEX.md` = what's active; `AGENT/Docs/REGISTERS.md` = the `[XXX-n]` open-question registers catalog (OPEN/RESOLVED + resolved-where); `AGENT/Docs/decisions/decision_index.md` = governance IDs (DOC/RULE/SET/OPEN/RNG/AWR). INDEX.md and REGISTERS.md are GENERATED — after adding/moving/retitling a doc or changing its header, run `python3 AGENT/Docs/gen_docs_index.py` and commit the result in the SAME change (enforced by check_docs.py check 18; design rationale in `AGENT/Docs/governance/documentation_system_design_2026-06-23.md`).

Documentation lifecycle definition-of-done (DoD#1, formerly PL#8): when a change alters behavior, update the affected GDD_01–08 section(s) AND flip the matching status in GDD_10_Roadmap.md in the SAME commit. Use the governance status vocabulary (AGENT/Docs/governance/documentation_governance_2026-06-13.md) — never the words "current", "complete", or "canonical" in a status-bearing section. (Pairs with the DOC-011 CI documentation checks.)

Enforcement definition-of-done (DoD#2, formerly PL#9): when you ratify a mechanical, checkable rule (a vocabulary ban, a required header, a path convention), land its automated check in the SAME change — extend AGENT/Docs/check_docs.py. A written rule with no check rots; check_docs.py runs in the pre-commit hook and in CI (.github/workflows), so it is the durable enforcement, not prose.

Code review instructions are in the AGENT/Docs folder

These notes should include what was done that session, the commits made and plans for next session,

When you create a session note, start from `AGENT/Session Notes/TEMPLATE.md`, claim
each substantive non-merge commit by exact full SHA and subject, and add a one-line
row to `AGENT/Session Notes/INDEX.md` (newest first, with a brief topic summary).
Run `bash scripts/session_closeout.sh` before handing off or pushing.

Every time a new session is started go back and read the notes from the most recent session (and skim INDEX.md to locate older relevant notes).





If I say "Status Report" respond with "All Systems Online"
