output "vault_contract" {
  description = "Provider-neutral Vault integration intent. This output represents no Vault deployment, provider configuration, or stored secret."
  value       = local.vault_contract
}
