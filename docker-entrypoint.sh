#!/bin/bash
set -e

CONFIG_FILE="/data/config.json"
PERMISSIONS_FILE="/data/permissions.json"
WHITELIST_FILE="/data/whitelist.json"
BANS_FILE="/data/bans.json"

PASSWORD="${PASSWORD:-}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

create_default_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Creating default config.json..."
        cat > "$CONFIG_FILE" << EOF
{
  "Version": 3,
  "ServerName": "${SERVER_NAME}",
  "MOTD": "${MOTD}",
  "Password": "${PASSWORD}",
  "MaxPlayers": ${MAX_PLAYERS},
  "MaxViewRadius": ${MAX_VIEW_RADIUS},
  "LocalCompressionEnabled": false,
  "Defaults": {
    "World": "${DEFAULT_WORLD}",
    "GameMode": "${DEFAULT_GAMEMODE}"
  },
  "ConnectionTimeouts": {
    "JoinTimeouts": {}
  },
  "RateLimit": {},
  "Modules": {},
  "LogLevels": {},
  "Mods": {},
  "DisplayTmpTagsInStrings": false,
  "PlayerStorage": {
    "Type": "Hytale"
  }
}
EOF
    else
        log "Updating existing config.json with environment variables..."
        tmp=$(mktemp)
        jq --arg name "$SERVER_NAME" \
           --arg motd "$MOTD" \
           --arg pass "$PASSWORD" \
           --argjson maxp "$MAX_PLAYERS" \
           --argjson maxvr "$MAX_VIEW_RADIUS" \
           --arg world "$DEFAULT_WORLD" \
           --arg gmode "$DEFAULT_GAMEMODE" \
           '.ServerName = $name |
            .MOTD = $motd |
            .Password = $pass |
            .MaxPlayers = $maxp |
            .MaxViewRadius = $maxvr |
            .Defaults.World = $world |
            .Defaults.GameMode = $gmode' \
           "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    fi
}

create_default_files() {
    if [ ! -f "$PERMISSIONS_FILE" ]; then
        log "Creating default permissions.json..."
        echo '{}' > "$PERMISSIONS_FILE"
    fi

    if [ ! -f "$WHITELIST_FILE" ]; then
        log "Creating default whitelist.json..."
        echo '{"enabled":false,"list":[]}' > "$WHITELIST_FILE"
    fi

    if [ ! -f "$BANS_FILE" ]; then
        log "Creating default bans.json..."
        echo '[]' > "$BANS_FILE"
    fi
}

setup_directories() {
    log "Setting up directories..."
    mkdir -p /data/logs /data/universe /data/mods

    log "Syncing Assets.zip from image..."
    cp /opt/hytale/Assets.zip /data/Assets.zip

    if [ -d "/data/.asset_cache" ]; then
        log "Clearing asset cache..."
        rm -rf /data/.asset_cache
    fi
    if [ -d "/data/asset_cache" ]; then
        log "Clearing asset cache..."
        rm -rf /data/asset_cache
    fi

    rm -f /data/.server-ready

    CONSOLE_IN_PIPE="/tmp/console-input"
    rm -f "$CONSOLE_IN_PIPE"
    mkfifo "$CONSOLE_IN_PIPE"
}

log "========================================="
log "  Hytale Server Docker Container"
log "========================================="
log "Server Name: ${SERVER_NAME}"
log "Max Players: ${MAX_PLAYERS}"
log "Bind Address: ${BIND_ADDRESS}:${BIND_PORT}"
log "Memory: ${MEMORY_MIN} - ${MEMORY_MAX}"
log "========================================="

setup_directories
create_default_config
create_default_files

cd /data

JAVA_ARGS="-Xms${MEMORY_MIN} -Xmx${MEMORY_MAX}"
JAVA_ARGS="$JAVA_ARGS -XX:+UseG1GC"
JAVA_ARGS="$JAVA_ARGS -XX:+ParallelRefProcEnabled"
JAVA_ARGS="$JAVA_ARGS -XX:MaxGCPauseMillis=200"
JAVA_ARGS="$JAVA_ARGS -XX:+UnlockExperimentalVMOptions"
JAVA_ARGS="$JAVA_ARGS -XX:+DisableExplicitGC"
JAVA_ARGS="$JAVA_ARGS -XX:+AlwaysPreTouch"
JAVA_ARGS="$JAVA_ARGS -XX:G1NewSizePercent=30"
JAVA_ARGS="$JAVA_ARGS -XX:G1MaxNewSizePercent=40"
JAVA_ARGS="$JAVA_ARGS -XX:G1HeapRegionSize=8M"
JAVA_ARGS="$JAVA_ARGS -XX:G1ReservePercent=20"
JAVA_ARGS="$JAVA_ARGS -XX:G1HeapWastePercent=5"
JAVA_ARGS="$JAVA_ARGS -XX:G1MixedGCCountTarget=4"
JAVA_ARGS="$JAVA_ARGS -XX:InitiatingHeapOccupancyPercent=15"
JAVA_ARGS="$JAVA_ARGS -XX:G1MixedGCLiveThresholdPercent=90"
JAVA_ARGS="$JAVA_ARGS -XX:G1RSetUpdatingPauseTimePercent=5"
JAVA_ARGS="$JAVA_ARGS -XX:SurvivorRatio=32"
JAVA_ARGS="$JAVA_ARGS -XX:+PerfDisableSharedMem"
JAVA_ARGS="$JAVA_ARGS -XX:MaxTenuringThreshold=1"

SERVER_ARGS="--assets /data/Assets.zip"
SERVER_ARGS="$SERVER_ARGS --bind ${BIND_ADDRESS}:${BIND_PORT}"

if [ "$BACKUP_ENABLED" = "true" ]; then
    BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
    mkdir -p "$BACKUP_DIR"
    SERVER_ARGS="$SERVER_ARGS --backup --backup-dir $BACKUP_DIR --backup-frequency ${BACKUP_FREQUENCY}"
fi

if [ -n "$EXTRA_ARGS" ]; then
    SERVER_ARGS="$SERVER_ARGS $EXTRA_ARGS"
fi

shutdown_server() {
    log "Received shutdown signal, stopping server gracefully..."
    if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "stop" > "$CONSOLE_IN_PIPE"
        wait "$SERVER_PID" 2>/dev/null
    fi
    log "Server stopped."
    exit 0
}

trap shutdown_server SIGTERM SIGINT

log "Starting Hytale Server..."
log "Java args: $JAVA_ARGS"
log "Server args: $SERVER_ARGS"

tail -f "$CONSOLE_IN_PIPE" | java $JAVA_ARGS -jar /opt/hytale/HytaleServer.jar $SERVER_ARGS &
SERVER_PID=$!

wait "$SERVER_PID"
