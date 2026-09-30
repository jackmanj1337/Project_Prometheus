#!/usr/bin/env node
// Follow-up item 4: re-execute the Section 2 edit-and-save step on 997caa93 directly
// (Edit a Copy, change one Campaign value, unsaved marker appears, save clears it,
// close editor, Menu Scale restored to what it was before entering).
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge, clickControl } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, importPack, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

let n = 0;
async function shot(page, label) {
  n += 1;
  const stem = `${String(n).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify(observed, null, 2)}\n`);
  console.log(`[${stem}] screen=${observed.screen}`);
  return observed;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const notes = [];
  let session;
  try {
    // First record Menu Scale BEFORE entering the editor, at a known non-default
    // value, so "restored" is a real assertion and not just "still at default".
    session = await boot({ url: buildUrl(URL_BASE, { menu_scale: "1.25", content_scale: "1.0" }), viewport: { width: 1920, height: 1080 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await waitForScreen(page, "main-menu");
    const before = await shot(page, "main-menu-before-editor-menu-scale-1-25");
    notes.push(`Menu Scale before entering editor: ${JSON.stringify(before.scales)}`);

    await importPack(page, PACK);
    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    await shot(page, "campaign-library");

    await clickSuffix(page, "/BtnEditCopy");
    await settle(page);
    await page.waitForTimeout(1000);
    await settle(page);
    const editorObs = await shot(page, "editor-opened");
    notes.push(`Menu Scale inside the editor: ${JSON.stringify(editorObs.scales)}`);

    // Select Campaigns collection, then the default Campaign record (canvas tree rows).
    await page.mouse.click(80, 156);
    await settle(page);
    await page.mouse.click(420, 160);
    await settle(page);
    const selected = await shot(page, "campaign-record-selected");
    console.log("Selection:", selected.rects?.["CampaignEditorScreen/Shell/StatusBar/Selection"]?.text);

    // Find the Display Name field and change it.
    let observed = await bridge.snapshot(page);
    const displayField = Object.entries(observed.rects ?? {}).find(([p, r]) =>
      p.includes("@LineEdit") && typeof r.text === "string" && r.text.length > 0 && !p.includes("Search"));
    if (!displayField) throw new Error("could not locate an editable LineEdit field in the inspector");
    notes.push(`Editing field: ${displayField[0]} (was "${displayField[1].text}")`);
    await clickControl(page, observed, displayField[0]);
    await page.keyboard.press("Control+A");
    await page.keyboard.type("The Proving Grounds Rewalk Test");
    await page.keyboard.press("Enter");
    await settle(page);
    const afterEdit = await shot(page, "after-edit-unsaved-marker");
    const workingCopyTab = Object.entries(afterEdit.rects ?? {}).find(([p]) => p.toLowerCase().includes("workingcopy") || p.toLowerCase().includes("tab"));
    notes.push(`Tab/working-copy indicator after edit (expect an unsaved marker): ${JSON.stringify(workingCopyTab)}`);

    await page.keyboard.press("Control+S");
    await settle(page);
    const afterSave = await shot(page, "after-save-marker-cleared");
    const workingCopyTabAfterSave = Object.entries(afterSave.rects ?? {}).find(([p]) => p.toLowerCase().includes("workingcopy") || p.toLowerCase().includes("tab"));
    notes.push(`Tab/working-copy indicator after Ctrl+S (expect no unsaved marker): ${JSON.stringify(workingCopyTabAfterSave)}`);

    await page.keyboard.press("Escape");
    await settle(page);
    const afterClose = await shot(page, "after-editor-close-menu-scale-restored");
    notes.push(`Screen after Escape: ${afterClose.screen}`);
    notes.push(`Menu Scale after closing the editor (expect back to the pre-editor 1.25x): ${JSON.stringify(afterClose.scales)}`);
    const restored = Math.abs((afterClose.scales?.menu ?? 0) - (before.scales?.menu ?? -1)) < 0.01;
    notes.push(`Menu Scale genuinely restored to its pre-editor value: ${restored}`);
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
