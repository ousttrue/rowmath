const list = require('./src/components/HomepageFeatures/list.json');
const pw = require('playwright');
const fs = require('fs');

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

    // inject html to ogp
    const path = `static/wasm/${item.base_name}.html`
    if(fs.existsSync(path)){ 
      let src = fs.readFileSync(path, 'utf8');
      fs.writeFileSync(path, src.replace('<meta charset=utf-8>', `<meta charset=utf-8>
<meta property="og:title" content="${item.name}">
<meta property="og:type" content="website">
<meta property="og:url" content="https://ousttrue.github.io/rowmath/wasm/${item.base_name}.html">
<meta property="og:image" content="https://ousttrue.github.io/rowmath/wasm/${item.base_name}.jpg">
<meta property="og:site_name" content="rowmath wasm examples">
<meta property="og:description" content="${item.name}">
`));
    }
  }

})();
