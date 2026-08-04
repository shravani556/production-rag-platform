# The application and Ollama remain independent images and Kubernetes Deployments.
ARG OLLAMA_IMAGE=ollama/ollama:0.32.3
FROM ${OLLAMA_IMAGE}
