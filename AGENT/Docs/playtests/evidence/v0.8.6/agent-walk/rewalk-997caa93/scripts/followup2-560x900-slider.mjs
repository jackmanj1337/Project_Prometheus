#!/usr/bin/env node
// Follow-up item 2: drive the REAL Viewport Scale slider at 560x900 (not URL params).
// Scroll the Settings list so the slider is actually inside the visible viewport
// before clicking it (the previous attempt clicked at its raw rect.y, which was
// below the fold at this window size and so never reached the canvas), then also
// try a pure keyboard path (Tab-focus + arrow keys) as a second, independent method.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;
const WIDTH = 560, HEIGHT = 900;

async function scrollUntilVisible(page, suffix, maxAttempts = 20) {
  for (let i = 0; i < maxAttempts; i += 1) {
    const observed = await bridge.snapshot(page);
    const entry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith(suffix));
    if (!entry) throw new Error(`${suffix} not published`);
    const [, rect] = entry;
    const viewport = page.viewportSize();
    const visible = rect.y >= 0 && rect.y + rect.h <= viewport.height;
    if (visible) return rect;
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    await page.mouse.wheel(0, rect.y + rect.h > viewport.height ? 200 : -200);
    await settle(page);
  }
  throw new Error(`${suffix} never scrolled into view after ${maxAttempts} attempts`);
}

async function readLabels(page) {
  const observed = await bridge.snapshot(page);
  const vp = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("LabelViewportScale"))?.[1]?.text;
  const menu = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("LabelUIScale"))?.[1]?.text;
  return { vp, menu, scales: observed.scales };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  const notes = [];
  let session;
  try {
    session = await boot({ url, viewport: { width: WIDTH, height: HEIGHT } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffix(page, "/SettingsButton");
    await waitForScreen(page, "settings");
    await page.screenshot({ path: path.join(OUT, "00-settings-top.png") });

    // ---- Method A: mouse click on the slider, scrolled into view first ----
    const rectA = await scrollUntilVisible(page, "SliderViewportScale");
    await page.screenshot({ path: path.join(OUT, "01-viewport-slider-scrolled-into-view.png") });
    notes.push(`SliderViewportScale rect once scrolled into view: ${JSON.stringify(rectA)}`);
    await page.mouse.click(rectA.x + rectA.w / 2, rectA.y + rectA.h / 2);
    await settle(page);
    for (let i = 0; i < 20; i += 1) { await page.keyboard.press("ArrowLeft"); await settle(page); } // force to min
    for (let i = 0; i < 3; i += 1) { await page.keyboard.press("ArrowRight"); await settle(page); } // 3 steps = 2.0x
    const afterMouseVP = await readLabels(page);
    notes.push(`After mouse-click + arrow keys on Viewport Scale slider: ${JSON.stringify(afterMouseVP)}`);
    await page.screenshot({ path: path.join(OUT, "02-after-mouse-drive-viewport-2x.png") });

    // Also drive Menu Scale the same way (scroll, click, keys) for a full "both at 2x".
    const rectB = await scrollUntilVisible(page, "SliderUIScale");
    await page.mouse.click(rectB.x + rectB.w / 2, rectB.y + rectB.h / 2);
    await settle(page);
    for (let i = 0; i < 20; i += 1) { await page.keyboard.press("ArrowLeft"); await settle(page); }
    for (let i = 0; i < 6; i += 1) { await page.keyboard.press("ArrowRight"); await settle(page); } // index 6 = 2.0x
    const afterBoth = await readLabels(page);
    notes.push(`After driving BOTH sliders to 2x via mouse+keys: ${JSON.stringify(afterBoth)}`);
    await page.screenshot({ path: path.join(OUT, "03-after-both-sliders-2x.png") });
    await writeFile(path.join(OUT, "after-both-2x.json"), `${JSON.stringify(await bridge.snapshot(page), null, 2)}\n`);

    const methodAWorked = afterBoth.vp?.includes("2.0x") || afterBoth.vp?.includes("2x");
    notes.push(`Method A (mouse click, scrolled into view, then arrow keys) worked: ${methodAWorked}`);

    // ---- Resize to 1920x1080 WITHOUT touching the slider ----
    await page.setViewportSize({ width: 1920, height: 1080 });
    await settle(page);
    await page.screenshot({ path: path.join(OUT, "04-after-resize-1920x1080.png") });
    const afterResize = await readLabels(page);
    notes.push(`After resizing to 1920x1080 (no slider touch): ${JSON.stringify(afterResize)}`);
    await writeFile(path.join(OUT, "after-resize.json"), `${JSON.stringify(await bridge.snapshot(page), null, 2)}\n`);

    // ---- Method B (independent confirmation): pure keyboard from a FRESH session,
    // Tab-focus the slider (no mouse at all), then arrow keys. ----
    await teardown(session);
    session = await boot({ url, viewport: { width: WIDTH, height: HEIGHT } });
    const page2 = session.page;
    await waitForScreen(page2, "main-menu");
    await clickSuffix(page2, "/SettingsButton");
    await waitForScreen(page2, "settings");
    let focusedOnSlider = false;
    for (let i = 0; i < 60; i += 1) {
      await page2.keyboard.press("Tab");
      await settle(page2);
      const observed = await bridge.snapshot(page2);
      if ((observed.focus?.path ?? "").endsWith("SliderViewportScale")) { focusedOnSlider = true; break; }
    }
    notes.push(`Method B: pure keyboard Tab-focus reached SliderViewportScale: ${focusedOnSlider}`);
    if (focusedOnSlider) {
      for (let i = 0; i < 20; i += 1) { await page2.keyboard.press("ArrowLeft"); await settle(page2); }
      for (let i = 0; i < 3; i += 1) { await page2.keyboard.press("ArrowRight"); await settle(page2); }
      const kbResult = await readLabels(page2);
      notes.push(`Method B result (pure keyboard, no mouse): ${JSON.stringify(kbResult)}`);
      await page2.screenshot({ path: path.join(OUT, "05-method-b-pure-keyboard.png") });
    }
  } catch (error) {
    notes.push(`FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log("\n" + notes.join("\n"));
    await teardown(session);
  }
}
main();
