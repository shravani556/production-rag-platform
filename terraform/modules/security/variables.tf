variable "environment" {
  description = "Environment to which this provider-neutral security contract belongs."
  type        = string
}

variable "security_configuration" {
  description = "Provider-neutral security intent. Identity, policy, certificate, and secret values must be references only; no credentials, private keys, certificates, or tokens may be supplied."
  type = object({
    ssh_access_policy             = object({ enabled = bool, port = number, require_mfa = bool, session_recording_required = bool })
    administrative_users          = map(object({ enabled = bool, access_level = string, identity_reference = string }))
    break_glass_accounts          = map(object({ enabled = bool, identity_reference = string, approval_reference = string, audit_required = bool }))
    allowed_management_cidrs      = list(string)
    node_to_node_communication    = object({ default_action = string, allowed_protocols = list(string), allowed_ports = list(number) })
    cluster_ingress_policy        = object({ default_action = string, rules = map(object({ protocols = list(string), ports = list(number), source_cidrs = list(string) })) })
    cluster_egress_policy         = object({ default_action = string, rules = map(object({ protocols = list(string), ports = list(number), destination_cidrs = list(string) })) })
    application_ingress_policy    = object({ default_action = string, rules = map(object({ protocols = list(string), ports = list(number), source_cidrs = list(string) })) })
    application_egress_policy     = object({ default_action = string, rules = map(object({ protocols = list(string), ports = list(number), destination_cidrs = list(string) })) })
    future_firewall_mapping       = object({ enabled = bool, policy_reference = string })
    future_security_group_mapping = object({ enabled = bool, policy_reference = string })
    future_nsg_mapping            = object({ enabled = bool, policy_reference = string })
    future_iam_mapping            = object({ enabled = bool, policy_reference = string })
    future_vault_integration      = object({ enabled = bool, integration_reference = string })
    future_certificate_management = object({ enabled = bool, integration_reference = string })
    future_pki                    = object({ enabled = bool, integration_reference = string })
    future_secrets_store_csi      = object({ enabled = bool, integration_reference = string })
    future_oidc                   = object({ enabled = bool, issuer_reference = string })
    future_workload_identity      = object({ enabled = bool, integration_reference = string })
    future_key_management         = object({ enabled = bool, key_reference = string })
    encryption_at_rest            = object({ required = bool, key_management_reference = string })
    encryption_in_transit         = object({ required = bool, minimum_tls_version = string })
    audit_logging                 = object({ enabled = bool, retention_days = number, sink_reference = string })
    compliance_policies           = map(object({ enabled = bool, policy_reference = string }))
    cis_benchmark_tracking        = object({ enabled = bool, benchmark_version = string, evidence_reference = string })
    soc2_controls                 = object({ enabled = bool, evidence_reference = string })
    iso27001_controls             = object({ enabled = bool, evidence_reference = string })
  })

  validation {
    condition     = var.security_configuration.ssh_access_policy.port > 0 && var.security_configuration.ssh_access_policy.port <= 65535
    error_message = "ssh_access_policy.port must be between 1 and 65535."
  }

  validation {
    condition     = alltrue([for cidr in var.security_configuration.allowed_management_cidrs : can(cidrnetmask(cidr))])
    error_message = "allowed_management_cidrs must contain valid CIDR blocks."
  }

  validation {
    condition = alltrue([for action in [
      var.security_configuration.node_to_node_communication.default_action,
      var.security_configuration.cluster_ingress_policy.default_action,
      var.security_configuration.cluster_egress_policy.default_action,
      var.security_configuration.application_ingress_policy.default_action,
      var.security_configuration.application_egress_policy.default_action,
    ] : contains(["allow", "deny"], action)])
    error_message = "Network policy default actions must be allow or deny."
  }

  validation {
    condition     = var.security_configuration.audit_logging.retention_days >= 0
    error_message = "audit_logging.retention_days must not be negative."
  }
}
