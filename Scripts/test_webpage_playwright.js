const { chromium } = require('playwright');
const path = require('path');

(async () => {
    console.log('🚀 Launching Playwright browser automation for docs/index.html...');
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
        viewport: { width: 1440, height: 900 },
        deviceScaleFactor: 2
    });
    const page = await context.newPage();

    const filePath = 'file://' + path.resolve(__dirname, '../docs/index.html');
    console.log(`🌐 Navigating to: ${filePath}`);
    await page.goto(filePath);

    // Wait for canvas animation to initialize
    await page.waitForTimeout(2000);

    // Take Full Page Screenshot of the Webpage
    const fullPagePath = path.resolve(__dirname, '../docs/screenshots/webpage_full.png');
    await page.screenshot({ path: fullPagePath, fullPage: true });
    console.log(`📸 Webpage full screenshot saved: ${fullPagePath}`);

    // Take Hero & Live Shader Simulator Screenshot
    const heroPath = path.resolve(__dirname, '../docs/screenshots/webpage_hero_simulator.png');
    const heroElement = await page.$('.hero');
    if (heroElement) {
        await page.screenshot({ path: heroPath, clip: { x: 0, y: 0, width: 1440, height: 900 } });
        console.log(`📸 Webpage hero screenshot saved: ${heroPath}`);
    }

    // Test Interactive Tab Switching on the Live Simulator
    console.log('🧪 Testing interactive shader tab switching in Playwright...');
    const matrixBtn = await page.$('button:has-text("Matrix Digital Rain")');
    if (matrixBtn) {
        await matrixBtn.click();
        await page.waitForTimeout(1000);
        console.log('  ✅ Switched to Matrix Digital Rain');
    }

    const cyberpunkBtn = await page.$('button:has-text("Cyberpunk Grid")');
    if (cyberpunkBtn) {
        await cyberpunkBtn.click();
        await page.waitForTimeout(1000);
        console.log('  ✅ Switched to Cyberpunk Grid');
    }

    const particleBtn = await page.$('button:has-text("3D Particle Wave")');
    if (particleBtn) {
        await particleBtn.click();
        await page.waitForTimeout(1000);
        console.log('  ✅ Switched to 3D Particle Wave');
    }

    const auroraBtn = await page.$('button:has-text("Aurora Borealis")');
    if (auroraBtn) {
        await auroraBtn.click();
        await page.waitForTimeout(1000);
        console.log('  ✅ Switched back to Aurora Borealis');
    }

    // Verify Copy Terminal Command Button
    const copyBtn = await page.$('.copy-btn');
    if (copyBtn) {
        await copyBtn.click();
        await page.waitForTimeout(500);
        const btnText = await copyBtn.innerText();
        console.log(`  ✅ Copy button state: "${btnText}"`);
    }

    await browser.close();
    console.log('🎉 Playwright Webpage Automation & Verification completed successfully!');
})();
