# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .
RUN flutter pub get

ARG GOOGLE_CLIENT_ID
ARG APP_VERSION=local-dev
RUN flutter build web --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID --dart-define=APP_VERSION=$APP_VERSION

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

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
