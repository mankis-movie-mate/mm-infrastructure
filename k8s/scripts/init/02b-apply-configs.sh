#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

kubectl apply -f ../../config/ -n "$NAMESPACE"
