#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GHCR_USER="${GHCR_USER:-}"
IMAGE_NAME="${IMAGE_NAME:-hytale-server}"
DOWNLOADER="./hytale-downloader-linux-amd64"

log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

if [ ! -f "$DOWNLOADER" ]; then
    error "hytale-downloader-linux-amd64 not found"
fi

chmod +x "$DOWNLOADER"

if [ ! -f "Server/HytaleServer.jar" ] || [ ! -f "Assets.zip" ]; then
    log "Server files not found, downloading..."

    $DOWNLOADER

    LATEST_ZIP=$(ls -t *.zip 2>/dev/null | grep -v Assets.zip | head -1)

    if [ -z "$LATEST_ZIP" ]; then
        error "No downloaded zip file found"
    fi

    log "Extracting $LATEST_ZIP..."
    unzip -o "$LATEST_ZIP"

    log "Server files ready"
else
    log "Server files already exist, skipping download"
fi

if [ ! -f "Server/HytaleServer.jar" ]; then
    error "Server/HytaleServer.jar not found after extraction"
fi

if [ ! -f "Assets.zip" ]; then
    error "Assets.zip not found after extraction"
fi

VERSION=$($DOWNLOADER -print-version 2>/dev/null || echo "latest")
log "Hytale version: $VERSION"

log "Building Docker image..."
docker build -t "$IMAGE_NAME:latest" -t "$IMAGE_NAME:$VERSION" .

log "Build complete: $IMAGE_NAME:latest, $IMAGE_NAME:$VERSION"

if [ -n "$GHCR_USER" ]; then
    FULL_IMAGE="ghcr.io/$GHCR_USER/$IMAGE_NAME"

    log "Tagging for GitHub Container Registry..."
    docker tag "$IMAGE_NAME:latest" "$FULL_IMAGE:latest"
    docker tag "$IMAGE_NAME:$VERSION" "$FULL_IMAGE:$VERSION"

    log "Logging in to ghcr.io..."
    echo "Enter your GitHub Personal Access Token (with write:packages scope):"
    docker login ghcr.io -u "$GHCR_USER"

    log "Pushing to $FULL_IMAGE..."
    docker push "$FULL_IMAGE:latest"
    docker push "$FULL_IMAGE:$VERSION"

    log "Published: $FULL_IMAGE:latest, $FULL_IMAGE:$VERSION"
else
    log ""
    log "To publish to GitHub Container Registry, run:"
    log "  GHCR_USER=your-github-username ./build-and-publish.sh"
fi