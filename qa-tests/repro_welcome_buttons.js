const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const APP_URL = 'https://sunnah-grandeur-app.web.app';
const outDir = path.join(__dirname, 'repro_out');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

function ts() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

async function main() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: '/opt/pw-browsers/chromium',
    proxy: { server: 'http://127.0.0.1:46787' },
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--ssl-version-max=tls1.2',
      '--ignore-certificate-errors',
    ],
  });

  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
    ignoreHTTPSErrors: true,
    // Fresh session every run: no storageState, and we clear SW/caches below.
  });

  const page = await context.newPage();

  const consoleMsgs = [];
  const pageErrors = [];
  const failedRequests = [];

  page.on('console', (msg) => {
    consoleMsgs.push(`[console.${msg.type()}] ${msg.text()}`);
  });
  page.on('pageerror', (err) => {
    pageErrors.push(`[pageerror] ${err.message}\n${err.stack || ''}`);
  });
  page.on('requestfailed', (req) => {
    failedRequests.push(`[requestfailed] ${req.method()} ${req.url()} -> ${req.failure()?.errorText}`);
  });
  const allResponses = [];
  page.on('response', (res) => {
    allResponses.push(`[${new Date().toISOString()}] [http ${res.status()}] ${res.url()}`);
    if (res.status() >= 400) {
      failedRequests.push(`[http ${res.status()}] ${res.url()}`);
    }
  });

  console.log(`Navigating to ${APP_URL} ...`);
  await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

  // Give the Flutter engine time to boot, splash to finish (~2.5s) and
  // LandingPage's auth-state resolution to settle (up to 5s safety valve).
  await page.waitForTimeout(8000);

  const shot1 = path.join(outDir, `01_first_page_${ts()}.png`);
  await page.screenshot({ path: shot1 });
  console.log(`Screenshot after 8s settle: ${shot1}`);

  // Flutter web (CanvasKit renderer) paints to a <canvas> and does not
  // expose real DOM/accessibility nodes unless a screen reader is active,
  // so text/role-based locators won't find these buttons. Tap by raw
  // coordinates instead, based on the 390x844 viewport screenshot:
  // "Continue as Guest" is the filled gold button, roughly centered
  // horizontally, ~595px down.
  const guestButtonFound = true; // coordinate-based, always "found"
  console.log('Tapping "Continue as Guest" by coordinates (195, 595)...');
  await page.mouse.click(195, 595);

  const checkpoints = [300, 600, 1000, 1500, 2500, 4000, 6000];
  let elapsed = 0;
  for (const target of checkpoints) {
    await page.waitForTimeout(target - elapsed);
    elapsed = target;
    const shot = path.join(outDir, `03_t${target}ms_${ts()}.png`);
    await page.screenshot({ path: shot });
    console.log(`Screenshot at t+${target}ms: ${shot}`);
  }

  const currentUrl = page.url();
  console.log(`URL after tap: ${currentUrl}`);

  fs.writeFileSync(
    path.join(outDir, `console_log_${ts()}.txt`),
    [
      '=== CONSOLE ===',
      ...consoleMsgs,
      '',
      '=== PAGE ERRORS ===',
      ...pageErrors,
      '',
      '=== FAILED / 4xx-5xx REQUESTS ===',
      ...failedRequests,
      '',
      '=== ALL RESPONSES (chronological) ===',
      ...allResponses,
      '',
      `guestButtonFound=${guestButtonFound}`,
      `finalUrl=${currentUrl}`,
    ].join('\n')
  );

  console.log('\n--- SUMMARY ---');
  console.log(`guestButtonFound: ${guestButtonFound}`);
  console.log(`finalUrl: ${currentUrl}`);
  console.log(`console messages: ${consoleMsgs.length}`);
  console.log(`page errors: ${pageErrors.length}`);
  console.log(`failed/4xx-5xx requests: ${failedRequests.length}`);
  if (pageErrors.length) {
    console.log('\nPAGE ERRORS:');
    pageErrors.forEach((e) => console.log(e));
  }
  if (failedRequests.length) {
    console.log('\nFAILED REQUESTS:');
    failedRequests.forEach((e) => console.log(e));
  }

  await browser.close();
}

main().catch((err) => {
  console.error('Fatal error running repro script:', err);
  process.exit(1);
});
