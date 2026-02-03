import { test, expect } from '@playwright/test';
import { setupMarketingPage, spotlightMultiple, clearHighlights, mockDate } from './helpers';

test('language-selector', async ({ page }) => {
  await setupMarketingPage(page);

  // Mock recommendations to be empty for general tests
  await page.route('**/recommendations', async route => {
    await route.fulfill({ status: 200, body: JSON.stringify({ suggestions: [] }) });
  });

  // Mock date to 15th to hide recommendations (persistent)
  await mockDate(page, '2026-02-15T12:00:00');

  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

  // 1. Go to Settings
  const settingsTab = page.getByRole('tab', { name: 'Settings' });
  await settingsTab.click();

  // 2. Open Language Selector
  const languageBtn = page.getByRole('button', { name: /Language/ });
  await expect(languageBtn).toBeVisible();
  await languageBtn.click();

  // 3. Spotlight both the open selector (or the button that opened it) and the Settings tab
  // Note: Since it's a menu, we might want to spotlight the menu itself if we can find it, 
  // or just the button and the settings tab as requested.

  // Let's wait for the menu to appear
  const spanishOption = page.getByRole('menuitem', { name: 'Spanish' });
  await expect(spanishOption).toBeVisible();

  // Also get the English option to spotlight the whole menu area
  const englishOption = page.getByRole('menuitem', { name: 'English' });
  const systemDefaultOption = page.getByRole('menuitem', { name: 'System Default' });

  // We want to spotlight:
  // 1. The settings tab (to show where we are)
  // 2. The language selector menu area
  // We can use the container of the menu items or just spotlight the items
  await spotlightMultiple(page, [
    { locator: page.locator('flt-semantics[role="tab"][aria-label="Settings"]').first(), description: 'Settings Tab' },
    { locator: systemDefaultOption, description: 'Language Menu' },
    { locator: spanishOption },
    { locator: englishOption }
  ]);

  // Take screenshot
  await page.waitForTimeout(1000); // Wait for animations
  await page.screenshot({ path: 'generated-assets/language-selector.png' });

  await clearHighlights(page);
});
