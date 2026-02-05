# Security Policy

## Reporting a Vulnerability

We take the security of this project seriously. If you find any vulnerabilities, please report them to us immediately.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please send an email to [security@getkeda.app](mailto:security@getkeda.app). We will aim to respond within 48 hours.

## Security Measures

### Automated Security Audits
We integrate multiple security scanning tools into our CI/CD pipeline and local development workflows:
- **Go Security (`gosec`)**: Scans Go source code for security problems.
- **Trivy**: Performs vulnerability, secret, and misconfiguration scans for both the client (Flutter) and server (Go).
- **MobSF Scan**: Used for automated security analysis of the mobile codebase.
- **npm audit**: Regularly checks the landing page dependencies for known vulnerabilities.

### Authentication & Authorization
- All API endpoints (except login and health checks) are protected by JWT authentication.
- Middleware enforces strict checks:
  - User existence in the database.
  - Active status (not soft-deleted).
  - Membership in the accessed household.
  - Verification that the token's household claim matches the URL resource.

### Data Protection
- **Database Encryption at Rest**: Sensitive fields are encrypted at the application level using AES-GCM with unique 96-bit nonces (IVs) for each field.
  - **Encrypted fields**: User emails/names, Household names, Account details, Category names, and Transaction descriptions.
  - **Secure Lookups**: Salted HMAC-SHA256 hashes are used for fields that require indexing or searching (e.g., email lookups during authentication), ensuring privacy even if the database is compromised.
  - **Key Management**: Encryption keys are managed via the `ENCRYPTION_KEY` environment variable. In production, it is recommended to use a secure Secret Manager to inject this key.
- Household data is logically isolated at the database level.
- Users can only access data belonging to their assigned household through enforced server-side filters.
