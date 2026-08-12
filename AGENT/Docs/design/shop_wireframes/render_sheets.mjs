// Renders one contact sheet per lifecycle state from shop_wireframe_album.html.
//
// The album is the source of truth: every frame is generated from one
// renderDevice(state, viewport, occlusion) function, so a changed ruling is a
// one-line edit that redraws all 113 frames. These PNGs are a convenience for
// reading the album in the repo without a browser.
//
// Usage, from the container (Playwright lives in the container repo's tooling):
//   node AGENT/Docs/design/shop_wireframes/render_sheets.mjs
//
import { chromium } from "/workspace/godot-prometheus-env/tools/playwright/node_modules/playwright/index.mjs";
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const HERE = dirname(fileURLToPath(import.meta.url));
const ALBUM = resolve(HERE, "..", "shop_wireframe_album.html");
const OUT = HERE;

// The album is published as an Artifact, which supplies the html/head/body
// skeleton. Locally we wrap it ourselves.
const body = readFileSync(ALBUM, "utf8");
const work = mkdtempSync(join(tmpdir(), "shop-album-"));
const page_path = join(work, "preview.html");
writeFileSync(page_path,
  `<!doctype html><html><head><meta charset="utf-8">` +
  `<meta name="viewport" content="width=device-width,initial-scale=1">` +
  `<style>*{margin:0;padding:0}</style></head><body>${body}</body></html>`);

mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1720, height: 1200 }, deviceScaleFactor: 1 });
const errors = [];
page.on("pageerror", e => errors.push(String(e.message)));
await page.goto("file://" + page_path);
await page.waitForTimeout(300);

const ids = await page.$$eval(".state", els => els.map(e => e.id));
for (const id of ids) {
  await page.evaluate(sid => {
    document.querySelectorAll(".state").forEach(s => s.setAttribute("hidden", ""));
    document.getElementById(sid).removeAttribute("hidden");
    // Un-stick the lifecycle nav so it cannot overlap the captured band.
    document.querySelector(".lifecycle").style.position = "static";
  }, id);
  await page.waitForTimeout(120);
  const el = await page.$("#" + id);
  await el.screenshot({ path: join(OUT, id.replace("state-", "shop_lifecycle_") + ".png") });
}

console.log(`wrote ${ids.length} sheets to ${OUT}`);
if (errors.length) {
  console.error("page errors:\n" + errors.join("\n"));
  process.exitCode = 1;
}
await browser.close();
