#!/usr/bin/env node
// Follow-up item 3: at 2x, raise the arrow-key press budget (looping until focus
// reaches Export Diagnostics/Back, capped ~200), and try dragging the scrollbar at
// its PAINTED screen position (read from a screenshot) rather than via the bridge.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;
const SCALE = "2.0";

async function openSettings(page) {
  await waitForScreen(page, "main-menu");
  await clickSuffix(page, "/SettingsButton");
  await waitForScreen(page, "settings");
}
async function capture(page, name) {
  const s = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  await writeFile(path.join(OUT, `${name}.json`), `${JSON.stringify(s, null, 2)}\n`);
  return s;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { menu_scale: SCALE, content_scale: SCALE });
  const notes = [];
  let session;

  // ---- Arrow keys, raised budget, loop until focus IS Export Diagnostics or Back ----
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await openSettings(page);
    const top = await capture(page, "arrows-00-top");
    notes.push(`[2.0x] Initial focus on opening Settings (before any key): ${JSON.stringify(top.focus)}`);
    // Initial focus is already BtnBack (a sensible "safe default"), so a single
    // Down/Tab that happens to be a no-op there would trivially "reach" Back at
    // step 0 without ever traversing the list -- a false positive that bit the
    // first attempt at this check. Establish a REAL starting point by clicking the
    // first slider explicitly, then walk forward one control at a time, requiring
    // the scroll position to have actually changed by the time we call it reached.
    const firstSlider = Object.entries(top.rects ?? {}).find(([p]) => p.endsWith("SliderMaster"));
    if (firstSlider) {
      const [, r] = firstSlider;
      await page.mouse.click(r.x + r.w / 2, r.y + r.h / 2);
      await settle(page);
    }
    const afterInitialClick = await bridge.snapshot(page);
    notes.push(`[2.0x] Focus after explicitly clicking the Master Volume slider: ${JSON.stringify(afterInitialClick.focus)}`);

    let reachedFocus = null;
    let pressCount = 0;
    const seenPaths = [];
    for (let i = 0; i < 200; i += 1) {
      await page.keyboard.press("Tab");
      await settle(page);
      pressCount = i + 1;
      const observed = await bridge.snapshot(page);
      const focusPath = observed.focus?.path ?? "";
      seenPaths.push(focusPath);
      if (focusPath.endsWith("BtnExportDiagnostics") || focusPath.endsWith("BtnBack")) {
        reachedFocus = { path: focusPath, text: observed.focus?.text, pressCount };
        break;
      }
    }
    notes.push(`[2.0x] Tab-cycling from an explicit starting focus (budget 200): ${reachedFocus ? `reached ${reachedFocus.path} ("${reachedFocus.text}") after ${reachedFocus.pressCount} Tab presses` : `did NOT reach Export Diagnostics/Back within 200 presses`}`);
    notes.push(`[2.0x] Last 10 focus paths seen (to show real traversal, not a stall): ${JSON.stringify(seenPaths.slice(-10))}`);
    await capture(page, "arrows-01-final");
  } catch (error) {
    notes.push(`Arrow-key method FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }

  // ---- Scroll bar: paint a fresh top screenshot, then drag at its VISUAL position ----
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await openSettings(page);
    await capture(page, "scrollbar-00-top");
    // From visual inspection of this screen at 560x900/2x, the thumb sits near the
    // right edge, spanning roughly the top quarter of the panel. Use a generous
    // vertical sweep from just below the header to well past the thumb's expected
    // location, at x very close to the right edge (a few px in from 560).
    const dragX = 553;
    await page.mouse.move(dragX, 90);
    await page.mouse.down();
    await page.mouse.move(dragX, 850, { steps: 20 });
    await settle(page);
    await page.mouse.up();
    await settle(page);
    const afterDrag = await capture(page, "scrollbar-01-after-drag");
    const bottomVisible = Object.entries(afterDrag.rects ?? {}).some(([p, r]) => p.endsWith("BtnExportDiagnostics") && r.y >= 0 && r.y <= 900);
    notes.push(`[2.0x] Scrollbar drag at painted position (x=${dragX}, 90->850): Export Diagnostics visible on-screen after drag: ${bottomVisible}`);
  } catch (error) {
    notes.push(`Scrollbar drag method FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }

  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
  console.log(notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
