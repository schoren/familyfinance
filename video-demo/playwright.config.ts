import { defineConfig, devices } from '@playwright/test';

const TIMEOUT = 10_000; // 1 second

export default defineConfig({
  testDir: './tests',
  timeout: TIMEOUT,
  workers: 1,
  reporter: 'list',

  use: {
    baseURL: 'http://localhost:8085',
    video: 'on',
    viewport: { width: 1280, height: 720 },
    trace: 'off',
    launchOptions: {
      slowMo: 500,
    }
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  testMatch: 'demo.spec.ts',
});
