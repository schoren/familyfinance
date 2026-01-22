import { test, expect } from '@playwright/test';
import { setupMarketingPage, highlight, clearHighlights } from './helpers';

test.describe('Documentation Assets', () => {
  test.beforeEach(async ({ page }) => {
    await setupMarketingPage(page);
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
    // Wait for the app to load
    await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeVisible({ timeout: 30000 });
  });

  test('dashboard-screenshot', async ({ page }) => {
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'generated-assets/dashboard.png' });
  });

  test('new-expense-flow', async ({ page }) => {
    const supermarketBtn = page.getByRole('group', { name: /Supermarket/i });
    await highlight(page, supermarketBtn, "Click on a category to add an expense");
    await supermarketBtn.click();
    await clearHighlights(page);

    const amountInput = page.getByRole('textbox', { name: 'Amount' });
    await expect(amountInput).toBeVisible();
    await highlight(page, amountInput, "Enter the amount");
    await amountInput.fill('42.50');
    await clearHighlights(page);

    const noteInput = page.getByRole('textbox', { name: 'Note (optional)' });
    await highlight(page, noteInput, "Add a description");
    await noteInput.fill('Dinner with friends');
    await clearHighlights(page);

    const saveBtn = page.getByRole('button', { name: 'Save Expense' });
    await highlight(page, saveBtn, "Save your expense");
    await saveBtn.click();

    await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeVisible();
    await page.screenshot({ path: 'generated-assets/expense-added.png' });
  });

  test('categories-flow', async ({ page }) => {
    const addBtn = page.getByRole('button', { name: 'New Category' });
    await highlight(page, addBtn, "Click here to add a new category");
    await addBtn.click();
    await clearHighlights(page);

    // Try to find the heading or the text "New Category"
    await expect(page.getByText('New Category')).toBeVisible({ timeout: 10000 });
    await page.screenshot({ path: 'generated-assets/categories.png' });
    const backBtn = page.locator('button').filter({ hasText: 'back' }).or(page.getByRole('button', { name: 'back' }));
    await backBtn.click();
  });

  test('accounts-screenshot', async ({ page }) => {
    const tab = page.getByRole('tab', { name: 'Accounts' });
    await tab.click();
    await expect(page.getByRole('heading', { name: 'Accounts' })).toBeVisible();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'generated-assets/accounts.png' });
  });

  test('members-screenshot', async ({ page }) => {
    const tab = page.getByRole('tab', { name: 'Members' });
    await tab.click();
    await expect(page.getByRole('heading', { name: 'Members' })).toBeVisible();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'generated-assets/members.png' });
  });

  test('settings-screenshot', async ({ page }) => {
    const tab = page.getByRole('tab', { name: 'Settings' });
    await tab.click();
    await expect(page.getByText('Language')).toBeVisible();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'generated-assets/settings.png' });
  });
});
