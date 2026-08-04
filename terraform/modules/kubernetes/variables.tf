variable "bootstrap_configuration" {
  description = "Provider-neutral Kubernetes bootstrap intent. Token and certificate values are external references only and must never contain secret material."
  type = object({
    kubernetes_version               = string
    container_runtime                = string
    containerd_version_reference     = string
    pod_cidr                         = string
    service_cidr                     = string
    cluster_dns_domain               = string
    control_plane_endpoint           = string
    cni_reference                    = string
    metrics_server_reference         = string
    ingress_controller_reference     = string
    future_load_balancer_reference   = string
    future_csi_reference             = string
    future_gpu_node_support          = bool
    token_management_reference       = string
    certificate_management_reference = string
    upgrade_policy = object({
      version_skew_policy_reference = string
      rollback_policy_reference     = string
    })
  })

  validation {
    condition     = var.bootstrap_configuration.container_runtime == "containerd"
    error_message = "Phase 6F supports containerd as the planned container runtime."
  }

  validation {
    condition     = can(cidrnetmask(var.bootstrap_configuration.pod_cidr)) && can(cidrnetmask(var.bootstrap_configuration.service_cidr))
    error_message = "pod_cidr and service_cidr must be valid CIDR blocks."
  }

  validation {
    condition     = length(trimspace(var.bootstrap_configuration.kubernetes_version)) > 0 && length(trimspace(var.bootstrap_configuration.cluster_dns_domain)) > 0
    error_message = "kubernetes_version and cluster_dns_domain must not be empty."
  }
}
