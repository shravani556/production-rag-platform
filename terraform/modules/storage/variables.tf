variable "environment" {
  description = "Environment to which this provider-neutral storage contract belongs."
  type        = string
}

variable "storage_definitions" {
  description = "Persistent-storage intent keyed by stable logical identifier. Policy and integration values are references only; no storage, Kubernetes, or provider resources are created."
  type = map(object({
    name                      = string
    storage_type              = string
    capacity_gib              = number
    access_modes              = list(string)
    performance_tier          = string
    encryption_enabled        = bool
    backup_policy_reference   = string
    snapshot_policy_reference = string
    retention_days            = number
    mount_point               = string
    future_kubernetes = optional(object({
      storage_class_name = string
      csi_driver_name    = string
      }), {
      storage_class_name = ""
      csi_driver_name    = ""
    })
    future_object_storage = optional(object({
      enabled          = bool
      bucket_reference = string
      prefix           = string
      }), {
      enabled          = false
      bucket_reference = ""
      prefix           = ""
    })
    future_shared_storage = optional(object({
      enabled  = bool
      protocol = string
      }), {
      enabled  = false
      protocol = ""
    })
    future_block_storage = optional(object({
      enabled     = bool
      volume_mode = string
      }), {
      enabled     = false
      volume_mode = ""
    })
  }))

  validation {
    condition     = alltrue([for definition in values(var.storage_definitions) : contains(["block", "shared", "object"], definition.storage_type)])
    error_message = "Each storage_type must be block, shared, or object."
  }

  validation {
    condition     = alltrue([for definition in values(var.storage_definitions) : definition.capacity_gib > 0 && definition.retention_days >= 0])
    error_message = "Each storage definition requires a positive capacity_gib and a non-negative retention_days value."
  }

  validation {
    condition     = length(distinct([for definition in values(var.storage_definitions) : definition.name])) == length(var.storage_definitions)
    error_message = "Each storage definition name must be unique."
  }

  validation {
    condition     = alltrue([for definition in values(var.storage_definitions) : !definition.future_object_storage.enabled || length(trimspace(definition.future_object_storage.bucket_reference)) > 0])
    error_message = "Enabled future object storage requires a bucket_reference."
  }

  validation {
    condition     = alltrue([for definition in values(var.storage_definitions) : !definition.future_shared_storage.enabled || length(trimspace(definition.future_shared_storage.protocol)) > 0])
    error_message = "Enabled future shared storage requires a protocol."
  }

  validation {
    condition     = alltrue([for definition in values(var.storage_definitions) : !definition.future_block_storage.enabled || length(trimspace(definition.future_block_storage.volume_mode)) > 0])
    error_message = "Enabled future block storage requires a volume_mode."
  }
}
