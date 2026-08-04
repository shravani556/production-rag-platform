#!/usr/bin/env bash
# Local node validation. This script does not change node state.
set -euo pipefail

test "$(swapon --noheadings | wc -l)" -eq 0
test "$(sysctl -n net.ipv4.ip_forward)" = "1"
test "$(sysctl -n net.bridge.bridge-nf-call-iptables)" = "1"
grep -qx 'overlay' /etc/modules-load.d/kubernetes.conf
grep -qx 'br_netfilter' /etc/modules-load.d/kubernetes.conf
systemctl is-enabled --quiet containerd
systemctl is-active --quiet containerd
systemctl is-enabled --quiet kubelet
systemctl is-active --quiet kubelet
containerd --version
kubeadm version -o short
kubelet --version
kubectl version --client=true

CRI_SOCKET="${CRI_SOCKET:-unix:///run/containerd/containerd.sock}"
crictl --runtime-endpoint "${CRI_SOCKET}" info >/dev/null
for module in overlay br_netfilter ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack; do
  lsmod | awk '{print $1}' | grep -qx "${module}"
done
