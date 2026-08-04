output "storage_contract" {
  description = "Provider-neutral persistent-storage intent for future approved implementations. This output represents no provisioned infrastructure."
  value       = local.storage_contract
}

output "storage_by_type" {
  description = "Storage intent grouped by block, shared, or object type; no storage resources are created."
  value       = local.storage_by_type
}
