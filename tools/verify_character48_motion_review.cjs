const {chromium}=require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');
const base='D:/freelance/gumaster2d/artifacts/';
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true}),checks=[],errors=[];
 const check=(ok,label,details={})=>{checks.push({ok,label,...details});if(!ok)errors.push(label)};
 try{
  const data=JSON.parse(fs.readFileSync(base+'concept48_review.json','utf8'));
  const page=await browser.newPage({viewport:{width:1440,height:1100}});
  page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
  await page.goto('http://localhost:8879/concept48_character_review.html',{waitUntil:'networkidle'});
  const ready=async()=>page.waitForFunction(()=>document.getElementById('surface').dataset.ready==='true');
  await ready();check(data.source_current,'Native source hashes match current project');
  for(const [direction,report] of Object.entries(data.directions)){
   await page.click(`[data-direction="${direction}"]`);await ready();
   check(await page.getAttribute(`[data-direction="${direction}"]`,'aria-pressed')==='true',`Direction ${direction} selected`);
   for(const body of ['male','female']){
    await page.selectOption('#body',body);await ready();
    check(await page.inputValue('#body')===body,`Body ${body} direction ${direction}`);
   }
   await page.selectOption('#body','male');
   for(const [clip,value] of Object.entries(report.clips)){
    await page.selectOption('#clip',clip);await page.waitForFunction(()=>!document.getElementById('play').disabled);await ready();
    check(Number(await page.getAttribute('#slider','max'))===value.frames-1,`Frame count ${direction}/${clip}`);
    for(const frame of [0,Math.floor(value.frames/2),value.frames-1]){
     await page.locator('#slider').fill(String(frame));await page.locator('#slider').dispatchEvent('input');await ready();
     const expected=`concept48/${value.records[frame].file}`;
     check(await page.getAttribute('#surface','data-source')===expected,`Native frame ${direction}/${clip}/${frame}`);
    }
    await page.click('#play');await page.waitForTimeout(150);await page.click('#play');await ready();
    check(Number(await page.inputValue('#slider'))!==value.frames-1,`Playback ${direction}/${clip}`);
    const canCompare=!!data.baseline[direction]?.clips[clip];
    check(await page.isDisabled('#compare')!==canCompare,`Baseline availability ${direction}/${clip}`);
    if(canCompare){
     await page.check('#compare');await ready();
     check(await page.getAttribute('#surface','width')==='960'&&await page.getAttribute('#surface','data-compare')==='true',`Genuine baseline ${direction}/${clip}`);
     await page.uncheck('#compare');await ready();
    }
   }
   await page.selectOption('#mode','poses');
   for(let pose=0;pose<report.poses.length;pose++){
    await page.selectOption('#pose',String(pose));await ready();
    check(await page.getAttribute('#surface','data-source')===`concept48/${report.pose_records[pose].file}`,`Static pose ${direction}/${pose}`);
   }
   await page.check('#bones');await ready();
   check(await page.getAttribute('#surface','data-bones')==='true',`Native joint overlay ${direction}`);
   await page.uncheck('#bones');await page.selectOption('#mode','motion');await ready();
  }
  await page.click('[data-direction="0"]');await page.selectOption('#clip','actor_walk_run_stop');await ready();
  await page.selectOption('#speed','.25');await page.check('#bones');await page.check('#compare');await ready();
  await page.locator('#slider').fill('26');await page.locator('#slider').dispatchEvent('input');await ready();
  check(await page.getAttribute('#surface','data-source')==='concept48/d0/actor_walk_run_stop/frame026.png','Actual ActorView evidence displayed');
  await page.screenshot({path:base+'concept48_browser.png',fullPage:true});
  await page.uncheck('#compare');await ready();
  const before=Number(await page.inputValue('#slider'));await page.click('#next');await ready();
  check(Number(await page.inputValue('#slider'))===before+1,'Single-frame next');
  await page.click('#prev');await ready();check(Number(await page.inputValue('#slider'))===before,'Single-frame previous');
  for(const width of [1440,960,390]){
   await page.setViewportSize({width,height:900});await ready();
   check(!await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),`No horizontal overflow ${width}`);
  }
  await page.screenshot({path:base+'concept48_browser_mobile.png',fullPage:true});
  check(await page.locator('#error').isHidden(),'No visible browser error');
  const result={pass:checks.filter(c=>c.ok).length,total:checks.length,checks,errors};
  fs.writeFileSync(base+'concept48_browser.json',JSON.stringify(result,null,2));console.log(JSON.stringify({pass:result.pass,total:result.total,errors}));
  if(errors.length)process.exitCode=1;
 } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
