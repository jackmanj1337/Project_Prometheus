import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import * as bridge from './lib/bridge.mjs';
import { boot, settle, teardown } from './lib/harness.mjs';
import { buildUrl, clickSuffixWithScrollFallback, importPack, openNewGame, selectCampaign, waitForLiveMap, waitForScreen } from './lib-common.mjs';
const [, , base, pack, out]=process.argv;
await mkdir(out,{recursive:true});
let session;
try {
 session=await boot({url:buildUrl(base,{content_scale:'1.0',menu_scale:'1.0'}),viewport:{width:1280,height:720}});
 const page=session.page;
 async function cap(name){const s=await bridge.snapshot(page);await page.screenshot({path:path.join(out,name+'.png')});await writeFile(path.join(out,name+'.json'),JSON.stringify(s,null,2)+'\n');console.log(name,s.screen,s.focus?.path,s.scales);}
 await importPack(page,pack);
 await openNewGame(page);await selectCampaign(page,'proving_grounds');await clickSuffixWithScrollFallback(page,'/BtnStart');await waitForScreen(page,'prep');await cap('01-prep');
 await clickSuffixWithScrollFallback(page,'/BeginButton');await waitForLiveMap(page);await cap('02-hud');
 await page.keyboard.press('m');await waitForScreen(page,'map-menu');await cap('03-map-menu');
 await clickSuffixWithScrollFallback(page,'/SettingsButton');await settle(page);await cap('04-settings');
}finally{await teardown(session);}
