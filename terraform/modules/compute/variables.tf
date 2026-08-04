variable "environment" {
  description = "Environment to which this provider-neutral compute contract belongs."
  type        = string
}

variable "nodes" {
  description = "Static node intent keyed by a stable logical node identifier. No instances are created. SSH key references and cloud-init template references must never contain secret material."
  type = map(object({
    hostname      = string
    role          = string
    cpu           = number
    memory_gib    = number
    root_disk_gib = number
    labels        = optional(map(string), {})
    ssh = optional(object({
      enabled                   = bool
      user                      = string
      authorized_key_references = list(string)
      }), {
      enabled                   = false
      user                      = ""
      authorized_key_references = []
    })
    cloud_init = optional(object({
      enabled            = bool
      template_reference = string
      variables          = map(string)
      }), {
      enabled            = false
      template_reference = ""
      variables          = {}
    })
    gpu = optional(object({
      enabled = bool
      count   = number
      model   = string
      }), {
      enabled = false
      count   = 0
      model   = ""
    })
    availability_zone = optional(string)
    extra_disks = optional(map(object({
      size_gib  = number
      purpose   = string
      encrypted = bool
    })), {})
  }))

  validation {
    condition     = alltrue([for node in values(var.nodes) : contains(["control-plane", "worker"], node.role)])
    error_message = "Each node role must be either control-plane or worker."
  }

  validation {
    condition     = alltrue([for node in values(var.nodes) : node.cpu > 0 && node.memory_gib > 0 && node.root_disk_gib > 0])
    error_message = "Each node must define positive cpu, memory_gib, and root_disk_gib values."
  }

  validation {
    condition     = alltrue([for node in values(var.nodes) : can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", node.hostname))])
    error_message = "Each hostname must be a lowercase RFC 1123-compatible hostname."
  }

  validation {
    condition     = length(distinct([for node in values(var.nodes) : node.hostname])) == length(var.nodes)
    error_message = "Each node hostname must be unique."
  }

  validation {
    condition     = alltrue(flatten([for node in values(var.nodes) : [for disk in values(node.extra_disks) : disk.size_gib > 0]]))
    error_message = "Each extra disk must define a positive size_gib value."
  }

  validation {
    condition     = alltrue([for node in values(var.nodes) : !node.gpu.enabled || (node.gpu.count > 0 && length(trimspace(node.gpu.model)) > 0)])
    error_message = "An enabled GPU configuration requires a positive count and a model."
  }
}

variable "future_autoscaling" {
  description = "Reserved autoscaling intent keyed by policy name. These policies are declarative only and do not create scaling resources."
  type = map(object({
    enabled                = bool
    node_role              = string
    min_nodes              = number
    desired_nodes          = number
    max_nodes              = number
    target_cpu_utilization = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for policy in values(var.future_autoscaling) : contains(["control-plane", "worker"], policy.node_role)])
    error_message = "Each autoscaling policy node_role must be either control-plane or worker."
  }

  validation {
    condition     = alltrue([for policy in values(var.future_autoscaling) : policy.min_nodes >= 0 && policy.min_nodes <= policy.desired_nodes && policy.desired_nodes <= policy.max_nodes])
    error_message = "Autoscaling node counts must satisfy 0 <= min_nodes <= desired_nodes <= max_nodes."
  }

  validation {
    condition     = alltrue([for policy in values(var.future_autoscaling) : policy.target_cpu_utilization == null || (policy.target_cpu_utilization > 0 && policy.target_cpu_utilization <= 100)])
    error_message = "target_cpu_utilization must be greater than 0 and no greater than 100 when specified."
  }
}
