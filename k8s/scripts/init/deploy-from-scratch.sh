#!/usr/bin/env bash
set -e

./01-helm-init.sh
./02a-create-namespaces.sh
./02b-apply-configs.sh
./03-install-databases.sh
./04-install-observability.sh
./05-install-core.sh
