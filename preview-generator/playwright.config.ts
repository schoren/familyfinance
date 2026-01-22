import { defineConfig, devices } from '@playwright/test';

const TIMEOUT = 120_000;

export default defineConfig({
  testDir: './tests',
  outputDir: './generated-assets',
  timeout: TIMEOUT,
  workers: 1,
  reporter: 'list',

  use: {
    baseURL: 'http://localhost:8085',
    video: 'on',
    trace: 'off',
    launchOptions: {
      slowMo: 1000,
    },
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'Chromium',
      use: {
        ...devices['Pixel 5'],
        deviceScaleFactor: 2,
      },
    },
  ],
});
