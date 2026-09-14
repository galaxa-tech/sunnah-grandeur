const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const SITE = 'https://sunnahgrandeur.us';
const outDir = path.join(__dirname, 'verify_fixes_out');
fs.mkdirSync(outDir, { recursive: true });

const results = [];
function log(name, pass, detail) {
  results.push({ name, pass, detail });
  console.log(`[${pass ? 'PASS' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
}

async function main() {
  const browser = await chromium.launch({ headless: true });

  // ── PDP checks ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE + '/shop', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2500);
    const firstProductHref = await page.locator('a[href^="/product/"]').first().getAttribute('href');
    await page.goto(SITE + firstProductHref, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    const has360 = await page.locator('text=360°').isVisible().catch(() => false);
    log('BUG-015: 360 View control removed', !has360);

    const qtyBox = await page.locator('select').first().boundingBox().catch(() => null);
    log('BUG-014: quantity select has reasonable width', qtyBox && qtyBox.width > 60, JSON.stringify(qtyBox));

    await page.click('text=Reviews');
    await page.waitForTimeout(500);
    const bodyText = await page.textContent('body');
    const hasWriteReviewOrSignIn = /Write a Review|Sign in to write a review/i.test(bodyText);
    log('BUG-016: Reviews tab shows write-review CTA or sign-in prompt', hasWriteReviewOrSignIn);
    await page.screenshot({ path: path.join(outDir, '05_pdp_reviews.png') });
    await context.close();
  }

  // ── Search fallback for photo-less product ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);
    await page.click('button[aria-label="Search products"]');
    await page.waitForTimeout(300);
    await page.fill('input[placeholder]', 'Ramadan');
    await page.waitForTimeout(800);
    const brokenImgCount = await page.evaluate(() => {
      const imgs = [...document.querySelectorAll('img')].filter((i) => i.closest('a[href^="/product/"]'));
      return imgs.filter((i) => i.naturalWidth === 0 && i.complete && i.src).length;
    });
    await page.screenshot({ path: path.join(outDir, '06_search_results.png') });
    log('BUG-013: no broken <img> icons in search results', brokenImgCount === 0, `broken=${brokenImgCount}`);
    await context.close();
  }

  // ── Promo popup persistence ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2200);
    const visible1 = await page.locator('text=Muslim Productivity App').isVisible().catch(() => false);
    if (visible1) {
      await page.click('text=Muslim Productivity App >> xpath=../.. >> button');
    }
    await page.waitForTimeout(300);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2200);
    const visible2 = await page.locator('text=Muslim Productivity App').isVisible().catch(() => false);
    log('BUG-008: promo popup dismissal persists across reload', visible1 ? !visible2 : true, `before=${visible1} after=${visible2}`);
    await context.close();
  }

  // ── Arabic RTL ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.evaluate(() => {
      localStorage.setItem('sunnah-lang-storage', JSON.stringify({ state: { language: 'AR' }, version: 0 }));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1200);
    const dir = await page.evaluate(() => document.documentElement.dir);
    log('BUG-003: Arabic sets dir=rtl', dir === 'rtl', dir);
    await page.screenshot({ path: path.join(outDir, '07_arabic_home.png'), fullPage: false });
    await context.close();
  }

  // ── Category sidebar flyout closes on outside click ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE + '/shop', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);
    const catButtons = page.locator('aside button').nth(1);
    await catButtons.hover();
    await page.waitForTimeout(400);
    const flyoutBefore = await page.locator('.absolute.left-full').first().isVisible().catch(() => false);
    await page.mouse.click(700, 400);
    await page.waitForTimeout(300);
    const flyoutAfter = await page.locator('.absolute.left-full').first().isVisible().catch(() => false);
    log('BUG-012: flyout closes on outside click', flyoutBefore ? !flyoutAfter : true, `before=${flyoutBefore} after=${flyoutAfter}`);
    await context.close();
  }

  await browser.close();

  const failed = results.filter((r) => !r.pass);
  console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
  if (failed.length) console.log('FAILED:', failed.map((f) => f.name).join('; '));
}

main().catch((e) => { console.error(e); process.exit(1); });
