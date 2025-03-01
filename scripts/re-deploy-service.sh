#!/bin/bash

# Ensure exactly two parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <docker_registry> <service> <image_tag>" >&2
    exit 1
fi

SERVICE="$1"
IMAGE_TAG="$2"

DOCKER_IMAGE="${DOCKER_REGISTRY}/${SERVICE}:${IMAGE_TAG}"
CONTAINER_NAME="${SERVICE}"
ENV_FILE=../${SERVICE}/.env

# Verify that the environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file '$ENV_FILE' not found." >&2
    exit 1
fi

# Log deployment details (sensitive info like PORT value remains hidden via env file)
echo "Deploying service: $SERVICE"
echo "Using Docker image: $DOCKER_IMAGE:$IMAGE_TAG"
echo "Container name: $CONTAINER_NAME"
echo "Loading environment from: $ENV_FILE"

# Pull the new Docker image
if ! docker pull "$DOCKER_IMAGE"; then
    echo "Error: Failed to pull image '$DOCKER_IMAGE'" >&2
    exit 1
fi

echo "Recreating the container for $SERVICE_NAME using Docker Compose..."
docker compose up -d --no-deps --build $SERVICE_NAME

echo "Service $SERVICE_NAME was redeployed successfully!"
