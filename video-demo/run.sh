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

echo "🔨 Starting containers..."
docker compose -p keda-video-demo -f docker-compose.yml up -d --remove-orphans

echo "⏳ Waiting for client to be ready..."
# We wait for client (8085) 
timeout 60 bash -c 'until curl -sf http://localhost:8085 > /dev/null 2>&1; do sleep 2; done' || \
    (echo "❌ Client failed to start" && docker compose -p keda-video-demo -f docker-compose.yml down -v && exit 1)
echo "✅ Demo environment ready at http://localhost:8085"

echo "🎬 Recording demo video..."
npm install
npx playwright test --trace on
TEST_EXIT_CODE=$?

echo "🛑 Stopping demo environment..."
docker compose -p keda-video-demo -f docker-compose.yml down -v

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✅ Demo video generated in test-results/"
else
  echo "❌ Demo recording failed with exit code $TEST_EXIT_CODE"
fi

exit $TEST_EXIT_CODE
