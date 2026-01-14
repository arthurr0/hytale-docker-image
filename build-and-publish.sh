#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GHCR_IMAGE="ghcr.io/arthurr0/hytale-docker-image"
DOCKERHUB_IMAGE="arthur00/hytale-docker-image"
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
docker build \
    -t "$GHCR_IMAGE:latest" \
    -t "$GHCR_IMAGE:$VERSION" \
    -t "$DOCKERHUB_IMAGE:latest" \
    -t "$DOCKERHUB_IMAGE:$VERSION" \
    .

log "Build complete"

if [ "$1" = "--push" ]; then
    log "Logging in to ghcr.io..."
    echo "Enter GitHub Personal Access Token (with write:packages scope):"
    read -s GHCR_TOKEN
    echo "$GHCR_TOKEN" | docker login ghcr.io -u arthurr0 --password-stdin

    log "Pushing to GitHub Container Registry..."
    docker push "$GHCR_IMAGE:latest"
    docker push "$GHCR_IMAGE:$VERSION"

    log "Logging in to Docker Hub..."
    docker login

    log "Pushing to Docker Hub..."
    docker push "$DOCKERHUB_IMAGE:latest"
    docker push "$DOCKERHUB_IMAGE:$VERSION"

    log "Published:"
    log "  - $GHCR_IMAGE:latest"
    log "  - $GHCR_IMAGE:$VERSION"
    log "  - $DOCKERHUB_IMAGE:latest"
    log "  - $DOCKERHUB_IMAGE:$VERSION"
else
    log ""
    log "Images built locally. To publish, run:"
    log "  ./build-and-publish.sh --push"
fi
