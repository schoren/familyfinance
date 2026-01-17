import { test, expect } from '@playwright/test';

test.describe('Keda E2E Member Management', () => {
  test('View members and invitation logic', async ({ page }) => {
    // 1. Login
    await page.goto('/');
    await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

    const loginButton = page.getByRole('button', { name: /Sign in with Google|Google/i });
    if (await loginButton.count() > 0) {
      await loginButton.click();
    }

    await page.getByRole('button', { name: /Budget|Spent/i }).waitFor({ state: 'attached', timeout: 15000 });

    // 2. Navigate to Members tab
    const membersTab = page.getByRole('tab', { name: /Members|Miembros/i });
    await membersTab.click();

    // 3. Verify member list
    await expect(page.getByRole('statictext', { name: 'Test User' })).toBeAttached();
    await expect(page.getByRole('statictext', { name: 'test@example.com' })).toBeAttached();

    // 4. Check for Invite button
    const inviteBtn = page.getByRole('button', { name: /Invite|Add Member|Invitar/i });
    if (await inviteBtn.count() > 0) {
      await inviteBtn.click();
      await expect(page.getByRole('statictext', { name: /Invite Code|Invitation|Código/i })).toBeAttached();
    }

    console.log('✅ Member management E2E verified');
  });
});
