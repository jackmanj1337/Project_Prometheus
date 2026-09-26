#!/usr/bin/env node
// 1A "look different on purpose" #1: at 1280x720/2x, deselecting the unit and moving
// the cursor to an empty corner should restore the full Objectives box.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickSuffixWithScrollFallback, clickTile, importPack,
  mapState, openNewGame, selectCampaign, tilePoint, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { content_scale: "2.0", menu_scale: "2.0" });
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
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
    let cursor;
    let lastError;
    for (const jitter of [0, 2, -2, 4, -4, 8, -8]) {
      try {
        const fresh = await mapState(page);
        const point = tilePoint(fresh, unit.tile);
        await page.mouse.move(point.x + jitter, point.y + jitter);
        await settle(page);
        const checked = await mapState(page);
        if (String(checked.cursorTile) !== String(unit.tile)) throw new Error(`landed on ${checked.cursorTile}`);
        await page.mouse.click(point.x + jitter, point.y + jitter);
        await settle(page);
        cursor = await mapState(page);
        lastError = null;
        break;
      } catch (e) { lastError = e; }
    }
    if (lastError) throw lastError;
    console.log("selected:", cursor.cursorState);
    await page.screenshot({ path: path.join(OUT, "01-selected.png") });
    const selectedObserved = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "01-selected.json"), `${JSON.stringify(selectedObserved, null, 2)}\n`);

    // Deselect (Escape / cancel action), then move the cursor to an empty corner tile
    // far from any unit. The map is 20x11ish; try a bottom-right-ish empty tile a few
    // tiles from any unit -- read from the map block's own tile grid via a large offset.
    await page.keyboard.press("Escape");
    await settle(page);
    const afterEscape = await mapState(page);
    console.log("after Escape:", afterEscape.cursorState);

    // Move mouse to a screen corner (empty of any panel) to move the game cursor there.
    // Use the map's own coordinate system: pick a tile far from the unit's, clamped to
    // a plausible in-bounds corner (map origin/step let us compute an arbitrary tile's
    // pixel position; MapCursor clamps to the visible view when following the mouse).
    // The camera only shows a few tiles at 2x on a 1280x720 window (logical 640x360),
    // so a target several tiles away is off-camera and the cursor silently clamps back
    // to wherever it already was (confirmed: +6/+4 left cursorTile unchanged at [1,3]).
    // Try progressively larger nearby offsets and stop at the first one that actually
    // moves the reported cursorTile away from the unit's own tile.
    const occupied = new Set((map.units ?? []).map((u) => String(u.tile)));
    let afterMove = afterEscape;
    const candidates = [[2, -1], [3, 0], [2, 1], [1, 2], [3, 1], [1, 1], [2, 2]];
    for (const [dx, dy] of candidates) {
      const farTile = [unit.tile[0] + dx, unit.tile[1] + dy];
      if (occupied.has(String(farTile))) { console.log("skip occupied", farTile); continue; }
      const fresh = await mapState(page);
      const point = tilePoint(fresh, farTile);
      await page.mouse.move(point.x, point.y);
      await settle(page);
      afterMove = await mapState(page);
      console.log("tried EMPTY corner tile", farTile, "-> cursorTile", afterMove.cursorTile, afterMove.cursorState);
      if (String(afterMove.cursorTile) === String(farTile)) break;
    }
    await page.screenshot({ path: path.join(OUT, "02-deselected-corner.png") });
    const restoredObserved = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "02-deselected-corner.json"), `${JSON.stringify(restoredObserved, null, 2)}\n`);

    const objBefore = selectedObserved.rects?.ObjectivePanel;
    const objAfter = restoredObserved.rects?.ObjectivePanel;
    console.log("ObjectivePanel while selected:", objBefore);
    console.log("ObjectivePanel after deselect+corner:", objAfter);
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
