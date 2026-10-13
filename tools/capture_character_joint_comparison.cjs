const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});try{
 const page=await browser.newPage({viewport:{width:1440,height:1050}});
 await page.goto('http://localhost:8879/concept44_character_review.html',{waitUntil:'networkidle'});
 await page.selectOption('#pose','5');await page.selectOption('#direction','0');
 await page.waitForFunction(()=>['before','focus'].every(id=>{const i=document.getElementById(id);return i.complete&&i.naturalWidth===2560}));
 await page.locator('.note').evaluate(el=>el.hidden=true);
 await page.locator('.compare').evaluate(el=>el.style.width='662px');
 await page.locator('.compare').screenshot({path:'D:/freelance/gumaster2d/artifacts/concept44_before_after.png'});
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
