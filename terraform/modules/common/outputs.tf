output "metadata" {
  description = "Standardized metadata for future provider-specific modules."
  value = {
    project_name = var.project_name
    environment  = var.environment
    name_prefix  = local.name_prefix
    tags         = var.tags
  }
}
