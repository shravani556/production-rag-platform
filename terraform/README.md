# Terraform foundation

This directory is the provider-neutral foundation for the RAG platform
infrastructure. It deliberately contains no provider configuration, resources,
cloud integrations, VM definitions, networking, Kubernetes installation, or
deployment automation.

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

`common` is the only implemented foundation module. It standardizes project,
environment, name-prefix, and tag metadata without creating infrastructure.
The remaining modules are intentionally empty contracts for future phases.
Both environment roots consume the same module set so provider-specific work can
be added once and reused without duplicating environment code.

## Environment strategy

`dev` and `prod` are isolated Terraform root modules. Each starts with a local
backend state file in its own directory. This is appropriate only for the
foundation and local validation. Before collaborative or production use, Phase
6B must replace the local backend with an approved remote backend that provides
locking, encryption, access control, and backup.

## Execution order

1. Select the target environment (`environments/dev` or `environments/prod`).
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace placeholders.
3. Run `terraform init` in that environment root.
4. Run `terraform fmt -check -recursive ../../` and `terraform validate`.
5. Future phases may introduce provider configuration and resources only after
   architecture approval. Do not apply this foundation as infrastructure code.

Because this foundation has no managed resources, a plan using the example
values will have no resources to create, change, or destroy.
