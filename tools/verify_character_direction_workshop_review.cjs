const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs');
const path = 'D:/freelance/gumaster2d/artifacts/';

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const checks = [], errors = [];
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1100 } });
    page.on('pageerror', error => errors.push(error.message));
    page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
    const data = JSON.parse(fs.readFileSync(path + 'concept46_workshop.json', 'utf8'));
    await page.goto('http://localhost:8879/concept46_character_workshop.html', { waitUntil: 'networkidle' });
    const imageReady = async () => page.waitForFunction(() => {
      const image = document.getElementById('native');
      return image.complete && image.naturalWidth === 960 && image.naturalHeight === 640;
    });
    await imageReady();
    for (const [direction, report] of Object.entries(data.directions)) {
      if (!report.source_current) errors.push(`Native evidence predates current source: direction ${direction}`);
      checks.push({ direction, source_current: report.source_current, ok: report.source_current });
      await page.click(`[data-direction="${direction}"]`);
      await page.selectOption('#mode', 'poses');
      for (let pose = 0; pose < report.poses.length; pose++) {
        await page.selectOption('#pose', String(pose));
        await imageReady();
        const actual = await page.getAttribute('#native', 'src');
        const expected = `concept46/d${direction}/pose${String(pose).padStart(2, '0')}.png`;
        if (actual !== expected) errors.push(`Pose source: ${actual} != ${expected}`);
        checks.push({ direction, mode: 'poses', pose, ok: actual === expected });
      }
      if (report.baseline) {
        if (!report.baseline_source_current) errors.push(`Frozen baseline changed: direction ${direction}`);
        await page.locator('#comparePanel summary').click();
        await page.waitForFunction(() => ['before', 'after'].every(id => {
          const image = document.getElementById(id);
          return image.complete && image.naturalWidth === 960;
        }));
        checks.push({ direction, baseline: true, ok: report.baseline_source_current });
        await page.locator('#comparePanel summary').click();
      }
      if (!report.poses_only) {
        await page.selectOption('#mode', 'motion');
        for (const action of Object.keys(report.clips)) {
          await page.selectOption('#action', action);
          await page.waitForFunction(() => !document.getElementById('play').disabled);
          await imageReady();
          for (const frame of [0, Math.floor(report.clips[action].frames / 3), report.clips[action].frames - 1]) {
            await page.locator('#slider').fill(String(frame));
            await page.locator('#slider').dispatchEvent('input');
            await imageReady();
            checks.push({ direction, action, frame, ok: true });
          }
          const before = await page.inputValue('#slider');
          await page.click('#play');
          await page.waitForTimeout(137);
          const after = await page.inputValue('#slider');
          await page.click('#play');
          if (before === after) errors.push(`Playback frozen: ${direction}/${action}`);
          checks.push({ direction, action, playback: before !== after, ok: before !== after });
        }
        await page.selectOption('#mode', 'equipment');
        for (const weapon of ['sword', 'spear', 'unarmed']) {
          await page.selectOption('#weapon', weapon);
          await imageReady();
          checks.push({ direction, weapon, ok: true });
        }
      }
      await page.selectOption('#mode', 'assets');
      for (const body of ['male', 'female']) {
        await page.selectOption('#body', body);
        await page.waitForFunction(() => [...document.querySelectorAll('#assets img')].every(image => image.complete && image.naturalWidth > 0));
        const count = await page.locator('#assets img').count();
        const expected = data.assets[`${body}_${direction}`].length;
        if (count !== expected) errors.push(`Asset count mismatch ${direction}/${body}: ${count}`);
        checks.push({ direction, body, assets: count, ok: count === expected });
      }
    }
    await page.click('[data-direction="0"]');
    await page.selectOption('#mode', 'poses');
    await page.selectOption('#pose', '2');
    await imageReady();
    if (data.world?.length) {
      await page.locator('#worldPanel summary').click();
      await page.locator('#world').scrollIntoViewIfNeeded();
      await page.waitForFunction(() => [...document.querySelectorAll('#world img')].every(image => image.complete && image.naturalWidth >= 960));
      checks.push({ ingame_captures: data.world.length, ok: true });
      await page.locator('#worldPanel summary').click();
      await page.locator('h1').scrollIntoViewIfNeeded();
    }
    await page.screenshot({ path: path + 'concept46_browser.png', fullPage: true });
    for (const width of [1440, 960, 390]) {
      await page.setViewportSize({ width, height: 900 });
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth > innerWidth);
      if (overflow) errors.push(`Horizontal overflow at ${width}`);
      checks.push({ viewport: width, overflow, ok: !overflow });
    }
    await page.screenshot({ path: path + 'concept46_browser_mobile.png', fullPage: true });
    const report = { checks, pass: checks.filter(check => check.ok).length, total: checks.length, errors };
    fs.writeFileSync(path + 'concept46_browser.json', JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ pass: report.pass, total: report.total, errors }));
    if (errors.length) process.exitCode = 1;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
