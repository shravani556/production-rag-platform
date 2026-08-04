# Storage module

This provider-neutral module defines persistent-storage intent for ChromaDB,
Ollama model storage, Prometheus, Grafana, future application logs, and a
future backup repository. It creates no cloud disks, shares, object stores,
PersistentVolumes, StorageClasses, CSI drivers, or Kubernetes resources.

## Contract

`storage_definitions` is keyed by a stable logical identifier and records name,
type (`block`, `shared`, or `object`), capacity, access-mode placeholders,
performance tier, encryption requirement, policy references, retention,
mount-point placeholder, and future Kubernetes StorageClass/CSI mapping.

The same definition reserves object-storage, shared-storage, and block-storage
integration without choosing a provider. Backup and snapshot policy values are
references only; the policies and their execution are deferred to later phases.
No credentials, endpoint secrets, or keys belong in this module or Terraform
state.

## Relationships

Compute nodes will consume mount and attachment intent only after a provider
implementation is approved. Networking will later supply private endpoints,
DNS, or paths needed by object and shared storage; this module creates neither.
Kubernetes StorageClasses and CSI drivers will map the recorded references to
provider-specific implementations in a future Kubernetes/storage phase.

## Backup strategy

The contract separates backup and snapshot references from storage capacity so
the future backup platform can apply retention, encryption, immutability, and
off-site replication consistently. Restore testing and backup scheduling remain
out of scope until an approved storage and backup provider is selected.
