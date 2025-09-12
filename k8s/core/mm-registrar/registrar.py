#!/usr/bin/env python3
"""
registrar.py

Reads services.yaml from the same directory as this script (or SERVICES_CONFIG_PATH env override)
and registers services in Consul with Traefik tags and checks.

Env:
 - CONSUL_URL            (optional if consul_url is set in services.yaml)
 - CONSUL_TOKEN          (optional)
 - DO_DEREGISTER         ("true"/"1"/"yes" to deregister mm-* missing services)
 - SERVICES_CONFIG_PATH  (optional path to override default)

# Startup wait / connectivity checks
 - CONSUL_WAIT_TIMEOUT   (seconds, default 90) — total time to wait for consul to be ready
 - CONSUL_WAIT_INTERVAL  (seconds, default 2)  — how often to ping

# TLS options (if you use https or self-signed certs)
 - CONSUL_INSECURE       ("true"/"1"/"yes" -> skip TLS verify)
 - CONSUL_CA_CERT        (path to CA bundle file)

Usage:
  python registrar.py
"""
from __future__ import annotations
import os
import sys
import time
import json
from typing import Dict, Any, List, Optional

import requests
import yaml

# --- Configurable constants ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CONFIG_FILENAME = "services.yaml"
CONFIG_PATH = os.getenv("SERVICES_CONFIG_PATH", os.path.join(SCRIPT_DIR, DEFAULT_CONFIG_FILENAME))
DEFAULT_ID_PREFIX = "mm-"
REQUEST_TIMEOUT = 10
RETRY_COUNT = 3
RETRY_DELAY = 2

CONSUL_WAIT_TIMEOUT = int(os.getenv("CONSUL_WAIT_TIMEOUT", "90"))
CONSUL_WAIT_INTERVAL = float(os.getenv("CONSUL_WAIT_INTERVAL", "2"))

# TLS verify parameter for requests
_INSECURE = os.getenv("CONSUL_INSECURE", "false").lower() in ("1", "true", "yes")
_CA_CERT = os.getenv("CONSUL_CA_CERT")
if _INSECURE:
    VERIFY_TLS: bool | str = False
elif _CA_CERT:
    VERIFY_TLS = _CA_CERT
else:
    VERIFY_TLS = True


# --- Helpers ---
def now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def log(msg: str, err: bool = False) -> None:
    prefix = "[registrar] "
    line = f"{now()} {prefix}{msg}"
    if err:
        print(line, file=sys.stderr, flush=True)
    else:
        print(line, flush=True)


# --- Load config ---
def load_config(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        raise FileNotFoundError(f"config file not found: {path}")
    with open(path, "r") as fh:
        data = yaml.safe_load(fh) or {}
    return data


# --- Build payloads ---
def build_tags(svc: Dict[str, Any], id_prefix: str) -> List[str]:
    name = svc.get("name")
    if not name:
        raise KeyError("service missing 'name'")

    if "prefix" not in svc:
        svc['prefix']=""

    if "port" not in svc:
        raise KeyError(f"service '{name}' missing required 'port'")

    rid = svc.get("id") or f"{id_prefix}{name}"
    tags = [
        "traefik.enable=true",
        f"traefik.http.routers.{rid}.rule=PathPrefix(`{svc['prefix']}`)",
        f"traefik.http.routers.{rid}.entrypoints={svc.get('entrypoint','internal')}",
        f"traefik.http.services.{rid}.loadbalancer.server.port={svc['port']}",
    ]
    middleware = svc.get("middleware")
    if middleware:
        tags.append(f"traefik.http.routers.{rid}.middlewares={middleware}")
    return tags


def build_check(svc: Dict[str, Any]) -> Dict[str, Any]:
    interval = svc.get("check_interval", "10s")
    timeout = svc.get("check_timeout", "2s")
    deregister_after = svc.get("deregister_after")

    if "address" not in svc or "port" not in svc:
        raise KeyError(f"service '{svc.get('name','<unknown>')}' must have 'address' and 'port'")

    if svc.get("check_http"):
        http_path = svc["check_http"]
        if not http_path.startswith("/"):
            http_path = "/" + http_path
        http_url = f"http://{svc['address']}:{svc['port']}{http_path}"
        check = {"HTTP": http_url, "Interval": interval, "Timeout": timeout}
    else:
        tcp_addr = f"{svc['address']}:{svc['port']}"
        check = {"TCP": tcp_addr, "Interval": interval, "Timeout": timeout}

    if deregister_after:
        check["DeregisterCriticalServiceAfter"] = deregister_after
    return check


def build_payload(svc: Dict[str, Any], id_prefix: str) -> Dict[str, Any]:
    sid = svc.get("id") or f"{id_prefix}{svc.get('name')}"
    payload: Dict[str, Any] = {
        "ID": sid,
        "Name": sid,
        "Tags": build_tags(svc, id_prefix),
        "Address": svc["address"],
        "Port": int(svc["port"]),
        "Check": build_check(svc),
    }
    return payload


# --- Consul operations ---
def _headers(token: Optional[str]) -> Dict[str, str]:
    h = {"Content-Type": "application/json"}
    if token:
        h["X-Consul-Token"] = token
    return h


def consul_put_register(consul_url: str, payload: Dict[str, Any], token: Optional[str] = None) -> None:
    url = consul_url.rstrip("/") + "/v1/agent/service/register"
    data = json.dumps(payload)
    last_exc = None
    for attempt in range(1, RETRY_COUNT + 1):
        try:
            r = requests.put(url, headers=_headers(token), data=data, timeout=REQUEST_TIMEOUT, verify=VERIFY_TLS)
            r.raise_for_status()
            log(f"registered {payload['ID']} (HTTP {r.status_code})")
            return
        except Exception as e:
            last_exc = e
            log(f"register attempt {attempt}/{RETRY_COUNT} failed for {payload['ID']}: {e}", err=True)
            time.sleep(RETRY_DELAY)
    raise RuntimeError(f"register failed for {payload['ID']}: {last_exc}")


def consul_list_services(consul_url: str, token: Optional[str] = None) -> Dict[str, Any]:
    url = consul_url.rstrip("/") + "/v1/agent/services"
    r = requests.get(url, headers=_headers(token), timeout=REQUEST_TIMEOUT, verify=VERIFY_TLS)
    r.raise_for_status()
    return r.json()


def consul_deregister(consul_url: str, service_id: str, token: Optional[str] = None) -> None:
    url = consul_url.rstrip("/") + f"/v1/agent/service/deregister/{service_id}"
    r = requests.put(url, headers=_headers(token), timeout=REQUEST_TIMEOUT, verify=VERIFY_TLS)
    r.raise_for_status()
    log(f"deregistered {service_id} (HTTP {r.status_code})")


# --- Consul readiness / ping ---
def consul_is_ready(consul_url: str, token: Optional[str]) -> bool:
    """
    Consider Consul 'ready' if either:
      - /v1/agent/self responds 200, OR
      - /v1/status/leader responds 200 with a non-empty leader string.
    """
    base = consul_url.rstrip("/")

    # Try agent first (since we register via agent API)
    try:
        resp = requests.get(f"{base}/v1/agent/self", headers=_headers(token), timeout=REQUEST_TIMEOUT, verify=VERIFY_TLS)
        if resp.status_code == 200 and isinstance(resp.json(), dict):
            return True
    except Exception:
        pass

    # Fallback to server cluster leader check
    try:
        resp = requests.get(f"{base}/v1/status/leader", headers=_headers(token), timeout=REQUEST_TIMEOUT, verify=VERIFY_TLS)
        if resp.status_code == 200:
            leader = (resp.text or "").strip().strip('"')
            if leader:
                return True
    except Exception:
        pass

    return False


def consul_wait_ready(consul_url: str, token: Optional[str], timeout_s: int, interval_s: float) -> None:
    start = time.time()
    log(f"waiting for Consul at {consul_url} (timeout={timeout_s}s, interval={interval_s}s)")
    while True:
        if consul_is_ready(consul_url, token):
            log("Consul is ready ✔")
            return
        if time.time() - start > timeout_s:
            raise TimeoutError(f"Consul not ready within {timeout_s}s at {consul_url}")
        time.sleep(interval_s)


# --- Main ---
def main() -> int:
    # Load config
    try:
        cfg = load_config(CONFIG_PATH)
    except Exception as e:
        log(f"failed to read config '{CONFIG_PATH}': {e}", err=True)
        return 2

    # Resolve Consul URL & token
    consul_url = os.getenv("CONSUL_URL") or cfg.get("consul_url")
    if not consul_url:
        log("CONSUL_URL not provided (env CONSUL_URL or 'consul_url' in config)", err=True)
        return 3

    consul_token = os.getenv("CONSUL_TOKEN") or cfg.get("consul_token")
    do_deregister = os.getenv("DO_DEREGISTER", "false").lower() in ("1", "true", "yes")
    id_prefix = cfg.get("id_prefix", DEFAULT_ID_PREFIX)
    services = cfg.get("services", [])

    if not services:
        log("no services defined; nothing to do")
        return 0

    # --- NEW: wait for discovery server to be reachable before registering ---
    try:
        consul_wait_ready(consul_url, consul_token, timeout_s=CONSUL_WAIT_TIMEOUT, interval_s=CONSUL_WAIT_INTERVAL)
    except Exception as e:
        log(f"consul readiness check failed: {e}", err=True)
        return 4

    # Optionally verify permissions (helpful error early)
    try:
        _ = consul_list_services(consul_url, token=consul_token)
    except Exception as e:
        log(f"warning: cannot list services (token/ACL issue?): {e}", err=True)

    # --- Register ---
    registered_ids: List[str] = []
    log(f"begin registering {len(services)} services to {consul_url}")

    for s in services:
        try:
            payload = build_payload(s, id_prefix)
        except Exception as e:
            log(f"skipping service (invalid config): {e}", err=True)
            continue

        try:
            consul_put_register(consul_url, payload, token=consul_token)
            registered_ids.append(payload["ID"])
        except Exception as e:
            log(f"ERROR registering {payload.get('ID')}: {e}", err=True)

    # --- Optional deregistration of stale mm-* services ---
    if do_deregister:
        try:
            existing = consul_list_services(consul_url, token=consul_token)
            to_remove = [sid for sid in existing.keys() if sid.startswith(id_prefix) and sid not in registered_ids]
            if to_remove:
                log(f"found {len(to_remove)} {id_prefix}* services to deregister: {to_remove}")
            for sid in to_remove:
                try:
                    consul_deregister(consul_url, sid, token=consul_token)
                except Exception as e:
                    log(f"failed to deregister {sid}: {e}", err=True)
        except Exception as e:
            log(f"failed to list services for deregistration: {e}", err=True)

    log("done")
    return 0


if __name__ == "__main__":
    # suppress SSL warnings if user opted to skip verification
    try:
        if VERIFY_TLS is False:
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    except Exception:
        pass

    sys.exit(main())
