const {chromium} = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
(async()=>{
  const browser = await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
  const page = await browser.newPage({viewport:{width:1280,height:900}});
  const checks=[],errors=[];
  const check=(passed,name)=>checks.push({passed,name});
  page.on('pageerror',error=>errors.push(error.message));
  page.on('response',response=>{if(response.status()>=400)errors.push(`${response.status()} ${response.url()}`)});
  await page.goto('http://localhost:8879/gu52_review.html');
  for(const mode of ['upgrade','fusion','confirm','success','fusion_success','maximum','missing','before']){
    await page.locator(`[data-mode="${mode}"]`).click();
    await page.locator('#screen').evaluate(element=>element.decode());
    check(await page.locator('#screen').evaluate(element=>element.naturalWidth)===1280,`${mode}: native 1280 image loads`);
  }
  await page.locator('[data-mode="upgrade"]').click();
  for(const gu of ['moon','shield','dash','frost']){
    await page.locator(`[data-gu="${gu}"]`).click();
    await page.locator('#screen').evaluate(element=>element.decode());
    check((await page.locator('#screen').getAttribute('src')).includes(`upgrade_${gu}_1280`),`${gu}: correct selected Gu image loads`);
  }
  for(const size of ['960','1280','1920']){
    await page.locator(`[data-size="${size}"]`).click();
    await page.locator('#screen').evaluate(element=>element.decode());
    check(await page.locator('#screen').evaluate(element=>element.naturalWidth)===Number(size),`Upgrade screenshot ${size} has correct native resolution`);
  }
  await page.locator('[data-mode="fusion"]').click();
  for(const size of ['960','1280']){
    await page.locator(`[data-size="${size}"]`).click();
    await page.locator('#screen').evaluate(element=>element.decode());
    check(await page.locator('#screen').evaluate(element=>element.naturalWidth)===Number(size),`Fusion screenshot ${size} has correct native resolution`);
  }
  await page.setViewportSize({width:390,height:844});
  check(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth),'Review has no horizontal overflow on a narrow viewport');
  await page.setViewportSize({width:1280,height:900});
  await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/gu52_browser.png',fullPage:true});
  check(errors.length===0,'No JavaScript or resource errors');
  const report={passed:checks.filter(item=>item.passed).length,failed:checks.filter(item=>!item.passed).length,total:checks.length,checks,errors};
  fs.writeFileSync('D:/freelance/gumaster2d/artifacts/gu52_browser.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify({passed:report.passed,total:report.total,errors}));
  await browser.close();process.exit(report.failed?1:0);
})().catch(error=>{console.error(error);process.exit(2)});
