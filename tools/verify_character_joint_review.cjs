const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});try{
 const page=await browser.newPage({viewport:{width:1440,height:1050}}),errors=[],checks=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
 await page.goto('http://localhost:8879/concept44_character_review.html',{waitUntil:'networkidle'});
 for(let pose=0;pose<8;pose++){await page.selectOption('#pose',String(pose));await page.waitForFunction(()=>['focus','before'].every(id=>{const img=document.getElementById(id);return img.complete&&img.naturalWidth===2560}));checks.push({compare:pose,ok:true})}
 await page.selectOption('#pose','5');await page.selectOption('#direction','0');await page.locator('.compare').screenshot({path:'D:/freelance/gumaster2d/artifacts/concept44_compare_guard.png'});
 await page.selectOption('#pose','4');await page.selectOption('#direction','6');await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/concept44_browser_compare.png'});
 await page.selectOption('#mode','motion');
 for(const action of ['walk','run','attack','defend','gather','mine']){await page.selectOption('#action',action);await page.waitForFunction(()=>!document.getElementById('play').disabled);for(const body of ['0','1']){await page.selectOption('#body',body);for(const d of ['0','1','2','3','4','5','6','7']){await page.selectOption('#direction',d);await page.waitForFunction(()=>{const img=document.getElementById('full');return img.complete&&img.naturalWidth===2560});checks.push({action,body,d,ok:true})}}}
 const before=await page.inputValue('#slider');await page.click('#play');await page.waitForTimeout(270);const after=await page.inputValue('#slider');await page.click('#play');if(before===after)errors.push('Playback did not advance');
 await page.selectOption('#bones','1');await page.waitForFunction(()=>document.getElementById('full').complete);const overlay=await page.getAttribute('#full','src');if(!overlay.includes('bones'))errors.push('Missing bone overlay');
 await page.setViewportSize({width:390,height:844});await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/concept44_browser_mobile.png'});if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))errors.push('Mobile horizontal overflow');
 const report={states:checks.length,checks,playback:before!==after,overlay,errors};fs.writeFileSync('D:/freelance/gumaster2d/artifacts/concept44_browser.json',JSON.stringify(report,null,2));console.log(JSON.stringify({states:checks.length,errors}));if(errors.length)process.exitCode=1;
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
