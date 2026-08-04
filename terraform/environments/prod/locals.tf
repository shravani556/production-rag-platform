locals {
  common_tags = {
    managed_by  = "terraform"
    environment = var.environment
    project     = var.project_name
  }
}
