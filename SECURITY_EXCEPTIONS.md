# Temporary security exceptions

## Ollama upstream binary / CVE-2026 findings

- **Image and scope:** `ollama/ollama:0.32.3`, compiled `/usr/bin/ollama`
  only. The exceptions are applied only to the `Scan Ollama image` Trivy step
  through `.trivyignore.ollama`; they do not affect the RAG application scan.
- **Scanner evidence:** the 2026-08-04 Trivy scan found zero Ubuntu 24.04 OS
  vulnerabilities and 31 High findings in the upstream Go binary (30 unique
  CVEs; `CVE-2026-33814` is detected in two compiled components).
- **Reason:** the current official image bundles Go 1.26.0 and dependencies
  below the fixes reported by Trivy, including `golang.org/x/crypto` 0.43.0,
  `golang.org/x/net` 0.46.0, `golang.org/x/image` 0.22.0,
  `golang.org/x/text` 0.30.0, and `github.com/buger/jsonparser` 1.1.1.
  This repository does not build or modify the upstream Ollama binary.
- **Expiry and review:** every exception expires on **2026-09-03**. Before that
  date, scan a newer official Ollama image and remove every CVE it remediates.
  Do not renew an exception without a documented risk review.
- **Risk acceptance:** this is a temporary CI exception, not a declaration that
  the CVEs are harmless. Production promotion requires an approved risk owner
  until an upstream image removes the findings.

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
