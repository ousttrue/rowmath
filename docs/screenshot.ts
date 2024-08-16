const pw = require('playwright');

(async () => {
  const browser = await pw.chromium.launch(); // or 'chromium', 'firefox'
  const context = await browser.newContext();
  const page = await context.newPage();
  page.setViewportSize({ "width": 400, "height": 300 });

  await page.goto('http://localhost:3000/rowmath/wasm/sokol_camera.html');
  await page.waitForLoadState('networkidle')
  await page.screenshot({ path: 'static/wasm/sokol_camera.jpg' });

  await page.goto('http://localhost:3000/rowmath/wasm/raylib_camera.html');
  await page.waitForLoadState('networkidle')
  await page.screenshot({ path: 'static/wasm/raylib_camera.jpg' });

  await browser.close();
})();
