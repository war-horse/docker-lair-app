FROM node:8.2.1 as builder

LABEL maintainer="warhorse@thedarkcloud.net"

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v1.0.1"

EXPOSE 11014

WORKDIR /root/app/build
RUN curl "https://install.meteor.com/?release=1.5.1" | sh
RUN git clone https://github.com/x-a-n-d-e-r-k/lair \
    && cd /root/app/build/lair/app \
    && meteor build --server-only ../releases --allow-superuser

FROM node:8.2.1

WORKDIR /root/app/lair
RUN curl "https://install.meteor.com/?release=1.5.1" | sh
COPY --from=builder /root/app/build/lair/releases/app.tar.gz .
RUN tar -zxf app.tar.gz \ 
    && cd bundle/programs/server \
    && npm i

COPY ./package.json /root/app/lair/bundle/programs/server/package.json

ENV LAIRDB_HOST=lairdb
ENV ROOT_URL=http://0.0.0.0
ENV PORT 11014
ENV MONGO_URL=mongodb://$LAIRDB_HOST:27017/lair
ENV MONGO_OPLOG_URL=mongodb://$LAIRDB_HOST:27017/local

CMD mkdir /scripts
COPY ./docker-entrypoint.sh /scripts/
COPY ./env_secrets_expand.sh /scripts/
COPY ./wait.sh /scripts/
COPY ./startup.js /root/app/lair/bundle/programs/server/app/server/
RUN chown 501:501 /root/app/lair/bundle/programs/server/app/server/startup.js
CMD chmod +x /scripts/docker-entrypoint.sh
CMD chmod +x /scripts/env_secrets_expand.sh 
RUN chmod +x /scripts/wait.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]

STOPSIGNAL SIGKILL

LABEL org.opencontainers.image.ref.name="warhorse/lair-app" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="warhorse <warhorse@thedarkcloud.net>" \
      org.opencontainers.image.documentation="https://github.com/war-horse/docker-lair-app/README.md" \
      org.opencontainers.image.description="lair-app Docker Build" \
      org.opencontainers.image.licenses="GPLv3" \
      org.opencontainers.image.source="https://github.com/war-horse/docker-lair-app" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.url="https://hub.docker.com/r/warhorse/lair-app/"

ENV BUILD_RFC3339 "$BUILD_RFC3339"
ENV COMMIT "$COMMIT"
ENV VERSION "$VERSION"