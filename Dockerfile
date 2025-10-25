FROM debian:stable-slim

WORKDIR /app

RUN apt update && apt install fortune-mod cowsay netcat-openbsd -y
ENV PATH="$PATH:/usr/games"

COPY wisecow.sh /app/
RUN chmod +x /app/wisecow.sh

ENTRYPOINT ["/app/wisecow.sh"]
