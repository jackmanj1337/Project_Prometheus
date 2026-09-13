// Bakes a JS-generated album into a static, script-free album.
//
// WHY THIS EXISTS. The distribution-surface albums generate every frame from one
// render function, which is what keeps 71 frames consistent with one ruling change.
// But a generated page is blank anywhere JavaScript does not run — a sandboxed
// preview pane, a docs viewer, an email client, a reviewer with scripts disabled.
// The frames are plain HTML and CSS, so the fix is to render once and write the
// resulting markup out: the reader gets a static document, and the author keeps the
// generator.
//
// The `.src.html` file is the SOURCE OF TRUTH. Edit it, then re-bake. Never hand-edit
// the baked album — it is overwritten.
//
// The measurement captions are baked with their computed values, so the numbers in
// the static file are the ones the layout actually produced.
//
// Usage, from the container (Playwright lives in the container image):
//   node AGENT/Docs/wireframes/albums/bake_album.mjs distribution_surface_album
//   node AGENT/Docs/wireframes/albums/bake_album.mjs distribution_surface_proof_set
//
import { chromium } from "/opt/prometheus-web-harness/node_modules/playwright/index.mjs";
import { readFileSync, writeFileSync, mkdtempSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const HERE = dirname(fileURLToPath(import.meta.url));
const name = process.argv[2];
if (!name) {
	console.error("usage: node bake_album.mjs <album-basename>");
	process.exit(2);
}
const SRC = resolve(HERE, `${name}.src.html`);
const OUT = resolve(HERE, `${name}.html`);

// The album is a fragment (no <html>/<body>) so it can also be published as an
// Artifact, which supplies the skeleton. Wrap it only to render it here.
const work = mkdtempSync(join(tmpdir(), "bake-album-"));
const page_path = join(work, "preview.html");
writeFileSync(page_path, `<!doctype html><html><head></head><body>${readFileSync(SRC, "utf8")}</body></html>`);

const browser = await chromium.launch();

// Baseline: what the file shows with scripts OFF. This is the reader's situation and
// the thing the bake has to improve on. Comparing against it is album-agnostic —
// albums do not share a frame class, so counting one would only work for our own.
const staticCtx = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 1400, height: 1000 } });
const staticPage = await staticCtx.newPage();
await staticPage.goto("file://" + page_path, { waitUntil: "load" });
const baseline = (await staticPage.evaluate(() => document.body.innerHTML.trim().length));
await staticCtx.close();

const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
await page.goto("file://" + page_path, { waitUntil: "load" });
await page.waitForTimeout(400);

const frames = await page.evaluate(() => document.querySelectorAll(".device,.frame,figure").length);
const baked = await page.evaluate(() => {
	// Drop the generator itself: the markup it produced is now the document.
	document.querySelectorAll("script").forEach((s) => s.remove());
	return { head: document.head.innerHTML.trim(), body: document.body.innerHTML.trim() };
});
await browser.close();

if (errors.length) {
	console.error("page errors:\n  " + errors.join("\n  "));
	process.exit(1);
}
if (baked.body.length <= baseline) {
	console.error(
		`the rendered document is no larger than the script-less one ` +
		`(${baked.body.length} vs ${baseline} chars) — nothing was generated, refusing to bake`
	);
	process.exit(1);
}

const banner =
	`<!-- GENERATED FILE — do not edit.\n` +
	`     Baked from ${name}.src.html, which is the source of truth.\n` +
	`     Regenerate: node AGENT/Docs/wireframes/albums/bake_album.mjs ${name} -->\n`;

writeFileSync(OUT, banner + baked.head + "\n" + baked.body + "\n");
console.log(`baked ${frames} frame element(s) → ${OUT}` +
	`  [static body ${baseline} → ${baked.body.length} chars]`);
