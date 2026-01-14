import { test, expect } from '@playwright/test';

const API_URL = process.env.API_URL || 'http://localhost:8090';

test.describe('E2E Tests', () => {
  test('Complete user flow: login, create category, add expense, view summary', async ({ request }) => {
    // 1. Login with test user
    const loginResponse = await request.post(`${API_URL}/auth/test-login`, {
      data: {
        email: 'e2e-test@example.com',
        name: 'E2E Test User',
      },
    });

    expect(loginResponse.ok()).toBeTruthy();
    const loginData = await loginResponse.json();
    const token = loginData.token;
    const householdId = loginData.household_id;

    expect(token).toBeTruthy();
    expect(householdId).toBeTruthy();
    console.log('✅ Logged in successfully');

    // 2. Create a category
    const categoryResponse = await request.post(
      `${API_URL}/households/${householdId}/categories`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        data: {
          name: 'Food',
          monthly_budget: 500.0,
          is_active: true,
        },
      }
    );

    expect(categoryResponse.ok()).toBeTruthy();
    const category = await categoryResponse.json();
    expect(category.name).toBe('Food');
    expect(category.monthly_budget).toBe(500.0);
    console.log(`✅ Created category: ${category.name}`);

    // 3. Get the auto-created cash account
    const accountsResponse = await request.get(
      `${API_URL}/households/${householdId}/accounts`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      }
    );

    expect(accountsResponse.ok()).toBeTruthy();
    const accounts = await accountsResponse.json();
    const account = accounts.find((a: any) => a.type === 'cash');
    expect(account).toBeTruthy();
    expect(account.name).toBe('Efectivo');
    expect(account.type).toBe('cash');
    console.log(`✅ Using auto-created account: ${account.name}`);

    // 4. Create a transaction
    const transactionResponse = await request.post(
      `${API_URL}/households/${householdId}/transactions`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        data: {
          category_id: category.id,
          account_id: account.id,
          amount: 50.0,
          date: new Date().toISOString(),
          note: 'Groceries',
        },
      }
    );

    expect(transactionResponse.ok()).toBeTruthy();
    const transaction = await transactionResponse.json();
    expect(transaction.amount).toBe(50.0);
    expect(transaction.note).toBe('Groceries');
    console.log(`✅ Created transaction: $${transaction.amount}`);

    // 5. Get monthly summary
    const now = new Date();
    const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const summaryResponse = await request.get(
      `${API_URL}/households/${householdId}/summary/${month}`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      }
    );

    expect(summaryResponse.ok()).toBeTruthy();
    const summary = await summaryResponse.json();

    expect(summary.total_budget).toBe(500.0);
    expect(summary.total_spent).toBe(50.0);
    expect(summary.categories).toHaveLength(1);

    const categorySummary = summary.categories[0];
    expect(categorySummary.name).toBe('Food');
    expect(categorySummary.spent).toBe(50.0);
    expect(categorySummary.remaining).toBe(450.0);

    console.log('✅ Monthly summary verified');
    console.log(`   Budget: $${summary.total_budget}`);
    console.log(`   Spent: $${summary.total_spent}`);
    console.log(`   Remaining: $${categorySummary.remaining}`);
  });

  test('Second user can create their own household', async ({ request }) => {
    // Create a second user with different email
    const loginResponse = await request.post(`${API_URL}/auth/test-login`, {
      data: {
        email: 'user2@example.com',
        name: 'User Two',
      },
    });

    expect(loginResponse.ok()).toBeTruthy();
    const loginData = await loginResponse.json();
    const token = loginData.token;
    const householdId = loginData.household_id;

    expect(token).toBeTruthy();
    expect(householdId).toBeTruthy();
    console.log(`✅ User 2 created household: ${householdId}`);

    // Verify user 2 can create their own category
    const categoryResponse = await request.post(
      `${API_URL}/households/${householdId}/categories`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        data: {
          name: 'User 2 Category',
          monthly_budget: 200.0,
          is_active: true,
        },
      }
    );

    expect(categoryResponse.ok()).toBeTruthy();
    const category = await categoryResponse.json();
    expect(category.name).toBe('User 2 Category');
    expect(category.monthly_budget).toBe(200.0);
    console.log('✅ User 2 created their own category');
  });

  test('Suggested notes are correctly returned for a category', async ({ request }) => {
    // 1. Login
    const loginResponse = await request.post(`${API_URL}/auth/test-login`, {
      data: { email: 'autocomplete@example.com', name: 'Auto User' },
    });
    const loginData = await loginResponse.json();
    const { token, household_id } = loginData;

    // 2. Create category
    const catResponse = await request.post(`${API_URL}/households/${household_id}/categories`, {
      headers: { 'Authorization': `Bearer ${token}` },
      data: { name: 'AutoCat', monthly_budget: 100 },
    });
    const cat = await catResponse.json();

    // 3. Get the auto-created cash account
    const accountsResponse = await request.get(`${API_URL}/households/${household_id}/accounts`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });
    const accounts = await accountsResponse.json();
    const acc = accounts.find((a: any) => a.type === 'cash');
    expect(acc).toBeTruthy();

    // 4. Create transactions with notes
    const notes = ['Pizza', 'Burger', 'Pizza']; // Pizza is duplicate
    for (const note of notes) {
      await request.post(`${API_URL}/households/${household_id}/transactions`, {
        headers: { 'Authorization': `Bearer ${token}` },
        data: {
          category_id: cat.id,
          account_id: acc.id,
          amount: 10,
          date: new Date().toISOString(),
          note: note,
        },
      });
    }

    // 5. Get suggested notes
    const suggestResponse = await request.get(
      `${API_URL}/households/${household_id}/categories/${cat.id}/suggested-notes`,
      { headers: { 'Authorization': `Bearer ${token}` } }
    );

    expect(suggestResponse.ok()).toBeTruthy();
    const suggestedNotes = await suggestResponse.json();

    expect(suggestedNotes).toContain('Pizza');
    expect(suggestedNotes).toContain('Burger');
    expect(suggestedNotes.length).toBe(2); // Unique notes
    console.log('✅ Suggested notes API verified');
  });
});
