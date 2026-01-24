# Docker Hytale Server

Docker image for running a Hytale dedicated server based on Eclipse Temurin JRE 25 Alpine.

## Quick Start

### Option 1: Docker Hub (Recommended)

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -v /etc/machine-id:/etc/machine-id:ro \
  -e SERVER_NAME="My Hytale Server" \
  arthur00/hytale-docker-image:latest
```

### Option 2: Build Locally

Requires a valid Hytale account with server access.

```bash
git clone https://github.com/arthurr0/hytale-docker-image.git
cd hytale-docker-image

# Download server files using hytale-downloader
./hytale-downloader-linux-amd64
unzip *.zip

docker compose up -d
```

## Server Authentication

After first launch, authenticate your server:

1. Attach to container:
```bash
docker attach hytale-server
```

2. Run authentication:
```
/auth login device
```

3. Follow the URL and enter the code at https://accounts.hytale.com/device

4. Enable persistent credentials:
```
/auth persistence Encrypted
```

5. Detach with `Ctrl+P` then `Ctrl+Q`

> **Note:** The `docker-compose.yml` already includes `/etc/machine-id` mount required for encrypted credential storage.

## Environment Variables

### Server Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `Hytale Server` | Server name in server list |
| `MOTD` | `` | Message of the day |
| `PASSWORD` | `` | Server password (empty = no password) |
| `MAX_PLAYERS` | `100` | Maximum players |
| `MAX_VIEW_RADIUS` | `12` | View distance (lower = less RAM) |
| `DEFAULT_WORLD` | `default` | Default world name |
| `DEFAULT_GAMEMODE` | `Adventure` | Default game mode |
| `BIND_ADDRESS` | `0.0.0.0` | Server bind address |
| `BIND_PORT` | `5520` | Server port (UDP) |

### Memory Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_MODE` | `percentage` | Memory mode: `percentage` or `fixed` |
| `MAX_RAM_PERCENTAGE` | `75` | RAM percentage (when `MEMORY_MODE=percentage`) |
| `MEMORY_MIN` | `` | Minimum heap `-Xms` (when `MEMORY_MODE=fixed`) |
| `MEMORY_MAX` | `` | Maximum heap `-Xmx` (when `MEMORY_MODE=fixed`) |

**Percentage mode** (recommended): JVM uses a percentage of container memory limit.
```yaml
environment:
  - MEMORY_MODE=percentage
  - MAX_RAM_PERCENTAGE=75
```

**Fixed mode**: Explicit heap sizes.
```yaml
environment:
  - MEMORY_MODE=fixed
  - MEMORY_MIN=4G
  - MEMORY_MAX=8G
```

### Backup Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_ENABLED` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `60` | Backup interval in minutes |
| `BACKUP_DIR` | `/data/backups` | Backup directory |

### Server CLI Options

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_MODE` | `` | Authentication mode (e.g., `authenticated`) |
| `DISABLE_SENTRY` | `false` | Disable Sentry error reporting |
| `ALLOW_OP` | `false` | Allow operator commands |
| `ACCEPT_EARLY_PLUGINS` | `false` | Accept early plugin API |
| `EXTRA_ARGS` | `` | Additional server arguments |

### Network Settings (config.json)

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_COMPRESSION_ENABLED` | `false` | Enable local packet compression |
| `RATE_LIMIT_ENABLED` | `true` | Enable rate limiting |
| `RATE_LIMIT_PACKETS_PER_SECOND` | `2000` | Max packets per second |
| `RATE_LIMIT_BURST_CAPACITY` | `500` | Burst capacity |

### Connection Timeouts

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECTION_TIMEOUT_INITIAL` | `PT10S` | Initial connection timeout |
| `CONNECTION_TIMEOUT_AUTH` | `PT30S` | Authentication timeout |
| `CONNECTION_TIMEOUT_PLAY` | `PT1M` | Play session timeout |

### Storage

| Variable | Default | Description |
|----------|---------|-------------|
| `PLAYER_STORAGE_TYPE` | `Hytale` | Player data storage type |

### Other

| Variable | Default | Description |
|----------|---------|-------------|
| `TZ` | `UTC` | Container timezone |

## Volumes

| Path | Description |
|------|-------------|
| `/data` | Persistent data (configs, worlds, mods, logs) |
| `/etc/machine-id` | Host machine ID (read-only, for credential encryption) |

### Data Directory Structure

```
/data
├── config.json
├── permissions.json
├── whitelist.json
├── bans.json
├── Assets.zip
├── logs/
├── universe/
│   └── worlds/
│       └── default/
├── mods/
└── backups/
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5520 | UDP | Game server (QUIC) |

## Commands

### Send Commands

```bash
docker exec hytale-server send-to-console /help
docker exec hytale-server send-to-console "/say Hello!"
```

### Interactive Console

```bash
docker attach hytale-server
# Detach: Ctrl+P, Ctrl+Q
```

### View Logs

```bash
docker logs -f hytale-server
```

### Check Health

```bash
docker inspect --format='{{.State.Health.Status}}' hytale-server
```

## Examples

### Password Protected Server

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e SERVER_NAME="Private Server" \
  -e PASSWORD="secret123" \
  arthur00/hytale-docker-image:latest
```

### High-Performance Server

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e MEMORY_MODE=fixed \
  -e MEMORY_MIN=8G \
  -e MEMORY_MAX=16G \
  -e MAX_VIEW_RADIUS=16 \
  -e MAX_PLAYERS=200 \
  arthur00/hytale-docker-image:latest
```

### With Backups

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e BACKUP_ENABLED=true \
  -e BACKUP_FREQUENCY=30 \
  arthur00/hytale-docker-image:latest
```

### Custom Port

```bash
docker run -d \
  --name hytale-server \
  -p 25565:25565/udp \
  -v hytale-data:/data \
  -e BIND_PORT=25565 \
  arthur00/hytale-docker-image:latest
```

## Updating

```bash
docker compose down
# Download new server files with hytale-downloader
docker compose build --no-cache
docker compose up -d
```

## Building

```bash
docker build -t hytale-server .
```

Required files:
- `Server/HytaleServer.jar`
- `Assets.zip`

## Requirements

- Docker 20.10+
- 4GB RAM minimum (8GB+ recommended)
- Valid Hytale account with server access

## Resources

- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Host Havoc Setup Guide](https://hosthavoc.com/blog/how-to-setup-a-hytale-server)
