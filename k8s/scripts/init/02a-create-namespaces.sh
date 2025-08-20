#!/usr/bin/env bash
set -e

source "$(dirname "$0")/env.sh"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
