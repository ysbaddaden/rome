FROM alpine:edge

RUN apk add crystal libc-dev make openssl-dev shards zlib-dev

RUN mkdir -p /usr/src
WORKDIR /usr/src
