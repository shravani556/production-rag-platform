module "common" {
  source = "../../modules/common"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  network_name              = var.network_name
  cidr                      = var.network_cidr
  dns_settings              = var.dns_settings
  future_subnets            = var.future_subnets
  future_load_balancers     = var.future_load_balancers
  future_nat                = var.future_nat
  future_ingress            = var.future_ingress
  future_vpn                = var.future_vpn
  future_private_networking = var.future_private_networking
  future_storage_endpoints  = var.future_storage_endpoints
}

module "compute" {
  source = "../../modules/compute"
}

module "kubernetes" {
  source = "../../modules/kubernetes"
}

module "storage" {
  source = "../../modules/storage"
}

module "monitoring" {
  source = "../../modules/monitoring"
}

module "security" {
  source = "../../modules/security"
}
