import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: 'html',

  use: {
    baseURL: process.env.API_URL || 'http://localhost:8090',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: process.env.CI ? undefined : {
    command: 'docker compose -f docker-compose.test.yml up',
    url: 'http://localhost:8090/health',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
