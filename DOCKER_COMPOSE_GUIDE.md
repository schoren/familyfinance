# Docker Compose Configurations

This project has two Docker Compose configurations for different purposes:

## 1. `docker-compose.yml` - Development

**Purpose**: Complete local development environment

**Services**:
- `client` - Flutter frontend (port 8080)
- `server` - Go backend (port 8090)
- `db` - PostgreSQL (port 5432)
- `mailpit` - Test SMTP server (ports 8025 UI, 1025 SMTP)

**Features**:
- ✅ Includes Mailpit for testing email sending
- ✅ Uses development credentials (`postgres/postgres`)
- ✅ Persistent volumes for DB and emails
- ✅ Requires real `GOOGLE_CLIENT_ID` for OAuth
- ✅ Configurable environment variables via `.env`
- ❌ Does NOT have `TEST_MODE` enabled

**Usage**:
```bash
docker compose up -d
# Access:
# - App: http://localhost:8080
# - API: http://localhost:8090
# - Mailpit UI: http://localhost:8025
```

---

## 2. `docker-compose.test.yml` - E2E Testing

**Purpose**: Isolated environment for integration tests

**Services**:
- `client` - Flutter frontend (port 8080)
- `server` - Go backend with `TEST_MODE=true` (port 8090)
- `db` - PostgreSQL on different port (5433)

**Features**:
- ✅ `TEST_MODE=true` enables `/auth/test-login`
- ✅ Port 5433 to avoid conflicts with development DB
- ✅ Test credentials (`test_user/test_password`)
- ✅ Health checks for service synchronization
- ✅ Fixed JWT secret for tests
- ✅ Non-persistent volumes (deleted with `down -v`)
- ❌ Does NOT include Mailpit (emails not tested in E2E)
- ❌ Does NOT require real Google OAuth

**Usage**:
```bash
docker compose -f docker-compose.test.yml up -d
flutter test integration_test/
docker compose -f docker-compose.test.yml down -v
```

---

## Side-by-Side Comparison

| Aspect | Development | Testing |
|---------|-----------|---------|
| **File** | `docker-compose.yml` | `docker-compose.test.yml` |
| **DB Port** | 5432 | 5433 |
| **DB Name** | `keda` | `keda_test` |
| **DB User** | `postgres` | `test_user` |
| **Mailpit** | ✅ Included | ❌ Not included |
| **TEST_MODE** | ❌ Disabled | ✅ Enabled |
| **Health Checks** | ❌ No | ✅ Yes |
| **Volumes** | Persistent | Ephemeral |
| **Google OAuth** | Required | Bypassed with test-login |
| **JWT Secret** | Variable | Fixed for tests |

---

## Why NO Mailpit in Tests?

**Reason 1: E2E Test Scope**
Current E2E tests verify:
- ✅ Authentication
- ✅ CRUD for categories/accounts/transactions
- ✅ Monthly summary calculations

**NOT verified**:
- ❌ Email sending (this is the server's responsibility)
- ❌ Invitation UI (requires complex interaction)

**Reason 2: Unit Tests Cover Emails**
The backend has unit tests for `CreateInvitation` that:
- Verify the DB record is created
- Mock email sending
- Don't require real SMTP

**Reason 3: Simplicity**
- Mailpit adds ~2-3 seconds to startup
- E2E tests don't interact with emails
- Reduces test environment complexity

**If you need to test emails in E2E**:
```yaml
# Add to docker-compose.test.yml
mailpit:
  image: axllent/mailpit
  ports:
    - "8025:8025"
    - "1025:1025"

# And in server:
environment:
  SMTP_HOST: mailpit
  SMTP_PORT: 1025
```

---

## When to Use Each

### Use `docker-compose.yml` when:
- 🔧 Developing new features
- 🐛 Debugging issues
- 📧 Testing email sending manually
- 👀 Need to see the complete app running

### Use `docker-compose.test.yml` when:
- 🧪 Running E2E tests
- 🤖 Running in CI/CD
- ✅ Verifying complete flows without Google OAuth
- 🔄 Need a clean and reproducible environment
