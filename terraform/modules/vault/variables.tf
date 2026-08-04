variable "vault_configuration" {
  description = "Vault integration contract. All addresses, roles, policies, paths, and integration values are references only; secret values, tokens, certificates, and private keys are prohibited."
  type = object({
    address_reference = string
    namespace         = string
    authentication = object({
      kubernetes = object({ enabled = bool, auth_mount = string, role_reference = string, service_account_reference = string })
      approle    = object({ enabled = bool, role_reference = string })
      oidc       = object({ enabled = bool, role_reference = string, issuer_reference = string })
    })
    engines = object({
      kv_v2             = object({ enabled = bool, mount = string, versioning_required = bool })
      transit           = object({ enabled = bool, mount = string, key_reference = string })
      pki               = object({ enabled = bool, mount = string, role_reference = string })
      database          = object({ enabled = bool, role_reference = string })
      cloud_credentials = object({ enabled = bool, role_reference = string })
    })
    policy_names = map(string)
    secret_paths = map(object({ owner_reference = string, rotation_reference = string, lifecycle_reference = string }))
    audit_logging = object({ enabled = bool, sink_reference = string, retention_reference = string })
    disaster_recovery = object({ recovery_reference = string, backup_reference = string })
    future_hsm_kms = object({ enabled = bool, integration_reference = string })
    future_external_secrets = object({ enabled = bool, integration_reference = string })
    future_secrets_store_csi = object({ enabled = bool, integration_reference = string })
  })

  validation {
    condition     = !var.vault_configuration.authentication.kubernetes.enabled || (length(trimspace(var.vault_configuration.authentication.kubernetes.auth_mount)) > 0 && length(trimspace(var.vault_configuration.authentication.kubernetes.role_reference)) > 0)
    error_message = "Enabled Kubernetes authentication requires auth_mount and role_reference."
  }

  validation {
    condition     = !var.vault_configuration.engines.kv_v2.enabled || (length(trimspace(var.vault_configuration.engines.kv_v2.mount)) > 0 && var.vault_configuration.engines.kv_v2.versioning_required)
    error_message = "Enabled KV v2 requires a mount and versioning_required=true."
  }
}
