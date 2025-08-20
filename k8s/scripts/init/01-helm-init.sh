#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add neo4j https://helm.neo4j.com/neo4j
helm repo add openzipkin https://openzipkin.github.io/zipkin
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts

helm repo update