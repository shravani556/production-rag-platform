#!/usr/bin/env bash
# Explicit control-plane validation. It does not modify cluster state.
set -euo pipefail

systemctl is-active --quiet kubelet
systemctl is-active --quiet containerd
test -f /etc/kubernetes/admin.conf
kubectl get --raw='/readyz?verbose'
kubectl -n kube-system get pods -l component=kube-apiserver
kubectl -n kube-system get pods -l component=kube-scheduler
kubectl -n kube-system get pods -l component=kube-controller-manager
kubectl -n kube-system get pods -l component=etcd
