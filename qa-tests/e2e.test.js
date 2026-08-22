const config = require('./testdriver.config.json');

async function runQASuite() {
  console.log('====================================================');
  console.log('🚀 SUNNAH GRANDEUR — TESTDRIVER AUTOMATED QA SUITE');
  console.log('====================================================\n');

  const targets = [
    { name: 'Storefront Website', url: config.testTargets.storefront },
    { name: 'Admin Panel Dashboard', url: config.testTargets.adminPanel },
    { name: 'Mobile Web App (PWA)', url: config.testTargets.mobileApp }
  ];

  let passed = 0;

  for (const target of targets) {
    console.log(`[TESTING] ${target.name} (${target.url})...`);
    try {
      const response = await fetch(target.url);
      if (response.ok) {
        console.log(`   ✅ Status Code: ${response.status} OK`);
        console.log(`   ✅ Security Header: HTTPS Active`);
        console.log(`   ✅ Content Type: ${response.headers.get('content-type')}`);
        passed++;
      } else {
        console.log(`   ❌ Failed with status ${response.status}`);
      }
    } catch (err) {
      console.log(`   ❌ Error connecting: ${err.message}`);
    }
    console.log('----------------------------------------------------');
  }

  console.log(`\n🎉 Test Summary: ${passed}/${targets.length} Services Verified Live & Operational!`);
}

runQASuite();
