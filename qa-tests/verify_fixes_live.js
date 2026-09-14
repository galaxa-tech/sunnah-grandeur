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

  // ── 1. Sign-in modal: viewport 1440x900, Escape + backdrop close ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);
    // scroll down a bit first to reproduce the "low page position" bug condition
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(300);
    await page.click('button[aria-label="Account menu"]');
    await page.waitForTimeout(500);
    const modalBox = await page.locator('text=Welcome Back').boundingBox();
    const inViewport = modalBox && modalBox.y >= 0 && modalBox.y < 900;
    await page.screenshot({ path: path.join(outDir, '01_signin_modal.png') });
    log('BUG-001: sign-in modal renders within viewport', !!inViewport, JSON.stringify(modalBox));

    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    const stillOpen = await page.locator('text=Welcome Back').isVisible().catch(() => false);
    log('BUG-001: Escape closes sign-in modal', !stillOpen);

    // reopen, test backdrop click
    await page.click('button[aria-label="Account menu"]');
    await page.waitForTimeout(400);
    await page.mouse.click(20, 20);
    await page.waitForTimeout(300);
    const stillOpen2 = await page.locator('text=Welcome Back').isVisible().catch(() => false);
    log('BUG-001: backdrop click closes sign-in modal', !stillOpen2);
    await context.close();
  }

  // ── 2. Search modal Escape ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.click('button[aria-label="Search products"]');
    await page.waitForTimeout(400);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    const searchOpen = await page.locator('text=Popular Searches').isVisible().catch(() => false);
    log('BUG-002: Escape closes search modal', !searchOpen);
    await context.close();
  }

  // ── 3. Mobile drawer opens from the right ──
  {
    const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.click('button[aria-label="Toggle mobile menu"]');
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(outDir, '02_mobile_drawer.png') });
    const box = await page.evaluate(() => {
      const drawer = [...document.querySelectorAll('div')].find(
        (d) => d.className.includes('w-[280px]') && d.className.includes('fixed')
      );
      if (!drawer) return null;
      const r = drawer.getBoundingClientRect();
      return { x: r.x, right: r.right, width: r.width, viewportWidth: window.innerWidth };
    });
    const nearRight = box && box.right >= box.viewportWidth - 2;
    log('BUG-004: mobile drawer anchored to right side', !!nearRight, JSON.stringify(box));
    await context.close();
  }

  // ── 4. Light mode: toggle and check hero/category section backgrounds adapt ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.click('button[aria-label="Account menu"]').catch(() => {});
    // account menu only shows theme toggle if logged in; use mobile-drawer-style toggle instead via localStorage
    await page.evaluate(() => {
      localStorage.setItem('sunnah-theme', JSON.stringify({ state: { theme: 'light' }, version: 0 }));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    const htmlTheme = await page.evaluate(() => document.documentElement.dataset.theme);
    const heroBg = await page.evaluate(() => {
      const hero = document.querySelector('section');
      return hero ? getComputedStyle(hero).backgroundColor : null;
    });
    await page.screenshot({ path: path.join(outDir, '03_light_mode_home.png'), fullPage: true });
    log('BUG-005: data-theme=light applied', htmlTheme === 'light', htmlTheme);
    log('BUG-005: hero background is light (not near-black)', heroBg && !heroBg.startsWith('rgb(7,') && !heroBg.startsWith('rgb(6,'), heroBg);
    await context.close();
  }

  // ── 5. FAQ payment copy ──
  {
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto(SITE + '/faq', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(800);
    const bodyText = await page.textContent('body');
    const claimsFakePayments = /Apple Pay|Google Pay|PayPal|Shop Pay/i.test(bodyText);
    log('BUG-017b: FAQ no longer claims unsupported payment methods', !claimsFakePayments);
    await context.close();
  }

  // ── 6. Homepage category tile counts are not all "4 Styles" ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2500); // allow Firestore onSnapshot to populate
    const counts = await page.locator('text=/\\d+ Products/').allTextContents();
    const allSame4 = counts.length > 0 && counts.every((c) => c.trim() === '4 Products');
    log('BUG-010: category tile counts vary (not hardcoded)', counts.length > 0 && !allSame4, JSON.stringify(counts));
    await context.close();
  }

  // ── 7. Bengali language switch translates hero/categories ──
  {
    const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
    const page = await context.newPage();
    await page.goto(SITE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.evaluate(() => {
      localStorage.setItem('sunnah-lang-storage', JSON.stringify({ state: { language: 'BN' }, version: 0 }));
    });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);
    const bodyText = await page.textContent('body');
    const hasBengaliHero = bodyText.includes('আগারউড') || bodyText.includes('সৌরভ');
    await page.screenshot({ path: path.join(outDir, '04_bengali_home.png'), fullPage: true });
    log('BUG-003: Bengali hero copy translated', hasBengaliHero);
    await context.close();
  }

  await browser.close();

  const failed = results.filter((r) => !r.pass);
  console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
  if (failed.length) {
    console.log('FAILED:', failed.map((f) => f.name).join('; '));
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
