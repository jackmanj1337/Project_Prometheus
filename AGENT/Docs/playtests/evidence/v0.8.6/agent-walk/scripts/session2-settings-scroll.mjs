import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import * as bridge from './lib/bridge.mjs';
import { boot, settle, teardown } from './lib/harness.mjs';
import { buildUrl, clickSuffix, waitForScreen } from './lib-common.mjs';
const [, , base, out, scale='2.0'] = process.argv;
await mkdir(out,{recursive:true});
let session;
try {
  session=await boot({url:buildUrl(base,{menu_scale:scale,content_scale:scale}),viewport:{width:560,height:900}});
  const page=session.page;
  await waitForScreen(page,'main-menu');
  await clickSuffix(page,'/SettingsButton');
  await waitForScreen(page,'settings');
  async function capture(name){
    const s=await bridge.snapshot(page);
    await page.screenshot({path:path.join(out,name+'.png')});
    await writeFile(path.join(out,name+'.json'),JSON.stringify(s,null,2)+'\n');
    console.log(name, 'focus',s.focus?.path,'settings controls',Object.entries(s.rects??{}).filter(([p])=>/Settings|Scroll|Slider|Button/.test(p)).map(([p,r])=>[p.split('/').slice(-2).join('/'),Math.round(r.y),Math.round(r.h),r.text]).slice(-20));
  }
  await capture('01-top');
  await page.mouse.move(280,450);
  for(let i=0;i<8;i++){await page.mouse.wheel(0,500);await settle(page);}
  await capture('02-wheel-bottom');
  for(let i=0;i<30;i++){await page.keyboard.press('Tab');await settle(page);}
  await capture('03-tab-bottom');
} finally {await teardown(session);}
