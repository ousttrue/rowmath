const list = require('./src/components/HomepageFeatures/list.json');
const pw = require('playwright');

(async () => {
  const browser = await pw.chromium.launch(); // or 'chromium', 'firefox'
  const context = await browser.newContext();
  const page = await context.newPage();
  page.setViewportSize({ "width": 400, "height": 300 });

  for(const item of list){

    await page.goto(`http://localhost:3000/rowmath/wasm/${item.name}.html`);
    await page.waitForLoadState('networkidle')
    await page.screenshot({ path: `static/wasm/${item.name}.jpg` });

  }

  await browser.close();
})();
