variable "project_name" {
  description = "Project identifier used for future infrastructure naming."
  type        = string
  default     = "replace-with-project-name"
}

variable "environment" {
  description = "Environment identifier for this root module."
  type        = string
  default     = "dev"
}

variable "network_name" {
  description = "Placeholder name for the future development private network."
  type        = string
  default     = "rag-platform-dev-network"
}

variable "network_cidr" {
  description = "Placeholder CIDR reserved for the future development network."
  type        = string
  default     = "10.10.0.0/16"
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
