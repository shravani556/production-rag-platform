module "common" {
  source = "../../modules/common"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "networking" {
  source = "../../modules/networking"
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
