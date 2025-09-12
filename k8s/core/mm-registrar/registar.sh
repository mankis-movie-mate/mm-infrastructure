#!/usr/bin/env bash
set -euo pipefail

# --- config (override via .env or exported env) ---
NAMESPACE="${NAMESPACE:-movie-mate}"
APP="${APP:-mm-registrar}"
IMAGE_NAME="${IMAGE_NAME:-mm-registrar}"
TAG="${TAG:-local}"
PLATFORM="${PLATFORM:-linux/amd64}"   # adjust if you're on arm64
ENV_FILE="${ENV_FILE:-.env}"         # path to your .env next to this script
# --------------------------------------------------

ROOT="$(cd "$(dirname "$0")" && pwd)"

# 1) Load .env so ${CONSUL_URL}, ${DO_DEREGISTER}, etc. are available
if [[ -f "${ROOT}/${ENV_FILE}" ]]; then
  echo "🔧 Loading ${ENV_FILE}"
  set -a
  # .env must be KEY=VALUE lines, no 'export'
  source "${ROOT}/${ENV_FILE}"
  set +a
else
  echo "⚠️  ${ENV_FILE} not found; using defaults if provided"
fi

# 2) Build image with a local name (NO registry) -> perfect for k3s import
IMAGE_REF="${IMAGE_NAME}:${TAG}"
DOCKER_IMAGE="${IMAGE_REF}"

echo "🧱 Building image: ${DOCKER_IMAGE}"
docker buildx build --no-cache --platform "${PLATFORM}" -t "${DOCKER_IMAGE}" "${ROOT}"

# 3) Save -> import into k3s containerd (single-node)
echo "📦 Saving Docker image..."
docker save "${DOCKER_IMAGE}" -o "${APP}.tar"

echo "📦 Importing image into k3s containerd..."
# k3s bundles containerd; 'k3s ctr' talks directly to it
sudo k3s ctr images import "${APP}.tar"

# (optional) verify it's there
sudo k3s ctr images ls | grep "${IMAGE_NAME}" || true

# 4) cleanup tarball
rm -f "${APP}.tar"

# 5) Ensure namespace
echo "📦 Ensuring namespace: ${NAMESPACE}"
kubectl create ns "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# 6) Deploy — values are substituted from the current shell (incl. .env)
# Safe defaults prevent 'unbound variable' crashes with set -u.
: "${CONSUL_URL:=http://consul-server.consul.svc.cluster.local:8500}"
: "${DO_DEREGISTER:=true}"

echo "🚀 Deploying ${APP} with image ${IMAGE_REF}"
kubectl -n "${NAMESPACE}" apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP}
  labels:
    app.kubernetes.io/name: ${APP}
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ${APP}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ${APP}
        io.kompose.network/movie-mate-network: "true"
        app.kubernetes.io/part-of: movie-mate
        app.kubernetes.io/component: backend
    spec:
      securityContext:
        runAsNonRoot: true
        fsGroup: 1000
      containers:
        - name: mm-registrar
          image: ${IMAGE_REF}                  # uses the image we just imported
          imagePullPolicy: IfNotPresent        # do NOT pull from registry
          env:
            - name: CONSUL_URL
              value: "${CONSUL_URL}"
            - name: DO_DEREGISTER
              value: "${DO_DEREGISTER}"
          resources:
            requests: { cpu: "20m", memory: "64Mi" }
            limits:   { cpu: "200m", memory: "256Mi" }
EOF

echo "⏳ Waiting for rollout..."
kubectl -n "${NAMESPACE}" rollout status deploy/${APP}

echo "📜 Tailing last logs (Ctrl-C to stop):"
kubectl -n "${NAMESPACE}" logs deploy/${APP} -f --tail=200
