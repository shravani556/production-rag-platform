# Security module

This provider-neutral module records enterprise security intent. It creates no
firewalls, NSGs, security groups, IAM identities or policies, Vault instances,
certificates, SSH keys, Kubernetes RBAC, or infrastructure resources.

## Responsibilities

`security_configuration` captures management and break-glass access, network
policy intent, future firewall/security-group/NSG/IAM mappings, Vault, PKI,
certificate, Secrets Store CSI, OIDC, workload identity, and key-management
integration references. It also records encryption, audit, compliance, CIS,
SOC 2, and ISO 27001 control intent. All identities and integrations are
non-secret references; credentials, private keys, certificates, and tokens are
prohibited.

## Relationships

Networking will translate ingress, egress, management-CIDR, and node-to-node
intent into approved provider controls. Compute will consume SSH and
administrative-access policy during node bootstrap. Storage will consume
encryption, key-management, backup, and audit requirements. Future Kubernetes
bootstrap will map relevant contracts to admission, RBAC, NetworkPolicy,
StorageClass, CSI, OIDC, and workload-identity implementations without this
module creating any of them.

## Future enterprise architecture

Vault and PKI references establish the integration boundary for secret delivery
and certificate lifecycle management. Central identity, workload identity, KMS,
audit sinks, compliance evidence, and benchmark tracking remain deliberately
provider-neutral until the target control plane and governance tools are
approved.
