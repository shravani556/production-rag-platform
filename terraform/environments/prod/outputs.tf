output "network_contract" {
  description = "The requested provider-neutral production networking contract; no infrastructure is provisioned."
  value       = module.networking.network_contract
}

output "compute_contract" {
  description = "The requested provider-neutral production compute contract; no infrastructure is provisioned."
  value       = module.compute.compute_contract
}

output "storage_contract" {
  description = "The requested provider-neutral production storage contract; no infrastructure is provisioned."
  value       = module.storage.storage_contract
}

output "security_contract" {
  description = "The requested provider-neutral production security contract; no infrastructure is provisioned."
  value       = module.security.security_contract
}

output "kubernetes_bootstrap_contract" {
  description = "The requested inert production Kubernetes bootstrap contract; no scripts run and no cluster is created."
  value       = module.kubernetes.bootstrap_contract
}

output "vault_contract" {
  description = "The requested provider-neutral production Vault contract; no Vault instance, provider, or secret is created."
  value       = module.vault.vault_contract
}
