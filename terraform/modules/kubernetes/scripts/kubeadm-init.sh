#!/usr/bin/env bash
# Run only on an approved control-plane node after prepare-node.sh validation.
set -euo pipefail

KUBEADM_CONFIG_PATH="${KUBEADM_CONFIG_PATH:-}"
[[ -n "${KUBEADM_CONFIG_PATH}" && -f "${KUBEADM_CONFIG_PATH}" ]] || {
  echo "Set KUBEADM_CONFIG_PATH to an approved, runtime-supplied kubeadm config file." >&2
  exit 2
}

# The runtime config supplies endpoint, CIDRs, and certificate handling. It must not
# be committed, rendered into Terraform state, or logged by this script. --upload-certs
# makes the certificate key available only in kubeadm output for controlled, ephemeral
# worker/control-plane operations; this script never stores that key.
kubeadm init --config "${KUBEADM_CONFIG_PATH}" --upload-certs
