variable "network_name" {
  description = "Provider-neutral name for the future virtual or private network."
  type        = string
}

variable "cidr" {
  description = "Placeholder IPv4 CIDR reserved for the environment network."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be a valid IPv4 or IPv6 CIDR block."
  }
}

variable "dns_settings" {
  description = "DNS behavior required from a future provider-specific network implementation."
  type = object({
    servers              = list(string)
    search_domains       = list(string)
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
  default = {
    servers              = []
    search_domains       = []
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
}

variable "future_subnets" {
  description = "Reserved subnet intent keyed by subnet name; no subnets are created in Phase 6B."
  type = map(object({
    cidr              = string
    purpose           = string
    private           = bool
    availability_zone = optional(string)
  }))
  default = {}
}

variable "future_load_balancers" {
  description = "Reserved load-balancer intent for a future provider implementation."
  type = object({
    enabled         = bool
    internal        = bool
    internet_facing = bool
  })
  default = {
    enabled         = false
    internal        = false
    internet_facing = false
  }
}

variable "future_nat" {
  description = "Reserved NAT gateway or appliance intent; no NAT is created in Phase 6B."
  type = object({
    enabled             = bool
    highly_available    = bool
    private_egress_only = bool
  })
  default = {
    enabled             = false
    highly_available    = false
    private_egress_only = true
  }
}

variable "future_ingress" {
  description = "Reserved ingress connectivity intent; no ingress controller or public endpoint is created."
  type = object({
    enabled    = bool
    visibility = string
    dns_name   = string
  })
  default = {
    enabled    = false
    visibility = "private"
    dns_name   = ""
  }

  validation {
    condition     = contains(["private", "public"], var.future_ingress.visibility)
    error_message = "future_ingress.visibility must be either private or public."
  }
}

variable "future_vpn" {
  description = "Reserved VPN connectivity intent; no VPN gateway or tunnel is created in Phase 6B."
  type = object({
    enabled           = bool
    allowed_cidrs     = list(string)
    route_propagation = bool
  })
  default = {
    enabled           = false
    allowed_cidrs     = []
    route_propagation = false
  }
}

variable "future_private_networking" {
  description = "Reserved private-connectivity controls for future service-to-service networking."
  type = object({
    enabled                     = bool
    allow_private_service_links = bool
    allow_peering               = bool
  })
  default = {
    enabled                     = true
    allow_private_service_links = true
    allow_peering               = false
  }
}

variable "future_storage_endpoints" {
  description = "Reserved private storage-endpoint intent; no endpoint is created in Phase 6B."
  type = object({
    enabled       = bool
    private_dns   = bool
    service_names = list(string)
  })
  default = {
    enabled       = false
    private_dns   = true
    service_names = []
  }
}
