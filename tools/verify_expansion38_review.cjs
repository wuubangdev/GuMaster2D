const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const browser = await chromium.launch({headless:true,channel:'chrome'});
 try {
  const page = await browser.newPage({viewport:{width:1360,height:900}});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://localhost:8879/expansion38_review.html');
  const count=await page.locator('img').count();
  assert.equal(count,13);
  await page.locator('img').evaluateAll(async images=>{for(const image of images){image.loading='eager';await image.decode();if(!image.naturalWidth)throw Error('Empty image');}});
  assert.equal(await page.locator('#world').isVisible(),true);
  assert.equal(await page.locator('#fx').isVisible(),false);
  await page.locator('[data-tab="fx"]').click();
  assert.equal(await page.locator('#world').isVisible(),false);
  assert.equal(await page.locator('#fx').isVisible(),true);
  for(const width of [960,390]){
   await page.setViewportSize({width,height:800});
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
  }
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(__dirname,'../artifacts/expansion38_browser.json'),JSON.stringify({passed:true,images:count,tab_switch:true,widths:[1360,960,390],page_errors:errors},null,2));
  console.log('EXPANSION_BROWSER 13 images decoded; tabs/responsive passed; 0 page errors');
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
