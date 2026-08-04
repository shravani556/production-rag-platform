#!/usr/bin/env bash
# Validates an approved CNI choice without downloading or installing it.
set -euo pipefail

CNI_PROVIDER="${CNI_PROVIDER:-}"
CNI_MANIFEST_REFERENCE="${CNI_MANIFEST_REFERENCE:-}"
case "${CNI_PROVIDER}" in cilium|calico|flannel) ;; *) echo "CNI_PROVIDER must be cilium, calico, or flannel." >&2; exit 2;; esac
[[ -n "${CNI_MANIFEST_REFERENCE}" ]] || { echo "CNI_MANIFEST_REFERENCE must be set." >&2; exit 2; }
printf 'Approved CNI selection: %s (%s)\n' "${CNI_PROVIDER}" "${CNI_MANIFEST_REFERENCE}"
