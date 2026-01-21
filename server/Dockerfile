FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG APP_VERSION=local-dev
RUN go build -o server -ldflags "-X main.Version=${APP_VERSION}" .

FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/server .

# Hardening: Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8090/health || exit 1

# Hardening: Run as non-root user
RUN adduser -D -g '' appuser
USER appuser

ENV PORT=8090
EXPOSE 8090

CMD ["./server"]
