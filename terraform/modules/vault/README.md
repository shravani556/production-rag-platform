# Vault foundation module

This provider-neutral module records future HashiCorp Vault integration intent.
It declares no Vault provider, secrets engine, policy, token, certificate, or
infrastructure resource.

The contract covers KV v2 versioned paths, Kubernetes/AppRole/OIDC authentication
references, Transit, PKI, dynamic database and cloud credentials, audit logging,
disaster recovery, HSM/KMS, External Secrets Operator, and Secrets Store CSI.
Every identity, path, policy, ownership, rotation, lifecycle, and endpoint value
is a non-secret reference.

Secret owners approve access policies and rotation windows; platform security
operates Vault, audit, backup, and break-glass controls; workload teams own the
application-level secret contract. Revocation removes the workload policy or
identity first, rotates the credential second, and retains audit evidence.
Recovery requires independently tested encrypted Vault backups, unseal/recovery
material governed by the approved HSM/KMS design, and documented break-glass
approval. Future runtime integrations must use least-privilege workload identity
and short-lived credentials, aligned with zero-trust principles.
