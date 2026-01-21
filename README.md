# Keda

A simple application for family finances, allowing expense tracking by categories and collaboration between household members.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start (Development)

The fastest way to get started is using the included `Makefile`:

1.  **Configure Environment**:
    ```bash
    cp .env.example .env
    # Edit .env with your settings (JWT_SECRET, Google Auth, etc.)
    ```

2.  **Start Environment**:
    ```bash
    make dev-up
    ```

3.  **Access Services**:
    - **Frontend (Web):** [http://localhost:8080](http://localhost:8080)
    - **Backend (API):** [http://localhost:8090](http://localhost:8090)
    - **Mailpit:** [http://localhost:8025](http://localhost:8025)

## Automation & Tools

This project uses a `Makefile` to centralize all common tasks.

### Android Development

1.  **Setup Environment**:
    Run the setup script to install Java and configure the Android SDK:
    ```bash
    make android-setup
    ```

2.  **Run on Device/Emulator**:
    Connect a device or start an emulator, then run:
    ```bash
    make android-run
    ```

3.  **Build APK**:
    ```bash
    make android-build   # Debug
    make android-release # Release
    ```

### Testing
We maintain a comprehensive test suite covering all layers:
```bash
make test             # Run ALL tests (backend + client + e2e + security + lint)
make test-backend     # Go unit tests with coverage
make test-client      # Flutter unit tests with coverage
make test-e2e         # End-to-end integration tests (Video Demo)
make test-quick       # Backend + Client only (skips slow E2E)
```

### Code Quality (Linting)
Ensure code follows project standards:
```bash
make lint             # Runs all linters
make lint-backend     # golangci-lint for Go server
make lint-client      # flutter analyze for the mobile/web app
```

### Security
Automated security scans for all components:
```bash
make security-check         # Runs ALL security scans
make security-check-gosec   # Go security analysis
make security-check-client  # Trivy scan for client vulnerabilities
make security-check-server  # Trivy scan for server vulnerabilities
make security-check-mobsf   # MobSF static analysis (Mobile security)
make security-check-landing # npm audit for landing page
```

### Landing Page
Tooling for the localized landing page:
```bash
make landing-build    # Build localized landing page
make landing-serve    # Serve landing page locally at http://localhost:3000
```

### Maintenance
```bash
make help             # Show all available commands
make dev-down         # Stop development environment
make clean            # Remove test artifacts and clean workspace
```

## Documentation
- [E2E Testing Guide](E2E_TESTING.md) - How E2E tests work and test authentication
- [Docker Compose Guide](DOCKER_COMPOSE_GUIDE.md) - Differences between dev and test environments
- [Style Guide](STYLE_GUIDE.md) - Coding standards and best practices

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for more details.
