const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function runVisualLiveSimulation() {
  console.log('================================================================');
  console.log('🎬 LAUNCHING LIVE VISUAL QA SIMULATION & VIDEO RECORDING');
  console.log('   Sit back and watch the browser execute customer, app & admin flows!');
  console.log('================================================================\n');

  const recordingsDir = path.join(__dirname, 'recordings');
  if (!fs.existsSync(recordingsDir)) {
    fs.mkdirSync(recordingsDir, { recursive: true });
  }

  // Launch REAL visible browser window with slowMo so user can watch live
  const browser = await chromium.launch({
    headless: false, // VISIBLE BROWSER ON SCREEN
    slowMo: 1200,    // 1.2s delay between actions so user can watch easily
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
    // ACT 1: 🛍️ THE CUSTOMER SHOPPING EXPERIENCE
    // -------------------------------------------------------------------------
    console.log('[ACT 1/3] 🛍️ Customer visiting Storefront (https://sunnah-grandeur.web.app)...');
    await page.goto('https://sunnah-grandeur.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);

    console.log('   ➔ Customer scrolling homepage to inspect collections...');
    await page.evaluate(() => window.scrollBy({ top: 600, behavior: 'smooth' }));
    await page.waitForTimeout(2000);

    console.log('   ➔ Customer visiting /shop catalog...');
    await page.goto('https://sunnah-grandeur.web.app/shop', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);

    console.log('   ➔ Customer inspecting product /product/1...');
    await page.goto('https://sunnah-grandeur.web.app/product/1', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);

    console.log('   ➔ Customer adding product to Cart...');
    const addToCartBtn = await page.$('button:has-text("Add to Cart"), button:has-text("ADD TO CART")');
    if (addToCartBtn) {
      await addToCartBtn.click();
      await page.waitForTimeout(2000);
    }

    console.log('   ➔ Customer proceeding to Checkout (/checkout)...');
    await page.goto('https://sunnah-grandeur.web.app/checkout', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    // -------------------------------------------------------------------------
    // ACT 2: 📱 THE MUSLIM PRODUCTIVITY APP EXPERIENCE
    // -------------------------------------------------------------------------
    console.log('\n[ACT 2/3] 📱 User launching Mobile Productivity App (https://sunnah-grandeur-app.web.app)...');
    await page.setViewportSize({ width: 390, height: 844 }); // iPhone 14 Viewport
    await page.goto('https://sunnah-grandeur-app.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3000);

    console.log('   ➔ User switching to Qibla Tab...');
    const qiblaBtn = await page.$('#tabBtn-qibla');
    if (qiblaBtn) await qiblaBtn.click();
    await page.waitForTimeout(2000);

    console.log('   ➔ User switching to Hadith & Sunnah Habits Tab...');
    const hadithBtn = await page.$('#tabBtn-hadith');
    if (hadithBtn) await hadithBtn.click();
    await page.waitForTimeout(2000);

    console.log('   ➔ User triggering "Install App to Home Screen"...');
    const installBtn = await page.$('button:has-text("Install App")');
    if (installBtn) await installBtn.click();
    await page.waitForTimeout(4000);

    // -------------------------------------------------------------------------
    // ACT 3: ⚙️ THE ADMIN COMMAND CENTER EXPERIENCE
    // -------------------------------------------------------------------------
    console.log('\n[ACT 3/3] ⚙️ Admin accessing Admin Panel (https://sunnah-grandeur-admin.web.app)...');
    await page.setViewportSize({ width: 1440, height: 900 }); // Desktop Viewport
    await page.goto('https://sunnah-grandeur-admin.web.app', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(4000);

    console.log('\n✅ SIMULATION COMPLETE! Closing browser and saving video...');
  } catch (err) {
    console.log(`⚠️ Simulation Notice: ${err.message}`);
  } finally {
    await page.close();
    await context.close();
    await browser.close();

    console.log('\n================================================================');
    console.log('📹 VIDEO RECORDED & SAVED SUCCESSFULLY!');
    console.log(`   Saved to: ${recordingsDir}`);
    console.log('================================================================\n');
  }
}

runVisualLiveSimulation();
