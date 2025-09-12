# Base
FROM python:3.11-slim

# Security & determinism
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create app dir and non-root user/group (uid/gid 10001 is a common choice)
RUN addgroup --system app && adduser --system --ingroup app --uid 10001 app

WORKDIR /app

# Copy requirements first for better layer caching
COPY --chown=app:app requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code as non-root
COPY --chown=app:app registrar.py services.yaml /app/

# Switch to non-root
USER 10001:10001

# Run  registrar once, then keep pod alive for reboots/reschedules
CMD ["bash","-lc","python /app/registrar.py /app/services.yaml && sleep infinity"]
