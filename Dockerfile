# Deliberately the newest Alpine release, see README "Available image tags"
# hadolint ignore=DL3007
FROM alpine:latest

LABEL org.opencontainers.image.title="alpinedockersocat" \
      org.opencontainers.image.description="Forwards a TCP port to the Docker socket with socat" \
      org.opencontainers.image.source="https://github.com/moerchel/alpinedockersocat" \
      org.opencontainers.image.licenses="MIT"

# Always the current Alpine release; "apk upgrade" pulls in updates
# published since the base image was built.
# hadolint ignore=DL3018
RUN apk upgrade --no-cache && apk add --no-cache socat

COPY --chmod=755 entrypoint.sh healthcheck.sh /usr/local/bin/

ENV SOCAT_PORT=2375 \
    SOCAT_DEBUG=no

EXPOSE 2375

HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
