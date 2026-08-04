# Kubernetes bootstrap module

This module contains a provider-neutral bootstrap contract and reusable assets.
It creates no resources, executes no scripts, installs no software, and does
not invoke `kubeadm`. A future approved cloud-init or provisioner phase may
render and execute these assets in a controlled order.

## Bootstrap sequence

1. Render the containerd and node-prerequisite templates on every approved node.
2. Install pinned Kubernetes packages and enable kubelet through the approved
   automation mechanism.
3. Render and execute the control-plane template on the single control-plane
   node; it initializes the cluster with the declared endpoint and CIDRs.
4. Obtain a short-lived, externally managed join token and CA hash, then render
   and execute the worker template on each worker node.
5. Install the approved CNI, then enable DNS, Metrics Server, ingress, CSI,
   LoadBalancer, and GPU integrations only in later approved phases.
6. Run validation scripts manually or from controlled automation after cluster
   bootstrap completes.

## Certificate and token flow

Token and certificate fields are references, never credentials. A future secret
manager or Vault integration must issue short-lived worker join material,
protect the control-plane certificate key, record its use, and revoke expired
tokens. The templates expect their runtime executor to retrieve these values;
they must not be rendered into Terraform state, source control, or logs.

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
