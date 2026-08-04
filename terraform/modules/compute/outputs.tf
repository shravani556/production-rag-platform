output "compute_contract" {
  description = "Provider-neutral compute intent for future approved infrastructure implementations. This output represents no provisioned infrastructure."
  value       = local.compute_contract
}

output "nodes_by_role" {
  description = "Static node intent grouped by Kubernetes node role; no compute resources are created."
  value       = local.nodes_by_role
}
