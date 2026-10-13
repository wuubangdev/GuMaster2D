const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1440,height:1000}});const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
 const url='http://localhost:8879/concept41_character_review.html';await page.goto(url);await page.waitForFunction(()=>document.getElementById('full').complete&&document.getElementById('full').naturalWidth===1600);
 const rows=[];
 for(const action of ['idle','walk','run','attack','defend','cast','channel','hit','dash','death']){
  await page.selectOption('#action',action);
  for(const weapon of action==='attack'?['sword','spear','unarmed']:['sword']){
   if(action==='attack')await page.selectOption('#weapon',weapon);
   for(const bones of action==='idle'?['0']:['0','1']){
    if(action!=='idle')await page.selectOption('#bones',bones);
    await page.selectOption('#body','1');await page.selectOption('#direction','4');
    await page.waitForFunction(()=>document.getElementById('full').complete&&document.getElementById('full').naturalWidth===1600);
    rows.push({action,weapon,bones,url:await page.locator('#full').getAttribute('src')});
   }
  }
 }
 await page.selectOption('#action','attack');await page.selectOption('#weapon','sword');await page.selectOption('#bones','0');await page.selectOption('#body','0');await page.selectOption('#direction','4');await page.locator('#slider').fill('12');await page.locator('#slider').dispatchEvent('input');await page.waitForFunction(()=>document.getElementById('full').complete);
 await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/concept41_browser.png',fullPage:true});
 const before=await page.locator('#count').textContent();await page.click('#next');if(await page.locator('#count').textContent()===before)throw Error('Frame step failed');
 await page.click('#play');await page.waitForTimeout(500);await page.click('#play');
 await page.setViewportSize({width:390,height:844});if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error('Mobile horizontal overflow');await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/concept41_browser_mobile.png',fullPage:true});
 for(const body of ['male','female']){
  await page.setViewportSize({width:1600,height:1400});await page.goto('http://localhost:8879/concept41_assets_'+body+'.html');await page.waitForFunction(()=>Array.from(document.images).every(i=>i.complete&&i.naturalWidth));
  if(await page.locator('img').count()!==176)throw Error('Asset count');
  await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/concept41_assets_'+body+'.png',fullPage:true});
 }
 fs.writeFileSync('D:/freelance/gumaster2d/artifacts/concept41_browser.json',JSON.stringify({passed:errors.length===0,errors,cases:rows,mobile:390,authoringAssets:352},null,2));await browser.close();if(errors.length)throw Error(errors.join('\n'));console.log('Browser review passed: '+rows.length+' states, 352 SVG assets, desktop + mobile');
})().catch(e=>{console.error(e);process.exit(1)});
