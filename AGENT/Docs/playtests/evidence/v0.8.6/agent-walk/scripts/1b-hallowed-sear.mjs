#!/usr/bin/env node
// Section 1B: Hallowed Sear countdown, release build, normal AI, Auto-End Turn off,
// followed to the letter of the v0.8.6 checklist wording (attack once, Wait afterward,
// Suspend & Continue at (1 phase), then on to (gone) at BLUE turn 3).

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, chooseOptionButtonByLabel, clickPathPart, clickSuffix,
  clickSuffixWithScrollFallback, clickTile,
  entryByPathPart, hoverTile, mapState, openLoadGame, unitOnMap,
  waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const URL_BASE = process.argv[2];
const BACKUP = process.argv[3];
const OUT = process.argv[4];
const SLOT = "resume_battle";
const BEARER = "m006_hallowed_bearer";
const TARGET = "m006_revenant_1";
const EXPECT = { bearerTile: [2, 3], bearerHp: 24, targetTile: [8, 3], targetHp: 22 };

let stepIndex = 0;
async function step(page, out, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const result = await fn();
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(out, `${stem}.png`) });
  const record = { step: stepIndex, label, result: result ?? null, map: observed.map, viewport: observed.viewport };
  await writeFile(path.join(out, `${stem}.json`), `${JSON.stringify(record, null, 2)}\n`);
  console.log(`  [${stem}] ${label}`);
  return { record, observed };
}

async function uploadThrough(page, suffix, file) {
  const chooser = page.waitForEvent("filechooser");
  await clickSuffix(page, suffix, { settleAfter: false });
  await (await chooser).setFiles(file);
}

async function readHudLabels(page) {
  const observed = await bridge.snapshot(page);
  const turn = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/TurnLabel") || p === "TurnLabel");
  const phase = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/PhaseLabel") || p === "PhaseLabel");
  return { turnLabel: turn?.[1]?.text ?? null, phaseLabel: phase?.[1]?.text ?? null };
}

async function readBothUnits(page) {
  const map = await mapState(page);
  return { bearer: unitOnMap(map, BEARER), target: unitOnMap(map, TARGET), map };
}

async function openUnitDetailsOnTile(page, tile) {
  await hoverTile(page, tile);
  await page.keyboard.press("i");
  await page.waitForFunction(
    (name) => {
      try { return JSON.parse(window[name]?.state ?? "{}").focus?.text === "Back"; }
      catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: 60_000 },
  );
  await settle(page);
}

// The bridge cannot read UnitDetailsScreen's InfoModifiers/InfoDescription text --
// WebTestBridge._active_screen() resolves "hud" first (HUD precedes UnitDetailsScreen
// in SCREEN_NAMES, and HUD stays visible underneath), so `rects` only ever contains
// HUD's own descendants while this screen is open (confirmed empirically this run: an
// attempted fixed-7-press cycle, which worked for a prior build's batch-a script,
// produced only the screen's idle "Click any entry..." hint here -- the count needed
// evidently differs and there is no machine-readable signal to detect the right one).
// So this takes a screenshot after EVERY press up to a generous ceiling and returns
// the list, and the report picks the one that actually shows the Resistance row by eye.
async function cycleMoreInfoAndCaptureEach(page, out, label, maxPresses = 14) {
  const shots = [];
  for (let i = 1; i <= maxPresses; i += 1) {
    await page.keyboard.press("f");
    await settle(page);
    const file = path.join(out, `moreinfo-${label}-press${String(i).padStart(2, "0")}.png`);
    await page.screenshot({ path: file });
    shots.push(file);
  }
  return shots;
}

async function closeUnitDetails(page) {
  await page.keyboard.press("i");
  await page.waitForFunction(
    (name) => {
      try { return JSON.parse(window[name]?.state ?? "{}").focus?.text !== "Back"; }
      catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: 60_000 },
  );
  await settle(page);
}

// Select the Bearer where it stands and issue Wait: click its own tile to select it,
// click its own tile again to confirm a zero-length move (opens ActionMenu), BtnWait.
async function bearerWait(page, tile) {
  let map = await clickTile(page, tile);
  if (map.cursorState !== "unit-selected") throw new Error(`selecting the Bearer left cursor ${map.cursorState}`);
  map = await clickTile(page, tile);
  await waitForScreen(page, "action-menu");
  await clickSuffix(page, "/BtnWait");
  map = await mapState(page);
  if (map.cursorState !== "free") throw new Error(`Wait left cursor ${map.cursorState}, expected free`);
}

async function endTurnFromMapMenu(page) {
  await page.keyboard.press("m");
  await waitForScreen(page, "map-menu");
  await clickSuffix(page, "/EndTurnButton");
  await settle(page);
  // End Turn commits immediately when every unit has acted. An extra Enter after
  // the next BLUE phase begins selects the Bearer under the cursor, so only press
  // it if the turn is still waiting for the confirmation dialog.
  if ((await mapState(page)).cursorState !== "free") {
    await page.keyboard.press("Enter");
    await settle(page);
  }
  await page.waitForFunction(
    (name) => {
      try { return JSON.parse(window[name]?.state ?? "{}").map?.cursorState === "free"; }
      catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: 60_000 },
  );
  await settle(page);
}

async function main() {
  if (!URL_BASE || !BACKUP || !OUT) {
    console.error("usage: 1b-hallowed-sear.mjs <served-url> <interaction-duration-backup.zip> <outDir>");
    process.exit(2);
  }
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  const notes = [];
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;

    await step(page, OUT, "boot main menu", async () => {
      await waitForScreen(page, "main-menu");
    });

    // --- Auto-End Turn OFF, before anything else, per the checklist. ---
    await step(page, OUT, "open Settings from Main Menu", async () => {
      await clickSuffix(page, "/SettingsButton");
      await waitForScreen(page, "settings");
    });
    await step(page, OUT, "set Auto-End Turn to Off", async () => {
      await chooseOptionButtonByLabel(page, "/OptAutoEndTurn", "Off", 0);
    });
    await step(page, OUT, "back to Main Menu from Settings", async () => {
      await clickSuffixWithScrollFallback(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });

    // --- Restore the backup, observe the stale row, Retry, Load. ---
    await step(page, OUT, "open Manage Library", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    const restoreResultStep = await step(page, OUT, "restore interaction-duration-backup.zip", async () => {
      await uploadThrough(page, "/BtnRestore", BACKUP);
      await page.waitForFunction(
        (name) => {
          try {
            const state = JSON.parse(window[name]?.state ?? "{}");
            return Object.entries(state.rects ?? {}).some(
              ([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text),
            );
          } catch { return false; }
        },
        bridge.BRIDGE_GLOBAL,
        { timeout: 60_000 },
      );
      await settle(page);
      const observed = await bridge.snapshot(page);
      const optPackage = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/OptPackage"));
      return { restoreDialogText: optPackage?.[1]?.text ?? null };
    });
    await step(page, OUT, "dismiss restore result dialog", async () => {
      await page.keyboard.press("Enter");
      await settle(page);
    });
    await step(page, OUT, "back to Main Menu", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });
    const staleLoadGame = await step(page, OUT, "open Load Game — expect stale [Needs campaign] rows", async () => {
      await openLoadGame(page);
      const observed = await bridge.snapshot(page);
      const rows = Object.entries(observed.rects ?? {})
        .filter(([p]) => p.includes("/Row_") && p.endsWith("/LoadButton"))
        .map(([p, r]) => ({ path: p, text: r.text }));
      return { rows };
    });
    notes.push(`Load Game rows immediately after restore, before Retry: ${JSON.stringify(staleLoadGame.record.result.rows)}`);
    await step(page, OUT, `press Retry on ${SLOT}`, async () => {
      await clickPathPart(page, `/Row_${SLOT}/`, "/RetryButton");
      await page.waitForTimeout(250);
      await page.keyboard.press("Enter");
      await page.waitForFunction(
        ([name, slotId]) => {
          try {
            const state = JSON.parse(window[name]?.state ?? "{}");
            const button = Object.entries(state.rects ?? {}).find(
              ([p]) => p.endsWith(`/Row_${slotId}/LoadButton`),
            );
            return Boolean(button?.[1]?.text) && !button[1].text.includes("[Needs campaign]");
          } catch { return false; }
        },
        [bridge.BRIDGE_GLOBAL, SLOT],
        { timeout: 60_000 },
      );
    });
    const retriedRow = await step(page, OUT, `${SLOT} row after Retry — should now be loadable`, async () => {
      const observed = await bridge.snapshot(page);
      return entryByPathPart(observed, `/Row_${SLOT}/`, "/LoadButton")[1];
    });
    notes.push(`${SLOT} row text after Retry: ${JSON.stringify(retriedRow.record.result)}`);

    await step(page, OUT, `load ${SLOT}`, async () => {
      await clickPathPart(page, `/Row_${SLOT}/`, "/LoadButton");
      await waitForLiveMap(page);
    });

    const boardCheck = await step(page, OUT, "assert exact starting board (Turn 1, Bearer 24@(2,3), Revenant 22@(8,3))", async () => {
      const { bearer, target } = await readBothUnits(page);
      const hud = await readHudLabels(page);
      const ok = (
        String(bearer.tile) === String(EXPECT.bearerTile) && bearer.hp === EXPECT.bearerHp
        && String(target.tile) === String(EXPECT.targetTile) && target.hp === EXPECT.targetHp
      );
      return { bearer, target, hud, matchesExpected: ok };
    });
    notes.push(`Starting board matches checklist expectation: ${boardCheck.record.result.matchesExpected}`);

    await step(page, OUT, "open Revenant Unit Details, cycle to Resistance (pre-hit)", async () => {
      const { target } = await readBothUnits(page);
      await openUnitDetailsOnTile(page, target.tile);
      await cycleMoreInfoAndCaptureEach(page, OUT, "prehit");
    });
    await step(page, OUT, "close Unit Details after pre-hit read", async () => {
      await closeUnitDetails(page);
    });

    // --- Move Bearer adjacent, Attack, confirm target. ---
    let boardNow = await readBothUnits(page);
    const approach = [boardNow.target.tile[0] - 1, boardNow.target.tile[1]];
    await step(page, OUT, `select Bearer at ${boardNow.bearer.tile}`, async () => {
      const map = await clickTile(page, boardNow.bearer.tile);
      if (map.cursorState !== "unit-selected") throw new Error(`selecting Bearer left cursor ${map.cursorState}`);
    });
    await step(page, OUT, `move Bearer to ${approach}`, async () => {
      await clickTile(page, approach);
      await waitForScreen(page, "action-menu");
    });
    await step(page, OUT, "choose Attack", async () => {
      await clickSuffix(page, "/BtnAttack");
    });
    await step(page, OUT, `confirm target ${TARGET} at ${boardNow.target.tile}`, async () => {
      await clickTile(page, boardNow.target.tile, { expectState: "targeting" });
      await waitForScreen(page, "attack-preview");
    });

    let hit = false;
    let attempts = 0;
    while (!hit && attempts < 3) {
      attempts += 1;
      const preHp = await step(page, OUT, `read pre-attack HP (attempt ${attempts})`, async () => readBothUnits(page));
      await step(page, OUT, `commit the attack (Enter), attempt ${attempts}`, async () => {
        await page.keyboard.press("Enter");
        await waitForScreen(page, "hud");
        await page.waitForFunction(
          (name) => {
            try { return JSON.parse(window[name]?.state ?? "{}").map?.cursorState === "free"; }
            catch { return false; }
          },
          bridge.BRIDGE_GLOBAL,
          { timeout: 60_000 },
        );
      });
      const postHp = await step(page, OUT, `read post-attack HP (attempt ${attempts})`, async () => readBothUnits(page));
      hit = postHp.record.result.target.hp < preHp.record.result.target.hp;
      notes.push(`Attack attempt ${attempts}: target HP ${preHp.record.result.target.hp} -> ${postHp.record.result.target.hp} (hit=${hit})`);
      if (!hit) {
        if (attempts >= 3) throw new Error("the attack missed three times; checklist says restore and restart 1B");
        // Missed: must wait a full BLUE/RED cycle before attacking again, per the checklist.
        boardNow = await readBothUnits(page);
        await step(page, OUT, `Bearer Wait after a miss (attempt ${attempts})`, async () => {
          await bearerWait(page, boardNow.bearer.tile);
        });
        await step(page, OUT, `End Turn after a miss (attempt ${attempts})`, async () => {
          await endTurnFromMapMenu(page);
        });
        boardNow = await readBothUnits(page);
        await step(page, OUT, `select Bearer again at ${boardNow.bearer.tile}`, async () => {
          const map = await clickTile(page, boardNow.bearer.tile);
          if (map.cursorState !== "unit-selected") throw new Error(`re-selecting Bearer left cursor ${map.cursorState}`);
        });
        const approach2 = [boardNow.target.tile[0] - 1, boardNow.target.tile[1]];
        await step(page, OUT, `move Bearer to ${approach2} (attempt ${attempts + 1})`, async () => {
          await clickTile(page, approach2);
          await waitForScreen(page, "action-menu");
        });
        await step(page, OUT, "choose Attack again", async () => {
          await clickSuffix(page, "/BtnAttack");
        });
        await step(page, OUT, `confirm target again at ${boardNow.target.tile}`, async () => {
          await clickTile(page, boardNow.target.tile, { expectState: "targeting" });
          await waitForScreen(page, "attack-preview");
        });
      }
    }

    // --- Hit landed: read Hallowed Sear (2 phases), Resistance -3. REQUIRED SCREENSHOT. ---
    await step(page, OUT, "SCREENSHOT — Unit Details after landing the hit: Hallowed Sear (2 phases), Resistance -3", async () => {
      const { target } = await readBothUnits(page);
      await openUnitDetailsOnTile(page, target.tile);
      await cycleMoreInfoAndCaptureEach(page, OUT, "landed-2phases");
      return readBothUnits(page);
    });
    await step(page, OUT, "close Unit Details after landing the hit", async () => {
      await closeUnitDetails(page);
    });

    // --- Do not attack again. End Turn, let AI play RED. BLUE turn 2: (1 phase). ---
    // NOTE: no Wait here. The Bearer already acted this turn (it attacked), and a unit
    // that has already acted cannot be re-selected (MapCursorSelection.select_at
    // refuses it, leaving the cursor FREE) -- confirmed empirically: the first version
    // of this script tried to Wait here and got "selecting the Bearer left cursor free".
    // The checklist's "give Hallowed Bearer Wait" applies on LATER BLUE turns, once it
    // has not yet acted that turn -- see the two bearerWait() calls below.
    await step(page, OUT, "End Turn (map menu), let RED AI play", async () => {
      await endTurnFromMapMenu(page);
    });
    await step(page, OUT, "SCREENSHOT — BLUE turn 2 begins: Unit Details should show (1 phase)", async () => {
      const { target } = await readBothUnits(page);
      await openUnitDetailsOnTile(page, target.tile);
      await cycleMoreInfoAndCaptureEach(page, OUT, "turn2-1phase");
      return readBothUnits(page);
    });
    const preSuspend = await step(page, OUT, "read state just before Suspend & Quit (still viewing Unit Details)", async () => readBothUnits(page));
    await step(page, OUT, "close Unit Details before Suspend & Quit", async () => {
      await closeUnitDetails(page);
    });

    // --- Suspend & Quit now, at (1 phase), then Continue. ---
    await step(page, OUT, "open Map Menu, Suspend & Quit, confirm", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
      await clickSuffix(page, "/SuspendAndQuitButton");
      await page.keyboard.press("Enter");
      await waitForScreen(page, "main-menu");
    });
    await step(page, OUT, "open Load Game to Continue the suspended battle", async () => {
      await openLoadGame(page);
    });
    await step(page, OUT, `Continue (Load) ${SLOT}`, async () => {
      await clickPathPart(page, `/Row_${SLOT}/`, "/LoadButton");
      await waitForLiveMap(page);
    });
    const postContinue = await step(page, OUT, "SCREENSHOT — after Continue: Unit Details should still show (1 phase), same HP/tiles", async () => {
      const { target } = await readBothUnits(page);
      await openUnitDetailsOnTile(page, target.tile);
      await cycleMoreInfoAndCaptureEach(page, OUT, "postcontinue-1phase");
      return readBothUnits(page);
    });
    const stateUnchanged = JSON.stringify(preSuspend.record.result) === JSON.stringify(postContinue.record.result.map ? postContinue.record.result : postContinue.record.result);
    notes.push(`Suspend/Continue HP+tile comparison — before: ${JSON.stringify(preSuspend.record.result)} after: ${JSON.stringify(postContinue.record.result)}`);
    await step(page, OUT, "close Unit Details after Continue", async () => {
      await closeUnitDetails(page);
    });

    // --- End BLUE's second phase, let RED play. BLUE turn 3: Hallowed Sear gone. ---
    boardNow = await readBothUnits(page);
    await step(page, OUT, `Bearer Wait for round 3 at ${boardNow.bearer.tile}`, async () => {
      await bearerWait(page, boardNow.bearer.tile);
    });
    await step(page, OUT, "End Turn (map menu), let RED AI play (second cycle)", async () => {
      await endTurnFromMapMenu(page);
    });
    await step(page, OUT, "SCREENSHOT — BLUE turn 3 begins: Hallowed Sear should be gone, Resistance restored", async () => {
      const { target } = await readBothUnits(page);
      await openUnitDetailsOnTile(page, target.tile);
      await cycleMoreInfoAndCaptureEach(page, OUT, "turn3-expired");
      return readBothUnits(page);
    });
    await step(page, OUT, "close Unit Details at expiry", async () => {
      await closeUnitDetails(page);
    });

    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log("\n1B journey completed without a harness error. Read Unit Details text from the screenshots.");
    console.log(notes.join("\n"));
  } catch (error) {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`).catch(() => {});
    console.error("FAILED:", error.stack ?? error.message);
    process.exitCode = 1;
  } finally {
    await teardown(session);
  }
}

main();
