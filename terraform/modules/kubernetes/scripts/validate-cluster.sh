#!/usr/bin/env bash
# Cluster validation. Run only after approved kubeadm initialization and CNI deployment.
set -euo pipefail

KUBECTL_CONTEXT="${KUBECTL_CONTEXT:-}"
context_args=()
if [[ -n "${KUBECTL_CONTEXT}" ]]; then context_args+=(--context "${KUBECTL_CONTEXT}"); fi

kubectl "${context_args[@]}" get --raw='/readyz?verbose'
kubectl "${context_args[@]}" get nodes
kubectl "${context_args[@]}" get pods --all-namespaces
kubectl "${context_args[@]}" -n kube-system wait --for=condition=Ready pod -l k8s-app=kube-dns --timeout="${COREDNS_TIMEOUT:-180s}"
kubectl "${context_args[@]}" -n kube-system get pods -l component=kube-apiserver
kubectl "${context_args[@]}" -n kube-system get pods -l component=kube-scheduler
kubectl "${context_args[@]}" -n kube-system get pods -l component=kube-controller-manager
kubectl "${context_args[@]}" -n kube-system get pods -l component=etcd
