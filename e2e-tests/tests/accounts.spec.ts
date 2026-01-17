import { test, expect } from '@playwright/test';

test.describe('Keda E2E Account Management', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

    const loginButton = page.getByRole('button', { name: /Sign in with Google|Google/i });
    if (await loginButton.count() > 0) {
      await loginButton.click();
    }

    // Wait for dashboard - check for attachment instead of visibility
    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 15000 });

    // Navigate to Accounts tab
    await page.getByRole('tab', { name: /Accounts|Cuentas/i }).click();
    await page.getByRole('heading', { name: /Manage Accounts|Administrar Cuentas/i }).waitFor({ state: 'attached' });
  });

  test('Verify cash account rules (cannot delete/edit)', async ({ page }) => {
    // 1. Find Cash account row
    const cashRow = page.getByRole('group', { name: /Cash|Efectivo/i }).first();
    await expect(cashRow).toBeAttached();

    // 2. Verify that Edit and Delete buttons are disabled
    const editBtn = cashRow.getByRole('button', { name: /Edit|Editar/i });
    const deleteBtn = cashRow.getByRole('button', { name: /Delete|Eliminar/i });

    await expect(editBtn).toBeDisabled();
    await expect(deleteBtn).toBeDisabled();
  });

  test('Create and delete a custom account', async ({ page }) => {
    // 1. Click Add account (floating action button)
    const addAccountBtn = page.getByRole('button', { name: /New Account|Nueva Cuenta/i });
    await addAccountBtn.click();

    // Wait for the form
    await expect(page.getByRole('heading', { name: /New Account|Nueva Cuenta/i })).toBeAttached();

    // 2. Select Bank type
    await page.getByRole('button', { name: /Type|Tipo/i }).click();
    await page.waitForTimeout(500);
    await page.getByRole('menuitem', { name: /Bank Account|Cuenta Bancaria/i }).click();

    // 3. Fill name
    const nameInput = page.getByRole('textbox', { name: /Account Name|Nombre de la cuenta|Nombre/i });
    await nameInput.pressSequentially('E2E Bank', { delay: 100 });

    // 4. Save
    await page.getByRole('button', { name: /SAVE|GUARDAR/i }).click();

    // 5. Verify it appears in the list
    await expect(page.getByRole('group', { name: /E2E Bank/i })).toBeAttached();

    // 6. Delete it
    const bankRow = page.getByRole('group', { name: /E2E Bank/i }).first();
    await bankRow.getByRole('button', { name: /Delete|Eliminar/i }).click();

    // 7. Confirm deletion
    await expect(page.getByRole('generic', { name: /Delete Account|Eliminar cuenta/i })).toBeAttached();
    await page.getByRole('button', { name: /Delete|Eliminar/i }).click();

    // 8. Verify it's gone
    await expect(page.getByRole('group', { name: /E2E Bank/i })).not.toBeAttached();
  });
});
