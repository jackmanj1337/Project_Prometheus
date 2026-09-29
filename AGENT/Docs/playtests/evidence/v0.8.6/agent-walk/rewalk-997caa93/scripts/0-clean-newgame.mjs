#!/usr/bin/env node
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, openNewGame, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;
await mkdir(OUT, { recursive: true });
let session;
try {
  session = await boot({ url: buildUrl(URL_BASE, {}), viewport: { width: 1280, height: 720 } });
  const page = session.page;
  await waitForScreen(page, "main-menu");
  await openNewGame(page);
  await page.screenshot({ path: path.join(OUT, "new-game-empty.png") });
  const observed = await bridge.snapshot(page);
  await writeFile(path.join(OUT, "new-game-empty.json"), `${JSON.stringify(observed, null, 2)}\n`);
  console.log("newGameEntries:", JSON.stringify(observed.newGameEntries));
} finally {
  await teardown(session);
}
