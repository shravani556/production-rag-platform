# Observability foundation

## Scope and architecture

Phase 9 is a deployment-ready, reference-only observability design. It deploys
no Kubernetes workload, CRD, namespace, monitoring server, log collector,
tracing service, dashboard, alert route, or infrastructure. The Terraform
module records provider-neutral retention, storage, backup, dashboard, and
alert-routing intent. Helm values are disabled, and Kubernetes placeholders are
comments only.

The target architecture separates telemetry collection from visualization and
response. Prometheus receives metrics from approved exporters and application
endpoints; Grafana visualizes approved metrics, logs, and traces; Loki receives
structured logs through an approved collector; Alertmanager routes reviewed
alerts; OpenTelemetry Collector receives traces and selected metrics; Jaeger is
a tracing placeholder; Tempo is the future scalable trace-backend option.

## Monitoring and logging components

- Prometheus: scrape, retention, recording-rule, and alert-evaluation plane.
- kube-state-metrics: Kubernetes object-state metrics.
- node-exporter and cAdvisor: node and container resource metrics.
- metrics-server: Kubernetes resource metrics; it is not a replacement for
  Prometheus retention or alerting.
- Grafana: dashboards and datasource visualization only; use SSO/RBAC and
  provision dashboards from reviewed source.
- Loki and Promtail: central structured-log storage and collection. Future
  production evaluation may replace Promtail with an approved OpenTelemetry or
  other collector path.
- Alertmanager: deduplication, grouping, silencing, routing, and escalation.
- OpenTelemetry Collector: controlled receiver, processor, sampling, and export
  boundary. Avoid exporting sensitive prompts, document contents, credentials,
  or unrestricted user identifiers.
- Jaeger and Tempo: placeholders for trace storage/query. Select one approved
  backend and define retention, storage, tenant isolation, and cost controls.

## Application telemetry contract

Future application instrumentation must emit bounded-cardinality, privacy-safe
metrics for HTTP request count, request duration/latency, error rate, token
usage, prompt count, embedding duration, retrieval latency, LLM latency, chunk
retrieval count/duration, vector database operations/latency/errors, and Ollama
inference availability/latency/errors. Use counters, histograms, and gauges as
appropriate; never label metrics with prompt text, document chunks, user input,
request IDs, tokens, full URLs, or other unbounded/sensitive values.

Trace spans should cover HTTP ingress, retrieval, embedding, vector lookup, LLM
inference, and response generation. Propagate standard context only over trusted
boundaries. Logs should be structured, correlated with a safe trace identifier,
and redacted before export. Sampling and retention must be explicitly approved.

## Dashboards

Prepare reviewed dashboard definitions for:

- Infrastructure: Prometheus health, scrape failures, ingestion volume,
  retention, storage, and alert delivery.
- Kubernetes: cluster state, nodes, pods, container CPU/memory, restarts,
  scheduling, network, PVC capacity/usage, and metrics-server health.
- Application: request rate, latency percentiles, availability, error rate,
  retrieval quality proxies, token/prompt volume, and saturation.
- RAG/LLM: embedding duration, retrieval latency, chunk counts, LLM duration,
  model/endpoint availability, and bounded token usage.
- ChromaDB and Ollama: operation/request rate, latency, errors, availability,
  resource saturation, persistence capacity, and model inference health.

Use stable dashboard UIDs, folder RBAC, source-controlled JSON, versioned
datasource references, ownership, and runbook links. Do not embed credentials or
datasource URLs in dashboards.

## Alerting contract

Future PrometheusRule definitions must include owner, severity, operational
window, actionable annotation, dashboard link, and runbook URL. Initial alert
classes are high CPU, high memory, restart loops, PVC nearing capacity, Node Not
Ready, Ollama unavailable, application unavailable, high latency, high error
rate, and low disk. Thresholds are intentionally not hardcoded here: tune them
against service objectives, capacity, noise budget, and escalation policy.

Route alerts through Alertmanager with environment isolation, grouping,
deduplication, inhibition, maintenance silences, escalation ownership, and an
auditable receiver integration. Test each alert with synthetic non-production
signals before paging production responders.

## Kubernetes and Helm integration

`infrastructure/kubernetes/observability-placeholders.yaml` contains no object;
it documents future ServiceMonitor, PodMonitor, PrometheusRule, Grafana dashboard
ConfigMap, and Loki datasource ConfigMap contracts. Do not add a custom resource
until its operator, CRD version, RBAC, namespace, and lifecycle owner are
approved. `infrastructure/helm/observability-values.yaml` is likewise reference
only, not a deployable chart; every component has `enabled: false`.

## Operational controls

Use TLS, network isolation, least-privilege RBAC, tenant/environment separation,
encryption at rest, backup/restore testing, immutable audit trails, SSO, and
short-lived identity. Define metrics/logs/traces retention independently, use
cost budgets, and document deletion and legal-hold requirements. Keep telemetry
within the approved data boundary and apply redaction before persistence.

## Future deployment gate and rollback

Before deployment, approve component topology, storage classes, retention,
backup/restore evidence, RBAC, network policy, dashboard reviews, alert routes,
SLOs, runbooks, data classification, redaction, and capacity/cost model. Start
with a non-production environment and validate scrape, ingestion, query,
alerting, tracing, and recovery paths.

Rollback disables the approved component values, removes the corresponding
reviewed release, restores the previous dashboard/rule version, and verifies no
unexpected telemetry collection remains. Do not delete telemetry storage until
the retention, incident, audit, and legal requirements are satisfied.
