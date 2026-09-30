#!/usr/bin/env node
// Clean redo of 1A's 560x900 "2x (1x)" check via the REAL Settings slider (no URL
// params), using the drive method confirmed working in followup2b (click on the
// track to jump near the target, then nudge with single arrow-key presses --
// NOT a blind 20x-ArrowLeft-then-N-ArrowRight sequence, which is what broke the
// earlier attempt).
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;
const WIDTH = 560, HEIGHT = 900;

async function scrollIntoView(page, suffix) {
  let rect;
  for (let i = 0; i < 20; i += 1) {
    const observed = await bridge.snapshot(page);
    const entry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith(suffix));
    rect = entry[1];
    if (rect.y >= 0 && rect.y + rect.h <= HEIGHT) return rect;
    await page.mouse.move(WIDTH / 2, HEIGHT / 2);
    await page.mouse.wheel(0, 200);
    await settle(page);
  }
  return rect;
}

// Step the slider one notch at a time, reading the numeric value back after EACH
// press, choosing ArrowRight or ArrowLeft by comparing to the target -- so this
// works regardless of where the initial click happened to land.
function parseScale(text) {
  const match = /([\d.]+)x/.exec(text ?? "");
  return match ? Number(match[1]) : null;
}
async function stepSliderTo(page, suffix, targetValue, maxSteps = 20) {
  const labelSuffix = suffix.replace("Slider", "Label");
  for (let i = 0; i < maxSteps; i += 1) {
    const observed = await bridge.snapshot(page);
    const labelEntry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith(labelSuffix));
    const text = labelEntry?.[1]?.text ?? "";
    const current = parseScale(text);
    if (current === targetValue) return { reached: true, steps: i, text };
    await page.keyboard.press(current !== null && current < targetValue ? "ArrowRight" : "ArrowLeft");
    await settle(page);
  }
  const observed = await bridge.snapshot(page);
  const labelEntry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith(labelSuffix));
  return { reached: false, steps: maxSteps, text: labelEntry?.[1]?.text ?? "" };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const notes = [];
  let session;
  try {
    session = await boot({ url: buildUrl(URL_BASE, {}), viewport: { width: WIDTH, height: HEIGHT } });
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffix(page, "/SettingsButton");
    await waitForScreen(page, "settings");
    await page.screenshot({ path: path.join(OUT, "00-top.png") });

    const rect = await scrollIntoView(page, "SliderViewportScale");
    await page.screenshot({ path: path.join(OUT, "01-slider-in-view.png") });
    // Click at the MIDDLE of the track (an edge click can miss the control's actual
    // hit area under this theme's decorative end-caps -- confirmed in followup2b,
    // where an edge click left the value unchanged but a middle click reliably
    // focused the slider and jumped its value), then step from wherever that lands.
    await page.mouse.click(rect.x + rect.w / 2, rect.y + rect.h / 2);
    await settle(page);
    const afterMidClick = await bridge.snapshot(page);
    const vpLabelAfterMidClick = Object.entries(afterMidClick.rects ?? {}).find(([p]) => p.endsWith("LabelViewportScale"))?.[1]?.text;
    notes.push(`Click at track MIDDLE: Viewport Scale label = "${vpLabelAfterMidClick}" (focus=${JSON.stringify(afterMidClick.focus)})`);

    const stepped = await stepSliderTo(page, "SliderViewportScale", 2.0, 16);
    notes.push(`Stepped Viewport Scale to 2.0x: ${JSON.stringify(stepped)}`);
    await page.screenshot({ path: path.join(OUT, "02-viewport-at-2x.png") });

    // Same for Menu Scale.
    const rectM = await scrollIntoView(page, "SliderUIScale");
    await page.mouse.click(rectM.x + 4, rectM.y + rectM.h / 2);
    await settle(page);
    const steppedMenu = await stepSliderTo(page, "SliderUIScale", 2.0, 10);
    notes.push(`Stepped Menu Scale to 2.0x: ${JSON.stringify(steppedMenu)}`);

    const finalObserved = await bridge.snapshot(page);
    await page.screenshot({ path: path.join(OUT, "03-both-at-2x.png") });
    await writeFile(path.join(OUT, "03-both-at-2x.json"), `${JSON.stringify(finalObserved, null, 2)}\n`);
    const vpLabel = Object.entries(finalObserved.rects ?? {}).find(([p]) => p.endsWith("LabelViewportScale"))?.[1]?.text;
    const menuLabel = Object.entries(finalObserved.rects ?? {}).find(([p]) => p.endsWith("LabelUIScale"))?.[1]?.text;
    notes.push(`Final labels at 560x900: Viewport Scale = "${vpLabel}", Menu Scale = "${menuLabel}", scales=${JSON.stringify(finalObserved.scales)}`);

    // Resize to 1920x1080 WITHOUT touching either slider.
    await page.setViewportSize({ width: 1920, height: 1080 });
    await settle(page);
    await page.screenshot({ path: path.join(OUT, "04-after-resize-1920x1080.png") });
    const afterResize = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "04-after-resize.json"), `${JSON.stringify(afterResize, null, 2)}\n`);
    const vpLabelAfter = Object.entries(afterResize.rects ?? {}).find(([p]) => p.endsWith("LabelViewportScale"))?.[1]?.text;
    notes.push(`After resizing to 1920x1080 (no slider touch): Viewport Scale = "${vpLabelAfter}", scales=${JSON.stringify(afterResize.scales)}`);
  } catch (error) {
    notes.push(`FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log(notes.join("\n"));
    await teardown(session);
  }
}
main();
