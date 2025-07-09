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

echo "📥 Pulling the latest image for $SERVICE..."
if ! docker pull "$DOCKER_IMAGE"; then
    echo "❌ Error: Failed to pull image '$DOCKER_IMAGE'" >&2
    exit 1
fi

# Check if any services in the compose stack are running
if docker compose ps --services --filter "status=running" | grep -q .; then
    echo "✅ Docker Compose stack is running."
else
    echo "🟡 Docker Compose stack is NOT running. Starting the whole stack..."
    docker compose --env-file ./.env --env-file ./.env.db up -d
fi

echo "🔄 Updating $SERVICE in Docker Compose..."

# Pull the latest image in the compose context (service name)
if ! docker compose pull "$SERVICE"; then
    echo "❌ Error: Failed to pull the latest service image for '$SERVICE'" >&2
    exit 1
fi

# Recreate the service with the latest image
if ! docker compose --env-file ./.env --env-file ./.env.db up -d --no-deps "$SERVICE"; then
    echo "❌ Error: Failed to redeploy service '$SERVICE'" >&2
    exit 1
fi

echo "✅ Service '$SERVICE' successfully redeployed!"
