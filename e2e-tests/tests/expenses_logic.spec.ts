import { test, expect } from '@playwright/test';

test.describe('Keda E2E Expense Logic', () => {
  test('Suggested notes are shown correctly after previous expenses', async ({ page }) => {
    // 1. Login
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

    const loginButton = page.getByRole('button', { name: /Sign in with Google|Google/i });
    if (await loginButton.count() > 0) {
      await loginButton.click();
    }

    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 15000 });

    // 2. Add an expense with a specific note "Pizza Night"
    const supermarketBtn = page.getByRole('button', { name: /Supermarket|Supermercado/i }).first();
    await supermarketBtn.waitFor({ state: 'attached', timeout: 10000 });
    await supermarketBtn.click();

    await page.getByRole('textbox', { name: /Amount|Monto/i }).fill('15.00');
    await page.getByRole('textbox', { name: /Note|Nota/i }).fill('Pizza Night');
    await page.getByRole('button', { name: /Save|Guardar/i }).click();

    // 3. Open the add expense screen again for the same category
    await supermarketBtn.waitFor({ state: 'attached', timeout: 10000 });
    await supermarketBtn.click();

    // 4. Verify "Pizza Night" appears in suggested notes
    const suggestion = page.getByRole('button', { name: 'Pizza Night' });
    await expect(suggestion).toBeAttached({ timeout: 10000 });

    // 5. Click the suggestion and verify it fills the note input
    await suggestion.click();
    await expect(page.getByRole('textbox', { name: /Note|Nota/i })).toHaveValue('Pizza Night');

    console.log('✅ Suggested notes E2E verified');
  });
});
