{{/*
Expand the name of the chart.
*/}}
{{- define "seerr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "seerr.fullname" -}}
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
{{- define "seerr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "seerr.labels" -}}
helm.sh/chart: {{ include "seerr.chart" . }}
{{ include "seerr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: {{ .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "seerr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "seerr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "seerr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "seerr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the pvc config to use
*/}}
{{- define "seerr.configPersistenceName" -}}
{{- default (printf "%s-config" (include "seerr.fullname" .)) .Values.config.persistence.name }}
{{- end }}

{{/*
Image digest from sha or digest values (digest may include sha256: prefix).
*/}}
{{- define "seerr.imageDigest" -}}
{{- if .Values.image.digest -}}
{{- $digest := .Values.image.digest -}}
{{- if hasPrefix "sha256:" $digest -}}
{{- trimPrefix "sha256:" $digest -}}
{{- else -}}
{{- $digest -}}
{{- end -}}
{{- else if .Values.image.sha -}}
{{- .Values.image.sha -}}
{{- end -}}
{{- end }}

{{/*
Container image reference.
*/}}
{{- define "seerr.image" -}}
{{- $registry := .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- $digest := include "seerr.imageDigest" . -}}
{{- if $digest -}}
{{- printf "%s/%s:%s@sha256:%s" $registry $repository $tag $digest -}}
{{- else -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Volume permissions init container image reference.
*/}}
{{- define "seerr.volumePermissions.image" -}}
{{- $registry := .Values.volumePermissions.image.registry -}}
{{- $repository := .Values.volumePermissions.image.repository -}}
{{- $tag := .Values.volumePermissions.image.tag -}}
{{- $digest := "" -}}
{{- if .Values.volumePermissions.image.digest -}}
{{- $raw := .Values.volumePermissions.image.digest -}}
{{- if hasPrefix "sha256:" $raw -}}
{{- $digest = trimPrefix "sha256:" $raw -}}
{{- else -}}
{{- $digest = $raw -}}
{{- end -}}
{{- end -}}
{{- if $digest -}}
{{- printf "%s/%s:%s@sha256:%s" $registry $repository $tag $digest -}}
{{- else -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
{{- end }}
