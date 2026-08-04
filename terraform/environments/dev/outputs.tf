output "network_contract" {
  description = "The requested provider-neutral development networking contract; no infrastructure is provisioned."
  value       = module.networking.network_contract
}
