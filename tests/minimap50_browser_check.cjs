const {chromium} = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
(async()=>{
  const browser = await chromium.launch({headless:true,executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe'});
  const page = await browser.newPage({viewport:{width:1280,height:900}});
  const errors=[];let checks=0;
  page.on('pageerror',error=>errors.push(error.message));
  await page.goto('http://localhost:8879/minimap50_review.html');
  for(const size of ['1280','960']){
    await page.locator(`[data-size="${size}"]`).click();
    for(const mode of ['hud','large']){
      await page.locator(`[data-mode="${mode}"]`).click();
      for(const id of ['before','after','screen']){
        const img=page.locator(`#${id}`);
        try{await img.evaluate(element=>element.decode());checks++;if(await img.evaluate(element=>element.naturalWidth)!==Number(size))errors.push(`${size}/${mode}/${id} width`)}catch{errors.push(`${size}/${mode}/${id} image`)}
      }
    }
  }
  await page.locator('[data-size="1280"]').click();
  await page.screenshot({path:'D:/freelance/gumaster2d/artifacts/minimap50_browser.png'});
  const report={passed:checks-errors.length,total:12,errors};
  fs.writeFileSync('D:/freelance/gumaster2d/artifacts/minimap50_browser.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));await browser.close();process.exit(errors.length?1:0);
})().catch(error=>{console.error(error);process.exit(2)});
