#!/usr/bin/env node
// v0.8.6 Section 4 (Chapter 6) browser walk on one fixture:
//   unit details of the attacker (stat identity), forecast vs m006_revenant_1 (Hit/Dmg/Crit),
//   and optionally land the hit and capture the Revenant's Unit Details More Info cycle.
// usage: section4.mjs <url> <backup.zip> <fixture.json> <outDir> [--land]
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import * as bridge from "./lib/bridge.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, chooseOptionButtonByLabel, clickSuffixWithScrollFallback, clickPathPart, clickSuffix, clickTile, hoverTile, mapState, openLoadGame,
  unitOnMap, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [URL_BASE, BACKUP, FIXTURE, OUT] = process.argv.slice(2);
const LAND = process.argv.includes("--land");
let n = 0;

async function shot(page, label, extra = null) {
  n += 1;
  const stem = `${String(n).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify({ label, extra, observed }, null, 2)}\n`);
  console.log(`  [${stem}]`);
  return observed;
}

function texts(observed, filter = () => true) {
  return Object.entries(observed?.rects ?? {})
    .filter(([p, r]) => r.text && filter(p))
    .map(([p, r]) => `${p} = ${JSON.stringify(r.text)}`);
}

async function openDetails(page, tile) {
  await hoverTile(page, tile);
  await page.keyboard.press("i");
  await page.waitForFunction(
    (name) => { try { return JSON.parse(window[name]?.state ?? "{}").focus?.text === "Back"; } catch { return false; } },
    bridge.BRIDGE_GLOBAL, { timeout: 60_000 });
  await settle(page);
}
async function closeDetails(page) {
  await page.keyboard.press("i");
  await page.waitForFunction(
    (name) => { try { return JSON.parse(window[name]?.state ?? "{}").focus?.text !== "Back"; } catch { return false; } },
    bridge.BRIDGE_GLOBAL, { timeout: 60_000 });
  await settle(page);
}
async function cycleDetails(page, label, presses) {
  for (let i = 1; i <= presses; i += 1) {
    await page.keyboard.press("f");
    await settle(page);
    await page.screenshot({ path: path.join(OUT, `details-${label}-f${String(i).padStart(2, "0")}.png`) });
  }
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const fixture = JSON.parse(await readFile(FIXTURE, "utf8"));
  const attackerId = fixture.bearer.unit_id;
  const targetId = fixture.target.unit_id;
  const slot = fixture.campaign_slot;
  const notes = { attacker: attackerId, target: targetId };
  let session;
  try {
    session = await boot({ url: buildUrl(URL_BASE, { bridge_rects: "all" }), viewport: { width: 1280, height: 720 } });
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await shot(page, "main menu");
    if (process.argv.includes("--auto-end-off")) {
      await clickSuffix(page, "/SettingsButton");
      await waitForScreen(page, "settings");
      await chooseOptionButtonByLabel(page, "/OptAutoEndTurn", "Off", 0);
      await shot(page, "auto-end turn off");
      await clickSuffixWithScrollFallback(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    }

    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    const chooser = page.waitForEvent("filechooser");
    await clickSuffix(page, "/BtnRestore", { settleAfter: false });
    await (await chooser).setFiles(BACKUP);
    await page.waitForFunction(
      (name) => { try { return Object.entries(JSON.parse(window[name]?.state ?? "{}").rects ?? {}).some(([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text)); } catch { return false; } },
      bridge.BRIDGE_GLOBAL, { timeout: 60_000 });
    await settle(page);
    await shot(page, "restore result");
    await page.keyboard.press("Enter");
    await settle(page);
    await clickSuffix(page, "/BtnBack");
    await waitForScreen(page, "main-menu");
    await openLoadGame(page);
    await clickPathPart(page, `/Row_${slot}/`, "/RetryButton");
    await page.waitForTimeout(250);
    await page.keyboard.press("Enter");
    await page.waitForFunction(
      ([name, s]) => { try { const b = Object.entries(JSON.parse(window[name]?.state ?? "{}").rects ?? {}).find(([p]) => p.endsWith(`/Row_${s}/LoadButton`)); return Boolean(b?.[1]?.text) && !b[1].text.includes("[Needs campaign]"); } catch { return false; } },
      [bridge.BRIDGE_GLOBAL, slot], { timeout: 60_000 });
    await clickPathPart(page, `/Row_${slot}/`, "/LoadButton");
    await waitForLiveMap(page);
    const board = await mapState(page);
    notes.board = board.units;
    await shot(page, "live board");

    // Stat identity: Unit Details of every blue unit named in the checklist that is on this board.
    for (const id of ["m006_hallowed_bearer", "m006_plain_axeman"]) {
      const unit = (board.units ?? []).find((u) => u.unitId === id);
      if (!unit) { notes[`${id}_present`] = false; continue; }
      notes[`${id}_present`] = true;
      await openDetails(page, unit.tile);
      await shot(page, `unit details ${id}`);
      await closeDetails(page);
    }

    const attacker = unitOnMap(await mapState(page), attackerId);
    const target = unitOnMap(await mapState(page), targetId);
    const approach = [target.tile[0] - 1, target.tile[1]];
    let map = await clickTile(page, attacker.tile);
    if (map.cursorState !== "unit-selected") throw new Error(`select left cursor ${map.cursorState}`);
    await clickTile(page, approach);
    await waitForScreen(page, "action-menu");
    await clickSuffix(page, "/BtnAttack");
    await clickTile(page, target.tile, { expectState: "targeting" });
    await waitForScreen(page, "attack-preview");
    const preview = await shot(page, `forecast ${attackerId} vs ${targetId}`);
    notes.forecastText = texts(preview, (p) => !p.includes("/HUD/"));

    if (LAND) {
      const before = unitOnMap(await mapState(page), targetId).hp;
      await page.keyboard.press("Enter");
      await waitForScreen(page, "hud");
      await page.waitForFunction(
        (name) => { try { return JSON.parse(window[name]?.state ?? "{}").map?.cursorState === "free"; } catch { return false; } },
        bridge.BRIDGE_GLOBAL, { timeout: 60_000 });
      await settle(page);
      const after = unitOnMap(await mapState(page), targetId).hp;
      notes.hit = { before, after, landed: after < before };
      const after_obs = await shot(page, "after attack");
      notes.hud = texts(after_obs, (p) => /TurnLabel|PhaseLabel/.test(p));
      await openDetails(page, target.tile);
      await shot(page, "revenant details after hit");
      await cycleDetails(page, "revenant-after-hit", 16);
      await closeDetails(page);
    }
    notes.browser = session.log;
  } catch (error) {
    notes.error = error.stack ?? String(error);
    process.exitCode = 1;
    if (session) await session.page.screenshot({ path: path.join(OUT, "failure.png") }).catch(() => {});
  } finally {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    await teardown(session);
  }
  console.log(JSON.stringify({ ...notes, browser: undefined }, null, 2));
}
main();
