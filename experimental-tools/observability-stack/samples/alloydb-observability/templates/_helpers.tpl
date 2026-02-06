{{/*
Expand the name of the chart.
*/}}
{{- define "alloydb-observability.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "alloydb-observability.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "alloydb-observability.labels" -}}
helm.sh/chart: {{ include "alloydb-observability.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "alloydb-observability.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "alloydb-observability.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alloydb-observability.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
