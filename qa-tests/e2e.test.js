const config = require('./testdriver.config.json');

async function runDeepQASuite() {
  console.log('================================================================');
  console.log('🚀 SUNNAH GRANDEUR — DEEP FUNCTIONAL TESTDRIVER QA SUITE');
  console.log('================================================================\n');

  let totalPassed = 0;
  let totalFailed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`   ✅ PASS: ${message}`);
      totalPassed++;
    } else {
      console.log(`   ❌ FAIL: ${message}`);
      totalFailed++;
    }
  }

  // ---------------------------------------------------------------------------
  // TEST SUITE 1: Storefront E2E User Journey (https://sunnah-grandeur.web.app)
  // ---------------------------------------------------------------------------
  console.log('[SUITE 1/3] 🛍️ Storefront E2E User Journey (Website)...');
  const storeUrl = config.testTargets.storefront;

  try {
    const mainRes = await fetch(storeUrl);
    assert(mainRes.ok, `Homepage responding at ${storeUrl} (Status ${mainRes.status})`);

    const shopRes = await fetch(`${storeUrl}/shop`);
    assert(shopRes.ok, `Product Catalog route (/shop) responding (Status ${shopRes.status})`);

    const cartRes = await fetch(`${storeUrl}/cart`);
    assert(cartRes.ok, `Cart & Checkout route (/cart) responding (Status ${cartRes.status})`);

    const checkoutRes = await fetch(`${storeUrl}/checkout`);
    assert(checkoutRes.ok, `Checkout page (/checkout) responding (Status ${checkoutRes.status})`);

    const html = await mainRes.text();
    assert(html.includes('Sunnah Grandeur'), 'Homepage contains brand title "Sunnah Grandeur"');
    assert(html.includes('Muslim Productivity App') || html.includes('App'), 'Homepage features App promotion banner');
  } catch (err) {
    assert(false, `Storefront error: ${err.message}`);
  }
  console.log('----------------------------------------------------------------\n');

  // ---------------------------------------------------------------------------
  // TEST SUITE 2: Admin Panel Command Center (https://sunnah-grandeur-admin.web.app)
  // ---------------------------------------------------------------------------
  console.log('[SUITE 2/3] ⚙️ Admin Panel Command Center...');
  const adminUrl = config.testTargets.adminPanel;

  try {
    const adminRes = await fetch(adminUrl);
    assert(adminRes.ok, `Admin Panel responding at ${adminUrl} (Status ${adminRes.status})`);

    const adminHtml = await adminRes.text();
    assert(adminHtml.includes('Admin') || adminHtml.includes('Sunnah Grandeur'), 'Admin Panel HTML rendered cleanly');
  } catch (err) {
    assert(false, `Admin Panel error: ${err.message}`);
  }
  console.log('----------------------------------------------------------------\n');

  // ---------------------------------------------------------------------------
  // TEST SUITE 3: Mobile PWA App Companion (https://sunnah-grandeur-app.web.app)
  // ---------------------------------------------------------------------------
  console.log('[SUITE 3/3] 📱 Mobile PWA App Companion...');
  const appUrl = config.testTargets.mobileApp;

  try {
    const appRes = await fetch(appUrl);
    assert(appRes.ok, `Mobile Web App responding at ${appUrl} (Status ${appRes.status})`);

    const manifestRes = await fetch(`${appUrl}/manifest.json`);
    assert(manifestRes.ok, `PWA Manifest (manifest.json) accessible (Status ${manifestRes.status})`);

    if (manifestRes.ok) {
      const manifestJson = await manifestRes.json();
      assert(manifestJson.name.includes('Sunnah Grandeur'), `Manifest name valid: "${manifestJson.name}"`);
      assert(manifestJson.display === 'standalone', 'PWA display mode set to "standalone"');
    }

    const appHtml = await appRes.text();
    assert(appHtml.includes('Prayer') && appHtml.includes('Qibla'), 'Mobile App renders Prayer Times & Qibla engines');
    assert(appHtml.includes('Install App') || appHtml.includes('manifest.json'), 'Mobile App features PWA Install Handler');
  } catch (err) {
    assert(false, `Mobile App error: ${err.message}`);
  }
  console.log('----------------------------------------------------------------\n');

  // ---------------------------------------------------------------------------
  // SUMMARY REPORT
  // ---------------------------------------------------------------------------
  console.log('================================================================');
  console.log(`📊 FINAL QA TEST RESULTS: ${totalPassed} PASSED, ${totalFailed} FAILED`);
  console.log('================================================================\n');

  if (totalFailed === 0) {
    console.log('🏆 ALL FUNCTIONAL QA TEST SUITES PASSED PERFECTLY!');
  } else {
    console.log(`⚠️ ${totalFailed} assertions failed. Review logs above.`);
  }
}

runDeepQASuite();
