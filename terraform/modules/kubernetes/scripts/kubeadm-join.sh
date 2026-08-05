#!/usr/bin/env bash
# Run only on an approved worker with short-lived, runtime-supplied join material.
set -euo pipefail

[[ "$#" -gt 0 ]] || {
  echo "Pass the approved ephemeral kubeadm join arguments at execution time." >&2
  exit 2
}

# Do not persist join arguments. They may include short-lived authentication data.
kubeadm join "$@"
