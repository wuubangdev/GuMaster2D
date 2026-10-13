const {chromium} = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
(async()=>{
  const browser = await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
  const page = await browser.newPage({viewport:{width:1280,height:900}});
  const checks=[], errors=[];
  const check=(passed,name)=>checks.push({passed,name});
  page.on('pageerror',error=>errors.push(error.message));
  page.on('response',response=>{if(response.status()>=400)errors.push(`${response.status()} ${response.url()}`)});
  await page.goto('http://localhost:8879/hud53_review.html');
  for(const screen of ['hud','bag','paired','craft','gu','settings','studio','quests']){
    await page.selectOption('#screen',screen);
    for(const size of ['960','1280','1920']){
      await page.selectOption('#resolution',size);
      await page.locator('#capture').evaluate(element=>element.decode());
      check(await page.locator('#capture').evaluate(element=>element.naturalWidth)===Number(size),`${screen} at ${size} loads its native screenshot`);
    }
  }
  for(const [screen,size] of [['bag','1280'],['craft','960'],['gu','960']]){
    await page.selectOption('#screen',screen);
    await page.selectOption('#resolution',size);
    await page.locator('#before').click();
    await page.locator('#capture').evaluate(element=>element.decode());
    check((await page.locator('#capture').getAttribute('src')).startsWith('hud53_baseline/') && await page.locator('#capture').evaluate(element=>element.naturalWidth)===Number(size),`${screen} before image matches comparison resolution`);
    await page.locator('#after').click();
  }
  await page.selectOption('#screen','hud');
  check(await page.locator('#before').isDisabled(),'Unavailable before images are disabled');
  await page.locator('#zoom').click();
  check(await page.locator('#stage').evaluate(element=>element.classList.contains('actual')),'100% zoom keeps native pixels in a scrollable viewport');
  await page.locator('#zoom').click();
  await page.setViewportSize({width:390,height:844});
  check(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth),'Review fits a narrow browser window');
  await page.setViewportSize({width:1280,height:900});
  await page.selectOption('#screen','craft');
  await page.locator('#capture').evaluate(element=>element.decode());
  await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/hud53_browser.png',fullPage:true});
  check(errors.length===0,'No script or resource errors');
  const report={passed:checks.filter(item=>item.passed).length,failed:checks.filter(item=>!item.passed).length,checks,errors};
  fs.writeFileSync('D:/freelance/gumaster2d/artifacts/hud53_browser.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify({passed:report.passed,total:checks.length,errors}));
  await browser.close();process.exit(report.failed?1:0);
})().catch(error=>{console.error(error);process.exit(2)});
