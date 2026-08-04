locals {
  network_contract = {
    name                      = var.network_name
    cidr                      = var.cidr
    dns_settings              = var.dns_settings
    future_subnets            = var.future_subnets
    future_load_balancers     = var.future_load_balancers
    future_nat                = var.future_nat
    future_ingress            = var.future_ingress
    future_vpn                = var.future_vpn
    future_private_networking = var.future_private_networking
    future_storage_endpoints  = var.future_storage_endpoints
  }
}
