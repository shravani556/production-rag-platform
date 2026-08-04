locals {
  observability_contract = {
    configuration = var.observability_configuration
    application_metric_categories = [
      "http-requests",
      "request-duration",
      "error-rate",
      "token-usage",
      "prompt-count",
      "embedding-duration",
      "retrieval-latency",
      "llm-latency",
      "chunk-retrieval",
      "vector-database",
      "ollama-inference",
    ]
    alert_categories = [
      "high-cpu",
      "high-memory",
      "pod-restart-loops",
      "pvc-nearing-capacity",
      "node-not-ready",
      "ollama-unavailable",
      "application-unavailable",
      "high-latency",
      "high-error-rate",
      "low-disk",
    ]
  }
}
