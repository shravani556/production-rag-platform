# RAG Platform Chart
Installs the Streamlit RAG workload, Chroma PVC, service, RBAC, and optional Ingress/HPA/PDB. Required: image, storage class or existing claim, Ollama endpoint, and namespace. Example: `helm upgrade --install rag ./infrastructure/helm/rag-platform -n rag-platform -f values-prod.yaml`. Install Ollama separately first. Production requires immutable images, storage, ingress/TLS, and managed secrets.

`vaultIntegration` is an inert Phase 8 configuration contract. It is disabled by
default and renders no Vault annotations, sidecars, init containers, CSI volumes,
ExternalSecret resources, authentication, or secret retrieval. Future operators
may supply approved Vault Agent pod annotations and Kubernetes-authentication
ServiceAccount annotations only after deploying and approving those integrations.
