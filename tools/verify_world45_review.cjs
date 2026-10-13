const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{const browser=await chromium.launch({headless:true,channel:'chrome'});try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://localhost:8879/world45_review.html');
 const count=await page.locator('#gallery img').count();assert.ok(count>=18);
 await page.locator('#gallery img').evaluateAll(async images=>{for(const image of images){image.loading='eager';await image.decode();if(image.naturalWidth<800)throw Error('Small or missing Godot capture '+image.src)}});
 const groups={};
 for(const group of ['maps','beasts','gu','all']){
  await page.locator(`[data-filter="${group}"]`).click();
  const visible=await page.locator('#gallery figure:visible').count();assert.ok(visible>0);groups[group]=visible;
  assert.equal(await page.locator(`[data-filter="${group}"]`).getAttribute('aria-pressed'),'true');
 }
 await page.screenshot({path:path.join(__dirname,'../artifacts/world45_browser.png'),fullPage:false});
 for(const width of [960,390]){await page.setViewportSize({width,height:800});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true)}
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(__dirname,'../artifacts/world45_browser.json'),JSON.stringify({passed:true,captures:count,filters:groups,widths:[1440,960,390],page_errors:errors},null,2));
 console.log('WORLD45_BROWSER',count,'captures;4filters;3widths;0errors');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
