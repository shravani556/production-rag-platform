# Temporary security exceptions

## PYSEC-2026-311 / CVE-2026-45829 — ChromaDB

- **Package and version:** `chromadb==1.5.9`
- **Scanner exception:** `pip-audit --ignore-vuln PYSEC-2026-311`
- **Reason:** `pip-audit` reports no fixed version for this advisory. ChromaDB
  1.5.9 is the current PyPI release, but remains in the affected range.
- **Scope and mitigation:** this platform uses `chromadb.PersistentClient` as a
  local embedded store. It does not expose the affected Chroma server API
  endpoint to untrusted networks. Kubernetes NetworkPolicies also restrict
  access to the RAG workload and Ollama only.
- **Review requirement:** remove this exception and upgrade ChromaDB as soon as
  the advisory lists a fixed version. `pip-audit` continues to scan every other
  dependency and every future ChromaDB advisory.
