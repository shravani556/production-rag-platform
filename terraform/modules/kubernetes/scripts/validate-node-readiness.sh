#!/usr/bin/env bash
# Manual or controlled-automation validation only; never called by Terraform.
set -euo pipefail
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.conditions[?(@.type=="Ready")]}{.status}{end}{"\n"}{end}'
