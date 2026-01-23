# Docker Hytale Server

Docker image for running a Hytale dedicated server.

## Quick Start

### Option 1: Pull Pre-built Image (Recommended)

From Docker Hub:
```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e SERVER_NAME="My Hytale Server" \
  arthur00/hytale-docker-image:latest
```

### Option 2: Build Locally

Requires a valid Hytale account with server access.

```bash
git clone https://github.com/arthurr0/hytale-docker-image.git
cd hytale-docker-image

./hytale-downloader-linux-amd64

unzip *.zip

docker compose up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `Hytale Server` | Server name displayed in the server list |
| `MOTD` | `` | Message of the day |
| `PASSWORD` | `` | Server password (empty = no password) |
| `MAX_PLAYERS` | `100` | Maximum number of players |
| `MAX_VIEW_RADIUS` | `16` | Maximum view distance (lower = less RAM usage) |
| `DEFAULT_WORLD` | `default` | Default world name |
| `DEFAULT_GAMEMODE` | `Adventure` | Default game mode |
| `BIND_ADDRESS` | `0.0.0.0` | Server bind address |
| `BIND_PORT` | `5520` | Server port (UDP) |
| `MEMORY_MIN` | `4G` | Minimum Java heap size |
| `MEMORY_MAX` | `8G` | Maximum Java heap size |
| `BACKUP_ENABLED` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `60` | Backup frequency in minutes |
| `USE_AOT` | `true` | Use AOT cache for faster startup |
| `EXTRA_ARGS` | `` | Additional server arguments |
| `TZ` | `UTC` | Container timezone |

## Volumes

| Path | Description |
|------|-------------|
| `/data` | Server data directory (configs, worlds, mods, logs) |

### Data Directory Structure

```
/data
├── config.json        # Server configuration
├── permissions.json   # Player permissions
├── whitelist.json     # Whitelist configuration
├── bans.json          # Banned players
├── Assets.zip         # Game assets
├── logs/              # Server logs
├── universe/          # World data
│   └── worlds/
│       └── default/   # Default world
└── mods/              # Server mods
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5520 | UDP | Game server (QUIC protocol) |

## Server Authentication

After first launch, you need to authenticate your server:

1. Attach to the container:
```bash
docker attach hytale-server
```

2. Run the authentication command:
```
/auth login device
```

3. Follow the URL and enter the code at https://accounts.hytale.com/device

4. Detach from container with `Ctrl+P` followed by `Ctrl+Q`

### Persistent Credentials

By default, credentials are stored in memory and lost on restart. To enable encrypted persistent storage:

1. Mount the host's machine-id (required for encryption key derivation):
```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -v /etc/machine-id:/etc/machine-id:ro \
  hytale-server
```

2. After authenticating, enable encrypted storage:
```
/auth persistence Encrypted
```

The `docker-compose.yml` already includes this volume mount.

## Sending Commands

### Using send-to-console

```bash
docker exec hytale-server send-to-console /help
docker exec hytale-server send-to-console /auth login device
```

### Interactive Console

```bash
docker attach hytale-server
```

Detach with `Ctrl+P` followed by `Ctrl+Q`.

## Health Check

The container includes a health check that verifies:
1. The Java process is running
2. The server has fully started (checks logs for "Server started")

Check health status:
```bash
docker inspect --format='{{.State.Health.Status}}' hytale-server
```

## Examples

### Custom Memory Allocation

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e MEMORY_MIN=8G \
  -e MEMORY_MAX=16G \
  hytale-server
```

### Enable Backups

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e BACKUP_ENABLED=true \
  -e BACKUP_FREQUENCY=30 \
  hytale-server
```

### Custom Port

```bash
docker run -d \
  --name hytale-server \
  -p 25565:25565/udp \
  -v hytale-data:/data \
  -e BIND_PORT=25565 \
  hytale-server
```

### With Password Protection

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/data \
  -e PASSWORD="mysecretpassword" \
  hytale-server
```

## Building the Image

```bash
docker build -t hytale-server .
```

## Logs

View server logs:

```bash
docker logs -f hytale-server
```

## Updating

1. Stop the container:
```bash
docker compose down
```

2. Download new server files (use hytale-downloader)

3. Rebuild the image:
```bash
docker compose build --no-cache
```

4. Start the container:
```bash
docker compose up -d
```

## Requirements

- Docker 20.10+
- At least 4GB RAM (8GB+ recommended)
- Valid Hytale account with server access

## Resources

- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Host Havoc Guide](https://hosthavoc.com/blog/how-to-setup-a-hytale-server)
