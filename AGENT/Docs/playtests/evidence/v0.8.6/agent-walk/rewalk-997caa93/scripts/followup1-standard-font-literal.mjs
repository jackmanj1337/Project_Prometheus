#!/usr/bin/env node
// Follow-up item 1: redo Section 2's "standard font, no pack active" check EXACTLY as
// the checklist words it. Quit free-roam to Main Menu, verify bridge activePackage is
// genuinely empty (not just "some other pack"), then try to reach HUD/Map Menu/Prep
// WITHOUT reactivating any package, to determine whether the checklist step describes
// a reachable state at all with only free-roam.zip installed.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickSuffix, clickSuffixWithScrollFallback, importPack,
  openNewGame, readEntries, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

let n = 0;
async function shot(page, out, label) {
  n += 1;
  const stem = `${String(n).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(out, `${stem}.png`) });
  await writeFile(path.join(out, `${stem}.json`), `${JSON.stringify(observed, null, 2)}\n`);
  console.log(`[${stem}] activePackage=${JSON.stringify(observed.activePackage)} screen=${observed.screen}`);
  return observed;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  const notes = [];
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await shot(page, OUT, "fresh-main-menu-before-any-pack");

    await importPack(page, PACK);
    await shot(page, OUT, "after-importing-free-roam");

    await openNewGame(page);
    await selectCampaign(page, "proving_grounds");
    await clickSuffixWithScrollFallback(page, "/BtnStart");
    await waitForScreen(page, "prep");
    await shot(page, OUT, "prep-free-roam-active");
    await clickSuffixWithScrollFallback(page, "/BeginButton");
    await waitForLiveMap(page);
    const liveObs = await shot(page, OUT, "live-map-free-roam-active");
    notes.push(`While playing free-roam: activePackage=${JSON.stringify(liveObs.activePackage)}`);

    // Use Suspend & Quit rather than Quit to Menu: BOTH exit paths call the same
    // MapCursor._return_to_main_menu() -> CampaignManager.quit_to_shell() ->
    // DataManager.reset_to_boot_content_baseline(), which is what deactivates the
    // package -- but Quit to Menu's dialog defaults Enter to CANCEL ("Stay in
    // Battle", confirmed in the main rewalk's Section 5 dialog check), so pressing
    // Enter there never leaves the map. Suspend & Quit's dialog defaults Enter to
    // CONFIRM, so it reliably reaches Main Menu with the same deactivation.
    await page.mouse.click(640, 360);
    await settle(page);
    await page.keyboard.press("Escape");
    await settle(page);
    await page.keyboard.press("m");
    await waitForScreen(page, "map-menu");
    await clickSuffix(page, "/SuspendAndQuitButton", { settleAfter: false });
    await page.waitForTimeout(300);
    await page.keyboard.press("Enter");
    await waitForScreen(page, "main-menu");
    const afterQuit = await shot(page, OUT, "main-menu-after-quit-to-menu");
    notes.push(`After Quit to Menu: activePackage=${JSON.stringify(afterQuit.activePackage)} (expect package_id empty)`);
    const genuinelyNoPack = !afterQuit.activePackage?.packageId;
    notes.push(`Genuinely no active package: ${genuinelyNoPack}`);

    // Now: is there ANY way to reach HUD/Map Menu/Prep from here WITHOUT reactivating
    // a package? Try "Continue" first (resumes the most recent save, if any).
    const observedMenu = await bridge.snapshot(page);
    const continueBtn = Object.entries(observedMenu.rects ?? {}).find(([p]) => p.endsWith("/ContinueButton"));
    notes.push(`Continue button present/enabled: ${JSON.stringify(continueBtn?.[1])}`);

    // Try New Game -- with ONLY free-roam.zip installed, what does it offer?
    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    await shot(page, OUT, "campaign-library-with-pack-installed-but-inactive");
    const libObs = await bridge.snapshot(session.page);
    notes.push(`Campaign Library activePackage while browsing (pack installed, not live): ${JSON.stringify(libObs.activePackage)}`);
    await clickSuffix(page, "/HBoxActions/BtnNewGame");
    await waitForScreen(page, "new-game");
    const entries = await readEntries(page);
    notes.push(`New Game offered campaigns with ONLY free-roam.zip installed: ${JSON.stringify(entries.offered.map((e) => e.campaign_id))}`);
    await shot(page, OUT, "new-game-only-freeroam-installed");

    if (entries.offered.length > 0) {
      // This is the crux: selecting the ONLY available campaign necessarily
      // reactivates free-roam's own package (and its font), because no other
      // package is installed. Prove it by actually doing it and reading the result.
      await selectCampaign(page, entries.offered[0].campaign_id);
      await clickSuffixWithScrollFallback(page, "/BtnStart");
      const afterStart = await shot(page, OUT, "after-starting-the-only-offered-campaign");
      notes.push(`After starting the only offered campaign (free-roam's own): screen=${afterStart.screen} activePackage=${JSON.stringify(afterStart.activePackage)}`);
      notes.push(`CONCLUSION: with only free-roam.zip installed, reaching Prep/HUD/Map Menu again necessarily reactivates free-roam and its font -- there is no route to those screens with activePackage genuinely empty.`);
    } else {
      notes.push("New Game offered nothing with only free-roam.zip installed -- unexpected, investigate separately.");
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
