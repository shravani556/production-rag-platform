#!/usr/bin/env bash
# Manual or controlled-automation validation only; never called by Terraform.
set -euo pipefail
kubectl get nodes -l node-role.kubernetes.io/control-plane
kubectl -n kube-system get pods
