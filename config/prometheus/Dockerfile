# Stage 1: Use the official Prometheus image as the base
FROM prom/prometheus as prometheus-base

# Stage 2: Add gettext (for envsubst) using Alpine
FROM alpine:3.10.2

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Copy the Prometheus binary from the first stage
COPY --from=prometheus-base /bin/prometheus /bin/prometheus

# Create directories and set correct permissions
RUN mkdir -p /prometheus /etc/prometheus && \
    chown -R nobody:nogroup /etc/prometheus /prometheus

# Copy your template file
# You must have `prometheus.template.yml` in the same directory as this Dockerfile
COPY prometheus.template.yml /etc/prometheus/orig.yml

# Add an entrypoint script that uses envsubst to create the actual config
RUN printf '#!/bin/sh\n\
envsubst < /etc/prometheus/orig.yml > /etc/prometheus/prometheus.yml\n\
exec /bin/prometheus "$@"\n' > /etc/prometheus/entrypoint.sh && \
    chmod +x /etc/prometheus/entrypoint.sh


ENTRYPOINT ["/etc/prometheus/entrypoint.sh"]

CMD ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus"]

# Run as non-root
USER nobody

# Define a volume for Prometheus data
VOLUME ["/prometheus"]

# Set working directory
WORKDIR /prometheus
