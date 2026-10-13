const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{const browser=await chromium.launch({headless:true,channel:'chrome'});try{
const page=await browser.newPage({viewport:{width:1360,height:900}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('http://localhost:8879/world40_review.html');
assert.equal(await page.locator('#gallery img').count(),23);
await page.locator('img').evaluateAll(async images=>{for(const image of images){image.loading='eager';await image.decode();if(image.naturalWidth<960)throw Error('Invalid capture size')}});
for(const [group,count] of [['forest',6],['ruins',4],['realm',3],['story',4],['systems',6]]){await page.locator(`[data-filter="${group}"]`).click();assert.equal(await page.locator('#gallery figure:visible').count(),count)}
for(const [group,count] of [['all',18],['main',10],['side',8]]){await page.locator(`[data-quests="${group}"]`).click();assert.equal(await page.locator('#quests details:visible').count(),count)}
await page.locator('#quests details:visible summary').first().click();assert.equal(await page.locator('#quests details[open]:visible').count(),1);
for(const width of [960,390]){await page.setViewportSize({width,height:800});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true)}
assert.deepEqual(errors,[]);fs.writeFileSync(path.join(__dirname,'../artifacts/world40_browser.json'),JSON.stringify({passed:true,stills:23,regions:3,gallery_filters:5,quests:18,quest_filters:3,widths:[1360,960,390],page_errors:errors},null,2));console.log('WORLD40_REVIEW: 23 native captures, filters, 18 quest entries, 3 widths, 0 errors');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
