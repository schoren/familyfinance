# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.12.x  | :white_check_mark: |
| < 0.12  | :x:                |

## Reporting a Vulnerability

Use this section to explain how user should report a vulnerability.

We take the security of this project seriously. If you find any vulnerabilities, please report them to us immediately.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please send an email to [security@keda.app](mailto:security@keda.app). We will aim to respond within 48 hours.

## Security Measures

### Static Analysis
We use `gosec` to perform automated security audits of our Go code. This is integrated into our CI/CD pipeline and local development workflow (`make security-check`).

### Authentication & Authorization
- All API endpoints (except login) are protected by JWT authentication.
- Middleware enforces strict checks:
  - User existence in the database.
  - Active status (not soft-deleted).
  - Membership in the accessed household.
  - Verification that the token's household claim matches the URL resource.

### Data Protection
- Household data is logically isolated.
- Users can only access data belonging to their assigned household.
