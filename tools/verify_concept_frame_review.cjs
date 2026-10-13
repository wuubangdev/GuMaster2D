// Local-only inspector verification against untouched native PNG captures.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { pathToFileURL } = require('node:url');
const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root = path.resolve(__dirname, '..');
const prefix = process.argv[2] || 'concept29';

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1100 } });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(pathToFileURL(path.join(root, 'artifacts', `${prefix}_frame_review.html`)).href);
    await page.locator('#full').evaluate(image => image.decode());
    assert.equal(await page.locator('#action option').count(), 11);
    assert.equal(await page.locator('#direction option').count(), 8);
    await page.locator('h1').click();
    await page.keyboard.press('ArrowRight');
    assert.equal(await page.locator('#slider').inputValue(), '1');
    await page.locator('#body').selectOption('1');
    await page.locator('#direction').selectOption('4');
    await page.locator('#action').selectOption('run');
    assert.match(await page.locator('#name').textContent(), /Chạy · Nữ · N/);
    await page.locator('#slider').evaluate(slider => { slider.value = '16'; slider.dispatchEvent(new Event('input')); });
    await page.locator('#full').evaluate(image => image.decode());
    if (['concept30','concept31','concept32','concept33','concept34','concept35','concept36','concept37'].includes(prefix)) {
      await page.locator('#baseline').evaluate(image => image.decode());
      assert.equal(await page.locator('#baseline').getAttribute('src'), `${'concept' + (Number(prefix.replace('concept','')) - 1)}_actions/run/frame016.png`);
      assert.equal(await page.locator('#baseline').evaluate(image => image.style.left), '-640px');
      assert.equal(await page.locator('#baseline').evaluate(image => image.style.top), '-450px');
    }
    await page.screenshot({ path: path.join(root, 'artifacts', `${prefix}_frame_review_preview.png`), fullPage: true });
    await page.setViewportSize({ width: 600, height: 900 });
	await page.waitForFunction(() => document.getElementById('focus').style.left === '-640px');
    assert.equal(await page.locator('#focus').evaluate(image => image.style.left), '-640px');
    assert.equal(await page.locator('#focus').evaluate(image => image.width), 1280);
    await page.locator('h1').click();
    await page.keyboard.press('Space');
    assert.equal(await page.locator('#play').textContent(), 'Dừng');
    await page.keyboard.press('Space');
    assert.equal(await page.locator('#play').textContent(), 'Phát');
    const decoded = await page.evaluate(async ({ prefix }) => {
      let decoded = 0;
      for (const action of Array.from(document.querySelectorAll('#action option'), option => option.value)) {
        for (let frame = 0; frame < 32; frame++) {
          const image = new Image();
          image.src = `${prefix}_actions/${action}/frame${String(frame).padStart(3, '0')}.png`;
          await image.decode();
          if (image.naturalWidth !== 1280 || image.naturalHeight !== 800) throw new Error(`Unexpected frame dimensions ${action}/${frame}`);
          decoded++;
        }
      }
      return decoded;
    }, { prefix });
    assert.equal(decoded, 352);
    assert.deepEqual(errors, []);
    const results = { decoded_native_frames: decoded, direction_options: 8, action_options: 11, keyboard_and_scrubber: 'passed', body_direction_selection: 'passed', responsive_focus: 'passed', page_errors: errors };
    fs.writeFileSync(path.join(root, 'artifacts', `${prefix}_frame_review_browser.json`), JSON.stringify(results, null, 2));
    console.log(JSON.stringify(results));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
