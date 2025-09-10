#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

CORE_DIR="../../core"

# Core Microservices
helm upgrade --install mm-user-service     "$CORE_DIR/mm-user-service"     -f "$CORE_DIR/mm-user-service/values.local.yaml"     -n "$NAMESPACE"
helm upgrade --install mm-api-gateway      "$CORE_DIR/mm-api-gateway"      -f "$CORE_DIR/mm-api-gateway/values.local.yaml"      -n "$NAMESPACE"
helm upgrade --install mm-discovery-server "$CORE_DIR/mm-discovery-server" -f "$CORE_DIR/mm-discovery-server/values.local.yaml" -n "$NAMESPACE"
helm upgrade --install mm-recommendation-service "$CORE_DIR/mm-recommendation-service" -f "$CORE_DIR/mm-recommendation-service/values.local.yaml" -n "$NAMESPACE"
helm upgrade --install mm-activity-service "$CORE_DIR/mm-activity-service" -f "$CORE_DIR/mm-activity-service/values.local.yaml" -n "$NAMESPACE"
helm upgrade --install mm-movie-service "$CORE_DIR/mm-movie-service" -f "$CORE_DIR/mm-movie-service/values.local.yaml" -n "$NAMESPACE"


# Core Third Party services
helm install mm-keycloak bitnami/keycloak -f "$CORE_DIR/mm-keycloack/values.local.yaml" -n "$NAMESPACE"
kubectl apply -f "$CORE_DIR/mm-api-gateway-forward-auth/" -n "$NAMESPACE"