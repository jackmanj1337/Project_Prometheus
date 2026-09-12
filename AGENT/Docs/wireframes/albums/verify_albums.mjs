// Verifies that every album in this directory is READABLE OFFLINE, WITH SCRIPTS OFF.
//
// WHY THIS EXISTS. The albums are the reference other agents build UI against, and they
// have failed silently twice in ways that look fine to the author:
//
//   1. A generated album renders BLANK wherever JavaScript does not run — which is where
//      an owner reads it. That is what `bake_album.mjs` fixes, and this asserts the fix
//      actually holds for the committed file rather than for the author's browser.
//   2. A baked album can carry `measuring…` placeholders if the bake ran before layout
//      settled, so a caption promises a measurement it does not have.
//
// It is deliberately MARKUP-AGNOSTIC. Albums share no frame class and no common wrapper —
// `.device`, `figure`, plain `div` and `table` are all in use — so asserting on any of them
// reports false failures on healthy albums. The album-agnostic test is the one `bake_album.mjs`
// already uses for its own safety check: RENDER TWICE, SCRIPTS OFF AND ON, AND COMPARE. A static
// album reads identically both ways. An unbaked generator reads materially shorter with scripts
// off, which is precisely the reader's situation.
//
// Usage, from the container (Playwright lives in the container image):
//   node AGENT/Docs/wireframes/albums/verify_albums.mjs            # every album
//   node AGENT/Docs/wireframes/albums/verify_albums.mjs compendium_album
//
import { chromium } from "/opt/prometheus-web-harness/node_modules/playwright/index.mjs";
import { readFileSync, writeFileSync, mkdtempSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const HERE = dirname(fileURLToPath(import.meta.url));
const names = process.argv.length > 2
	? process.argv.slice(2).map((n) => n.replace(/\.html$/, ""))
	: readdirSync(HERE)
		.filter((f) => f.endsWith(".html") && !f.endsWith(".src.html"))
		.map((f) => f.replace(/\.html$/, ""))
		.sort();

const work = mkdtempSync(join(tmpdir(), "verify-albums-"));
const browser = await chromium.launch();
let failed = 0;

for (const name of names) {
	const src = resolve(HERE, `${name}.html`);
	const page_path = join(work, `${name}.html`);
	// Albums are fragments so they can also publish as Artifacts; wrap to render locally.
	writeFileSync(
		page_path,
		`<!doctype html><html><head><meta charset="utf-8"></head><body>${readFileSync(src, "utf8")}</body></html>`
	);

	const measure = async (js) => {
		const ctx = await browser.newContext({ javaScriptEnabled: js, viewport: { width: 1400, height: 1000 } });
		const page = await ctx.newPage();
		await page.goto("file://" + page_path, { waitUntil: "load" });
		if (js) await page.waitForTimeout(400);
		const r = await page.evaluate(() => {
			const metrics = Array.from(document.querySelectorAll(".metric"));
			return {
				chars: document.body.innerText.trim().length,
				nodes: document.body.querySelectorAll("*").length,
				metricsTotal: metrics.length,
				metricsUnfilled: metrics.filter((e) => /measuring/i.test(e.textContent)).length,
				scripts: document.querySelectorAll("script").length,
			};
		});
		await ctx.close();
		return r;
	};

	const off = await measure(false);
	const on = await measure(true);

	const problems = [];
	if (off.chars < 2000) problems.push(`only ${off.chars} chars of text with scripts off — effectively blank`);
	// The real test: does running scripts materially change the document? If so the committed
	// file is a generator, not a document, and a scriptless reader sees a fraction of it.
	if (on.chars > off.chars * 1.1) {
		problems.push(
			`generates content at load — ${off.chars} chars scripts-off vs ${on.chars} scripts-on ` +
			`(${off.nodes} vs ${on.nodes} nodes). Needs baking.`
		);
	}
	if (off.metricsUnfilled > 0) problems.push(`${off.metricsUnfilled} unfilled 'measuring…' caption(s)`);

	if (problems.length) {
		failed++;
		console.log(`FAIL  ${name}\n        ${problems.join("\n        ")}`);
	} else {
		const measured = off.metricsTotal ? `${off.metricsTotal} measured · ` : "";
		console.log(`PASS  ${name.padEnd(32)} ${measured}${off.chars} chars · ${off.nodes} nodes (static)`);
	}
}

await browser.close();
if (failed) {
	console.error(`\nverify_albums: ${failed} album(s) are not readable with scripts off.`);
	console.error("If the album is generated, re-bake it: node bake_album.mjs <basename>");
	process.exit(1);
}
console.log(`\nverify_albums: PASS — ${names.length} album(s) readable offline with scripts disabled.`);
