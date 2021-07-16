{{/*
Expand the name of the chart.
*/}}
{{- define "datarobot-management-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "datarobot-management-agent.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "datarobot-management-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "datarobot-management-agent.labels" -}}
helm.sh/chart: {{ include "datarobot-management-agent.chart" . }}
{{ include "datarobot-management-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: bosun
{{- end }}

{{/*
Selector labels
*/}}
{{- define "datarobot-management-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datarobot-management-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for bosun
*/}}
{{- define "datarobot-management-agent.bosunServiceAccountName" -}}
{{- if .Values.bosun.serviceAccount.create }}
{{- default (include "datarobot-management-agent.fullname" .) .Values.bosun.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.bosun.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for kaniko
*/}}
{{- define "datarobot-management-agent.kanikoServiceAccountName" -}}
{{- if .Values.imageBuilder.serviceAccount.create }}
{{- default (printf "kaniko-%s" (include "datarobot-management-agent.fullname" .) | trunc 63 | trimSuffix "-") .Values.imageBuilder.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.imageBuilder.serviceAccount.name }}
{{- end }}
{{- end }}
