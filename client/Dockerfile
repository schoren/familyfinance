# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable BuildKit cache for pub get
RUN --mount=type=cache,target=/root/.pub-cache \
  flutter config --no-analytics

# Copy pubspec files first for dependency caching
COPY pubspec.yaml pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache \
  flutter pub get

# Copy the rest of the source code
COPY . .

ARG APP_VERSION=local-dev
# Build web with cache for pub-cache
RUN --mount=type=cache,target=/root/.pub-cache \
  flutter build web --dart-define=APP_VERSION=$APP_VERSION --pwa-strategy=none

RUN sed -i "s|APP_VERSION_PLACEHOLD|$APP_VERSION|g" build/web/index.html

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx config if needed, or rely on default
# For SPA, we often need to fallback to index.html
RUN echo 'server { \
  listen 80; \
  server_name localhost; \
  root /usr/share/nginx/html; \
  index index.html; \
  \
  # Cache Control for HTML, JS, CSS and Version files (no cache, always re-validate) \
  location ~* \.(?:html|json|js|css)$ { \
  add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0"; \
  expires off; \
  } \
  \
  # Cache Control for Static Assets (long-lived cache for immutable-like assets) \
  location ~* \.(?:png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|otf|wasm)$ { \
  add_header Cache-Control "public, max-age=31536000, immutable"; \
  access_log off; \
  } \
  \
  location / { \
  try_files $uri $uri/ /index.html; \
  } \
  }' > /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Replace placeholders with actual environment variables at runtime
CMD ["/bin/sh", "-c", "sed -i \"s|API_URL_PLACEHOLD|${API_URL:-http://localhost:8090}|g; s|GOOGLE_CLIENT_ID_PLACEHOLD|${GOOGLE_CLIENT_ID:-}|g; s|TEST_MODE_PLACEHOLD|${TEST_MODE:-false}|g; s|TEST_HOUSEHOLD_ID_PLACEHOLD|${TEST_HOUSEHOLD_ID:-}|g\" /usr/share/nginx/html/config.js && nginx -g 'daemon off;'"]
