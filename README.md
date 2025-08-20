# mm-infrastructure

A central place to manage **CI/CD**, documentation, and infrastructure for [MovieMate](https://github.com/your-org/MovieMate).  
This repo contains everything you need to deploy the full MovieMate stack — either with **Docker Compose** for local development, or **Kubernetes** for a full production-like setup.

---

## 🚀 Deployment Options

You can run the platform in **two main ways**:

---

### 1️⃣ Docker Compose

**Quickest way to get MovieMate running locally.**

#### **How to use:**

1. **Prepare environment variables:**
    ```bash
    cp .env.example .env
    cp .env.db.example .env.db
    ```
   Edit `.env` and `.env.db` and fill out all required values (database, secrets, ports, etc).

2. **Configure observability (optional):**

   You can further customize logging, tracing, and monitoring services by editing configs in the root `config/` folder.

   For example, adjust settings for Grafana, Prometheus, Loki, Zipkin, etc. by editing the relevant files in:
    ```
    config/
    ├── grafana/
    ├── loki/
    ├── prometheus/
    └── zipkin/
    ```
   These files will be mounted automatically by Docker Compose.

3. **Run the deploy script:**
    ```bash
    ./scripts/deploy.sh
    ```

- All services will start in Docker containers using your settings from `.env`.
- Great for development and quick local testing.

---

### 2️⃣ Kubernetes

**For production or staging — runs on any K8s cluster (Minikube, k3s, EKS, etc).**

#### **How to use:**

1. **Configure values for your environment:**
    - Edit YAML files under:
        - `k8s/core/`
        - `k8s/dbs/`
        - `k8s/observability/`
    - Adjust settings (secrets, ports, replica counts) as needed.

2. **Deploy to your cluster:**
    ```bash
    cd k8s/scripts/init
    ./deploy-from-scratch.sh
    ```
   This script will:
    - Add & update Helm repos
    - Create the required namespace
    - Deploy all core services, databases, and observability stack (Prometheus, Grafana, Zipkin, Loki, OpenTelemetry, etc.)
    - Apply all extra manifests in `config/`

---


