import { test, expect } from '@playwright/test';

const API_URL = process.env.API_URL || 'http://localhost:8090';

test.describe('Members API', () => {
  test('Invite a member and verify they appear in the list', async ({ request }) => {
    // 1. Login
    const loginResponse = await request.post(`${API_URL}/auth/test-login`, {
      data: {
        email: 'inviter@example.com',
        name: 'Inviter User',
      },
    });
    expect(loginResponse.ok()).toBeTruthy();
    const loginData = await loginResponse.json();
    const token = loginData.token;
    const householdId = loginData.household_id;

    // 2. Invite a member
    const inviteEmail = 'invited@example.com';
    const inviteResponse = await request.post(
      `${API_URL}/households/${householdId}/invites`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        data: {
          email: inviteEmail,
        },
      }
    );
    if (!inviteResponse.ok()) {
      console.log('Invite failed:', inviteResponse.status(), await inviteResponse.text());
    }
    expect(inviteResponse.ok()).toBeTruthy();

    // 3. Get members list
    const membersResponse = await request.get(
      `${API_URL}/households/${householdId}/members`,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      }
    );
    expect(membersResponse.ok()).toBeTruthy();
    const members = await membersResponse.json();

    // 4. Verify both the inviter and the invited email are in the list
    const inviter = members.find((m: any) => m.email === 'inviter@example.com');
    expect(inviter).toBeTruthy();
    expect(inviter.name).toBe('Inviter User');

    // Check if the invited user is present (this is expected to fail currently)
    const invitedStr = JSON.stringify(members);
    console.log('Members list:', invitedStr);

    const invited = members.find((m: any) => m.email === inviteEmail);
    expect(invited).toBeTruthy();
    expect(invited.status).toBe('pending');
  });
});
