const { chromium } = require('C:/Users/Admin/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('http://localhost:8879/production49_review.html');
  for (const tab of ['hud', 'inventory', 'settings', 'atlas', 'beasts']) {
    await page.locator(`[data-tab="${tab}"]`).click();
    const image = page.locator(`#${tab} img`);
    await image.waitFor({ state: 'visible' });
    try { await image.evaluate(element => element.decode()); } catch { errors.push(`${tab} image missing`); }
  }
  for (const tab of ['hud', 'settings', 'atlas']) {
    await page.locator(`[data-tab="${tab}"]`).click();
    await page.locator(`#${tab} button[data-size="960"]`).click();
    const image = page.locator(`#${tab} img`);
    await image.waitFor();
    try { await image.evaluate(element => element.decode()); } catch { errors.push(`${tab} 960 image missing`); }
    if (await image.evaluate(element => element.naturalWidth) !== 960) errors.push(`${tab} 960 width mismatch`);
  }
  await page.locator('[data-tab="beasts"]').click();
  for (const frame of ['idle', 'walk_20', 'walk_45', 'walk_70']) {
    await page.locator(`[data-frame="${frame}"]`).click();
    try { await page.locator('#beast-image').evaluate(element => element.decode()); } catch { errors.push(`${frame} beast sheet missing`); }
    if (await page.locator('#beast-image').evaluate(element => element.naturalWidth) !== 1920) errors.push(`${frame} beast width mismatch`);
  }
  console.log(JSON.stringify({ passed: 12 - errors.length, total: 12, errors }));
  await browser.close();
  process.exit(errors.length ? 1 : 0);
})().catch(error => { console.error(error); process.exit(2); });
