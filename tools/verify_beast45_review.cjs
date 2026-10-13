const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:950}}), errors=[],checks=[];
 page.on('pageerror',e=>errors.push(e.message)); page.on('requestfailed',r=>errors.push(r.url()+': '+r.failure().errorText));
 await page.goto('http://127.0.0.1:8879/beast45_review.html');
 await page.click('#play');
 for(let species=0;species<8;species++)for(const clip of ['idle','walk','attack','windup','strike','hit','death']){
  await page.selectOption('#species',String(species));await page.selectOption('#clip',clip);
  await page.waitForFunction(()=>{const i=cache.get(source(elapsed).url);return i&&i.complete&&i.naturalWidth>0});
  const state=await page.evaluate(()=>({url:source(elapsed).url,width:cache.get(source(elapsed).url).naturalWidth,height:cache.get(source(elapsed).url).naturalHeight,caption:document.querySelector('#caption').textContent}));
  checks.push({species,clip,...state,passed:state.width===1920&&state.height===(species===4?200:1720)});
 }
 await page.selectOption('#species','4');await page.selectOption('#clip','walk');await page.click('#play');
 await page.waitForTimeout(600);checks.push({name:'Playback advances',passed:(await page.locator('#frame').textContent())!=='1 / 24 · 8 hướng'});
 await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/beast45_browser.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(100);
 checks.push({name:'390px viewport has no horizontal overflow',passed:await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth)});
 checks.push({name:'No browser errors',passed:errors.length===0});
 const report={passed:checks.filter(c=>c.passed).length,failed:checks.filter(c=>!c.passed).length,errors,checks};
 fs.writeFileSync('D:/freelance/gumaster2d/artifacts/beast45_browser.json',JSON.stringify(report,null,2));console.log(JSON.stringify({passed:report.passed,failed:report.failed,errors}));
 await browser.close();process.exitCode=report.failed?1:0;
})().catch(e=>{console.error(e);process.exitCode=1});
