.PHONY: help test test-backend test-client test-e2e test-all clean dev-up dev-down test-up test-down

TEST_COMPOSE_PROJECT := keda-test
TEST_SERVER_PORT := 8091

DEV_DOCKER_COMPOSE := docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml

# Use timestamp as version for development to facilitate testing update notifications
export APP_VERSION ?= dev-$(shell date +%Y%m%d%H%M%S)

# Default target
help:
	@echo "Keda - Project Automation"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  🚀 Development"
	@echo "    make dev-up          - Start development environment"
	@echo "    make dev-down        - Stop development environment"
	@echo "    make dev-restart     - Restart development environment"
	@echo "    make dev-rebuild     - Rebuild and start development environment"
	@echo "    make dev-clean       - Stop and remove development volumes"
	@echo ""
	@echo "  🧪 Testing"
	@echo "    make test            - Run all tests (backend + client + e2e + security + lint)"
	@echo "    make test-quick      - Run backend + client tests (skip slow E2E)"
	@echo "    make test-backend    - Run backend unit tests with coverage"
	@echo "    make test-client     - Run client unit tests with coverage"
	@echo "    make test-e2e        - Run E2E integration tests (Preview Generator)"
	@echo "    make test-android-integration - Run Android integration tests (needs emulator)"
	@echo ""
	@echo "  🔍 Code Quality"
	@echo "    make lint            - Run all linters (backend + client)"
	@echo "    make lint-backend    - Run Go linters (golangci-lint)"
	@echo "    make lint-client     - Run Flutter analyzer"
	@echo ""
	@echo "  🛡️  Security"
	@echo "    make security-check  - Run all security scans"
	@echo "    make security-check-gosec   - Static analysis for Go"
	@echo "    make security-check-client  - Trivy scan for client"
	@echo "    make security-check-server  - Trivy scan for server"
	@echo "    make security-check-mobsf   - MobSF static analysis"
	@echo "    make security-check-landing - npm audit for landing page"
	@echo ""
	@echo "  🌐 Landing Page"
	@echo "    make landing-build   - Build localized landing page"
	@echo "    make landing-serve   - Serve landing page locally"
	@echo ""
	@echo "  ⚙️  Infrastructure"
	@echo "    make build           - Build backend and client Docker images"
	@echo "    make test-up         - Start test environment"
	@echo "    make test-down       - Stop test environment"
	@echo ""
	@echo "  🧹 Maintenance"
	@echo "    make clean           - Clean all test artifacts and containers"
	@echo "    make help            - Show this help message"
	@echo ""
	@echo "  📱 Android"
	@echo "    make android-setup   - Setup Android environment (Java, SDK)"
	@echo "    make android-build   - Build Android APK (debug)"
	@echo "    make android-release - Build Android APK (release)"
	@echo "    make android-run     - Run Android app on connected device/emulator"
	@echo "    make android-clean   - Clean Android build artifacts"
	@echo ""

# Backend tests
test-backend:
	@echo "🧪 Running backend tests..."
	cd server/app && go test -v -coverprofile=coverage.out .
	@echo ""
	@echo "📊 Coverage report:"
	cd server/app && go tool cover -func=coverage.out

security-check: security-check-gosec security-check-client security-check-server security-check-mobsf security-check-landing

lint: lint-backend lint-client

# Security Check
security-check-gosec:
	@echo "🛡️  Running security check..."
	@if command -v gosec >/dev/null 2>&1; then \
		cd server && gosec -fmt=golint ./...; \
	elif docker info >/dev/null 2>&1; then \
		echo "Using Docker for gosec..."; \
		docker run --rm -it -w /app -v $(PWD)/server:/app securego/gosec /app/...; \
	else \
		echo "⚠️  gosec not found and Docker not available. Please install gosec: go install github.com/securego/gosec/v2/cmd/gosec@latest"; \
		exit 1; \
	fi


# Client Security Check
security-check-client:
	@echo "🛡️  Running client security check..."
	@if docker info >/dev/null 2>&1; then \
		echo "Using Docker for Trivy..."; \
		docker run --rm -v $(PWD)/client:/app -w /app aquasec/trivy:latest fs . --scanners vuln,secret,misconfig; \
	else \
		echo "⚠️  Docker not available. Skipping Trivy scan."; \
		exit 1; \
	fi

# Server Security Check (Container/FS)
security-check-server:
	@echo "🛡️  Running server container security check..."
	@if docker info >/dev/null 2>&1; then \
		echo "Using Docker for Trivy..."; \
		docker run --rm -v $(PWD)/server:/app -w /app aquasec/trivy:latest fs . --scanners vuln,secret,misconfig; \
	else \
		echo "⚠️  Docker not available. Skipping Trivy scan."; \
		exit 1; \
	fi

# MobSF Security Check (Source Code)
security-check-mobsf:
	@echo "🛡️  Running MobSF static analysis..."
	@if docker info >/dev/null 2>&1; then \
		echo "Using Docker for mobsfscan..."; \
		docker run --rm -v $(PWD):/code opensecurity/mobsfscan:latest /code; \
	else \
		echo "⚠️  Docker not available. Skipping MobSF scan."; \
		exit 1; \
	fi

# Server Linting
lint-backend:
	@echo "🔍 Running Go linters..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		cd server && golangci-lint run ./...; \
	else \
		echo "⚠️  golangci-lint not found. Skipping."; \
		exit 1; \
	fi

# Client Linting
lint-client:
	@echo "🔍 Running Flutter analyzer..."
	cd client && flutter analyze || echo "⚠️  Flutter analyzer found issues. Please review details above."

# Landing Page Security
security-check-landing:
	@echo "🛡️  Running npm audit for landing page..."
	cd landing && npm audit

# Client tests
test-client:
	@echo "🧪 Running client tests..."
	cd client && flutter test --coverage
	@echo ""
	@echo "📊 Coverage summary:"
	@cd client && \
		TOTAL=$$(grep "LF:" coverage/lcov.info | cut -d: -f2 | awk '{s+=$$1} END {print s}') && \
		HIT=$$(grep "LH:" coverage/lcov.info | cut -d: -f2 | awk '{s+=$$1} END {print s}') && \
		echo "Total Lines: $$TOTAL" && \
		echo "Hit Lines: $$HIT" && \
		echo "Coverage: $$(echo "scale=1; $$HIT * 100 / $$TOTAL" | bc)%"

test-e2e:
	@echo "🧪 Running E2E / Preview Generator tests..."
	@cd preview-generator && ./run.sh

# Android Integration tests
test-android-integration:
	@echo "🧪 Running Android Integration tests..."
	@./scripts/ensure_emulator.sh
	@cd client && flutter test integration_test/app_test.dart \
		--dart-define=API_URL=http://10.0.2.2:8090 \
		--dart-define=TEST_MODE=true \
		--dart-define=INTEGRATION_TEST=true \
		--dart-define=MOCK_DATA=true

# Run all tests
test-all: test-backend test-client test-e2e security-check lint
	@echo ""
	@echo "✅ All tests completed successfully!"

test: test-all

# Development environment
dev-up:
	@echo "🚀 Starting development environment..."
	$(DEV_DOCKER_COMPOSE) up -d
	@echo "✅ Development environment started"
	@echo "   Client: $$(grep '^APP_URL=' .env.dev | cut -d '=' -f2)"
	@echo "   Server: $$(grep '^API_URL=' .env.dev | cut -d '=' -f2)"
	@echo "   Mailpit: http://localhost:8025"

dev-rebuild:
	@echo "🔨 Rebuilding development environment..."
	$(DEV_DOCKER_COMPOSE) up -d --build

dev-restart:
	@echo "🔨 Restarting development environment..."
	$(DEV_DOCKER_COMPOSE) restart

dev-down:
	@echo "🛑 Stopping development environment..."
	$(DEV_DOCKER_COMPOSE) down

dev-clean:
	@echo "🧹 Cleaning development environment..."
	$(DEV_DOCKER_COMPOSE) down -v

build:
	@echo "🔨 Building images..."
	cd server && docker build -t keda-server:latest --build-arg APP_VERSION=$(APP_VERSION) .
	cd client && docker build -t keda-client:latest --build-arg APP_VERSION=$(APP_VERSION) .

# Test environment
test-up:
	@echo "🧪 Starting test environment..."
	@docker compose -p $(TEST_COMPOSE_PROJECT) -f docker-compose.test.yml down -v 2>/dev/null || true
	@echo "🔨 Building images..."
	@docker compose -p $(TEST_COMPOSE_PROJECT) -f docker-compose.test.yml build
	docker compose -p $(TEST_COMPOSE_PROJECT) -f docker-compose.test.yml up -d --remove-orphans
	@echo "✅ Test environment started"

test-down:
	@echo "🛑 Stopping test environment..."
	docker compose -p $(TEST_COMPOSE_PROJECT) -f docker-compose.test.yml down -v

# Clean everything
clean: dev-down test-down
	@echo "🧹 Cleaning test artifacts..."
	rm -f server/app/coverage.out
	rm -rf client/coverage
	rm -rf client/.dart_tool/build
	@echo "✅ Cleanup complete"

# Quick test (backend + client only, no E2E)
test-quick: test-backend test-client
	@echo ""
	@echo "✅ Quick tests completed!"

# Landing Page
landing-build: docs-build
	@echo "🏗️  Building landing page..."
	cd landing && npm install && npm run build
	@echo "📦 Integrating documentation into landing page..."
	rm -rf landing/dist/docs
	mkdir -p landing/dist/docs
	cp -r docs/.vitepress/dist/* landing/dist/docs/
	@echo "✅ Landing page built in landing/dist"

landing-serve: landing-build
	@echo "🚀 Serving landing page at http://localhost:3000"
	npx serve landing/dist -l 3000

# Documentation
docs-build:
	@echo "🏗️  Building documentation..."
	cd docs && npm install && npx vitepress build
	@echo "✅ Documentation built in docs/.vitepress/dist"

docs-serve:
	@echo "🚀 Serving documentation locally..."
	cd docs && npx vitepress dev --port 3001

# Assets Generation
generate-assets:
	@echo "🎬 Generating visual assets (screenshots/videos)..."
	cd preview-generator && ./run.sh
	@echo "📦 Moving assets to documentation and landing..."
	mkdir -p docs/public/assets landing/assets
	cp preview-generator/generated-assets/*.png docs/public/assets/
	cp preview-generator/generated-assets/*.webm docs/public/assets/ 2>/dev/null || true
	cp preview-generator/generated-assets/dashboard.png landing/assets/ 2>/dev/null || true
	@echo "✅ Assets generated and distributed."

# Android Targets
android-setup:
	@echo "🤖 Setting up Android environment..."
	@./scripts/setup_android.sh

android-build:
	@echo "🔨 Building Android APK (Debug)..."
	cd client && flutter build apk --debug

android-release:
	@echo "🚀 Building Android APK (Release)..."
	cd client && flutter build apk --release

android-run:
	@echo "📱 Ensuring Android device/emulator is ready..."
	@./scripts/ensure_emulator.sh
	@echo "📱 Running on Android device..."
	@set -a && . ./.env.dev && set +a && \
	DEVICE_ID=$$(flutter devices | grep "•" | grep -E "mobile|android" | grep -vE "desktop|web|offline" | head -n 1 | awk -F'•' '{print $$2}' | xargs); \
	cd client && flutter run -d $$DEVICE_ID --dart-define=GOOGLE_CLIENT_ID=$$GOOGLE_CLIENT_ID --dart-define=API_URL=$$API_URL

android-clean:
	@echo "🧹 Cleaning Android build..."
	cd client && flutter clean
