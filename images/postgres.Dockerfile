# Rebuild gosu with a patched Go toolchain; upstream 1.19 binaries used Go 1.24.6.
FROM golang:1.27.1-alpine3.23 AS gosu
ENV CGO_ENABLED=0 GOTOOLCHAIN=local
RUN go install github.com/tianon/gosu@1.19
FROM postgres:17.11-alpine3.23@sha256:9ae4e8f8d0284836a505f0b2e825144e32e20499856e7dc5f7b99e19d10eedd6
RUN apk upgrade --no-cache
COPY --from=gosu /go/bin/gosu /usr/local/bin/gosu
RUN gosu nobody true
