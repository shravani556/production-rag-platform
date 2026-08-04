# Continuous deployment foundation

Phase 7 adds manual, gated continuous-deployment preparation only. It never
connects to Kubernetes, invokes `kubectl`, runs `helm upgrade` or `helm install`,
or pushes an image unless an operator explicitly sets `push_images` to `true`.

## Workflow architecture

`cd-artifacts.yml` is the reusable build and package workflow. It validates and
packages both Helm charts, renders manifests locally, builds the RAG image, and
optionally builds Ollama. It tags images with the immutable Git SHA and, when
enabled, the supplied semantic-version placeholder. Release artifacts are
retained for 30 days in development and 90 days in production.

`deploy-development.yml` and `deploy-production.yml` are manual entry points.
They call the reusable workflow, then record a smoke-test placeholder and a
deployment summary. They do not deploy. `rollback.yml` is also manual and only
records the approved immutable release reference; it performs no rollback.
`release-tag.yml` is manual and creates an annotated semantic Git tag.

Vault authentication is deliberately outside this foundation. See
[`VAULT_AUTHENTICATION.md`](VAULT_AUTHENTICATION.md) for the non-executable
future integration contract.

## Registry abstraction

Configure the following secrets in each GitHub Environment; no workflow code
contains a registry URL, image repository, username, or token:

- `CONTAINER_REGISTRY`
- `CONTAINER_REPOSITORY`
- `OLLAMA_CONTAINER_REPOSITORY` (only when optional Ollama push is enabled)
- `REGISTRY_USERNAME`
- `REGISTRY_TOKEN`

The interface works with GHCR, Docker Hub, Azure Container Registry, Amazon
ECR, Google Artifact Registry, or another registry whose credentials support
`docker login`. Keep `push_images` false until the registry and permissions are
approved. Configure GitHub Environment secrets and protection rules for
`development` and `production`; production required reviewers provide manual
approval before its environment-bound jobs run.

## Release and rollback strategy

Immutable Git SHA tags are the primary deployment identity. Semantic tags are
human-facing release aliases and must be created only after validation. Future
deployment automation must resolve a rollback to an immutable, signed artifact,
validate chart compatibility, and record the result. It must not rely on mutable
registry tags such as `latest`.
