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
        cat > "$CONFIG_FILE" << 'EOF'
{
  "Version": 3,
  "ServerName": "Hytale Server",
  "MOTD": "",
  "Password": "",
  "MaxPlayers": 100,
  "MaxViewRadius": 12,
  "LocalCompressionEnabled": false,
  "Defaults": {
    "World": "default",
    "GameMode": "Adventure"
  },
  "ConnectionTimeouts": {
    "InitialTimeout": "PT10S",
    "AuthTimeout": "PT30S",
    "PlayTimeout": "PT1M",
    "JoinTimeouts": {}
  },
  "RateLimit": {
    "Enabled": true,
    "PacketsPerSecond": 2000,
    "BurstCapacity": 500
  },
  "Modules": {},
  "LogLevels": {},
  "Mods": {},
  "DisplayTmpTagsInStrings": false,
  "PlayerStorage": {
    "Type": "Hytale"
  }
}
EOF
    fi
}

update_config_from_env() {
    log "Applying environment variable overrides to config.json..."
    tmp=$(mktemp)
    cp "$CONFIG_FILE" "$tmp"

    [ -n "$SERVER_NAME" ] && jq --arg v "$SERVER_NAME" '.ServerName = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$MOTD" ] && jq --arg v "$MOTD" '.MOTD = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$PASSWORD" ] && jq --arg v "$PASSWORD" '.Password = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$MAX_PLAYERS" ] && jq --argjson v "$MAX_PLAYERS" '.MaxPlayers = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$MAX_VIEW_RADIUS" ] && jq --argjson v "$MAX_VIEW_RADIUS" '.MaxViewRadius = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$LOCAL_COMPRESSION_ENABLED" ] && jq --argjson v "$LOCAL_COMPRESSION_ENABLED" '.LocalCompressionEnabled = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$DEFAULT_WORLD" ] && jq --arg v "$DEFAULT_WORLD" '.Defaults.World = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$DEFAULT_GAMEMODE" ] && jq --arg v "$DEFAULT_GAMEMODE" '.Defaults.GameMode = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$CONNECTION_TIMEOUT_INITIAL" ] && jq --arg v "$CONNECTION_TIMEOUT_INITIAL" '.ConnectionTimeouts.InitialTimeout = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$CONNECTION_TIMEOUT_AUTH" ] && jq --arg v "$CONNECTION_TIMEOUT_AUTH" '.ConnectionTimeouts.AuthTimeout = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$CONNECTION_TIMEOUT_PLAY" ] && jq --arg v "$CONNECTION_TIMEOUT_PLAY" '.ConnectionTimeouts.PlayTimeout = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$RATE_LIMIT_ENABLED" ] && jq --argjson v "$RATE_LIMIT_ENABLED" '.RateLimit.Enabled = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$RATE_LIMIT_PACKETS_PER_SECOND" ] && jq --argjson v "$RATE_LIMIT_PACKETS_PER_SECOND" '.RateLimit.PacketsPerSecond = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$RATE_LIMIT_BURST_CAPACITY" ] && jq --argjson v "$RATE_LIMIT_BURST_CAPACITY" '.RateLimit.BurstCapacity = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
    [ -n "$PLAYER_STORAGE_TYPE" ] && jq --arg v "$PLAYER_STORAGE_TYPE" '.PlayerStorage.Type = $v' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"

    mv "$tmp" "$CONFIG_FILE"
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

setup_directories
create_default_config
update_config_from_env
create_default_files

cd /data

JAVA_ARGS=""

if [ "$MEMORY_MODE" = "percentage" ]; then
    JAVA_ARGS="$JAVA_ARGS -XX:MaxRAMPercentage=${MAX_RAM_PERCENTAGE}"
    JAVA_ARGS="$JAVA_ARGS -XX:InitialRAMPercentage=${MAX_RAM_PERCENTAGE}"
else
    if [ -n "$MEMORY_MIN" ]; then
        JAVA_ARGS="$JAVA_ARGS -Xms${MEMORY_MIN}"
    fi
    if [ -n "$MEMORY_MAX" ]; then
        JAVA_ARGS="$JAVA_ARGS -Xmx${MEMORY_MAX}"
    fi
fi

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

if [ -n "$AUTH_MODE" ]; then
    SERVER_ARGS="$SERVER_ARGS --auth-mode $AUTH_MODE"
fi

if [ "$DISABLE_SENTRY" = "true" ]; then
    SERVER_ARGS="$SERVER_ARGS --disable-sentry"
fi

if [ "$ALLOW_OP" = "true" ]; then
    SERVER_ARGS="$SERVER_ARGS --allow-op"
fi

if [ "$ACCEPT_EARLY_PLUGINS" = "true" ]; then
    SERVER_ARGS="$SERVER_ARGS --accept-early-plugins"
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

startup_watchdog() {
    sleep "$STARTUP_TIMEOUT"
    if [ ! -f "/data/.server-ready" ]; then
        log "ERROR: Server failed to start within ${STARTUP_TIMEOUT} seconds. Shutting down."
        kill -TERM $$ 2>/dev/null
    fi
}

log "Starting Hytale Server..."
log "Java args: $JAVA_ARGS"
log "Server args: $SERVER_ARGS"
log "Startup timeout: ${STARTUP_TIMEOUT}s"

startup_watchdog &
WATCHDOG_PID=$!

tail -f "$CONSOLE_IN_PIPE" | java $JAVA_ARGS -jar /opt/hytale/HytaleServer.jar $SERVER_ARGS &
SERVER_PID=$!

wait "$SERVER_PID"
kill "$WATCHDOG_PID" 2>/dev/null