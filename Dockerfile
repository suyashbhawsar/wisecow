FROM alpine:latest

WORKDIR /app

RUN apk add cowsay --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing && \
    apk add fortune bash netcat-openbsd

COPY wisecow.sh /app/
RUN chmod +x /app/wisecow.sh

ENTRYPOINT ["/app/wisecow.sh"]
