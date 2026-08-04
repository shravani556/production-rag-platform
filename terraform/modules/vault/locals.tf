locals {
  vault_contract = {
    configuration = var.vault_configuration
    secret_categories = [
      "application-secrets",
      "llm-api-keys",
      "database-credentials",
      "registry-credentials",
      "tls-certificates",
      "ssh-credentials",
      "terraform-credentials",
      "github-actions-credentials",
      "monitoring-credentials",
      "backup-credentials",
    ]
  }
}
