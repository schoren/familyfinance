#!/bin/bash
set -e

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

# Pull images if they are remote tags, otherwise just use local
BUILD_FLAG=""
if [[ "${SERVER_IMAGE}" == "" && "${CLIENT_IMAGE}" == "" ]]; then
  echo "🐳 No images provided via environment, will build from source..."
  BUILD_FLAG="--build"
fi

echo "🔨 Starting containers..."
docker compose -p keda-preview-generator -f docker-compose.yml up -d $BUILD_FLAG --remove-orphans

echo "⏳ Waiting for client to be ready..."
# We wait for client (8085) 
timeout 60 bash -c 'until curl -sf http://localhost:8085 > /dev/null 2>&1; do sleep 2; done' || \
    (echo "❌ Client failed to start" && docker compose -p keda-preview-generator -f docker-compose.yml down -v && exit 1)
echo "✅ Demo environment ready at http://localhost:8085"

echo "🎬 Generating assets..."
set +e
npx playwright test --trace on
TEST_EXIT_CODE=$?
set -e

echo "🛑 Stopping demo environment..."
docker compose -p keda-preview-generator -f docker-compose.yml down -v

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ Assets generated."
  # Playwright saves assets in generated-assets/<test-name>/video.webm or screenshot.png
  
  find generated-assets -mindepth 2 -name "*.webm" | while read -r video; do
    DIR_NAME=$(basename "$(dirname "$video")")
    # Extract the test name from Playwright's directory format.
    # New logic: remove project name, then remove the hash if present, 
    # then remove known prefixes like Video-Assets or Shortcuts.
    # Also remove the file-name-screenshot- prefix if it matches the test name.
    CLEAN_NAME=$(echo "$DIR_NAME" | sed -E 's/-Chromium.*//; s/-Record.*//; s/.*Video-Assets-//; s/.*Screenshots-//; s/.*Documentation-Video-Assets-//; s/.*Documentation-Screenshots-//; s/-[a-f0-9]{5}-.*//; s/-[a-f0-9]{5}$//; s/^new-expense-screenshot-//; s/^language-selector-screenshot-//')
    mv "$video" "generated-assets/${CLEAN_NAME}.webm"
  done

  # 2. Handle screenshots: consolidated in the root
  find generated-assets -mindepth 2 -name "*.png" -exec cp {} generated-assets/ \;
  
  # 3. Cleanup: remove individual test directories
  find generated-assets -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

  echo "📦 Assets consolidated and cleaned up in generated-assets/"
else
  echo "❌ Asset generation failed with exit code $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE
