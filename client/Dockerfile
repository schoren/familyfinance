# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .
RUN flutter pub get

ARG APP_VERSION=local-dev
RUN flutter build web --dart-define=APP_VERSION=$APP_VERSION

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
  location / { \
  try_files $uri $uri/ /index.html; \
  } \
  }' > /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Replace API_URL_PLACEHOLD and GOOGLE_CLIENT_ID_PLACEHOLD with actual environment variables at runtime
CMD ["/bin/sh", "-c", "sed -i 's|API_URL_PLACEHOLD|'\"${API_URL:-http://localhost:8090}\"'|g; s|GOOGLE_CLIENT_ID_PLACEHOLD|'\"${GOOGLE_CLIENT_ID:-}\"'|g' /usr/share/nginx/html/config.js && nginx -g 'daemon off;'"]
