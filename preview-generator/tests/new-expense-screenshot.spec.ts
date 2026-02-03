import { test, expect } from '@playwright/test';
import { setupMarketingPage, mockDate } from './helpers';

test('new-expense', async ({ page }) => {
  await setupMarketingPage(page);

  // Mock recommendations to be empty for general tests
  await page.route('**/recommendations', async route => {
    await route.fulfill({ status: 200, body: JSON.stringify({ suggestions: [] }) });
  });

  // Mock date to 15th to hide recommendations (persistent)
  await mockDate(page, '2026-02-15T12:00:00');

  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

  // Add New Expense
  const supermarketBtn = page.getByRole('group', { name: /Supermarket/i });
  await supermarketBtn.click();

  // New Expense Screen
  const amountInput = page.getByRole('textbox', { name: 'Amount' });
  await expect(amountInput).toBeVisible();
  await amountInput.pressSequentially('42.00', { delay: 100 });

  const noteInput = page.getByRole('textbox', { name: 'Note (optional)' });
  await noteInput.click();
  await noteInput.pressSequentially('Weekly groceries', { delay: 100 });

  // Take screenshot
  await page.waitForTimeout(1000); // Wait for animations to settle
  await page.screenshot({ path: 'generated-assets/new-expense.png' });
});
