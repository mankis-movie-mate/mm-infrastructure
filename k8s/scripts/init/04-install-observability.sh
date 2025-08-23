#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

OBSERVABILITY_DIR="../../observability"

helm upgrade --install mm-zipkin      openzipkin/zipkin                         -f "$OBSERVABILITY_DIR/mm-zipkin/values.yaml"        -n "$NAMESPACE"
helm upgrade --install mm-prometheus  prometheus-community/prometheus           -f "$OBSERVABILITY_DIR/mm-prometheus/values.local.yaml"    -n "$NAMESPACE"
helm upgrade --install mm-grafana     grafana/grafana                           -f "$OBSERVABILITY_DIR/mm-grafana/values.local.yaml" -n "$NAMESPACE"
helm upgrade --install mm-otel-collector open-telemetry/opentelemetry-collector -f "$OBSERVABILITY_DIR/mm-otel/values.local.yaml"    -n "$NAMESPACE"
helm upgrade --install mm-loki        grafana/loki                              -f "$OBSERVABILITY_DIR/mm-loki/values.yaml"          -n "$NAMESPACE"
helm upgrade --install mm-alloy       grafana/alloy                             -f "$OBSERVABILITY_DIR/mm-alloy/values.yaml"         -n "$NAMESPACE"
helm upgrade --install mm-openapi-hub       ../../../../mm-openapi-hub/helm      -f ../../../../mm-openapi-hub/helm/values.local.yaml        -n "$NAMESPACE"
