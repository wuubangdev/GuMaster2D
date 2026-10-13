const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{const browser=await chromium.launch({headless:true,channel:'chrome'});try{
const page=await browser.newPage({viewport:{width:1360,height:900}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('http://localhost:8879/quests39_review.html');
assert.equal(await page.locator('#gallery img').count(),13);
await page.locator('img').evaluateAll(async images=>{for(const image of images){image.loading='eager';await image.decode();if(!image.naturalWidth)throw Error('Empty image')}});
await page.evaluate(async()=>{for(const src of window.npcFrames){const img=new Image();img.src=src;await img.decode();if(img.naturalWidth!==1280)throw Error('Frame size')}});
await page.locator('[data-tab="motion"]').click();assert.equal(await page.locator('#motion').isVisible(),true);assert.equal(await page.locator('#gallery').isVisible(),false);
await page.locator('#next').click();assert.equal(await page.locator('#frame').textContent(),'02 / 24');
await page.locator('#seek').fill('23');assert.equal(await page.locator('#frame').textContent(),'24 / 24');
await page.locator('#play').click();await page.waitForFunction(()=>document.querySelector('#seek').value!=='23');
await page.locator('#play').click();const frozen=await page.locator('#seek').inputValue();await page.waitForTimeout(400);assert.equal(await page.locator('#seek').inputValue(),frozen);
for(const width of [960,390]){await page.setViewportSize({width,height:800});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true)}
await page.locator('[data-tab="gallery"]').click();assert.equal(await page.locator('#gallery').isVisible(),true);assert.deepEqual(errors,[]);
fs.writeFileSync(path.join(__dirname,'../artifacts/quests39_browser.json'),JSON.stringify({passed:true,stills:13,motion_frames:24,controls:true,widths:[1360,960,390],page_errors:errors},null,2));console.log('QUEST_REVIEW: 13 stills / 24 frames, playback/seek/tabs/responsive passed, 0 errors');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
