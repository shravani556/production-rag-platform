output "network_contract" {
  description = "The requested provider-neutral production networking contract; no infrastructure is provisioned."
  value       = module.networking.network_contract
}
