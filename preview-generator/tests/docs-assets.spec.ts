import { test, expect } from '@playwright/test';
import { setupMarketingPage, mockDate } from './helpers';

// Helper to get current month name for dynamic button selection
function getCurrentMonthYear(): string {
  const date = new Date();
  const month = date.toLocaleString('en-US', { month: 'long' });
  const year = date.getFullYear();
  return `${month} ${year}`;
}

test.describe('Documentation Video Assets', () => {
  test.beforeEach(async ({ page }) => {
    page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));
    await setupMarketingPage(page);
    // Mock recommendations to be empty for all general tests
    await page.route('**/recommendations', async route => {
      await route.fulfill({ status: 200, body: JSON.stringify({ suggestions: [] }) });
    });
    // Mock date to 15th to hide recommendations by default (persistent)
    await mockDate(page, '2026-02-15T12:00:00');
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    await page.waitForTimeout(5000);
  });

  test('expenses-creation', async ({ page }) => {
    const supermarketBtn = page.getByRole('group', { name: /Supermarket/i });
    await supermarketBtn.first().click();

    // Use pressSequentially as it's more reliable for Flutter Web
    const amountInput = page.getByRole('textbox', { name: /Amount/i });
    await amountInput.pressSequentially('42.50', { delay: 100 });

    const noteInput = page.getByRole('textbox', { name: /Note/i });
    await noteInput.pressSequentially('Personal groceries', { delay: 100 });

    const saveBtn = page.getByRole('button', { name: /Save/i });
    await saveBtn.click();

    await page.waitForTimeout(500);
  });

  test('expenses-editing', async ({ page }) => {
    // Navigate to general expenses list via month summary
    const currentMonth = getCurrentMonthYear();
    const monthSummaryBtn = page.getByRole('button', { name: new RegExp(currentMonth, 'i') });
    await monthSummaryBtn.click();
    await page.waitForTimeout(500);

    // Tap on an expense tile to Edit
    const groceriesTile = page.getByRole('button', { name: /Groceries/i }).first();
    await groceriesTile.click();
    await page.waitForTimeout(500);

    // Update the amount
    const amountInput = page.getByRole('textbox', { name: /Amount/i });
    await amountInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await amountInput.pressSequentially('55.00', { delay: 100 });

    // Update the note
    const noteInput = page.getByRole('textbox', { name: /Note/i });
    await noteInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await noteInput.pressSequentially('Weekly shopping updated', { delay: 100 });

    // Save/Update
    const updateBtn = page.getByRole('button', { name: /Update/i });
    await updateBtn.click();

    await page.waitForTimeout(1000);
  });

  test('expenses-deletion', async ({ page }) => {
    // Navigate to general expenses list via month summary
    const currentMonth = getCurrentMonthYear();
    const monthSummaryBtn = page.getByRole('button', { name: new RegExp(currentMonth, 'i') });
    await monthSummaryBtn.click();
    await page.waitForTimeout(500);

    // Swipe LEFT-TO-RIGHT on an expense tile to Delete
    const groceriesTile = page.getByRole('button', { name: /Groceries/i }).first();
    const pos = await groceriesTile.evaluate((el) => {
      const rect = el.getBoundingClientRect();
      return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2, w: rect.width };
    });

    // Perform swipe gesture
    await page.mouse.move(pos.x - pos.w / 3, pos.y);
    await page.mouse.down();
    await page.mouse.move(pos.x + pos.w / 3, pos.y, { steps: 20 });
    await page.mouse.up();
    await page.waitForTimeout(500);

    // Confirm deletion
    const deleteBtn = page.getByRole('button', { name: /Delete/i }).filter({ hasText: /^Delete$/i });
    await deleteBtn.click();

    await page.waitForTimeout(1000);
  });

  test('categories-creation', async ({ page }) => {
    const addBtn = page.getByRole('button', { name: /New Category/i });
    await addBtn.click();

    const nameInput = page.getByRole('textbox', { name: /Name/i });
    await nameInput.pressSequentially('New Hobby', { delay: 100 });

    const budgetInput = page.getByRole('textbox', { name: /Budget/i });
    await budgetInput.pressSequentially('100', { delay: 100 });

    const saveBtn = page.getByRole('button', { name: /Save/i });
    await saveBtn.click();

    await page.waitForTimeout(500);
  });

  test('accounts-creation', async ({ page }) => {
    // Navigate to Accounts
    const tab = page.getByLabel('Accounts').first();
    await tab.click();

    const addBtn = page.getByRole('button', { name: /New Account/i });
    await addBtn.click();

    const brandDropdown = page.getByRole('button', { name: /Brand/i });
    await brandDropdown.click();

    const mastercardMenuitem = page.getByRole('menuitem', { name: /Mastercard/i });
    await mastercardMenuitem.click();

    const bankInput = page.getByRole('textbox', { name: /Bank/i });
    await bankInput.pressSequentially('Modern Bank');

    const saveBtn = page.getByRole('button', { name: /SAVE/i });
    await saveBtn.click();

    await page.waitForTimeout(1000);
  });

  test('server-url-settings', async ({ page }) => {
    // Navigate to Settings
    const tab = page.getByLabel('Settings').first();
    await tab.click();

    // Click Server URL item
    const serverUrlItem = page.getByRole('button', { name: /Server URL/i }).first();
    await serverUrlItem.click();

    // Fill new URL
    const urlInput = page.getByRole('textbox', { name: /Server URL/i });
    await urlInput.waitFor({ state: 'visible' });

    await urlInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await urlInput.pressSequentially('https://keda.example.com', { delay: 100 });

    // Save
    const saveBtn = page.getByRole('button', { name: /SAVE/i });
    await saveBtn.click();

    await page.waitForTimeout(500);
  });

});

test.describe('Server URL from Login', () => {
  test('server-url-login', async ({ page }) => {
    await setupMarketingPage(page);

    // Navigate with forceShowLogin
    await page.goto('/login?forceShowLogin=true');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    await page.waitForTimeout(3000);

    const configBtn = page.getByRole('button', { name: /Set server URL/i });
    await configBtn.click();

    // Fill new URL
    const urlInput = page.getByRole('textbox', { name: /Server URL/i });
    await urlInput.waitFor({ state: 'visible' });

    await urlInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await urlInput.pressSequentially('https://keda.example.com', { delay: 100 });

    // Save
    const saveBtn = page.getByRole('button', { name: /SAVE/i });
    await saveBtn.click();

    await page.waitForTimeout(500);
  });
});

test.describe('Documentation Screenshots', () => {
  test.beforeEach(async ({ page }) => {
    page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));
    // Mock recommendations to be empty for all general tests
    await page.route('**/recommendations', async route => {
      await route.fulfill({ status: 200, body: JSON.stringify({ suggestions: [] }) });
    });
    // Mock date to 15th to hide recommendations by default (persistent)
    await mockDate(page, '2026-02-15T12:00:00');
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    await page.waitForTimeout(5000);
  });

  test('dashboard-view', async ({ page }) => {
    await page.screenshot({ path: 'generated-assets/dashboard.png' });
  });

  test('members-view', async ({ page }) => {
    const tab = page.getByLabel('Members').first();
    await tab.click();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'generated-assets/members.png' });
  });

  test('settings-view', async ({ page }) => {
    const tab = page.getByLabel('Settings').first();
    await tab.click();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'generated-assets/settings.png' });
  });

  test('recommendations-notification', async ({ page }) => {
    // UNMOCK recommendations for this test
    await page.unroute('**/recommendations');

    // Override the default mock to show recommendations
    await mockDate(page, '2026-02-01T12:00:00');

    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    await page.waitForTimeout(5000);

    // The notification should be visible now
    await page.screenshot({ path: 'generated-assets/recommendations-notification.png' });
  });

  test('recommendations-dialog', async ({ page }) => {
    // UNMOCK recommendations for this test
    await page.unroute('**/recommendations');

    // Override the default mock to show recommendations
    await mockDate(page, '2026-02-01T12:00:00');

    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    await page.waitForTimeout(5000);

    const viewBtn = page.getByRole('button', { name: /View Suggestions|Ver Sugerencias/i });
    await viewBtn.click();
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'generated-assets/recommendations-dialog.png' });
  });

});
