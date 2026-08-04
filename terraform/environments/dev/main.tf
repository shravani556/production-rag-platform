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

  environment        = var.environment
  nodes              = var.compute_nodes
  future_autoscaling = var.future_compute_autoscaling
}

module "kubernetes" {
  source = "../../modules/kubernetes"

  bootstrap_configuration = var.kubernetes_bootstrap_configuration
}

module "storage" {
  source = "../../modules/storage"

  environment         = var.environment
  storage_definitions = var.storage_definitions
}

module "monitoring" {
  source = "../../modules/monitoring"
}

module "security" {
  source = "../../modules/security"

  environment            = var.environment
  security_configuration = var.security_configuration
}

module "vault" {
  source = "../../modules/vault"

  vault_configuration = var.vault_configuration
}
