#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

CORE_DIR="../../core"

helm upgrade --install mm-user-service     "$CORE_DIR/mm-user-service"     -f "$CORE_DIR/mm-user-service/values.local.yaml"     -n "$NAMESPACE"
helm upgrade --install mm-api-gateway      "$CORE_DIR/mm-api-gateway"      -f "$CORE_DIR/mm-api-gateway/values.local.yaml"      -n "$NAMESPACE"
helm upgrade --install mm-discovery-server "$CORE_DIR/mm-discovery-server" -f "$CORE_DIR/mm-discovery-server/values.local.yaml" -n "$NAMESPACE"
<<<<<<< HEAD
=======
helm upgrade --install mm-recommendation-service "$CORE_DIR/mm-recommendation-service" -f "$CORE_DIR/mm-recommendation-service/values.local.yaml" -n "$NAMESPACE"
>>>>>>> master
