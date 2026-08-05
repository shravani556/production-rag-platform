# Kubernetes bootstrap module

This module contains a provider-neutral bootstrap contract and reusable assets.
It creates no resources, executes no scripts, installs no software, and does
not invoke `kubeadm`. A future approved cloud-init or provisioner phase may
render and execute these assets in a controlled order.

## Bootstrap sequence

1. Supply the role-specific cloud-init template during VM provisioning. It sets
   hostname/time and writes only non-secret bootstrap references; it does not
   run bootstrap scripts, `kubeadm`, or a join operation.
2. An approved post-VM executor runs `prepare-node.sh` and
   `install-containerd.sh` on every node, then runs `validate-node.sh`.
3. Provide the approved repository and key URLs plus OS-specific package version
   to `prepare-node.sh`; it installs and pins kubeadm, kubelet, and kubectl.
4. In a separately approved Kubernetes-installation phase, run
   `kubeadm-init.sh` only on the control plane with ephemeral runtime config.
5. After CNI approval, run `kubeadm-join.sh` on each worker with short-lived
   runtime join material, then use `validate-cluster.sh`.
6. DNS, Metrics Server, ingress, CSI, LoadBalancer, GPU, Helm, and workloads
   remain later-phase integrations.

## Certificate and token flow

Token and certificate fields are references, never credentials. A future secret
manager or Vault integration must issue short-lived worker join material,
protect the control-plane certificate key, record its use, and revoke expired
tokens. The scripts accept that material only at runtime; it must not be
rendered into cloud-init, Terraform state, source control, or logs.

## Operations strategy

Upgrades must follow the declared version-skew policy: drain a worker, upgrade
control plane first, then workers one at a time, validate, and retain rollback
evidence. Rollback restores known-good node images/configuration and the
documented etcd backup where compatible; it must not assume `kubeadm downgrade`
is safe. Disaster recovery requires encrypted, tested etcd and persistent-data
backups plus reconstruction from these versioned contracts. Future HA migration
replaces the single control-plane endpoint with a stable load-balanced endpoint,
adds control planes sequentially, and updates certificates and CNI assumptions
under an approved migration plan.
