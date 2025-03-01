#!/bin/bash
set -euo pipefail

declare -A REPOS=(
  ["mm-recommendation-service"]="git@github.com:mankis-movie-mate/mm-recommendation-service.git"
  ["mm-activity-service"]="git@github.com:mankis-movie-mate/mm-activity-service.git"
  ["mm-user-service"]="git@github.com:mankis-movie-mate/mm-user-service.git"
  ["mm-movie-service"]="git@github.com:mankis-movie-mate/mm-movie-service.git"
  ["mm-discovery-server"]="git@github.com:mankis-movie-mate/mm-discovery-server.git"
  ["mm-api-gateway"]="git@github.com:mankis-movie-mate/mm-api-gateway.git"
)


echo "Initializing cluster..."
cd ../..

for SERVICE in "${!REPOS[@]}"; do
  REPO_URL="${REPOS[$SERVICE]}"
  echo "Processing repository: $SERVICE"

  # Clone if the directory doesn't exist; otherwise, pull latest changes.
  if [ -d "$SERVICE" ]; then
    echo "  Repository exists. Pulling latest changes..."
    cd "$SERVICE"
    git pull || echo "  Warning: Failed to update $SERVICE"
    cd ..
  else
    echo "  Cloning repository from $REPO_URL..."
    git clone "$REPO_URL"
  fi

  # Move into the repository directory
  cd "$SERVICE"

  # Check if a .env file already exists; if not, create it by copying .env.example.
  if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
      echo "  Creating .env from .env.example..."
      cp .env.example .env
    else
      echo "  Warning: No .env.example found for $SERVICE;"
      touch .env
    fi
  else
    echo "  .env already exists; skipping."
  fi

  cd ..
  cp .env.example .env
  cp .env.db.example .env.db
  echo "Finished processing $SERVICE."
done

echo "Cluster initialization complete."
