#!/usr/bin/env node
// 1A "look different on purpose" #2: at 900x760 and 560x900, Settings shows
// "2x (1x)" for Viewport Scale after choosing 2x; resizing to 1920x1080 (without
// touching the slider) grows the view to real 2x.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import { buildUrl, chooseOptionButtonByLabel, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT, WIDTH, HEIGHT] = process.argv;

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  try {
    session = await boot({ url, viewport: { width: Number(WIDTH), height: Number(HEIGHT) } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffix(page, "/SettingsButton");
    await waitForScreen(page, "settings");

    // Drive BOTH sliders to 2x via keyboard once focused: click to focus, then press
    // the End key (max) which for a slider stepped at 0.5 with min 0.5 max 4 needs many
    // steps -- easier to use the existing OptionButton helper's Home/Down keys ONLY for
    // true OptionButtons. Viewport/Menu Scale are HSliders, not OptionButtons, so drive
    // them by clicking to focus then pressing Right/Up repeatedly from the minimum, or
    // more directly: click near the right end of the track. We use direct value entry
    // via repeated Right arrow presses from a focused slider (Godot HSlider responds to
    // ui_right / ui_up by step).
    // SliderViewportScale: min 0.5 max 4.0 step 0.5 -> 2.0x is 3 steps up from min.
    // SliderUIScale: an INDEX into MENU_SCALE_LEVELS [0.5,.75,1,1.25,1.5,1.75,2.0],
    // min 0 max 6 step 1 -> 2.0x is index 6, the max (6 steps up from min).
    // (scenes/ui/SettingsScreen.tscn, scripts/autoloads/SettingsManager.gd)
    async function setSlider(suffix, stepsFromMin) {
      const observed = await bridge.snapshot(page);
      const path_ = Object.keys(observed.rects).find((p) => p.endsWith(suffix));
      const rect = observed.rects[path_];
      await page.mouse.click(rect.x + rect.w / 2, rect.y + rect.h / 2);
      await settle(page);
      // Force to min_value regardless of where the click landed on the track (Home is
      // not reliably bound on Godot's Slider), then step up the exact count.
      for (let i = 0; i < 20; i += 1) await page.keyboard.press("ArrowLeft");
      await settle(page);
      for (let i = 0; i < stepsFromMin; i += 1) {
        await page.keyboard.press("ArrowRight");
        await settle(page);
      }
    }
    await setSlider("SliderViewportScale", 3);
    await setSlider("SliderUIScale", 6);
    await page.screenshot({ path: path.join(OUT, `01-settings-${WIDTH}x${HEIGHT}-after-2x.png`) });
    let observed = await bridge.snapshot(page);
    const vpLabel = Object.entries(observed.rects).find(([p]) => p.endsWith("LabelViewportScale"))?.[1];
    const menuLabel = Object.entries(observed.rects).find(([p]) => p.endsWith("LabelUIScale"))?.[1];
    console.log("Viewport Scale label:", JSON.stringify(vpLabel?.text));
    console.log("Menu Scale label:", JSON.stringify(menuLabel?.text));
    await writeFile(path.join(OUT, "after-2x.json"), `${JSON.stringify(observed, null, 2)}\n`);

    // Now resize the window to 1920x1080 WITHOUT touching the slider.
    await page.setViewportSize({ width: 1920, height: 1080 });
    await settle(page);
    await page.screenshot({ path: path.join(OUT, "02-after-resize-1920x1080.png") });
    observed = await bridge.snapshot(page);
    const vpLabelAfter = Object.entries(observed.rects).find(([p]) => p.endsWith("LabelViewportScale"))?.[1];
    console.log("Viewport Scale label after resize to 1920x1080:", JSON.stringify(vpLabelAfter?.text));
    console.log("scales after resize:", JSON.stringify(observed.scales));
    await writeFile(path.join(OUT, "after-resize.json"), `${JSON.stringify(observed, null, 2)}\n`);
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
