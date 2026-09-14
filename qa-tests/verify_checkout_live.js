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
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  const consoleErrors = [];
  page.on('pageerror', (e) => consoleErrors.push(e.message));

  await page.goto(SITE + '/shop', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);

  // Add first in-stock product to cart via quick-add on the grid
  const addBtn = page.locator('button:has-text("Add to Cart")').first();
  await addBtn.scrollIntoViewIfNeeded();
  await addBtn.click({ timeout: 10000 }).catch(async () => {
    // fall back: open a product page and add from there
    const href = await page.locator('a[href^="/product/"]').first().getAttribute('href');
    await page.goto(SITE + href, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1000);
    await page.locator('button:has-text("Add to Cart")').first().click();
  });
  await page.waitForTimeout(1000);

  await page.goto(SITE + '/checkout', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(1500);

  const testEmail = `qa-guest-${Date.now()}@example.com`;
  await page.fill('input[placeholder="Ahmed Al-Mansour"]', 'QA Test Guest');
  await page.fill('input[placeholder="+1 (212) 555-0100"]', '2125550100');
  await page.fill('input[placeholder="3715 73rd St, Suite 205"]', '123 Test St');
  await page.fill('input[placeholder="Jackson Heights"]', 'Jackson Heights');
  await page.fill('input[placeholder="11372"]', '11372');
  await page.fill('input[placeholder="you@example.com"]', testEmail);

  await page.screenshot({ path: path.join(outDir, '08_checkout_form.png') });

  await page.click('button:has-text("Place COD Order")');
  await page.waitForSelector('text=Order Placed', { timeout: 20000 }).catch(() => {});

  const bodyText = await page.textContent('body');
  const orderPlaced = /Order Placed/i.test(bodyText);
  log('BUG-017c: COD order places successfully', orderPlaced);
  await page.screenshot({ path: path.join(outDir, '09_order_confirmed.png') });

  const showsUpgradeCTA = /Create an account to track this order/i.test(bodyText);
  log('BUG-018: guest confirmation shows account-upgrade CTA', showsUpgradeCTA);

  const showsEmail = bodyText.includes(testEmail);
  log('BUG-018: upgrade CTA references the checkout email', showsEmail);

  if (orderPlaced && showsUpgradeCTA) {
    await page.fill('input[placeholder="Set a password"]', 'TestPass123!');
    await page.click('button:has-text("Create Account")');
    await page.waitForTimeout(2500);
    const afterUpgrade = await page.textContent('body');
    const upgraded = /Account created/i.test(afterUpgrade);
    log('BUG-018: guest session upgrades to real account', upgraded);
    await page.screenshot({ path: path.join(outDir, '10_account_upgraded.png') });

    // Verify the account now shows the right name/email in the header menu
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);
    await page.click('button[aria-label="Account menu"]');
    await page.waitForTimeout(500);
    const menuText = await page.textContent('body');
    const nameShown = menuText.includes('QA Test Guest');
    const emailShown = menuText.includes(testEmail);
    log('BUG-018: account menu shows real name after upgrade', nameShown);
    log('BUG-018: account menu shows real email after upgrade', emailShown);
    await page.screenshot({ path: path.join(outDir, '11_account_menu_after_upgrade.png') });
  }

  log('No uncaught page errors during checkout', consoleErrors.length === 0, consoleErrors.join(' | '));

  await browser.close();

  const failed = results.filter((r) => !r.pass);
  console.log(`\n${results.length - failed.length}/${results.length} checks passed.`);
  if (failed.length) console.log('FAILED:', failed.map((f) => f.name).join('; '));
}

main().catch((e) => { console.error(e); process.exit(1); });
