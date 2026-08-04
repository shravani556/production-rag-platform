# Vault integration foundation

## Scope and architecture

Phase 8 records a provider-neutral Vault contract for the RAG platform. It does
not deploy Vault, configure a Terraform Vault provider, create Vault resources,
authenticate any identity, or store/retrieve secrets. The Terraform module is an
inert interface; the Helm and Kubernetes configuration is disabled-by-default
metadata for a later deployment.

The target production architecture places Vault in a separately operated,
high-availability security boundary. Workloads authenticate with their own
short-lived identity, receive only the minimum authorized material, and are
audited centrally. Platform security operates Vault and recovery controls;
application teams own each secret's purpose and lifecycle; workload identities
are scoped per service and environment.

## Engines and data boundaries

### KV v2

Use KV v2 for versioned application configuration and static credentials that
cannot yet be issued dynamically. Separate mounts or path prefixes by
environment and workload. Policies must grant exact paths and required verbs
only. Enable versioning, deletion recovery, ownership metadata, rotation dates,
and an approved retention policy. Never put values in Terraform, Helm values,
Kubernetes manifests, workflow logs, source control, or documentation.

### Transit

Use Transit for envelope encryption, signing, verification, and key rotation
without exposing key material to the caller. Assign separate keys and policies
per cryptographic purpose and environment. Applications use narrow encrypt,
decrypt, sign, or verify permissions; they do not administer keys. Record key
rotation, rewrap, and recovery procedures in the cryptographic key lifecycle.

### PKI

Use dedicated PKI mounts and roles for short-lived service certificates. Define
per-environment trust domains, constrained common names/SANs, short TTLs, and
revocation paths. Keep root/intermediate authority operations segregated from
workload issuance. Certificate private keys and issued certificates are never
committed or embedded in this foundation.

## Authentication and authorization

### Kubernetes authentication

Each service account receives a distinct Vault role with bound namespace,
service-account name, audience, TTL, and policy. The optional Helm
`serviceAccountAnnotations` field and raw-manifest annotations are placeholders
only. Future enablement requires an approved Vault Kubernetes auth mount and
does not permit a shared cluster-wide workload role.

### OIDC

Human and CI access should federate through an approved OIDC issuer with group,
repository, environment, ref, workflow, and audience claim constraints. Use
short-lived sessions and least-privilege policies. GitHub Actions has no Vault
authentication in Phase 8; its future contract is in `.github/VAULT_AUTHENTICATION.md`.

### AppRole

Reserve AppRole for non-interactive systems that cannot use Kubernetes or OIDC.
Use a uniquely scoped role, tightly controlled SecretID issuance, short-lived
and single-use SecretIDs where possible, CIDR restrictions when applicable, and
independent delivery channels. Prefer workload identity or OIDC over AppRole.

## Delivery integrations

Vault Agent Injector may later add approved pod annotations to render ephemeral
files or environment templates. This phase renders none: no sidecars, init
containers, templates, or injected files.

External Secrets Operator may later reconcile explicit, narrowly scoped
ExternalSecret resources into Kubernetes Secrets. It is not installed or
configured here. Before adoption, define ownership, refresh interval, deletion
policy, RBAC, namespace isolation, and incident handling.

Secrets Store CSI Driver may later mount ephemeral secret material through an
approved SecretProviderClass. It is not installed or referenced by a volume
here. Before adoption, define node/plugin trust, mount permissions, rotation
semantics, workload restart behaviour, and whether synchronization into a
Kubernetes Secret is prohibited.

## Lifecycle, rotation, and revocation

Every secret has an owner, classification, consumer, approved paths, rotation
interval, expiry, downstream dependency map, and revocation procedure. Prefer
dynamic credentials and short TTLs. Rotate after scheduled windows, suspected
exposure, offboarding, policy changes, and disaster recovery tests. Revoke by
removing the compromised identity or policy first, rotating the affected
credential or key next, invalidating dependent sessions, and preserving audit
evidence. Test rotation without logging values.

## Audit logging and operations

Enable durable, tamper-resistant Vault audit devices in production and forward
them to the approved security sink. Alert on auth failures, policy denials,
privileged changes, audit-device failure, root or recovery operations, abnormal
read patterns, and sealing events. Restrict audit-log access, redact sensitive
fields according to the approved policy, set retention, and regularly review
evidence.

## Disaster recovery and revocation readiness

Operate a tested backup and restore design appropriate to the chosen Vault
edition and storage backend. Protect unseal/recovery material with separation of
duties and the approved HSM/KMS design. Run scheduled restore exercises in an
isolated environment; validate policy, auth, engine, audit, and application
recovery without copying production secrets unnecessarily. Maintain a
break-glass runbook with dual approval, time-bounded access, and post-event
review.

## Zero-trust controls

Trust no network location by itself. Authenticate each workload, authorize each
request to an exact path and operation, use short-lived credentials, encrypt in
transit and at rest, segment namespaces, deny by default, and continuously
audit. No workload receives a broad shared token, root capability, wildcard
policy, or environment-crossing access.

## Future production deployment gate

Before any enablement, approve the Vault topology, HA/storage design, network
policy, TLS and PKI design, identity bindings, least-privilege policies, audit
sink, monitoring, backup/restore evidence, rotation/revocation tests, disaster
recovery RTO/RPO, and incident runbooks. Deploy and validate Vault separately.
Only then enable one delivery integration for a non-production workload, verify
no secret values enter logs or manifests, and promote through reviewed change
control. Roll back by disabling the integration values/annotations, revoking the
new identity or policy, and restoring the last approved workload release; do not
use source control to recover secret material.
