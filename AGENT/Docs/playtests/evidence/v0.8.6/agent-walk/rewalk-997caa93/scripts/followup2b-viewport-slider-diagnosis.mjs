#!/usr/bin/env node
// Diagnose: does clicking + arrow-keying the Viewport Scale slider work at 1280x720
// (no scroll needed) but not at 560x900 (needs scroll first)? Read bridge.focus
// immediately after the click, before any keys, at both sizes, for a clean compare.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;

async function driveOne(width, height, label) {
  const notes = [];
  let session;
  try {
    session = await boot({ url: buildUrl(URL_BASE, {}), viewport: { width, height } });
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffix(page, "/SettingsButton");
    await waitForScreen(page, "settings");

    // Scroll (if needed) until the slider is inside the viewport.
    let rect;
    for (let i = 0; i < 20; i += 1) {
      const observed = await bridge.snapshot(page);
      const entry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("SliderViewportScale"));
      rect = entry[1];
      if (rect.y >= 0 && rect.y + rect.h <= height) break;
      await page.mouse.move(width / 2, height / 2);
      await page.mouse.wheel(0, 200);
      await settle(page);
    }
    notes.push(`[${label}] slider rect once in view: ${JSON.stringify(rect)}`);
    await page.screenshot({ path: path.join(OUT, `${label}-00-before-click.png`) });

    // Click dead center of the track.
    const clickX = rect.x + rect.w / 2, clickY = rect.y + rect.h / 2;
    await page.mouse.click(clickX, clickY);
    await settle(page);
    let observed = await bridge.snapshot(page);
    notes.push(`[${label}] focus immediately after click at (${clickX},${clickY}): ${JSON.stringify(observed.focus)}`);
    notes.push(`[${label}] value immediately after click (a mid-track click should jump the value): ${JSON.stringify(observed.scales)}`);
    await page.screenshot({ path: path.join(OUT, `${label}-01-after-click.png`) });

    // Press ArrowRight once and see if the value moves AT ALL (regardless of focus target).
    await page.keyboard.press("ArrowRight");
    await settle(page);
    observed = await bridge.snapshot(page);
    notes.push(`[${label}] value after ONE ArrowRight: ${JSON.stringify(observed.scales)} focus=${JSON.stringify(observed.focus)}`);
    await page.screenshot({ path: path.join(OUT, `${label}-02-after-one-arrowright.png`) });

    // Now try clicking nearer the RIGHT end of the track directly (should jump close to max).
    const rightClickX = rect.x + rect.w * 0.9;
    await page.mouse.click(rightClickX, clickY);
    await settle(page);
    observed = await bridge.snapshot(page);
    notes.push(`[${label}] value after clicking near the right end of the track (x=${rightClickX}): ${JSON.stringify(observed.scales)} focus=${JSON.stringify(observed.focus)}`);
    await page.screenshot({ path: path.join(OUT, `${label}-03-after-right-end-click.png`) });

    // Drag the handle itself from wherever it now is to the far right.
    const observed2 = await bridge.snapshot(page);
    const rect2 = Object.entries(observed2.rects ?? {}).find(([p]) => p.endsWith("SliderViewportScale"))[1];
    await page.mouse.move(rect2.x + rect2.w / 2, rect2.y + rect2.h / 2);
    await page.mouse.down();
    await page.mouse.move(rect2.x + rect2.w - 2, rect2.y + rect2.h / 2, { steps: 10 });
    await page.mouse.up();
    await settle(page);
    observed = await bridge.snapshot(page);
    notes.push(`[${label}] value after DRAGGING the handle to the track's right end: ${JSON.stringify(observed.scales)}`);
    await page.screenshot({ path: path.join(OUT, `${label}-04-after-drag-to-end.png`) });
  } catch (error) {
    notes.push(`[${label}] FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }
  return notes;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const allNotes = [];
  allNotes.push(...await driveOne(1280, 720, "1280x720"));
  allNotes.push(...await driveOne(560, 900, "560x900"));
  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(allNotes, null, 2)}\n`);
  console.log(allNotes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
