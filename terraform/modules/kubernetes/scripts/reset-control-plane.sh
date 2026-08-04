#!/usr/bin/env bash
# Destructive rollback helper. Use only after etcd backup and change approval.
set -euo pipefail

[[ "${CONFIRM_KUBERNETES_RESET:-}" == "yes" ]] || {
  echo "Set CONFIRM_KUBERNETES_RESET=yes after etcd backup and control-plane reset approval." >&2
  exit 2
}
"$(dirname "$0")/reset-worker.sh"
rm -rf /etc/kubernetes/pki /etc/kubernetes/admin.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf
