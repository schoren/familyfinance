import { test, expect } from '@playwright/test';

test('Record Demo Video', async ({ page }) => {
  page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));

  await page.goto('/');
  // Wait for Flutter to be ready
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
  await page.waitForTimeout(3000); // Wait for initial load

  // 1. Dashboard Overview
  console.log('Step 1: Dashboard Overview');
  await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeVisible();
  await page.waitForTimeout(2000);

  // 2. Add New Expense
  console.log('Step 2: Add New Expense');
  // Use the working locator from user's example
  await page.getByRole('group', { name: /Supermarket/i }).click();

  // New Expense Screen
  await expect(page.getByRole('textbox', { name: 'Amount' })).toBeVisible();
  await page.getByRole('textbox', { name: 'Amount' }).fill('100');
  await page.getByRole('textbox', { name: 'Note (optional)' }).fill('Weekly grocery shopping');

  await page.waitForTimeout(1000);
  await page.getByRole('button', { name: 'Save Expense' }).click();

  // 3. Verification & Category Details
  console.log('Step 3: Verification & Details');
  // Check updated balance on dashboard
  await expect(page.getByRole('group', { name: /Supermarket \$342\.20/i })).toBeVisible();

  // Navigate to category details via the menu
  const supermarketCard = page.getByRole('group', { name: /Supermarket/i });
  await supermarketCard.getByRole('button').click();
  await page.getByRole('menuitem', { name: 'View Detail' }).click();

  // Wait for Detail screen header
  await expect(page.getByRole('heading', { name: 'Supermarket' })).toBeVisible();
  await page.waitForTimeout(3000); // Buffer for video to show history

  // 4. Home Navigation & Summary Listing
  console.log('Step 4: Home Navigation & Summary Listing');

  // Go back to Home using the bottom navigation bar
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeVisible();

  // Click on the summary card to see all expenses
  await page.getByRole('button', { name: /Budget|Spent/i }).click();

  // Verify redirected to "All Expenses"
  await expect(page.getByRole('heading', { name: 'All Expenses' })).toBeVisible();
  await page.waitForTimeout(3000); // Final buffer
});
