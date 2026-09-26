#!/usr/bin/env node
// Section 1A: 12 live-map font/panel captures across 4 windows x 3 scales, plus the
// three "looks different on purpose" behaviours the v0.8.6 checklist calls out.

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickSuffixWithScrollFallback, importPack, mapState,
  openNewGame, rectsOverlap, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const URL_BASE = process.argv[2];
const PACK = process.argv[3];
const OUT = process.argv[4];

const WINDOWS = [
  { width: 1280, height: 720 },
  { width: 1920, height: 1080 },
  { width: 900, height: 760 },
  { width: 560, height: 900 },
];
const SCALES = ["0.5", "1.0", "2.0"];

const PANEL_PATHS = {
  objectives: "ObjectivePanel",
  unit: "UnitInfoPanel",
  terrain: "TerrainCorner/TerrainInfoPanel",
};

function findPath(rects, suffix) {
  const hit = Object.keys(rects ?? {}).find((p) => p === suffix || p.endsWith(`/${suffix}`));
  return hit ?? null;
}

async function startLiveMap(page, pack) {
  await importPack(page, pack);
  await openNewGame(page);
  await selectCampaign(page, "proving_grounds");
  await clickSuffixWithScrollFallback(page, "/BtnStart");
  await waitForScreen(page, "prep");
  await clickSuffixWithScrollFallback(page, "/BeginButton");
  await waitForLiveMap(page);
}

async function clickTileDirect(page, map, tile) {
  const x = map.origin.x + tile[0] * map.step.x;
  const y = map.origin.y + tile[1] * map.step.y;
  await page.mouse.move(x, y);
  await settle(page);
  await page.mouse.click(x, y);
  await settle(page);
}

function analyzePanels(rects) {
  const found = {};
  for (const [key, suffix] of Object.entries(PANEL_PATHS)) {
    const p = findPath(rects, suffix);
    found[key] = p ? { path: p, rect: rects[p] } : null;
  }
  const visible = Object.entries(found).filter(([, v]) => v && v.rect.w > 0 && v.rect.h > 0);
  const overlaps = [];
  for (let i = 0; i < visible.length; i += 1) {
    for (let j = i + 1; j < visible.length; j += 1) {
      const [nameA, a] = visible[i];
      const [nameB, b] = visible[j];
      if (rectsOverlap(a.rect, b.rect)) overlaps.push(`${nameA} x ${nameB}`);
    }
  }
  return { found, overlaps };
}

async function runOne(caseName, viewport, scale, pack, outRoot) {
  const out = path.join(outRoot, caseName);
  await mkdir(out, { recursive: true });
  const url = buildUrl(URL_BASE, { content_scale: scale, menu_scale: scale });
  let session;
  const record = { case: caseName, viewport, scale, url };
  try {
    session = await boot({ url, viewport });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    await startLiveMap(session.page, pack);
    const map = await mapState(session.page);
    const unit = (map.units ?? [])[0];
    if (!unit) throw new Error("no units on live map");
    await clickTileDirect(session.page, map, unit.tile);
    let observed = await bridge.snapshot(session.page);
    // If the click selected a unit, cursorState should be unit-selected; if it merely
    // moved the cursor without selecting (e.g. wrong faction unit), try once more.
    if (observed.map?.cursorState !== "unit-selected") {
      await clickTileDirect(session.page, observed.map, unit.tile);
      observed = await bridge.snapshot(session.page);
    }
    await session.page.screenshot({ path: path.join(out, "01-live-map-selected.png") });
    const analysis = analyzePanels(observed.rects);
    record.mapLive = (observed.map?.units ?? []).length > 0;
    record.cursorState = observed.map?.cursorState ?? null;
    record.scales = observed.scales;
    record.viewportReported = observed.viewport;
    record.panels = analysis.found;
    record.overlaps = analysis.overlaps;
    await writeFile(path.join(out, "snapshot.json"), `${JSON.stringify(observed, null, 2)}\n`);
    await writeFile(path.join(out, "result.json"), `${JSON.stringify(record, null, 2)}\n`);
    console.log(`[OK] ${caseName}: mapLive=${record.mapLive} scales=${JSON.stringify(record.scales)} overlaps=${JSON.stringify(record.overlaps)}`);
  } catch (error) {
    record.error = error instanceof Error ? error.message : String(error);
    await writeFile(path.join(out, "result.json"), `${JSON.stringify(record, null, 2)}\n`);
    await session?.page?.screenshot({ path: path.join(out, "failure.png") }).catch(() => {});
    console.error(`[FAIL] ${caseName}: ${record.error}`);
  } finally {
    await teardown(session);
  }
  return record;
}

async function main() {
  if (!URL_BASE || !PACK || !OUT) {
    console.error("usage: 1a-live-map.mjs <served-url> <free-roam.zip> <outDir>");
    process.exit(2);
  }
  await mkdir(OUT, { recursive: true });
  const results = [];
  for (const viewport of WINDOWS) {
    for (const scale of SCALES) {
      const caseName = `${viewport.width}x${viewport.height}-${scale}`;
      results.push(await runOne(caseName, viewport, scale, PACK, OUT));
    }
  }
  await writeFile(path.join(OUT, "1a-summary.json"), `${JSON.stringify(results, null, 2)}\n`);
  const failed = results.filter((r) => r.error);
  console.log(`\n${results.length - failed.length}/${results.length} 1A cases captured without a harness error`);
}

main().catch((error) => {
  console.error(error.stack ?? error.message);
  process.exit(1);
});
