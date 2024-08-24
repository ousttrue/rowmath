const list = require('./src/components/HomepageFeatures/list.json');
const pw = require('playwright');

(async () => {
  const browser = await pw.chromium.launch(); // or 'chromium', 'firefox'
  const context = await browser.newContext();
  const page = await context.newPage();
  page.setViewportSize({ "width": 300, "height": 157 });

  for(const item of list){

    await page.goto(`http://localhost:3000/rowmath/wasm/${item.base_name}.html`);
    await page.waitForLoadState('networkidle')
    await page.screenshot({ path: `static/wasm/${item.base_name}.jpg` });

  }

  await browser.close();
})();
