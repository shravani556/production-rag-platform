#!/usr/bin/env bash
# Manual or controlled-automation validation only; never called by Terraform.
set -euo pipefail
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/healthz'
