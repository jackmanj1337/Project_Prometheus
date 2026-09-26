#!/usr/bin/env node
// Section 2: Campaign Editor via Manage Library -> Edit a Copy, at 1920x1080.
// Exploratory: dumps bridge state + screenshots at each stage so the report can judge
// the Rules wrap/hover, dirty-state, Menu Scale restore, and pack-font behaviour.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge, clickableEntries, clickControl } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickSuffix, importPack, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

async function shot(page, name) {
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  const observed = await bridge.snapshot(page);
  await writeFile(path.join(OUT, `${name}.json`), `${JSON.stringify(observed, null, 2)}\n`);
  return observed;
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
    await shot(page, "00-after-import");

    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    let observed = await shot(page, "01-campaign-library");
    console.log("clickable controls on Campaign Library:", clickableEntries(observed).map(([p]) => p));

    // The OptPackage selector should already default to the just-imported free-roam
    // package (only one installed at this point). Click Edit a Copy directly.
    await clickSuffix(page, "/BtnEditCopy");
    await settle(page);
    observed = await shot(page, "02-after-edit-copy-click");
    console.log("screen:", observed.screen);

    // Give the editor a moment; it may need extra frames to load the working copy.
    await page.waitForTimeout(1000);
    await settle(page);
    observed = await shot(page, "03-editor-settled");
    console.log("rects sample:", Object.keys(observed.rects ?? {}).slice(0, 80));

    // Select the Campaigns collection in the editor's content tree (the tree rows are
    // canvas-backed and not exposed as focusable controls by the bridge).
    await page.mouse.click(80, 156);
    await settle(page);
    observed = await shot(page, "04-campaigns-collection-selected");
    console.log("Campaign record collection rects:", Object.entries(observed.rects ?? {})
      .filter(([p]) => p.includes("/Records/") || p.includes("Inspector"))
      .map(([p, r]) => [p, r.text, r.x, r.y, r.w, r.h]));
    await page.mouse.click(420, 160);
    await settle(page);
    observed = await shot(page, "05-default-campaign-record-selected");
    console.log("Campaign selection:", observed.rects?.["CampaignEditorScreen/Shell/StatusBar/Selection"]?.text);
    await page.mouse.move(1700, 800);
    await page.mouse.wheel(0, 1010);
    await page.waitForTimeout(500);
    await settle(page);
    observed = await shot(page, "05b-inspector-scrolled-to-rules");
    console.log("Rules after inspector scroll:", Object.entries(observed.rects ?? {})
      .filter(([p, r]) => p.includes("Inspector") && /Rules|rule/i.test(r.text ?? ""))
      .map(([p, r]) => [p, r.text?.slice(0, 160), r.x, r.y, r.w, r.h, r.truncation]));
    const displayField = Object.entries(observed.rects ?? {}).find(([p, r]) =>
      p.includes("@LineEdit") && r.text === "The Proving Grounds");
    if (!displayField) throw new Error("could not locate the working-copy Campaign Display Name field");
    await clickControl(page, observed, displayField[0]);
    await page.keyboard.press("Control+A");
    await page.keyboard.type("The Proving Grounds Test");
    await settle(page);
    observed = await shot(page, "06-edited-campaign-display-name");
    await page.keyboard.press("Control+S");
    await settle(page);
    observed = await shot(page, "07-after-save-campaign-display-name");
    console.log("working copy after save:", observed.rects?.["CampaignEditorScreen/Shell/StatusBar/WorkingCopy"]?.text);
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
