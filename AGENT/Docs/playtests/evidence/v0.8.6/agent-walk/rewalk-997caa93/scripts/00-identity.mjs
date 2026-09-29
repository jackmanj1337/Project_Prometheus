// Verify build identity: load the web export, confirm BUILD STAMP via bridge/main menu text.
import { chromium } from "../../../tools/playwright/node_modules/playwright/index.mjs";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { settle } from "../../../tools/playwright/lib/harness.mjs";

const OUT = "builds/v086-rewalk-997caa93/0-identity";
import fs from "node:fs";
fs.mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const url = new URL("http://127.0.0.1:8060/index.html");
url.searchParams.set("test_bridge", "1");
url.searchParams.set("bridge_rects", "all");
await page.goto(url.href);
await page.waitForFunction((name) => Boolean(window[name]), bridge.BRIDGE_GLOBAL, { timeout: 30000 });
await settle(page);
await page.waitForTimeout(1500);
await settle(page);

const observed = await bridge.snapshot(page);
fs.writeFileSync(`${OUT}/snapshot.json`, JSON.stringify(observed, null, 2));
await page.screenshot({ path: `${OUT}/main-menu.png` });

// Grab all visible text via rects to find BUILD STAMP / version string
const texts = Object.entries(observed.rects ?? {}).map(([k, v]) => [k, v.text]).filter(([, t]) => t);
fs.writeFileSync(`${OUT}/texts.json`, JSON.stringify(texts, null, 2));
console.log("screen:", observed.screen);
console.log(JSON.stringify(texts, null, 2));

await browser.close();
