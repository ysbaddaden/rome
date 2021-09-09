FROM crystallang/crystal:1.1.1-alpine

# RUN apk add --no-cache crystal libc-dev make openssl-dev shards zlib-dev

RUN mkdir -p /usr/src
WORKDIR /usr/src
