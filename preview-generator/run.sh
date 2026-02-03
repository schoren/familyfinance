#!/bin/bash
set -e

# Parse command line arguments
SKIP_BUILD=false
TEST_FILTER=""
TIMEOUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --test)
      TEST_FILTER="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--skip-build] [--test <test-name>] [--timeout <ms>]"
      echo "  --skip-build: Skip Docker build step"
      echo "  --test <name>: Run only tests matching the given name"
      echo "  --timeout <ms>: Override test timeout in milliseconds (default: 120000)"
      exit 1
      ;;
  esac
done

if [ "$CI" = "true" ]; then
  echo "📦 Using CI cache..."
  npm ci
else
  echo "📦 Installing dependencies..."
  npm install
  
  echo "Installing Playwright browsers"
  npx playwright install chromium --with-deps
fi

echo "🎥 Starting demo environment..."
# Ensure cleanup of any previous run
docker compose -p keda-preview-generator -f docker-compose.yml down -v 2>/dev/null || true

# Determine if we need to build
BUILD_FLAG=""
if [ "$SKIP_BUILD" = false ]; then
  if [[ "${SERVER_IMAGE}" == "" && "${CLIENT_IMAGE}" == "" ]]; then
    echo "🐳 No images provided via environment, will build from source..."
    BUILD_FLAG="--build"
  fi
else
  echo "⏭️  Skipping build (--skip-build flag set)"
fi

echo "🔨 Starting containers..."
docker compose -p keda-preview-generator -f docker-compose.yml up -d $BUILD_FLAG --remove-orphans

echo "⏳ Waiting for client to be ready..."
# We wait for client (8085) 
timeout 60 bash -c 'until curl -sf http://localhost:8085 > /dev/null 2>&1; do sleep 2; done' || \
    (echo "❌ Client failed to start" && docker compose -p keda-preview-generator -f docker-compose.yml down -v && exit 1)
echo "✅ Demo environment ready at http://localhost:8085"

echo "🎬 Generating assets..."

# Build Playwright command with optional flags
PW_CMD="npx playwright test --trace on"
if [ -n "$TEST_FILTER" ]; then
  echo "🎯 Running tests matching: $TEST_FILTER"
  PW_CMD="$PW_CMD -g \"$TEST_FILTER\""
fi
if [ -n "$TIMEOUT" ]; then
  echo "⏱️  Using timeout: ${TIMEOUT}ms"
  PW_CMD="$PW_CMD --timeout $TIMEOUT"
fi

set +e
eval $PW_CMD
TEST_EXIT_CODE=$?
set -e

echo "🛑 Stopping demo environment..."
docker compose -p keda-preview-generator -f docker-compose.yml down -v

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ Assets generated."
  # Playwright saves assets in generated-assets/<test-name>/video.webm or screenshot.png
  echo "📋 Consolidating assets..."
  
  find generated-assets -mindepth 2 \( -name "*.webm" -o -name "*.png" \) | while read -r asset; do
    DIR_NAME=$(basename "$(dirname "$asset")")
    EXT="${asset##*.}"
    
    # Simple approach: extract test name after known prefixes
    # 1. Remove browser suffix
    # 2. Remove trailing hash (5 hex chars)
    # 3. Extract name after known prefix patterns
    # 4. Remove embedded hashes
    TEST_NAME=$(echo "$DIR_NAME" \
      | sed -E 's/-(Chromium|Firefox|WebKit)$//' \
      | sed -E 's/-[a-f0-9]{5}$//' \
      | sed -E 's/^.*-(Video-Assets|Screenshots|from-Login|screenshot)-//' \
      | sed -E 's/-[a-f0-9]{5}-/-/' \
      | sed -E 's/^-+|-+$//g')
    
    # Special cases
    if [[ "$DIR_NAME" == demo-* ]]; then
      TEST_NAME="demo"
    elif [[ "$DIR_NAME" == *"ecommendations-notification"* ]]; then
      TEST_NAME="recommendations-notification"
    # If no prefix matched, try removing common test suite prefixes
    elif [[ "$TEST_NAME" == "$DIR_NAME" ]] || [[ "$TEST_NAME" == *"docs-assets"* ]] || [[ "$TEST_NAME" == *"Video"* ]]; then
      TEST_NAME=$(echo "$DIR_NAME" \
        | sed -E 's/-(Chromium|Firefox|WebKit)$//' \
        | sed -E 's/-[a-f0-9]{5}$//' \
        | sed -E 's/^(docs-assets-|demo-|new-expense-screenshot-|language-selector-screenshot-)//g' \
        | sed -E 's/^Documentation-//' \
        | sed -E 's/-[a-f0-9]{5}-/-/' \
        | sed -E 's/^-+|-+$//g')
    fi
    
    if [ -n "$TEST_NAME" ] && [ "$TEST_NAME" != "-" ]; then
      cp "$asset" "generated-assets/${TEST_NAME}.${EXT}"
    fi
  done
  
  # 3. Cleanup: remove individual test directories
  find generated-assets -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

  echo "📦 Assets consolidated and cleaned up in generated-assets/"
else
  echo "❌ Asset generation failed with exit code $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE
