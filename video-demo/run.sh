#!/bin/bash
set -e

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

echo "🔨 Starting DB and Server..."
docker compose -p keda-video-demo -f docker-compose.yml up -d db server

echo "⏳ Waiting for server to be ready..."
# We wait for server (8092)
timeout 60 bash -c 'until curl -sf http://localhost:8092/health > /dev/null 2>&1; do sleep 2; done' || \
    (echo "❌ Server failed to start" && docker compose -p keda-video-demo -f docker-compose.yml down -v && exit 1)
echo "✅ Server ready at http://localhost:8092"

echo "🎬 Recording demo video with Patrol..."
# Ensure dependencies are up to date
cd ../client
flutter pub get

# Run patrol test with video recording
# Note: Using absolute path to patrol if not in PATH
PATROL_BIN="$HOME/.pub-cache/bin/patrol"
if ! command -v patrol &> /dev/null; then
    if [ -f "$PATROL_BIN" ]; then
        PATROL="sh $PATROL_BIN" # Sometimes needs sh if not executable or depends on shell
        PATROL="$PATROL_BIN"
    else
        echo "❌ patrol command not found"
        exit 1
    fi
else
    PATROL="patrol"
fi

$PATROL test \
  --target integration_test/demo_test.dart \
  -d chrome \
  --web-video on \
  --web-results-dir ../video-demo/test-results \
  --dart-define=API_URL=http://localhost:8092 \
  --dart-define=TEST_MODE=true \
  --dart-define=TEST_HOUSEHOLD_ID=test-household-id

echo "🛑 Stopping demo environment..."
cd ../video-demo
docker compose -p keda-video-demo -f docker-compose.yml down -v

echo "✅ Demo video generated in video-demo/test-results/"
