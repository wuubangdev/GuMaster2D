const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { pathToFileURL } = require('node:url');
const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root = path.resolve(__dirname, '..');
const prefix = process.argv[2] || 'concept36';
(async () => {
  const browser = await chromium.launch({headless:true, channel:'chrome'});
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1100}});
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(pathToFileURL(path.join(root,'artifacts',`${prefix}_combat_review.html`)).href);
    await page.locator('#full').evaluate(image => image.decode());
    assert.equal(await page.locator('#weapon option').count(),3);
    assert.equal(await page.locator('#direction option').count(),8);
    await page.locator('#weapon').selectOption('spear');
    await page.locator('#body').selectOption('1');
    await page.locator('#direction').selectOption('4');
    await page.locator('#bones').selectOption('1');
    await page.locator('#full').evaluate(image => image.decode());
    await page.locator('#baseline').evaluate(image => image.decode());
    assert.match(await page.locator('#full').getAttribute('src'), /spear_bones_16/);
    assert.match(await page.locator('#baseline').getAttribute('src'), new RegExp(`concept${Number(prefix.replace('concept',''))-1}_combat_spear_bones_16`));
    assert.equal(await page.locator('#focus').evaluate(image => image.style.left),'-640px');
    assert.equal(await page.locator('#focus').evaluate(image => image.style.top),'-450px');
    await page.locator('h1').click();
    await page.keyboard.press('ArrowRight');
    assert.equal(await page.locator('#slider').inputValue(),'23');
    await page.keyboard.press('Space');
    assert.equal(await page.locator('#play').textContent(),'Dừng');
    await page.keyboard.press('Space');
    await page.setViewportSize({width:600,height:900});
    assert.equal(await page.locator('#focus').evaluate(image => image.width),1280);
    await page.locator('#weapon').selectOption('sword');
    await page.locator('#body').selectOption('0');
    await page.locator('#direction').selectOption('6');
    await page.locator('#bones').selectOption('0');
    await page.locator('#slider').evaluate(input => { input.value=16; input.dispatchEvent(new Event('input')); });
    await page.locator('#full').evaluate(image => image.decode());
    const decoded = await page.evaluate(async prefix => {
      let count=0;
      for(const weapon of ['sword','spear','unarmed']) {
        for(let frame=0;frame<48;frame++) {
          const image = new Image();
          image.src=`${prefix}_combat/${weapon}/frame${String(frame).padStart(3,'0')}.png`;
          await image.decode();
          if(image.naturalWidth!==1280 || image.naturalHeight!==800) throw new Error('Wrong native image size');
          count++;
        }
        for(const frame of [0,8,12,16,23,32,47]) {
          const image = new Image();
          image.src=`${prefix}_combat_${weapon}_bones_${String(frame).padStart(2,'0')}.png`;
          await image.decode();
          count++;
        }
      }
      return count;
    },prefix);
    assert.equal(decoded,165);
    assert.deepEqual(errors,[]);
    await page.screenshot({path:path.join(root,'artifacts',`${prefix}_combat_review_browser.png`),fullPage:true});
    const report = {decoded_native_captures:decoded, weapons:3, directions:8, overlay_phases:7, body_and_direction:'passed', keyboard_and_scrubber:'passed', native_crop_at_mobile:'passed', page_errors:errors};
    fs.writeFileSync(path.join(root,'artifacts',`${prefix}_combat_review_browser.json`),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode=1; });
