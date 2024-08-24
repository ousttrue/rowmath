const list = require('./src/components/HomepageFeatures/list.json');
const pw = require('playwright');

(async () => {

  for (const item of list) {
    console.log(`${item.name} (${item.base_name})`);
    const browser = await pw.chromium.launch(); // or 'chromium', 'firefox'
    const context = await browser.newContext();
    const page = await context.newPage();
    page.setViewportSize({ "width": 300, "height": 157 });
    try {
      await page.goto(`http://localhost:3000/rowmath/wasm/${item.base_name}.html`);
      await page.waitForLoadState('networkidle')
      await page.screenshot({ path: `static/wasm/${item.base_name}.jpg` });
    } catch (ex) {
      console.error(ex);
    }
    await browser.close();
  }

})();
