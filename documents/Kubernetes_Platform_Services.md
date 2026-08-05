# Kubernetes platform services

## Scope and dependencies

Phase 12 is non-executing. Its Helm value contracts are not charts and cannot
create a release, CRD, namespace, or workload. The platform first requires a
healthy Kubernetes control plane, CNI, CoreDNS, and provider-supported network
exposure. The target installation order is: cert-manager CRDs/controller,
ingress-nginx, metrics-server, approved CSI driver/StorageClasses, CoreDNS
tuning, optional Node Local DNS, optional GPU Operator, and finally any
dashboard access layer. No Issuer, ClusterIssuer, dashboard, or platform
service is created in this phase.

## Service decisions

ingress-nginx is designed for two replicas, anti-affinity, topology spread,
PDB, admission webhooks, metrics, TLS integration, and empty provider-specific
LoadBalancer annotation placeholders. Cert-manager is designed for controller,
webhook, and cainjector high availability; its CRD flag remains false until the
approved release operation. Issuers are deliberately absent.

Metrics Server has two planned replicas and secure kubelet-address preferences.
Do not enable insecure kubelet TLS in production: the aggregation layer and
valid kubelet certificates are prerequisites. CoreDNS is tuned conservatively
with two replicas, PDB, bounded cache, and deferred upstream references. Node
Local DNS remains documentation only until its networking, address, and CNI
compatibility design is approved.

CSI remains provider-neutral: select a driver after provider selection, use
`WaitForFirstConsumer` for topology-aware placement, allow expansion only when
supported, and default persistent production data to `Retain` until backup and
deletion controls are approved. Dynamic provisioning, snapshots, and backup are
disabled placeholders. GPU Operator and Kubernetes Dashboard are disabled;
both require dedicated security reviews before any adoption.

## Future validation commands

After a separately approved installation, validate rendered values offline with
`helm lint` and `helm template` against the exact pinned upstream chart. Then
check controller readiness, admission webhook health, IngressClass, Metrics API,
CoreDNS readiness, CSI driver registration, StorageClass behaviour, and
certificate-controller logs using read-only `kubectl get` and `kubectl describe`
commands. Validate dashboard access with least-privilege identities only. Do not
create or upgrade a Helm release, or submit manifests to the API server, until
an authorized deployment phase.

## Security and availability

Use least-privilege RBAC, network policies, pod security controls, trusted
images, pinned chart versions/digests, admission-webhook availability, TLS
rotation, and audit logging. Place redundant controllers on distinct nodes with
PDBs and topology spread. Protect service endpoints with private exposure or
approved load-balancer controls. Do not expose a dashboard publicly or grant it
cluster-admin access.

## Upgrade, rollback, and disaster recovery

Review chart release notes, CRD migration requirements, Kubernetes-version
compatibility, and rendered diffs before each upgrade. Upgrade one platform
service at a time and verify its health before the next. Rollback to the last
approved chart and values revision only when the upstream compatibility matrix
permits it; CRDs often need a dedicated migration/rollback plan. Back up
configuration, dashboards, certificate and CSI metadata, and cluster state.
Test restoration in an isolated environment, with special attention to
certificate issuance, persistent volumes, and DNS recovery.
