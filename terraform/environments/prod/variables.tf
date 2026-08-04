variable "project_name" {
  description = "Project identifier used for future infrastructure naming."
  type        = string
  default     = "replace-with-project-name"
}

variable "environment" {
  description = "Environment identifier for this root module."
  type        = string
  default     = "prod"
}

variable "network_name" {
  description = "Placeholder name for the future production private network."
  type        = string
  default     = "rag-platform-prod-network"
}

variable "network_cidr" {
  description = "Placeholder CIDR reserved for the future production network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "dns_settings" {
  description = "DNS contract forwarded to the provider-neutral networking module."
  type = object({
    servers              = list(string)
    search_domains       = list(string)
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
  default = { servers = [], search_domains = [], enable_dns_hostnames = true, enable_dns_support = true }
}

variable "future_subnets" {
  type    = map(any)
  default = {}
}

variable "future_load_balancers" {
  type    = object({ enabled = bool, internal = bool, internet_facing = bool })
  default = { enabled = false, internal = false, internet_facing = false }
}

variable "future_nat" {
  type    = object({ enabled = bool, highly_available = bool, private_egress_only = bool })
  default = { enabled = false, highly_available = false, private_egress_only = true }
}

variable "future_ingress" {
  type    = object({ enabled = bool, visibility = string, dns_name = string })
  default = { enabled = false, visibility = "private", dns_name = "" }
}

variable "future_vpn" {
  type    = object({ enabled = bool, allowed_cidrs = list(string), route_propagation = bool })
  default = { enabled = false, allowed_cidrs = [], route_propagation = false }
}

variable "future_private_networking" {
  type    = object({ enabled = bool, allow_private_service_links = bool, allow_peering = bool })
  default = { enabled = true, allow_private_service_links = true, allow_peering = false }
}

variable "future_storage_endpoints" {
  type    = object({ enabled = bool, private_dns = bool, service_names = list(string) })
  default = { enabled = false, private_dns = true, service_names = [] }
}

variable "compute_nodes" {
  description = "Provider-neutral production compute intent. This fixed topology has one control-plane and two worker nodes."
  type        = map(any)
  default = {
    control_plane_01 = {
      hostname      = "rag-prod-cp-01"
      role          = "control-plane"
      cpu           = 4
      memory_gib    = 16
      root_disk_gib = 100
      labels        = { "node.rag-platform.io/role" = "control-plane" }
      ssh           = { enabled = true, user = "platform-admin", authorized_key_references = ["approved-secret-store://rag-platform/prod/ssh/authorized-keys"] }
      cloud_init    = { enabled = true, template_reference = "cloud-init://rag-platform/kubernetes-node", variables = { node_role = "control-plane" } }
      gpu           = { enabled = false, count = 0, model = "" }
      extra_disks   = {}
    }
    worker_01 = {
      hostname      = "rag-prod-worker-01"
      role          = "worker"
      cpu           = 8
      memory_gib    = 32
      root_disk_gib = 200
      labels        = { "node.rag-platform.io/role" = "worker" }
      ssh           = { enabled = true, user = "platform-admin", authorized_key_references = ["approved-secret-store://rag-platform/prod/ssh/authorized-keys"] }
      cloud_init    = { enabled = true, template_reference = "cloud-init://rag-platform/kubernetes-node", variables = { node_role = "worker" } }
      gpu           = { enabled = false, count = 0, model = "" }
      extra_disks   = {}
    }
    worker_02 = {
      hostname      = "rag-prod-worker-02"
      role          = "worker"
      cpu           = 8
      memory_gib    = 32
      root_disk_gib = 200
      labels        = { "node.rag-platform.io/role" = "worker" }
      ssh           = { enabled = true, user = "platform-admin", authorized_key_references = ["approved-secret-store://rag-platform/prod/ssh/authorized-keys"] }
      cloud_init    = { enabled = true, template_reference = "cloud-init://rag-platform/kubernetes-node", variables = { node_role = "worker" } }
      gpu           = { enabled = false, count = 0, model = "" }
      extra_disks   = {}
    }
  }
}

variable "future_compute_autoscaling" {
  description = "Reserved production autoscaling intent. Disabled until a provider-specific implementation is approved."
  type        = map(any)
  default = {
    workers = { enabled = false, node_role = "worker", min_nodes = 2, desired_nodes = 2, max_nodes = 6, target_cpu_utilization = 70 }
  }
}

variable "storage_definitions" {
  description = "Provider-neutral production storage intent. These are definitions only and do not create storage."
  type        = any
  default = {
    chromadb = {
      name                 = "chromadb", storage_type = "block", capacity_gib = 500, access_modes = ["ReadWriteOnce"], performance_tier = "high", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/daily", snapshot_policy_reference = "snapshot-policy://rag-platform/prod/hourly", retention_days = 30, mount_point = "/var/lib/chromadb"
      future_block_storage = { enabled = true, volume_mode = "Filesystem" }
    }
    ollama_models = {
      name                 = "ollama-models", storage_type = "block", capacity_gib = 1000, access_modes = ["ReadWriteOnce"], performance_tier = "high", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/weekly", snapshot_policy_reference = "snapshot-policy://rag-platform/prod/daily", retention_days = 30, mount_point = "/root/.ollama"
      future_block_storage = { enabled = true, volume_mode = "Filesystem" }
    }
    prometheus = {
      name                 = "prometheus", storage_type = "block", capacity_gib = 500, access_modes = ["ReadWriteOnce"], performance_tier = "high", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/daily", snapshot_policy_reference = "snapshot-policy://rag-platform/prod/hourly", retention_days = 30, mount_point = "/prometheus"
      future_block_storage = { enabled = true, volume_mode = "Filesystem" }
    }
    grafana = {
      name                 = "grafana", storage_type = "block", capacity_gib = 50, access_modes = ["ReadWriteOnce"], performance_tier = "standard", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/daily", snapshot_policy_reference = "snapshot-policy://rag-platform/prod/daily", retention_days = 30, mount_point = "/var/lib/grafana"
      future_block_storage = { enabled = true, volume_mode = "Filesystem" }
    }
    application_logs = {
      name                  = "application-logs", storage_type = "shared", capacity_gib = 500, access_modes = ["ReadWriteMany"], performance_tier = "high", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/daily", snapshot_policy_reference = "snapshot-policy://rag-platform/prod/daily", retention_days = 90, mount_point = "/var/log/rag-platform"
      future_shared_storage = { enabled = true, protocol = "provider-defined" }
    }
    backup_repository = {
      name                  = "backup-repository", storage_type = "object", capacity_gib = 5000, access_modes = [], performance_tier = "standard", encryption_enabled = true, backup_policy_reference = "backup-policy://rag-platform/prod/repository", snapshot_policy_reference = "", retention_days = 365, mount_point = ""
      future_object_storage = { enabled = true, bucket_reference = "approved-object-store://rag-platform/prod/backups", prefix = "rag-platform" }
    }
  }
}

variable "security_configuration" {
  description = "Provider-neutral production security intent. All values are policy or integration references, not credentials or provisioned controls."
  type        = any
  default = {
    ssh_access_policy             = { enabled = true, port = 22, require_mfa = true, session_recording_required = true }
    administrative_users          = { platform_admins = { enabled = true, access_level = "administrator", identity_reference = "identity-group://rag-platform/prod/platform-admins" } }
    break_glass_accounts          = { emergency_admin = { enabled = true, identity_reference = "identity://rag-platform/prod/break-glass", approval_reference = "runbook://rag-platform/break-glass", audit_required = true } }
    allowed_management_cidrs      = ["10.20.0.0/16"]
    node_to_node_communication    = { default_action = "deny", allowed_protocols = ["tcp", "udp"], allowed_ports = [53, 6443, 10250] }
    cluster_ingress_policy        = { default_action = "deny", rules = { api_server = { protocols = ["tcp"], ports = [6443], source_cidrs = ["10.20.0.0/16"] } } }
    cluster_egress_policy         = { default_action = "deny", rules = { internal_dns = { protocols = ["tcp", "udp"], ports = [53], destination_cidrs = ["10.20.0.0/16"] } } }
    application_ingress_policy    = { default_action = "deny", rules = { private_https = { protocols = ["tcp"], ports = [443], source_cidrs = ["10.20.0.0/16"] } } }
    application_egress_policy     = { default_action = "deny", rules = { internal_dns = { protocols = ["tcp", "udp"], ports = [53], destination_cidrs = ["10.20.0.0/16"] } } }
    future_firewall_mapping       = { enabled = false, policy_reference = "" }
    future_security_group_mapping = { enabled = false, policy_reference = "" }
    future_nsg_mapping            = { enabled = false, policy_reference = "" }
    future_iam_mapping            = { enabled = false, policy_reference = "" }
    future_vault_integration      = { enabled = false, integration_reference = "" }
    future_certificate_management = { enabled = false, integration_reference = "" }
    future_pki                    = { enabled = false, integration_reference = "" }
    future_secrets_store_csi      = { enabled = false, integration_reference = "" }
    future_oidc                   = { enabled = false, issuer_reference = "" }
    future_workload_identity      = { enabled = false, integration_reference = "" }
    future_key_management         = { enabled = false, key_reference = "" }
    encryption_at_rest            = { required = true, key_management_reference = "approved-kms://rag-platform/prod" }
    encryption_in_transit         = { required = true, minimum_tls_version = "1.2" }
    audit_logging                 = { enabled = true, retention_days = 365, sink_reference = "approved-audit-sink://rag-platform/prod" }
    compliance_policies           = { baseline = { enabled = true, policy_reference = "compliance-policy://rag-platform/prod/baseline" } }
    cis_benchmark_tracking        = { enabled = true, benchmark_version = "provider-defined", evidence_reference = "compliance-evidence://rag-platform/prod/cis" }
    soc2_controls                 = { enabled = true, evidence_reference = "compliance-evidence://rag-platform/prod/soc2" }
    iso27001_controls             = { enabled = true, evidence_reference = "compliance-evidence://rag-platform/prod/iso27001" }
  }
}

variable "kubernetes_bootstrap_configuration" {
  description = "Inert production Kubernetes bootstrap intent. It does not install software or execute scripts."
  type        = any
  default = {
    kubernetes_version               = "v1.31.0"
    container_runtime                = "containerd"
    containerd_version_reference     = "approved-runtime://containerd/v1.7.22"
    pod_cidr                         = "10.244.0.0/16"
    service_cidr                     = "10.96.0.0/12"
    cluster_dns_domain               = "cluster.local"
    control_plane_endpoint           = "rag-prod-cp-01"
    cni_reference                    = "approved-cni://deferred"
    metrics_server_reference         = "approved-addon://metrics-server/deferred"
    ingress_controller_reference     = "approved-addon://ingress/deferred"
    future_load_balancer_reference   = "approved-load-balancer://deferred"
    future_csi_reference             = "approved-csi://deferred"
    future_gpu_node_support          = false
    token_management_reference       = "approved-token-manager://rag-platform/prod"
    certificate_management_reference = "approved-certificate-manager://rag-platform/prod"
    upgrade_policy = {
      version_skew_policy_reference = "runbook://rag-platform/kubernetes/version-skew"
      rollback_policy_reference     = "runbook://rag-platform/kubernetes/rollback"
    }
  }
}

variable "vault_configuration" {
  description = "Provider-neutral production Vault integration intent. It contains references only and never secret values."
  type        = any
  default = {
    address_reference = "vault-address://rag-platform/prod"
    namespace         = "rag-platform-prod"
    authentication = {
      kubernetes = { enabled = false, auth_mount = "kubernetes", role_reference = "vault-role://rag-platform/prod/workload", service_account_reference = "kubernetes-service-account://rag-platform-prod/rag-platform" }
      approle    = { enabled = false, role_reference = "vault-role://rag-platform/prod/automation" }
      oidc       = { enabled = false, role_reference = "vault-role://rag-platform/prod/github-actions", issuer_reference = "oidc-issuer://deferred" }
    }
    engines = {
      kv_v2             = { enabled = false, mount = "kv", versioning_required = true }
      transit           = { enabled = false, mount = "transit", key_reference = "vault-key://rag-platform/prod" }
      pki               = { enabled = false, mount = "pki", role_reference = "vault-pki-role://rag-platform/prod" }
      database          = { enabled = false, role_reference = "vault-database-role://rag-platform/prod" }
      cloud_credentials = { enabled = false, role_reference = "vault-cloud-role://rag-platform/prod" }
    }
    policy_names = { workload = "vault-policy://rag-platform/prod/workload", automation = "vault-policy://rag-platform/prod/automation" }
    secret_paths = { application = { owner_reference = "owner://rag-platform/prod/application", rotation_reference = "rotation-policy://rag-platform/prod/application", lifecycle_reference = "lifecycle-policy://rag-platform/prod/application" } }
    audit_logging              = { enabled = false, sink_reference = "audit-sink://rag-platform/prod", retention_reference = "retention-policy://rag-platform/prod/audit" }
    disaster_recovery          = { recovery_reference = "runbook://rag-platform/vault/recovery", backup_reference = "backup-policy://rag-platform/prod/vault" }
    future_hsm_kms             = { enabled = false, integration_reference = "hsm-kms://deferred" }
    future_external_secrets    = { enabled = false, integration_reference = "external-secrets://deferred" }
    future_secrets_store_csi   = { enabled = false, integration_reference = "secrets-store-csi://deferred" }
  }
}
