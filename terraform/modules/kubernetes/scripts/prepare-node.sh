#!/usr/bin/env bash
# Provider-independent bootstrap asset. It prepares a node but never runs kubeadm.
set -euo pipefail

require_value() { [[ -n "${!1:-}" ]] || { echo "${1} must be set" >&2; exit 2; }; }
require_value NODE_HOSTNAME
require_value KUBERNETES_VERSION
require_value KUBERNETES_REPOSITORY_URL
require_value KUBERNETES_REPOSITORY_KEY_URL
require_value KUBERNETES_PACKAGE_VERSION

hostnamectl set-hostname "${NODE_HOSTNAME}"
if command -v timedatectl >/dev/null 2>&1; then timedatectl set-ntp true; fi

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates curl gpg ipset ipvsadm conntrack socat
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL "${KUBERNETES_REPOSITORY_KEY_URL}" | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${KUBERNETES_REPOSITORY_URL} /" > /etc/apt/sources.list.d/kubernetes.list
  apt-get update
  apt-get install -y \
    "kubelet=${KUBERNETES_PACKAGE_VERSION}" \
    "kubeadm=${KUBERNETES_PACKAGE_VERSION}" \
    "kubectl=${KUBERNETES_PACKAGE_VERSION}"
  apt-mark hold kubelet kubeadm kubectl
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y ca-certificates curl ipset ipvsadm conntrack-tools socat
  cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=${KUBERNETES_REPOSITORY_URL}
enabled=1
gpgcheck=1
gpgkey=${KUBERNETES_REPOSITORY_KEY_URL}
EOF
  dnf install -y \
    "kubelet-${KUBERNETES_PACKAGE_VERSION}" \
    "kubeadm-${KUBERNETES_PACKAGE_VERSION}" \
    "kubectl-${KUBERNETES_PACKAGE_VERSION}"
  dnf versionlock add kubelet kubeadm kubectl || true
else
  echo "Unsupported package manager; install prerequisites from ${KUBERNETES_REPOSITORY_URL}." >&2
  exit 1
fi

cat >/etc/modules-load.d/kubernetes.conf <<'EOF'
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
modprobe overlay
modprobe br_netfilter
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack

cat >/etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
swapoff -a
sed -ri '/\sswap\s/s/^/#/' /etc/fstab

# Do not add SSH, auditd, fail2ban, or firewall rules here until the security baseline
# is approved; their configuration is a controlled placeholder, not an implicit default.
