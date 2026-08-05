#!/usr/bin/env bash
# Provider-independent bootstrap asset. Run only through approved post-VM automation.
set -euo pipefail

require_value() { [[ -n "${!1:-}" ]] || { echo "${1} must be set" >&2; exit 2; }; }
require_value CONTAINERD_VERSION
require_value SANDBOX_IMAGE

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y "containerd=${CONTAINERD_VERSION}" || apt-get install -y containerd
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y "containerd-${CONTAINERD_VERSION}" || dnf install -y containerd
else
  echo "Unsupported package manager; install containerd ${CONTAINERD_VERSION} through the approved repository." >&2
  exit 1
fi

install -d -m 0755 /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i "s#sandbox_image = \".*\"#sandbox_image = \"${SANDBOX_IMAGE}\"#" /etc/containerd/config.toml

# REGISTRY_MIRRORS is a comma-separated list of approved registry-host=endpoint pairs.
# Configure mirror blocks through the approved configuration-management layer; do not
# place registry credentials in this script or its environment file.
: "${REGISTRY_MIRRORS:=}"
systemctl daemon-reload
systemctl enable --now containerd
