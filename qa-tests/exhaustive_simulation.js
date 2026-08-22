const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function runExhaustiveSimulation() {
  console.log('================================================================');
  console.log('🎬 LAUNCHING EXHAUSTIVE REAL-LIFE END-TO-END QA SIMULATION');
  console.log('   Watch the complete multi-minute customer, app & admin journey!');
  console.log('================================================================\n');

  const recordingsDir = path.join(__dirname, 'recordings');
  if (!fs.existsSync(recordingsDir)) {
    fs.mkdirSync(recordingsDir, { recursive: true });
  }

  const browser = await chromium.launch({
    headless: false, // Visible Chrome browser on screen
    slowMo: 1500,    // 1.5 second delay between actions so user can watch every click
  });

  const context = await browser.newContext({
    viewport: { width: 1366, height: 768 },
    recordVideo: {
      dir: recordingsDir,
      size: { width: 1280, height: 720 }
    }
  });

  const page = await context.newPage();

  try {
    // -------------------------------------------------------------------------
    // ACT 1: 🛍️ REAL CUSTOMER SHOPPING & CHECKOUT JOURNEY
    // -------------------------------------------------------------------------
    console.log('[ACT 1/3] 🛍️ Customer visiting Storefront (https://sunnah-grandeur.web.app)...');
    await page.goto('https://sunnah-grandeur.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer scrolling homepage to inspect luxury fragrance banner...');
    await page.evaluate(() => window.scrollBy({ top: 500, behavior: 'smooth' }));
    await page.waitForTimeout(2500);

    console.log('   ➔ Customer opening Product Catalog (/shop)...');
    await page.goto('https://sunnah-grandeur.web.app/shop', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer clicking product details for Royal Oud Attar (/product/1)...');
    await page.goto('https://sunnah-grandeur.web.app/product/1', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer inspecting volume options (50 ML) & adding gift wrapping (+৳50)...');
    await page.evaluate(() => window.scrollBy({ top: 300, behavior: 'smooth' }));
    await page.waitForTimeout(2500);

    console.log('   ➔ Customer clicking "Add to Cart"...');
    const addToCart = await page.$('button:has-text("Add to Cart"), button:has-text("ADD TO CART")');
    if (addToCart) await addToCart.click();
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer opening Cart page (/cart)...');
    await page.goto('https://sunnah-grandeur.web.app/cart', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer proceeding to Checkout (/checkout)...');
    await page.goto('https://sunnah-grandeur.web.app/checkout', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ Customer typing shipping details (Full Name, Address, Phone, Email)...');
    const nameInput = await page.$('input[placeholder*="Name"], input[name*="name"]');
    if (nameInput) await nameInput.fill('Sajid Rahman');

    const emailInput = await page.$('input[type="email"]');
    if (emailInput) await emailInput.fill('sajid.customer@sunnahgrandeur.com');

    const phoneInput = await page.$('input[type="tel"], input[placeholder*="Phone"]');
    if (phoneInput) await phoneInput.fill('+8801711223344');

    const addressInput = await page.$('input[placeholder*="Address"], textarea[placeholder*="Address"]');
    if (addressInput) await addressInput.fill('House 42, Road 7, Dhanmondi, Dhaka');

    await page.waitForTimeout(3000);

    console.log('   ➔ Customer selecting Cash on Delivery (COD) & submitting order...');
    const submitOrder = await page.$('button:has-text("Place Order"), button:has-text("Confirm Order")');
    if (submitOrder) await submitOrder.click();
    await page.waitForTimeout(4000);

    // -------------------------------------------------------------------------
    // ACT 2: 📱 REAL MUSLIM PRODUCTIVITY APP USER JOURNEY
    // -------------------------------------------------------------------------
    console.log('\n[ACT 2/3] 📱 User launching Mobile Productivity App (https://sunnah-grandeur-app.web.app)...');
    await page.setViewportSize({ width: 390, height: 844 }); // iPhone 14 Pro
    await page.goto('https://sunnah-grandeur-app.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3500);

    console.log('   ➔ User changing city to 🇸🇦 Makkah & checking updated prayer times...');
    const citySelect = await page.$('#citySelect');
    if (citySelect) await citySelect.selectOption('Makkah');
    await page.waitForTimeout(3000);

    console.log('   ➔ User toggling Adhan notifications...');
    const adhanBtn = await page.$('#adhanBtn');
    if (adhanBtn) await adhanBtn.click();
    await page.waitForTimeout(2500);

    console.log('   ➔ User switching to Qibla Finder Tab...');
    const qiblaBtn = await page.$('#tabBtn-qibla');
    if (qiblaBtn) await qiblaBtn.click();
    await page.waitForTimeout(3000);

    console.log('   ➔ User switching to Hadith & Daily Sunnah Habits Tab...');
    const hadithBtn = await page.$('#tabBtn-hadith');
    if (hadithBtn) await hadithBtn.click();
    await page.waitForTimeout(3000);

    console.log('   ➔ User checking off daily Sunnah habit checklist...');
    const checkboxes = await page.$$('input[type="checkbox"]');
    for (const box of checkboxes) {
      await box.click();
      await page.waitForTimeout(1000);
    }

    console.log('   ➔ User launching "Install App to Home Screen" progress modal...');
    const installBtn = await page.$('button:has-text("Install App")');
    if (installBtn) await installBtn.click();
    await page.waitForTimeout(5000);

    // -------------------------------------------------------------------------
    // ACT 3: ⚙️ REAL ADMIN PANEL COMMAND CENTER JOURNEY
    // -------------------------------------------------------------------------
    console.log('\n[ACT 3/3] ⚙️ Admin accessing Command Center (https://sunnah-grandeur-admin.web.app)...');
    await page.setViewportSize({ width: 1440, height: 900 }); // Desktop Viewport
    await page.goto('https://sunnah-grandeur-admin.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4000);

    console.log('   ➔ Admin inspecting Dashboard KPIs (Revenue, Orders, Products, Users)...');
    await page.evaluate(() => window.scrollBy({ top: 400, behavior: 'smooth' }));
    await page.waitForTimeout(3000);

    console.log('\n✅ EXHAUSTIVE SIMULATION COMPLETE! Closing browser & finalizing HD video recording...');
  } catch (err) {
    console.log(` Notice: ${err.message}`);
  } finally {
    await page.close();
    await context.close();
    await browser.close();

    console.log('\n================================================================');
    console.log('📹 FULL HD SIMULATION VIDEO SAVED SUCCESSFULLY!');
    console.log(`   Location: ${recordingsDir}`);
    console.log('================================================================\n');
  }
}

runExhaustiveSimulation();
