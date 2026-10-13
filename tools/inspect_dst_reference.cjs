const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
 const pages=await Promise.allSettled([
  ['youtube','https://www.youtube.com/watch?v=dU-aq2JbLkk'],
  ['gdc','https://www.youtube.com/watch?v=8_KBjd0iaCU']
 ].map(async([id,url])=>{
  const page=await browser.newPage({viewport:{width:1440,height:1000}});
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:20000});
  await page.waitForTimeout(6000);
  const videos=await page.locator('video').evaluateAll(vs=>vs.map(v=>({src:v.currentSrc,duration:v.duration,ready:v.readyState,error:v.error?.message})));
  const text=(await page.locator('body').innerText()).slice(0,1800);
  await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/reference42/'+id+'.png'});
  const data={id,url,videos,text};
  if(videos[0]?.ready>=2){
   await page.locator('video').first().evaluate(v=>{v.muted=true;v.pause()});
   for(const t of (id==='youtube'?[26,27,28,29,33.0,33.15,33.3,33.45,33.6]:[310,480,610,850])){
    await page.locator('video').first().evaluate((v,t)=>new Promise((resolve,reject)=>{setTimeout(()=>reject(new Error("Video seek timeout")),8000);v.addEventListener('seeked',resolve,{once:true});v.currentTime=t}),t);
    await page.locator('video').first().screenshot({path:`D:/freelance/gumaster2d/artifacts/reference42/${id}_${t}.png`});
   }
  }
  if(id==='steam')data.videoAttributes=await page.locator('[data-mp4-source],[data-webm-source]').evaluateAll(ns=>ns.map(n=>Object.fromEntries(Array.from(n.attributes).map(a=>[a.name,a.value]))));
  return data;
 }));
 fs.writeFileSync('D:/freelance/gumaster2d/artifacts/reference42/browser.json',JSON.stringify(pages,null,2));console.log(JSON.stringify(pages,null,2));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
