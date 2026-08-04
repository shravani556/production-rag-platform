output "network_contract" {
  description = "The requested provider-neutral development networking contract; no infrastructure is provisioned."
  value       = module.networking.network_contract
}

output "compute_contract" {
  description = "The requested provider-neutral development compute contract; no infrastructure is provisioned."
  value       = module.compute.compute_contract
}

output "storage_contract" {
  description = "The requested provider-neutral development storage contract; no infrastructure is provisioned."
  value       = module.storage.storage_contract
}

output "security_contract" {
  description = "The requested provider-neutral development security contract; no infrastructure is provisioned."
  value       = module.security.security_contract
}

output "kubernetes_bootstrap_contract" {
  description = "The requested inert development Kubernetes bootstrap contract; no scripts run and no cluster is created."
  value       = module.kubernetes.bootstrap_contract
}

output "vault_contract" {
  description = "The requested provider-neutral development Vault contract; no Vault instance, provider, or secret is created."
  value       = module.vault.vault_contract
}

output "observability_contract" {
  description = "The requested provider-neutral development observability contract; no observability service or infrastructure is created."
  value       = module.monitoring.observability_contract
}
