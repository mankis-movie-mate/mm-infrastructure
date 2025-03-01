#!/bin/bash

set -euo pipefail

# Ensure exactly three parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <docker_registry> <service> <image_tag>" >&2
    exit 1
fi

DOCKER_REGISTRY="$1"
SERVICE="$2"
IMAGE_TAG="$3"

DOCKER_IMAGE="${DOCKER_REGISTRY}/${SERVICE}:${IMAGE_TAG}"
CONTAINER_NAME="${SERVICE}"

echo "🚀 Deploying service: $SERVICE"
echo "📦 Using Docker image: $DOCKER_IMAGE"
echo "🔄 Container name: $CONTAINER_NAME"

echo "📥 Pulling image: $DOCKER_IMAGE..."
if ! docker pull "$DOCKER_IMAGE"; then
    echo "❌ Error: Failed to pull image '$DOCKER_IMAGE'" >&2
    exit 1
fi

echo "🔄 Restarting service $SERVICE using Docker Compose..."
if ! docker compose up -d --no-deps --build "$SERVICE"; then
    echo "❌ Error: Failed to redeploy service '$SERVICE'" >&2
    exit 1
fi

echo "✅ Service '$SERVICE' was successfully redeployed!"
