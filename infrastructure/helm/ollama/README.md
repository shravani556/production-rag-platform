# Ollama Chart
Installs independent Ollama inference and persistent model storage. Required: tested image, PVC storage class, and preloaded models. Example: `helm upgrade --install ollama ./infrastructure/helm/ollama -n rag-platform -f values-prod.yaml`. The default full name is deliberately `ollama`, preserving the Phase 3 service DNS contract used by the RAG chart (`ollama.rag-platform.svc.cluster.local`). The RAG chart reaches this service through its `config.ollamaHost` value.

`vaultIntegration` is an inert Phase 8 configuration contract. It is disabled by
default and renders no Vault annotations, sidecars, init containers, CSI volumes,
ExternalSecret resources, authentication, or secret retrieval. It records future
Vault Agent Injector, External Secrets Operator, and Secrets Store CSI Driver
integration points without enabling them.
