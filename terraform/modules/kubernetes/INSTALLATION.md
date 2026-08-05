# Kubernetes installation automation

## Scope

These provider-independent assets prepare an operator-controlled kubeadm
installation. They are never invoked by Terraform, cloud-init, CI, or Helm.
They create no VM, Kubernetes deployment, CNI, addon, application, or external
service unless an approved operator executes them in a later change.

## Execution order

1. Provision approved VMs externally and provide the role-specific cloud-init
   template. Cloud-init writes references only; it does not invoke kubeadm.
2. Run `prepare-node.sh`, `install-containerd.sh`, and `validate-node.sh` on
   every control-plane and worker VM. Supply approved OS repository/key URLs and
   pinned package versions at runtime.
3. Render `kubeadm-init-config.yaml.tftpl` in a controlled secret-management
   environment. Its certificate-key placeholder is runtime-only.
4. Run `kubeadm-init.sh` on the single control-plane node, then run
   `configure-kubeconfig.sh` and `validate-control-plane.sh`.
5. Select Cilium, Calico, or Flannel using `validate-cni-selection.sh`; perform
   CNI installation only in an approved operator change.
6. Render worker join configuration only with a short-lived bootstrap token and
   CA hash, then run `kubeadm-join.sh` on each worker: one in development and
   two in production.
7. Run `validate-cluster.sh` after CNI is ready. Metrics Server, ingress, CSI,
   GPU runtime, Helm, monitoring, Vault, and workloads remain later phases.

## Validation order

Local validation checks swap, kernel modules, sysctl, containerd, CRI socket,
kubelet, and client tools. Control-plane validation checks kubelet/containerd,
the API server readiness endpoint, and control-plane static pods including etcd.
Cluster validation checks nodes, all pods, CoreDNS readiness, API server,
scheduler, controller manager, and etcd pod presence.

## Addon instructions only

Metrics Server requires an approved manifest/version, compatibility review, and
post-install resource-metrics verification. Ingress requires an approved
controller, class, exposure model, TLS and network policies. CSI requires an
approved driver, StorageClass, snapshots, access policy, and backup/restore
test. GPU support requires an approved NVIDIA driver/runtime, node labelling,
resource-plugin compatibility, and scheduling policy. None is installed here.

## Rollback and recovery

Drain a worker before `reset-worker.sh`; it requires
`CONFIRM_KUBERNETES_RESET=yes`, resets kubeadm, cleans local CNI/kubelet state,
and flushes iptables. `reset-control-plane.sh` has the same confirmation and
also removes local control-plane certificates/configuration. Take and validate
an etcd backup before a control-plane reset. Rebuild from a known-good image if
state consistency is uncertain. Never use a kubeadm downgrade as rollback.

## Upgrades, pinning, HA, and disaster recovery

Pin kubeadm, kubelet, kubectl, and containerd using approved repository and
OS-specific package versions. Upgrade the control plane first, then drained
workers one at a time, validating after each step and preserving rollback
evidence. A future HA migration requires a stable load-balanced control-plane
endpoint, sequential additional control planes, renewed certificate assumptions,
and tested etcd quorum/recovery. Disaster recovery requires encrypted, tested
etcd backups, node-image provenance, CNI configuration records, and runbooks
for credential, certificate, and endpoint recovery.
