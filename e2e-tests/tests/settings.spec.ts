import { test, expect } from '@playwright/test';

test.describe('Keda E2E Settings and Budgets', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

    const loginButton = page.getByRole('button', { name: /Sign in with Google|Google/i });
    if (await loginButton.count() > 0) {
      await loginButton.click();
    }

    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 15000 });
  });

  test('Change monthly budget of a category and verify dashboard', async ({ page }) => {
    // 1. Edit "Supermarket" category budget
    const supermarketCard = page.getByRole('button', { name: /SUPERMARKET|SUPERMERCADO/i }).first();
    await supermarketCard.getByRole('button', { name: /Edit|Editar/i }).click();

    // Select "Edit" / "Editar" from menu
    await page.getByRole('menuitem', { name: /Edit|Editar/i }).click();

    // 2. Change budget
    const budgetInput = page.getByRole('textbox', { name: /Monthly Budget|Presupuesto Mensual/i });
    await budgetInput.fill('5000');
    await page.getByRole('button', { name: /SAVE|GUARDAR/i }).click();

    // 4. Verify dashboard shows updated budget
    await expect(page.getByText('$5,000')).toBeAttached({ timeout: 10000 });
  });

  test('Change language in Settings', async ({ page }) => {
    // 1. Navigate to Settings tab
    await page.getByRole('tab', { name: /Settings|Ajustes/i }).click();

    // 2. Change language to Spanish
    const languageBtn = page.getByRole('button', { name: /Language|Idioma/i });
    await languageBtn.click();

    await page.getByRole('option', { name: /Spanish|Español/i }).click();

    // 3. Verify labels changed to Spanish
    await expect(page.getByRole('button', { name: /Cerrar sesión/i })).toBeAttached();

    // 4. Change back to English
    await page.getByRole('button', { name: /Idioma/i }).click();
    await page.getByRole('option', { name: /English|Inglés/i }).click();

    // 5. Verify labels changed back to English
    await expect(page.getByRole('button', { name: /Logout/i })).toBeAttached();
  });
});
