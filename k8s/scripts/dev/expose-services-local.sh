#!/usr/bin/env bash
set -e

# === Configuration ===
NAMESPACE="movie-mate"

# Local bind ports (adjust as needed)
ZIPKIN_LOCAL_PORT=9411
PROMETHEUS_LOCAL_PORT=9090
GRAFANA_LOCAL_PORT=5555
DISCOVERY_LOCAL_PORT=8500
REDPANDA_CONSOLE_LOCAL_PORT=8967

# K8s service ports
ZIPKIN_SERVICE_PORT=9411
PROMETHEUS_SERVICE_PORT=80
GRAFANA_SERVICE_PORT=3444
DISCOVERY_SERVICE_PORT=8500
REDPANDA_CONSOLE_SERVICE_PORT=8080

# === Expose Dashboards ===
trap 'echo "Killing port-forwards..."; pkill -f "kubectl.*port-forward.*$NAMESPACE"; exit' SIGINT SIGTERM

kubectl -n "$NAMESPACE" port-forward svc/mm-zipkin $ZIPKIN_LOCAL_PORT:$ZIPKIN_SERVICE_PORT --address 0.0.0.0 &
kubectl -n "$NAMESPACE" port-forward svc/mm-prometheus-server $PROMETHEUS_LOCAL_PORT:$PROMETHEUS_SERVICE_PORT --address 0.0.0.0 &
kubectl -n "$NAMESPACE" port-forward svc/mm-grafana $GRAFANA_LOCAL_PORT:$GRAFANA_SERVICE_PORT --address 0.0.0.0 &
kubectl -n "$NAMESPACE" port-forward svc/mm-discovery-server $DISCOVERY_LOCAL_PORT:$DISCOVERY_SERVICE_PORT --address 0.0.0.0 &
kubectl -n "$NAMESPACE" port-forward svc/redpanda-console $REDPANDA_CONSOLE_LOCAL_PORT:$REDPANDA_CONSOLE_SERVICE_PORT --address 0.0.0.0 &

echo "Dashboards are now accessible from your LAN/VPN:"
echo "  Zipkin:           http://<your_host>:$ZIPKIN_LOCAL_PORT"
echo "  Prometheus:       http://<your_host>:$PROMETHEUS_LOCAL_PORT"
echo "  Grafana:          http://<your_host>:$GRAFANA_LOCAL_PORT"
echo "  Discovery Server: http://<your_host>:$DISCOVERY_LOCAL_PORT"
echo "  Redpanda Console: http://<your_host>:$REDPANDA_CONSOLE_LOCAL_PORT"

wait  # wait for all background jobs
