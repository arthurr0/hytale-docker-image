FROM eclipse-temurin:25-jre-noble

LABEL maintainer="arthurr0" \
      org.opencontainers.image.title="Hytale Server" \
      org.opencontainers.image.description="Docker image for Hytale dedicated server" \
      org.opencontainers.image.source="https://github.com/arthurr0/hytale-docker-image"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        tzdata \
        procps \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1001 hytale \
    && useradd -u 1001 -g hytale -m -d /home/hytale hytale \
    && mkdir -p /data/logs /data/universe /data/mods /opt/hytale \
    && chown -R hytale:hytale /data /opt/hytale

ENV BIND_ADDRESS="0.0.0.0" \
    BIND_PORT=5520 \
    MEMORY_MODE="percentage" \
    MAX_RAM_PERCENTAGE=75 \
    MEMORY_MIN="" \
    MEMORY_MAX="" \
    STARTUP_TIMEOUT=300 \
    BACKUP_ENABLED="false" \
    BACKUP_FREQUENCY=60 \
    BACKUP_DIR="/data/backups" \
    AUTH_MODE="" \
    DISABLE_SENTRY="false" \
    ALLOW_OP="false" \
    ACCEPT_EARLY_PLUGINS="false" \
    EXTRA_ARGS="" \
    TZ="UTC"

WORKDIR /data

COPY --chown=hytale:hytale docker-entrypoint.sh /docker-entrypoint.sh
COPY --chown=hytale:hytale health.sh /health.sh
COPY --chmod=755 send-to-console /usr/local/bin/send-to-console
RUN chmod +x /docker-entrypoint.sh /health.sh

COPY --chown=hytale:hytale Server/HytaleServer.jar /opt/hytale/HytaleServer.jar
COPY --chown=hytale:hytale Assets.zip /opt/hytale/Assets.zip

EXPOSE 5520/udp

VOLUME ["/data"]

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD /health.sh

USER hytale

ENTRYPOINT ["/docker-entrypoint.sh"]
