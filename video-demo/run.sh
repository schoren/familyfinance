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
docker compose -p keda-video-demo -f docker-compose.yml down -v 2>/dev/null || true

# Pull images if they are remote tags, otherwise just use local
if [[ "${SERVER_IMAGE}" != "" ]]; then
  echo "Using server image: ${SERVER_IMAGE}"
fi
if [[ "${CLIENT_IMAGE}" != "" ]]; then
  echo "Using client image: ${CLIENT_IMAGE}"
fi

echo "🔨 Starting containers..."
docker compose -p keda-video-demo -f docker-compose.yml up -d --remove-orphans

echo "⏳ Waiting for client to be ready..."
# We wait for client (8085) 
timeout 60 bash -c 'until curl -sf http://localhost:8085 > /dev/null 2>&1; do sleep 2; done' || \
    (echo "❌ Client failed to start" && docker compose -p keda-video-demo -f docker-compose.yml down -v && exit 1)
echo "✅ Demo environment ready at http://localhost:8085"

echo "🎬 Recording demo video..."
set +e
npx playwright test --trace on
TEST_EXIT_CODE=$?
set -e

echo "🛑 Stopping demo environment..."
docker compose -p keda-video-demo -f docker-compose.yml down -v

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ Assets generated."
  # Playwright saves assets in generated-assets/<test-name>/video.webm or screenshot.png
  
  # 1. Handle videos: rename them to a clean test name to avoid collisions
  # Format is usually: [file-slug]-[title-slug]-[project-name]
  # We try to keep only the [file-slug] part.
  find generated-assets -mindepth 2 -name "*.webm" | while read -r video; do
    DIR_NAME=$(basename "$(dirname "$video")")
    # Remove everything starting from the first capital letter (start of title slug or project)
    # OR from a 5-char hex hash which Playwright sometimes inserts
    CLEAN_NAME=$(echo "$DIR_NAME" | sed 's/-[A-Z].*//; s/-[0-9a-f]\{5\}.*//')
    cp "$video" "generated-assets/${CLEAN_NAME}.webm"
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
