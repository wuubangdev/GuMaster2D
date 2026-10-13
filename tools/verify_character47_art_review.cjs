const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
const crypto = require('crypto');
const root = 'D:/freelance/gumaster2d/';
const artifacts = root + 'artifacts/';

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const checks = [], errors = [];
  const check = (name, ok, detail = {}) => {
    checks.push({ name, ok, ...detail });
    if (!ok) errors.push(name + ': ' + JSON.stringify(detail));
  };
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    page.on('pageerror', error => errors.push(error.message));
    page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
    const data = JSON.parse(fs.readFileSync(artifacts + 'concept47_review.json', 'utf8'));
    for (const [file, sha] of Object.entries(data.source_sha256)) {
      const actual = crypto.createHash('sha256').update(fs.readFileSync(root + file)).digest('hex');
      check('source_current', actual === sha, { file });
    }
    await page.goto('http://localhost:8879/concept47_character_review.html', { waitUntil: 'networkidle' });
    const ready = async expected => page.waitForFunction(expected => {
      const image = document.getElementById('native'), canvas = document.getElementById('surface');
      return image.complete && image.naturalWidth === 960 && image.naturalHeight === 380 &&
        image.getAttribute('src') === expected && canvas.dataset.source === expected && canvas.dataset.ready === 'true';
    }, expected);
    for (let direction = 0; direction < 8; direction++) {
      await page.click(`[data-direction="${direction}"]`);
      for (const body of ['male', 'female']) {
        await page.selectOption('#body', body);
        await page.selectOption('#mode', 'poses');
        for (let pose = 0; pose < 9; pose++) {
          await page.selectOption('#pose', String(pose));
          const expected = `concept47/d${direction}/${body}/pose${String(pose).padStart(2, '0')}.png`;
          await ready(expected);
          check('native_pose', true, { direction, body, pose });
        }
        for (const compare of ['before', 'after', 'both']) {
          await page.click(`[data-compare="${compare}"]`);
          const result = await page.evaluate(compare => {
            const image = document.getElementById('native'), canvas = document.getElementById('surface');
            const reference = document.createElement('canvas');
            reference.width = compare === 'both' ? 960 : 480;
            reference.height = 380;
            reference.getContext('2d').drawImage(image, compare === 'after' ? 480 : 0, 0, reference.width, 380, 0, 0, reference.width, 380);
            const original = reference.getContext('2d').getImageData(0, 0, reference.width, 380).data;
            const displayed = canvas.getContext('2d').getImageData(0, 0, reference.width, 380).data;
            return { exact_pixels: original.every((value, index) => value === displayed[index]), no_upscale: canvas.getBoundingClientRect().width <= reference.width, desktop_one_to_one: canvas.getBoundingClientRect().width === reference.width, width: canvas.width };
          }, compare);
          check('native_crop', result.exact_pixels && result.no_upscale && result.desktop_one_to_one && result.width === (compare === 'both' ? 960 : 480), { direction, body, compare, ...result });
        }
        await page.selectOption('#mode', 'motion');
        for (const [action, clip] of Object.entries(data.directions[direction].clips)) {
          await page.selectOption('#action', action);
          await page.waitForFunction(() => !document.getElementById('play').disabled);
          for (const frame of [0, 7, 23]) {
            await page.locator('#slider').fill(String(frame));
            await page.locator('#slider').dispatchEvent('input');
            await ready(`concept47/d${direction}/${body}/${action}/frame${String(frame).padStart(3, '0')}.png`);
            check('motion_frame', true, { direction, body, action, frame });
          }
          const before = await page.inputValue('#slider');
          await page.click('#play');
          await page.waitForTimeout(135);
          const after = await page.inputValue('#slider');
          await page.click('#play');
          check('motion_playback', before !== after, { direction, body, action, before, after, duration: clip.duration });
        }
      }
    }
    await page.click('[data-direction="0"]');
    await page.selectOption('#body', 'male');
    await page.selectOption('#mode', 'motion');
    await page.selectOption('#action', 'attack');
    await page.waitForFunction(() => !document.getElementById('play').disabled);
    await page.locator('#slider').fill('0');
    await page.locator('#slider').dispatchEvent('input');
    await page.click('#prev');
    check('previous_wrap', await page.inputValue('#slider') === '23');
    await page.click('#next');
    check('next_wrap', await page.inputValue('#slider') === '0');
    await page.selectOption('#speed', '.25');
    await page.click('#play');
    await page.waitForTimeout(270);
    const slowFrame = Number(await page.inputValue('#slider'));
    await page.click('#play');
    check('quarter_speed', slowFrame > 0 && slowFrame < 12, { frame: slowFrame });
    await page.selectOption('#mode', 'poses');
    await page.selectOption('#pose', '0');
    await page.click('[data-compare="both"]');
    await ready('concept47/d0/male/pose00.png');
    await page.screenshot({ path: artifacts + 'concept47_browser.png', fullPage: true });
    for (const width of [1440, 960, 390]) {
      await page.setViewportSize({ width, height: 900 });
      for (const compare of ['both', 'before', 'after']) {
        await page.click(`[data-compare="${compare}"]`);
        const layout = await page.evaluate(() => {
          const canvas = document.getElementById('surface');
          return { overflow: document.documentElement.scrollWidth > innerWidth, no_upscale: canvas.getBoundingClientRect().width <= canvas.width };
        });
        check('responsive_layout', !layout.overflow && layout.no_upscale, { width, compare, ...layout });
      }
    }
    await page.screenshot({ path: artifacts + 'concept47_browser_mobile.png', fullPage: true });
    check('no_visible_error', await page.locator('#error').isHidden());
    const worldFile = await page.locator('#world').getAttribute('href');
    const worldResponse = await page.request.get('http://localhost:8879/' + worldFile);
    const worldBytes = await worldResponse.body();
    const nativeWorld = worldResponse.status() === 200 && worldBytes.length > 24 &&
      worldBytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) &&
      worldBytes.readUInt32BE(16) >= 960;
    check('actual_ingame_capture_link', nativeWorld, { file: worldFile, status: worldResponse.status() });
  } catch (error) {
    errors.push(error.stack || error.message);
  } finally {
    await browser.close();
    const report = { checks, pass: checks.filter(check => check.ok).length, total: checks.length, errors };
    fs.writeFileSync(artifacts + 'concept47_browser.json', JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ pass: report.pass, total: report.total, errors }));
    if (errors.length || report.pass !== report.total) process.exitCode = 1;
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
