# E2E Testing Guide

## Overview

This project includes end-to-end tests that run the full application stack using Docker Compose. The tests use a special test authentication endpoint to bypass Google OAuth.

## Test Authentication

When `TEST_MODE=true`, the server exposes a `/auth/test-login` endpoint that creates test users without requiring Google OAuth. This endpoint:

- Only works when `TEST_MODE` environment variable is set to `"true"`
- Creates new users or authenticates existing ones
- Returns the same JWT token format as regular authentication
- Supports invitation codes for multi-user household testing

**⚠️ WARNING**: Never enable `TEST_MODE` in production!

**ℹ️ NOTE**: E2E tests run locally only. They are disabled in GitHub Actions CI because they require a real device/browser which is complex to set up in headless environments. Unit tests (backend + client) run in CI.

## Running E2E Tests Locally

### Prerequisites

- Docker and Docker Compose
- Flutter SDK

### Steps

1. **Start the test environment**:
   ```bash
   docker compose -f docker-compose.test.yml up -d
   ```

2. **Wait for services to be ready**:
   ```bash
   # Check server health
   curl http://localhost:8090/health
   ```

3. **Run the integration tests**:
   ```bash
   cd client
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter test integration_test/ --dart-define=API_URL=http://localhost:8090
   ```

4. **Cleanup**:
   ```bash
   docker compose -f docker-compose.test.yml down -v
   ```

## Test Structure

### Backend Test Auth (`server/app/test_auth.go`)

- `POST /auth/test-login` - Test-only authentication endpoint
- Request body:
  ```json
  {
    "email": "test@example.com",
    "name": "Test User",
    "invite_code": "optional"
  }
  ```
- Response:
  ```json
  {
    "token": "jwt_token_here",
    "user": { ... },
    "household_id": "uuid"
  }
  ```

### Integration Tests (`client/integration_test/`)

- `test_helper.dart` - Helper utilities for E2E tests
  - `loginTestUser()` - Authenticate with test endpoint
  - `createCategory()`, `createAccount()`, `createTransaction()` - API helpers
  - `getMonthlySummary()` - Fetch monthly summary
  - `waitForServer()` - Wait for backend to be ready

- `app_test.dart` - Main E2E test suite
  - Complete user flow: login → create category → add expense → view summary
  - Multi-user household scenarios

## CI/CD

E2E tests run automatically on pull requests via GitHub Actions:

1. Spins up test environment with Docker Compose
2. Waits for services to be healthy
3. Runs Flutter integration tests
4. Shows logs on failure
5. Cleans up containers

The E2E job runs in parallel with unit tests for faster feedback.

## Adding New E2E Tests

1. Add test cases to `client/integration_test/app_test.dart`
2. Use `E2ETestHelper` for common operations
3. Test runs automatically in CI on next PR

## Troubleshooting

### Tests timeout waiting for server

Check Docker logs:
```bash
docker compose -f docker-compose.test.yml logs server
docker compose -f docker-compose.test.yml logs db
```

### Authentication fails

Ensure `TEST_MODE=true` is set in `docker-compose.test.yml` for the server service.

### Database connection errors

The test database runs on port 5433 to avoid conflicts with local development databases.
