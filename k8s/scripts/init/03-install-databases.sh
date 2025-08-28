#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

VALUES_DIR="../../dbs"

helm upgrade --install mm-kafka     bitnami/kafka       -f "$VALUES_DIR/mm-kafka/values.yaml"        -n "$NAMESPACE"
helm upgrade --install mm-postgres bitnami/postgresql -f "$VALUES_DIR/mm-postgres/values.local.yaml" -n "$NAMESPACE"
helm upgrade --install mm-redis     bitnami/redis       -f "$VALUES_DIR/mm-redis/values.yaml"        -n "$NAMESPACE"
helm upgrade --install mm-mongo     bitnami/mongodb     -f "$VALUES_DIR/mm-mongo/values.yaml"        -n "$NAMESPACE"
helm upgrade --install mm-neo4j     neo4j/neo4j         -f "$VALUES_DIR/mm-neo4j/values.local.yaml"  -n "$NAMESPACE"
