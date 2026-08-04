output "network_contract" {
  description = "Provider-neutral networking intent for future provider-specific modules. This output represents no provisioned infrastructure."
  value       = local.network_contract
}

output "network_name" {
  description = "Requested future network name."
  value       = var.network_name
}

output "cidr" {
  description = "Requested placeholder network CIDR."
  value       = var.cidr
}
