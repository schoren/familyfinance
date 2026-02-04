import { test, expect } from '@playwright/test';
import { highlight, clearHighlights, setupMarketingPage, mockDate } from './helpers';

test('Record Demo Video', async ({ page }) => {
  await setupMarketingPage(page);

  page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));

  // Mock recommendations to be empty for general tests
  await page.route('**/recommendations', async route => {
    await route.fulfill({ status: 200, body: JSON.stringify({ suggestions: [] }) });
  });

  // Mock date to 15th to hide recommendations (persistent)
  await mockDate(page, '2026-02-15T12:00:00');

  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

  // 1. Dashboard Overview
  console.log('Step 1: Dashboard Overview');
  const summaryCard = page.getByRole('button', { name: /Budget|Spent/i });
  await highlight(page, summaryCard, "Manage your monthly household budget at a glance");
  await clearHighlights(page);
  await page.waitForTimeout(500);

  // 2. Add New Expense
  console.log('Step 2: Add New Expense');
  const supermarketBtn = page.getByRole('group', { name: /Supermarket/i });
  await highlight(page, supermarketBtn, "Track expenses by clicking on a category");
  await clearHighlights(page);
  await supermarketBtn.click();

  // New Expense Screen - Step 1
  const amountInput = page.getByRole('textbox', { name: /Amount/i });
  await expect(amountInput).toBeVisible();
  await highlight(page, amountInput, "Enter the transaction amount");
  await clearHighlights(page);
  await amountInput.pressSequentially('20.50', { delay: 100 });

  await page.getByRole('button', { name: /ADD DETAILS/i }).click();

  // Step 2
  const noteInput = page.getByRole('textbox', { name: /Note/i });
  await highlight(page, noteInput, "Add an optional description for the expense");
  await clearHighlights(page);
  await noteInput.pressSequentially('Drive-Thru Burger', { delay: 100 });
  await page.waitForTimeout(500);

  await page.getByRole('button', { name: /CHOOSE ACCOUNT/i }).click();

  const saveBtn = page.getByRole('button', { name: /SAVE EXPENSE/i });
  await saveBtn.click();

  // 3. Verification & Category Details
  console.log('Step 3: Verification & Details');
  const updatedSupermarket = page.getByRole('group', { name: /Supermarket \$421\.70/i });
  await expect(updatedSupermarket).toBeVisible();
  await highlight(page, updatedSupermarket, "Budget and totals update automatically");
  await clearHighlights(page);

  // Navigate to category details via the menu
  const menuBtn = page.getByRole('group', { name: /Supermarket/i }).getByRole('button');
  await menuBtn.click();

  const viewDetail = page.getByRole('menuitem', { name: 'View Detail' });
  await highlight(page, viewDetail, "Deep dive into your spending habits");
  await clearHighlights(page);
  await viewDetail.click();

  // Wait for Detail screen header
  await expect(page.getByRole('heading', { name: 'Supermarket' })).toBeVisible();
  await page.waitForTimeout(2000);

  // 4. Home Navigation & Summary Listing
  console.log('Step 4: Home Navigation & Summary Listing');

  // Go back to Home using the Back button
  const backBtn = page.getByRole('button', { name: 'Back' });
  await backBtn.click();

  await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeVisible();
  await page.waitForTimeout(1000);

  // Click on the summary card to see all expenses
  const mainSummary = page.getByRole('button', { name: /Budget|Spent/i });
  await highlight(page, mainSummary, "View all your recent household activity");
  await clearHighlights(page);
  await mainSummary.click();

  // Verify redirected to "All Expenses"
  await expect(page.getByRole('heading', { name: 'All Expenses' })).toBeVisible();
  await page.waitForTimeout(1000);

  // Go back to Home using the Back button
  const backBtn2 = page.getByRole('button', { name: 'Back' });
  await backBtn2.click();
  await page.waitForTimeout(1000);
});
