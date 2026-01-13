FROM eclipse-temurin:25-jre

LABEL maintainer="Hytale Docker Server" \
      org.opencontainers.image.title="Hytale Server" \
      org.opencontainers.image.description="Docker image for Hytale dedicated server" \
      org.opencontainers.image.source="https://github.com/your-repo/docker-hytale-server"

ENV SERVER_NAME="Hytale Server" \
    MOTD="" \
    MAX_PLAYERS=100 \
    MAX_VIEW_RADIUS=32 \
    DEFAULT_WORLD="default" \
    DEFAULT_GAMEMODE="Adventure" \
    BIND_ADDRESS="0.0.0.0" \
    BIND_PORT=5520 \
    MEMORY_MIN="4G" \
    MEMORY_MAX="8G" \
    BACKUP_ENABLED="false" \
    BACKUP_FREQUENCY=60 \
    BACKUP_DIR="/data/backups" \
    EXTRA_ARGS="" \
    PUID=1000 \
    PGID=1000 \
    TZ="UTC"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    unzip \
    tzdata \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1001 hytale && \
    useradd -u 1001 -g hytale -m -d /home/hytale hytale

WORKDIR /data

RUN mkdir -p /data/logs /data/universe /data/mods /opt/hytale && \
    chown -R hytale:hytale /data /opt/hytale

COPY --chown=hytale:hytale docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY --chown=hytale:hytale Server/HytaleServer.jar /opt/hytale/HytaleServer.jar
COPY --chown=hytale:hytale Server/HytaleServer.aot /opt/hytale/HytaleServer.aot
COPY --chown=hytale:hytale Assets.zip /opt/hytale/Assets.zip

EXPOSE 5520/udp

VOLUME ["/data"]

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "HytaleServer" > /dev/null || exit 1

USER hytale

ENTRYPOINT ["/docker-entrypoint.sh"]
