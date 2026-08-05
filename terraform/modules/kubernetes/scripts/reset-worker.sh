#!/usr/bin/env bash
# Destructive rollback helper. It runs only when explicitly invoked and confirmed.
set -euo pipefail

[[ "${CONFIRM_KUBERNETES_RESET:-}" == "yes" ]] || {
  echo "Set CONFIRM_KUBERNETES_RESET=yes after draining and approving this worker reset." >&2
  exit 2
}
kubeadm reset --force
systemctl stop kubelet || true
rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes/kubelet.conf
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
