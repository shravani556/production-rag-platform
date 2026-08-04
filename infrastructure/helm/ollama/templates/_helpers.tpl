{{- define "ollama.name" -}}{{ default .Chart.Name .Values.nameOverride }}{{- end }}
{{- define "ollama.fullname" -}}{{ default (printf "%s-%s" .Release.Name (include "ollama.name" .)) .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "ollama.labels" -}}{ app.kubernetes.io/name: {{ include "ollama.name" . }}, app.kubernetes.io/instance: {{ .Release.Name }}, app.kubernetes.io/component: inference }{{- end }}
{{- define "ollama.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ollama.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- define "ollama.serviceAccountName" -}}{{ if .Values.serviceAccount.create }}{{ default (include "ollama.fullname" .) .Values.serviceAccount.name }}{{ else }}{{ required "serviceAccount.name is required when serviceAccount.create=false" .Values.serviceAccount.name }}{{ end }}{{- end }}
