#!/usr/bin/env node
// Gap 3: Rules field full value on hover, Section 2. Try REAL mouse trajectories
// (multi-step moves) into the Rules readonly Label, then wait at several intervals
// and screenshot each, to determine whether Godot's built-in tooltip (TooltipPanel)
// ever appears in headless Chromium. The bridge cannot see it (it is not a child of
// the active screen node — see WebTestBridge._active_screen()/_relative_path), so
// screenshots are the only evidence.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge, clickControl } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, importPack, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

async function shot(page, name) {
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  try {
    session = await boot({ url, viewport: { width: 1920, height: 1080 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await importPack(page, PACK);
    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    await clickSuffix(page, "/BtnEditCopy");
    await settle(page);
    await page.waitForTimeout(1000);
    await settle(page);

    // Select Campaigns collection, then the default Campaign record (canvas tree rows).
    await page.mouse.click(80, 156);
    await settle(page);
    await page.mouse.click(420, 160);
    await settle(page);

    // Scroll the inspector to the Rules field.
    await page.mouse.move(1700, 800);
    await page.mouse.wheel(0, 1010);
    await page.waitForTimeout(500);
    await settle(page);
    let observed = await bridge.snapshot(page);
    const rulesField = Object.entries(observed.rects ?? {}).find(
      ([p, r]) => p.includes("Inspector") && /Rules/i.test(r.text ?? "") || p.endsWith("/@Label@2109"),
    );
    if (!rulesField) throw new Error("Rules field not visible in editor snapshot after scroll");
    const [rulesPath, rulesRect] = rulesField;
    await writeFile(path.join(OUT, "rules-field-rect.json"), `${JSON.stringify({ path: rulesPath, rect: rulesRect }, null, 2)}\n`);
    console.log("Rules field:", rulesPath, rulesRect);

    const targetX = rulesRect.x + rulesRect.w / 2;
    const targetY = rulesRect.y + rulesRect.h / 2;

    // Start well outside the control, then move in with many intermediate steps so the
    // engine sees a real trajectory of mousemotion events crossing into the control
    // (a single teleport-style page.mouse.move can skip the NOTIFICATION_MOUSE_ENTER
    // the tooltip system relies on in some Godot builds).
    await page.mouse.move(targetX - 400, targetY - 200);
    await settle(page);
    await page.mouse.move(targetX, targetY, { steps: 40 });
    await settle(page);
    await shot(page, "hover-000ms-on-enter");

    const waits = [300, 500, 1000, 2000, 3000, 5000];
    let elapsed = 0;
    for (const w of waits) {
      await page.waitForTimeout(w);
      elapsed += w;
      // Tiny jiggle within the control (a few px) to emulate a real, imperfectly-still
      // hand, in case Godot's tooltip timer requires periodic confirmation the mouse is
      // still over the SAME control rather than a single static position.
      await page.mouse.move(targetX + 1, targetY + 1, { steps: 3 });
      await page.mouse.move(targetX, targetY, { steps: 3 });
      await settle(page);
      await shot(page, `hover-${elapsed}ms`);
    }

    // Full-page screenshot plus a viewport-wide search of the DOM/canvas is not possible
    // (canvas-rendered), so also capture a cropped region around the Rules field at max
    // wait for closer visual inspection.
    await page.screenshot({ path: path.join(OUT, "hover-final-full.png") });

    // Record final bridge state too, in case scrolling or hover shifted the screen.
    observed = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "final-snapshot.json"), `${JSON.stringify(observed, null, 2)}\n`);

    console.log("DONE. Inspect hover-*.png by eye for a tooltip popup.");
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
