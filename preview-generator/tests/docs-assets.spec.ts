import { test, expect } from '@playwright/test';
import { setupMarketingPage } from './helpers';

test.describe('Documentation Video Assets', () => {
  test.beforeEach(async ({ page }) => {
    await setupMarketingPage(page);
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

    await page.waitForTimeout(2000);
  });

  test('server-config-flow', async ({ page }) => {
    // Navigate to Settings
    const tab = page.getByLabel('Settings').first();
    await tab.click();

    // Click Server URL item - specify that we want the button/listitem
    const serverUrlItem = page.getByRole('button', { name: /Server URL/i }).first();
    await serverUrlItem.click();

    // Fill new URL - wait for it to be visible first
    const urlInput = page.getByRole('textbox', { name: /Server URL/i });
    await urlInput.waitFor({ state: 'visible' });

    // Clear and type - for Flutter Web, clicking and pressing keys one by one is better
    // Triple click to select all text, then backspace
    await urlInput.click({ clickCount: 3 });
    await page.keyboard.press('Backspace');
    await urlInput.pressSequentially('https://mykeda.example.com', { delay: 100 });

    // Save
    const saveBtn = page.getByRole('button', { name: /SAVE/i });
    await saveBtn.click();

    // Verify it navigated back (the input field should be gone)
    await expect(urlInput).not.toBeVisible();
    // And we should be back at Settings
    await expect(page.getByRole('heading', { name: /Settings/i })).toBeVisible();

    await page.waitForTimeout(1000);
  });
});

test.describe('Documentation Screenshots', () => {
  test.beforeEach(async ({ page }) => {
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
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'generated-assets/members.png' });
  });

  test('settings-view', async ({ page }) => {
    const tab = page.getByLabel('Settings').first();
    await tab.click();
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'generated-assets/settings.png' });
  });

  test('server-url-settings', async ({ page }) => {
    const tab = page.getByLabel('Settings').first();
    await tab.click();

    const serverUrlItem = page.getByRole('button', { name: /Server URL/i }).first();
    await serverUrlItem.click();

    await page.screenshot({ path: 'generated-assets/server-url-settings.png' });
  });

  // test('server-url-login', async ({ page }) => {
  //   // Navigate with forceShowLogin
  //   await page.goto('/login?forceShowLogin=true');
  //   await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
  //   await page.waitForTimeout(3000);

  //   const configBtn = page.getByRole('button', { name: /Set server URL/i });
  //   await configBtn.click();

  //   await page.screenshot({ path: 'generated-assets/server-url-login.png' });
  // });
});
