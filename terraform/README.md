# Terraform foundation

This directory is the provider-neutral foundation for the RAG platform
infrastructure. Phase 6F defines reusable networking, compute, storage, security, and Kubernetes bootstrap contracts,
but still contains no provider configuration or managed infrastructure
resources.

## Layout

```text
terraform/
├── modules/
│   ├── common/       # Shared naming, environment metadata, and tags
│   ├── networking/   # Reserved for network primitives
│   ├── compute/      # Reserved for control-plane and worker compute
│   ├── kubernetes/   # Reserved for cluster lifecycle configuration
│   ├── storage/      # Reserved for persistent storage primitives
│   ├── monitoring/   # Reserved for observability infrastructure
│   └── security/     # Reserved for infrastructure security controls
└── environments/
    ├── dev/          # Development root module
    └── prod/         # Production root module
```

## Module responsibilities

`common` standardizes project, environment, name-prefix, and tag metadata.
`networking` records CIDR, DNS, and future subnet/load-balancer/NAT/ingress/VPN/
private-networking/storage-endpoint intent without creating infrastructure.
`compute` records static control-plane and worker topology, hostnames, capacity,
labels, SSH and cloud-init references, and future GPU, extra-disk, availability-
zone, and autoscaling intent. `storage` records persistence intent for ChromaDB,
Ollama, Prometheus, Grafana, future logs, and backups, including capacity,
access-mode and mount placeholders, encryption, policy references, and future
block/shared/object, StorageClass, and CSI mapping. It neither attaches storage
to compute nor creates networking endpoints, Kubernetes resources, or storage
resources. `security` records access, network-policy, encryption, audit,
compliance, identity, secret-management, certificate, PKI, and future
firewall/IAM integration intent. It neither creates nor configures any security
control. `kubernetes` records bootstrap configuration and points to inert
containerd, node prerequisite, control-plane, worker-join, and validation
assets. It does not install software, execute scripts, invoke kubeadm, or
create a cluster. Both environment roots consume the same module set so
provider-specific work can be added once and reused without duplicating module
implementation code.

## Environment strategy

`dev` and `prod` are isolated Terraform root modules. Each starts with a local
backend state file in its own directory. Dev reserves `10.10.0.0/16`; Prod
reserves `10.20.0.0/16`. These are placeholders, not provisioned networks. The
CIDRs must be checked for overlap before any provider-specific resources are
introduced. The local backend is appropriate only for foundation validation;
before collaborative or production use it must be replaced with an approved
remote backend that provides locking, encryption, access control, and backup.

## Execution order

1. Select the target environment (`environments/dev` or `environments/prod`).
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders.
3. Run `terraform init` in that environment root.
4. Run `terraform fmt -check -recursive ../../`, `terraform validate`, and
   `terraform plan -input=false -lock=false`.
5. Future phases may introduce provider configuration and resources only after
   architecture approval. Do not apply this foundation as infrastructure code.

Because Phase 6F has no managed resources, a plan using the example values will
have no resources to create, change, or destroy.
