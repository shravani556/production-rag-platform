# Future Vault authentication contract

Phase 8 does not authenticate GitHub Actions to Vault. No workflow logs in to
Vault, reads a secret, creates a token, invokes a Vault command, or configures a
Vault action. This document is a planning boundary for a future, separately
approved implementation.

## Intended production pattern

Use GitHub Actions OIDC federation with Vault's JWT/OIDC auth method. Bind a
dedicated, least-privilege Vault role to the repository, protected environment,
branch or tag, workflow, and audience claims. Grant the role only the policy
capabilities needed by the one automation operation. Prefer short TTLs, narrow
bound claims, immutable release references, and GitHub Environment approval for
production.

Do not use long-lived Vault tokens, AppRole secret IDs, client certificates, or
static cloud credentials as GitHub secrets. A future workflow must obtain a
short-lived identity during the job, avoid printing sensitive values, mask
outputs, and revoke or expire access at job completion.

## Required approval before implementation

- Vault endpoint, namespace, OIDC issuer, and allowed audiences are approved.
- The production GitHub Environment has required reviewers and restricted refs.
- Vault policies, role bindings, TTLs, audit sink, rotation, and incident
  response runbook are reviewed by platform security.
- The workflow has a tested failure path that performs no deployment when Vault
  authentication or authorization fails.
- Secret delivery is selected deliberately: runtime workload identity, External
  Secrets Operator, or Secrets Store CSI Driver. CI must not become a general
  secret-distribution channel.

Any implementation following this document must be reviewed as a new phase and
must explicitly add its least-privilege policy and validation evidence.
