import { test, expect } from '@playwright/test';
import { setupMarketingPage } from './helpers';

test('new-expense', async ({ page }) => {
  await setupMarketingPage(page);
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
