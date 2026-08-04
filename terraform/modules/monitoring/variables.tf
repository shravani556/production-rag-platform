variable "observability_configuration" {
  description = "Provider-neutral observability contract. It contains disabled feature flags and non-sensitive references only; it never deploys monitoring, logging, alerting, or tracing services."
  type = object({
    namespace = object({ enabled = bool, name = string, create = bool })
    components = map(object({ enabled = bool, integration_reference = string }))
    retention = object({ metrics_days = number, logs_days = number, traces_days = number })
    storage = object({ enabled = bool, policy_reference = string, backup_reference = string })
    dashboards = object({ enabled = bool, catalog_reference = string })
    alert_routing = object({ enabled = bool, routing_reference = string, escalation_reference = string })
  })

  validation {
    condition     = !var.observability_configuration.namespace.enabled || length(trimspace(var.observability_configuration.namespace.name)) > 0
    error_message = "An enabled monitoring namespace requires a name."
  }
}
