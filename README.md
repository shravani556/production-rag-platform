# Local RAG Platform

## Project overview

This project is a local Retrieval-Augmented Generation (RAG) application.
It indexes HTML and PDF source documents in ChromaDB, retrieves relevant
document chunks with hybrid search, and generates document-grounded answers
through Ollama.

## Current architecture

`app/streamlit_app.py` provides the Streamlit user interface and RAG query
pipeline. `app/ingestion/ingest.py` extracts, chunks, embeds, and indexes the
documents in `documents/source/`. The persistent ChromaDB index remains in
`data/chroma_db/`. Ollama provides `nomic-embed-text` embeddings and the
`qwen2.5:3b` generation model.

Root-level `app.py` and `ingest.py` are compatibility entry points, so the
existing launch commands continue to work.

## Local development

Install the dependencies listed in `requirements.txt`, ensure Ollama is
running with the configured embedding and generation models, then run:

```powershell
streamlit run app.py
```

To rebuild the local ChromaDB index from the source documents, run:

```powershell
python ingest.py
```

The existing `data/chroma_db/` index is persistent runtime data. Rebuilding it
replaces that index.

## Docker

Build the image from the repository root:

```powershell
docker build -t local-rag-platform:dev .
```

The application needs an Ollama server that has the configured generation and
embedding models. For Docker Desktop, a local Ollama server is typically
available through `host.docker.internal`. Mount the persistent ChromaDB
directory because runtime data is deliberately excluded from the image:

```powershell
docker run --rm -p 8501:8501 `
  -e OLLAMA_HOST=http://host.docker.internal:11434 `
  --mount type=bind,source="${PWD}\data\chroma_db",target=/app/data/chroma_db `
  local-rag-platform:dev
```

The image contains only application code and Python runtime dependencies.
ChromaDB, source documents, and evaluation fixtures are runtime data and must
be supplied through mounts or deployment configuration. The default ChromaDB
mount path is `/app/data/chroma_db`.

To run ingestion in a container, additionally mount a source-document
directory and invoke the existing compatibility entry point:

```powershell
docker run --rm `
  -e OLLAMA_HOST=http://host.docker.internal:11434 `
  --mount type=bind,source="${PWD}\data\chroma_db",target=/app/data/chroma_db `
  --mount type=bind,source="${PWD}\documents\source",target=/app/documents/source,readonly `
  local-rag-platform:dev python ingest.py
```

### Runtime configuration

All application settings retain their existing defaults. These optional
environment variables provide deployment-time overrides:

| Variable | Default | Purpose |
| --- | --- | --- |
| `RAG_CHROMA_PATH` | Local: `data/chroma_db`; container: `/app/data/chroma_db` | Persistent ChromaDB directory. |
| `RAG_DOCUMENTS_PATH` | Local: `documents/source`; container: `/app/documents/source` | Source directory used by ingestion. |
| `RAG_EVALUATION_FILE` | Local: `evaluation/evaluation_cases.json`; container: `/app/evaluation/evaluation_cases.json` | Evaluation fixture file. |
| `RAG_COLLECTION_NAME` | `rag_docs` | Chroma collection name. |
| `RAG_LLM_MODEL` | `qwen2.5:3b` | Ollama generation model. |
| `RAG_EMBEDDING_MODEL` | `nomic-embed-text` | Ollama embedding model. |
| `OLLAMA_HOST` | Ollama client default | URL of the Ollama service. |
| `STREAMLIT_SERVER_ADDRESS` | `0.0.0.0` in the image | Interface Streamlit listens on. |
| `STREAMLIT_SERVER_PORT` | `8501` in the image | Streamlit listening port. |
| `STREAMLIT_SERVER_HEADLESS` | `true` in the image | Disables Streamlit browser-launch behavior. |

Example configuration overrides:

```powershell
docker run --rm -p 8501:8501 `
  -e OLLAMA_HOST=http://host.docker.internal:11434 `
  -e RAG_LLM_MODEL=qwen2.5:1.5b `
  -e RAG_COLLECTION_NAME=rag_docs `
  --mount type=bind,source="${PWD}\data\chroma_db",target=/app/data/chroma_db `
  local-rag-platform:dev
```

## High-level roadmap

1. Repository restructuring
2. Docker improvements
3. Helm chart
4. Terraform infrastructure
5. GitHub Actions CI/CD
6. Kubernetes production deployment
7. Prometheus and Grafana monitoring
8. Vault, RBAC, and network security
9. Scaling, optimization, backups, and disaster recovery
