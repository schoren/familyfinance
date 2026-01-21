FROM golang:1.24 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG APP_VERSION=local-dev
RUN CGO_ENABLED=0 go build -o server -ldflags "-X main.Version=${APP_VERSION}" .

FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/server .

ENV PORT=8090
EXPOSE 8090

CMD ["./server"]
