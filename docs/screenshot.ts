import { list } from './src/components/HomepageFeatures/list';
import { chromium } from 'playwright';
import fs from 'node:fs';


for (const item of list) {
  console.log(`${item.name} (${item.base_name})`);
  const browser = await chromium.launch(); // or 'chromium', 'firefox'
  try {
    const context = await browser.newContext();
    const page = await context.newPage();
    page.setViewportSize({ "width": 300, "height": 157 });
    await page.goto(`http://localhost:3000/rowmath/wasm/${item.base_name}.html`);
    await page.waitForLoadState('networkidle')
    await page.screenshot({ path: `static/wasm/${item.base_name}.jpg` });
    await browser.close();
  } catch (ex) {
    console.error(ex);
  }

  // inject html to ogp
  const path = `static/wasm/${item.base_name}.html`
  if (fs.existsSync(path)) {
    let src = fs.readFileSync(path, 'utf8');
    const replace = `<meta charset=utf-8>
<meta property="og:title" content="${item.name}">
<meta property="og:type" content="website">
<meta property="og:url" content="https://ousttrue.github.io/rowmath/wasm/${item.base_name}.html">
<meta property="og:image" content="https://ousttrue.github.io/rowmath/wasm/${item.base_name}.jpg">
<meta property="og:site_name" content="rowmath wasm examples">
<meta property="og:description" content="${item.name}">
`;
    fs.writeFileSync(path, src.replace('<meta charset=utf-8>', replace));
  }
}
