#!/usr/bin/env bash
# Explicit post-init helper. It copies kubeconfig only after kubeadm init succeeds.
set -euo pipefail

ADMIN_CONF_PATH="${ADMIN_CONF_PATH:-/etc/kubernetes/admin.conf}"
KUBECONFIG_TARGET_USER="${KUBECONFIG_TARGET_USER:-root}"
target_home="$(getent passwd "${KUBECONFIG_TARGET_USER}" | cut -d: -f6)"
[[ -n "${target_home}" && -f "${ADMIN_CONF_PATH}" ]] || {
  echo "An existing admin.conf and a valid KUBECONFIG_TARGET_USER are required." >&2
  exit 2
}

install -d -m 0700 -o "${KUBECONFIG_TARGET_USER}" -g "${KUBECONFIG_TARGET_USER}" "${target_home}/.kube"
install -m 0600 -o "${KUBECONFIG_TARGET_USER}" -g "${KUBECONFIG_TARGET_USER}" "${ADMIN_CONF_PATH}" "${target_home}/.kube/config"
