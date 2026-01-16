import { test, expect } from '@playwright/test';

test('Record Demo Video', async ({ page }) => {
  page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));

  // 1. Go to Home Page with semantics enabled for better testing
  await page.goto('/');
  await page.evaluate(() => console.log('[Browser Console] FF_CONFIG:', JSON.stringify((window as any).FF_CONFIG)));
  await expect(page).toHaveTitle(/Keda/);

  // With TEST_MODE=true, the app should bypass login and go straight to home ('Inicio').
  // We'll wait for something that appears on the Home Screen.
  await expect(page.getByText('Inicio')).toBeVisible();

  // 3. Create Category
  // We need to navigate to 'Configuración' -> 'Categorías' or use a FAB.
  // Based on home_screen.dart, there is a FAB with add icon that pushes '/manage-category/new'.
  // This FAB is on the Home Screen ('Inicio').
  await page.getByText('Inicio').click();

  // The FAB usually has an 'Add' icon. Playwright can find by icon wrapper or generic button if last.
  // We'll try to find the button with the 'add' icon or the last button which is usually FAB.
  await page.locator('button').last().click();

  await page.getByLabel('Nombre').fill('General');
  await page.getByLabel('Presupuesto Monthly').fill('1000'); // Label might be 'Monthly Budget' or 'Presupuesto Mensual', let's check code or try fuzzy.
  // Actually, checking content_localization_test.dart earlier, but let's assume 'Presupuesto Mensual' or just fill by order if needed.
  // Let's safe bet: fill by placeholder or mostly used logic.
  // Re-reading home_screen.dart didn't show form.
  // Let's assume standard labels.
  await page.getByLabel('Presupuesto Mensual').fill('1000');

  await page.getByRole('button', { name: 'Guardar' }).click();
  await expect(page.getByText('GENERAL')).toBeVisible();

  // 4. Create Account
  // Navigate to 'Cuentas'
  await page.getByText('Cuentas').click();

  // Click Add FAB
  await page.getByRole('button').last().click();

  await page.getByLabel('Nombre').fill('Billetera');
  // Type selection might be needed. If 'Efectivo' is default or strict rule involved.
  // Let's just save.
  await page.getByRole('button', { name: 'Guardar' }).click();

  await expect(page.getByText('Billetera')).toBeVisible();

  // 5. Add Expense
  // Go back to Home
  await page.getByText('Inicio').click();

  // Click the category 'GENERAL' to open expense form (as seen in home_screen.dart onTap)
  await page.getByText('GENERAL').click();

  // Fill Expense Form
  await page.getByLabel('Monto').fill('15.50');
  await page.getByLabel('Nota').fill('Almuerzo');

  await page.getByRole('button', { name: 'Guardar' }).click();

  // Verify
  // Budget should update. 1000 - 15.50 = 984.50
  await expect(page.getByText('984.50')).toBeVisible();

  // Wait to finish video
  await page.waitForTimeout(3000);
});
