# Preserve Caddy's version while applying fixed library/toolchain releases.
FROM golang:1.27.1-alpine3.23 AS builder
ENV CGO_ENABLED=0 GOTOOLCHAIN=local
WORKDIR /build
RUN go mod init maia-caddy && go get github.com/caddyserver/caddy/v2@v2.11.4 golang.org/x/crypto@v0.55.0 golang.org/x/net@v0.56.0 golang.org/x/text@v0.39.0 google.golang.org/grpc@v1.83.1 && go build -trimpath -o /out/caddy github.com/caddyserver/caddy/v2/cmd/caddy
FROM caddy:2.11.4-alpine
RUN apk upgrade --no-cache
COPY --from=builder /out/caddy /usr/bin/caddy
