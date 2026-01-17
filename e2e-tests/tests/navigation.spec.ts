import { test, expect } from '@playwright/test';

test.describe('Keda E2E Navigation Flow', () => {
  test('Complete flow: login, add expense, and view summary', async ({ page }) => {
    // 1. Go to the app
    await page.goto('/');

    // Wait for the app to load
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

    // 2. Login as test user
    const loginButton = page.getByRole('button', { name: /Sign in with Google|Google/i });
    if (await loginButton.count() > 0) {
      await loginButton.click();
    }

    // After login, we should see the dashboard
    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 15000 });

    // 3. Click Supermarket category
    const supermarketBtn = page.getByRole('button', { name: /Supermarket|Supermercado/i }).first();
    await supermarketBtn.waitFor({ state: 'attached', timeout: 10000 });
    await supermarketBtn.click();

    // 4. Add an expense
    await page.getByRole('textbox', { name: /Amount|Monto/i }).fill('25.50');
    await page.getByRole('textbox', { name: /Note|Nota/i }).fill('E2E Test Expense');
    await page.getByRole('button', { name: /Save|Guardar/i }).click();

    // 5. Verify back on Dashboard
    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 10000 });

    // 6. View Summary/All Expenses
    await page.getByRole('button', { name: /Budget|Spent/i }).click();

    // Verify expense in list
    await expect(page.getByText('E2E Test Expense')).toBeAttached();
    await expect(page.getByText('$25.50')).toBeAttached();

    // 7. Go back
    await page.getByRole('button', { name: /Back|Volver/i }).click();
    await expect(page.getByRole('button', { name: /Budget|Spent/i })).toBeAttached();
  });
});
