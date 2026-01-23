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
    await page.waitForTimeout(2000);

    const addBtn = page.getByRole('button', { name: /New Account/i });
    await addBtn.click();
    await page.waitForTimeout(1000);

    // Default is Card, which has "Bank" field
    const bankInput = page.getByRole('textbox', { name: /Bank/i });
    await bankInput.pressSequentially('Modern Bank');

    const saveBtn = page.getByRole('button', { name: /SAVE/i });
    await saveBtn.click();

    await page.waitForTimeout(2000);
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
});
