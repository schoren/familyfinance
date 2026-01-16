import { test, expect } from '@playwright/test';

test('Record Demo Video', async ({ page }) => {
  // Helpers for visual effects
  const highlight = async (locator: any, description?: string) => {
    await locator.evaluate((el: HTMLElement, description?: string) => {
      const rect = el.getBoundingClientRect();

      // Container for highight and text
      const container = document.createElement('div');
      container.id = 'demo-highlight-container';
      container.style.position = 'fixed';
      container.style.left = '0';
      container.style.top = '0';
      container.style.width = '100vw';
      container.style.height = '100vh';
      container.style.zIndex = '999999';
      container.style.pointerEvents = 'none';
      document.body.appendChild(container);

      // Dark overlay with a hole (using SVG mask for better effect)
      const overlay = document.createElement('div');
      overlay.style.position = 'absolute';
      overlay.style.width = '100%';
      overlay.style.height = '100%';
      overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.6)';
      overlay.style.maskImage = `radial-gradient(circle at ${rect.left + rect.width / 2}px ${rect.top + rect.height / 2}px, transparent ${Math.max(rect.width, rect.height) / 1.5}px, black ${Math.max(rect.width, rect.height) / 1.5 + 40}px)`;
      overlay.style.webkitMaskImage = overlay.style.maskImage;
      container.appendChild(overlay);

      // Yellow border highlight
      const highlight = document.createElement('div');
      highlight.style.position = 'absolute';
      highlight.style.left = `${rect.left - 4}px`;
      highlight.style.top = `${rect.top - 4}px`;
      highlight.style.width = `${rect.width + 8}px`;
      highlight.style.height = `${rect.height + 8}px`;
      highlight.style.border = '4px solid #FACC15';
      highlight.style.borderRadius = '8px';
      highlight.style.backgroundColor = 'rgba(250, 204, 21, 0.1)';
      container.appendChild(highlight);

      if (description) {
        const text = document.createElement('div');
        text.innerText = description;
        text.style.position = 'absolute';
        text.style.left = '50%';
        text.style.transform = 'translateX(-50%)';
        // If the element is in the bottom half of the screen, show text at the top
        if (rect.top > window.innerHeight / 2) {
          text.style.top = `${rect.top - 80}px`;
        } else {
          text.style.top = `${rect.bottom + 40}px`;
        }
        text.style.color = 'white';
        text.style.backgroundColor = 'rgba(0, 0, 0, 0.8)';
        text.style.padding = '12px 24px';
        text.style.borderRadius = '32px';
        text.style.fontSize = '20px';
        text.style.fontWeight = 'bold';
        text.style.textAlign = 'center';
        text.style.border = '2px solid #FACC15';
        text.style.boxShadow = '0 10px 25px rgba(0,0,0,0.5)';
        text.style.maxWidth = '80%';
        container.appendChild(text);
      }
    }, description);
    await page.waitForTimeout(2500);
    await page.evaluate(() => document.getElementById('demo-highlight-container')?.remove());
  };

  // Click Visualizer: Show a ripple effect on every click
  await page.addInitScript(() => {
    window.addEventListener('click', (e) => {
      const circle = document.createElement('div');
      circle.style.position = 'fixed';
      circle.style.width = '40px';
      circle.style.height = '40px';
      circle.style.borderRadius = '50%';
      circle.style.backgroundColor = 'rgba(250, 204, 21, 0.4)';
      circle.style.border = '2px solid white';
      circle.style.left = `${e.clientX - 20}px`;
      circle.style.top = `${e.clientY - 20}px`;
      circle.style.pointerEvents = 'none';
      circle.style.zIndex = '999999';
      circle.style.transition = 'all 0.5s ease-out';
      document.body.appendChild(circle);
      setTimeout(() => {
        circle.style.transform = 'scale(2.5)';
        circle.style.opacity = '0';
      }, 0);
      setTimeout(() => circle.remove(), 500);
    }, true);
  });

  page.on('console', msg => console.log(`[Browser Console] ${msg.text()}`));

  await page.goto('/');
  // Wait for Flutter to be ready
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
  await page.waitForTimeout(3000);

  // 1. Dashboard Overview
  console.log('Step 1: Dashboard Overview');
  const summaryCard = page.getByRole('button', { name: /Budget|Spent/i });
  await highlight(summaryCard, "Manage your monthly household budget at a glance");
  await page.waitForTimeout(1000);

  // 2. Add New Expense
  console.log('Step 2: Add New Expense');
  const supermarketBtn = page.getByRole('group', { name: /Supermarket/i });
  await highlight(supermarketBtn, "Track expenses by clicking on a category");
  await supermarketBtn.click();

  // New Expense Screen
  const amountInput = page.getByRole('textbox', { name: 'Amount' });
  await expect(amountInput).toBeVisible();
  await highlight(amountInput, "Enter the transaction amount");
  await amountInput.pressSequentially('20.50', { delay: 100 });

  const noteInput = page.getByRole('textbox', { name: 'Note (optional)' });
  await highlight(noteInput, "Add an optional description for the expense");
  await noteInput.click();
  await noteInput.pressSequentially('Drive-Thru Burger', { delay: 100 });
  await page.waitForTimeout(500);

  const saveBtn = page.getByRole('button', { name: 'Save Expense' });
  await saveBtn.click();

  // 3. Verification & Category Details
  console.log('Step 3: Verification & Details');
  const updatedSupermarket = page.getByRole('group', { name: /Supermarket \$421\.70/i });
  await expect(updatedSupermarket).toBeVisible();
  await highlight(updatedSupermarket, "Budget and totals update automatically");

  // Navigate to category details via the menu
  const menuBtn = page.getByRole('group', { name: /Supermarket/i }).getByRole('button');
  await menuBtn.click();

  const viewDetail = page.getByRole('menuitem', { name: 'View Detail' });
  await highlight(viewDetail, "Deep dive into your spending habits");
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
  await highlight(mainSummary, "View all your recent household activity");
  await mainSummary.click();

  // Verify redirected to "All Expenses"
  await expect(page.getByRole('heading', { name: 'All Expenses' })).toBeVisible();
  await page.waitForTimeout(1000);

  // Go back to Home using the Back button
  const backBtn2 = page.getByRole('button', { name: 'Back' });
  await backBtn2.click();
  await page.waitForTimeout(1000);
});
