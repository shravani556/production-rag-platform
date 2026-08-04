{{- define "rag-platform.name" -}}{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "rag-platform.fullname" -}}{{ if .Values.fullnameOverride }}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{ else }}{{ printf "%s-%s" .Release.Name (include "rag-platform.name" .) | trunc 63 | trimSuffix "-" }}{{ end }}{{- end }}
{{- define "rag-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rag-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "rag-platform.labels" -}}
{ app.kubernetes.io/name: {{ include "rag-platform.name" . }}, app.kubernetes.io/instance: {{ .Release.Name }}, app.kubernetes.io/component: frontend, app.kubernetes.io/part-of: production-rag-platform, app.kubernetes.io/managed-by: {{ .Release.Service }} }{{- end }}
{{- define "rag-platform.serviceAccountName" -}}{{ if .Values.serviceAccount.create }}{{ default (include "rag-platform.fullname" .) .Values.serviceAccount.name }}{{ else }}{{ required "serviceAccount.name is required when serviceAccount.create=false" .Values.serviceAccount.name }}{{ end }}{{- end }}
{{- define "rag-platform.httpProbe" -}}
httpGet:
  path: {{ .probe.path }}
  port: http
periodSeconds: {{ .probe.periodSeconds }}
timeoutSeconds: {{ .probe.timeoutSeconds }}
failureThreshold: {{ .probe.failureThreshold }}
{{- end }}
