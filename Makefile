.PHONY: help test test-backend test-client test-e2e test-all clean dev-up dev-down test-up test-down

TEST_COMPOSE_PROJECT := keda-test
TEST_SERVER_PORT := 8091

DEV_DOCKER_COMPOSE := docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml

# Use timestamp as version for development to facilitate testing update notifications
export APP_VERSION ?= dev-$(shell date +%Y%m%d%H%M%S)

# Default target
help:
	@echo "Keda - Test Automation"
	@echo ""
	@echo "Available targets:"
	@echo "  make test-backend    - Run backend unit tests with coverage"
	@echo "  make test-client     - Run client unit tests with coverage"
	@echo "  make test-e2e        - Run E2E integration tests"
	@echo "  make test-all        - Run all tests (backend + client + e2e)"
	@echo "  make test            - Alias for test-all"
	@echo ""
	@echo "  make dev-up          - Start development environment"
	@echo "  make dev-down        - Stop development environment"
	@echo "  make test-up         - Start test environment"
	@echo "  make test-down       - Stop test environment"
	@echo "  make clean           - Clean all test artifacts and containers"

# Backend tests
test-backend:
	@echo "🧪 Running backend tests..."
	cd server/app && go test -v -coverprofile=coverage.out .
	@echo ""
	@echo "📊 Coverage report:"
	cd server/app && go tool cover -func=coverage.out

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

# E2E tests
test-e2e: test-up
	@echo "🧪 Running E2E integration tests..."
	@echo "⏳ Waiting for server to be ready..."
	@timeout 60 bash -c 'until curl -sf http://localhost:$(TEST_SERVER_PORT)/health > /dev/null 2>&1; do sleep 2; done' || \
		(echo "❌ Server failed to start" && make test-down && exit 1)
	@echo "✅ Server is ready"
	@echo ""
	cd e2e-tests && npm install && API_URL=http://localhost:$(TEST_SERVER_PORT) npx playwright test
	@make test-down

# Run all tests
test-all: test-backend test-client test-e2e
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
