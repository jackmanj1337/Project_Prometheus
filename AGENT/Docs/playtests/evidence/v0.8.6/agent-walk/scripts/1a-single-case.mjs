#!/usr/bin/env node
// Re-run ONE 1A case with verified tile-cursor arrival (clickTile asserts the cursor
// actually reached the tile before clicking; the main sweep's clickTileDirect did not,
// which is how 1280x720/2x captured a selection that silently missed the unit).
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickSuffixWithScrollFallback, clickTile, hoverTile, importPack,
  mapState, openNewGame, rectsOverlap, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT, WIDTH, HEIGHT, SCALE] = process.argv;
const PANEL_PATHS = { objectives: "ObjectivePanel", unit: "UnitInfoPanel", terrain: "TerrainCorner/TerrainInfoPanel" };
function findPath(rects, suffix) {
  return Object.keys(rects ?? {}).find((p) => p === suffix || p.endsWith(`/${suffix}`)) ?? null;
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
      if (rectsOverlap(visible[i][1].rect, visible[j][1].rect)) overlaps.push(`${visible[i][0]} x ${visible[j][0]}`);
    }
  }
  return { found, overlaps };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const viewport = { width: Number(WIDTH), height: Number(HEIGHT) };
  const url = buildUrl(URL_BASE, { content_scale: SCALE, menu_scale: SCALE });
  let session;
  try {
    session = await boot({ url, viewport });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await importPack(page, PACK);
    await openNewGame(page);
    await selectCampaign(page, "proving_grounds");
    await clickSuffixWithScrollFallback(page, "/BtnStart");
    await waitForScreen(page, "prep");
    await clickSuffixWithScrollFallback(page, "/BeginButton");
    await waitForLiveMap(page);
    const map = await mapState(page);
    const unit = (map.units ?? [])[0];
    console.log("unit", unit, "map.origin/step", map.origin, map.step, "cursorTile", map.cursorTile);
    let cursor;
    try {
      cursor = await clickTile(page, unit.tile);
    } catch (e) {
      console.log("clickTile threw:", e.message);
      // Camera may not be centred on this tile yet; try hovering first (which itself
      // throws with a helpful message naming where the cursor actually landed).
      try { await hoverTile(page, unit.tile); } catch (e2) { console.log("hoverTile:", e2.message); }
      cursor = await mapState(page);
    }
    console.log("cursorState after click:", cursor.cursorState);
    if (cursor.cursorState !== "unit-selected") {
      // Fallback: Tab cycles unit selection on many screens in this codebase.
      for (let i = 0; i < 6; i += 1) {
        await page.keyboard.press("Tab");
        await page.waitForTimeout(200);
      }
      cursor = await mapState(page);
      console.log("cursorState after Tab fallback:", cursor.cursorState);
    }
    await page.screenshot({ path: path.join(OUT, "01-live-map-selected.png") });
    const observed = await bridge.snapshot(page);
    const analysis = analyzePanels(observed.rects);
    await writeFile(path.join(OUT, "snapshot.json"), `${JSON.stringify(observed, null, 2)}\n`);
    console.log("panels:", JSON.stringify(analysis.found, null, 2));
    console.log("overlaps:", analysis.overlaps);
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
