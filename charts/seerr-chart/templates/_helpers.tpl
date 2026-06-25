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

{{/*
Settings management mode (ui or helm).
*/}}
{{- define "seerr.settings.management" -}}
{{- $settings := .Values.settings | default dict -}}
{{- default "ui" $settings.management -}}
{{- end }}

{{/*
True when Helm manages settings.json via init container.
*/}}
{{- define "seerr.settings.helmEnabled" -}}
{{- eq (include "seerr.settings.management" .) "helm" -}}
{{- end }}

{{/*
Name of the chart-rendered settings Secret.
*/}}
{{- define "seerr.settings.secretName" -}}
{{- printf "%s-settings" (include "seerr.fullname" .) -}}
{{- end }}

{{/*
Secret name used as settings source in helm mode.
*/}}
{{- define "seerr.settings.sourceSecretName" -}}
{{- $settings := .Values.settings | default dict -}}
{{- if $settings.existingSecret -}}
{{- $settings.existingSecret -}}
{{- else -}}
{{- include "seerr.settings.secretName" . -}}
{{- end -}}
{{- end }}

{{/*
Read a Secret data key at render time (requires cluster lookup; no-op when absent).
*/}}
{{- define "seerr.settings.secretValue" -}}
{{- $secret := lookup "v1" "Secret" .context.Release.Namespace .secret -}}
{{- if and $secret (index $secret.data .key) -}}
{{- index $secret.data .key | b64dec -}}
{{- end -}}
{{- end }}

{{/*
Merged settings.json content for helm mode.
*/}}
{{- define "seerr.settings.json" -}}
{{- $settings := .Values.settings | default dict -}}
{{- $defaults := .Files.Get "resources/settings-defaults.json" | fromJson -}}
{{- $overrides := $settings.data | default dict -}}
{{- $merged := mergeOverwrite $defaults $overrides -}}
{{- $secretRefs := $settings.secretRefs | default dict -}}
{{- if $secretRefs.clientId }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.clientId.secret "key" $secretRefs.clientId.key "context" .) -}}
{{- if $val }}{{- $_ := set $merged "clientId" $val -}}{{- end }}
{{- end }}
{{- if $secretRefs.sessionSecret }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.sessionSecret.secret "key" $secretRefs.sessionSecret.key "context" .) -}}
{{- if $val }}{{- $_ := set $merged "sessionSecret" $val -}}{{- end }}
{{- end }}
{{- if $secretRefs.vapidPrivate }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.vapidPrivate.secret "key" $secretRefs.vapidPrivate.key "context" .) -}}
{{- if $val }}{{- $_ := set $merged "vapidPrivate" $val -}}{{- end }}
{{- end }}
{{- if $secretRefs.vapidPublic }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.vapidPublic.secret "key" $secretRefs.vapidPublic.key "context" .) -}}
{{- if $val }}{{- $_ := set $merged "vapidPublic" $val -}}{{- end }}
{{- end }}
{{- if $secretRefs.mainApiKey }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.mainApiKey.secret "key" $secretRefs.mainApiKey.key "context" .) -}}
{{- if $val }}
{{- $main := $merged.main | default dict | deepCopy -}}
{{- $_ := set $main "apiKey" $val -}}
{{- $_ := set $merged "main" $main -}}
{{- end }}
{{- end }}
{{- if or $secretRefs.oidcClientId $secretRefs.oidcClientSecret }}
{{- $oidcId := "" -}}
{{- $oidcSecret := "" -}}
{{- if $secretRefs.oidcClientId }}
{{- $oidcId = include "seerr.settings.secretValue" (dict "secret" $secretRefs.oidcClientId.secret "key" $secretRefs.oidcClientId.key "context" .) -}}
{{- end }}
{{- if $secretRefs.oidcClientSecret }}
{{- $oidcSecret = include "seerr.settings.secretValue" (dict "secret" $secretRefs.oidcClientSecret.secret "key" $secretRefs.oidcClientSecret.key "context" .) -}}
{{- end }}
{{- if or $oidcId $oidcSecret }}
{{- $oidc := $merged.oidc | default dict | deepCopy -}}
{{- $providers := $oidc.providers | default list -}}
{{- if $providers }}
{{- $provider := index $providers 0 | default dict | deepCopy -}}
{{- if $oidcId }}{{- $_ := set $provider "clientId" $oidcId -}}{{- end }}
{{- if $oidcSecret }}{{- $_ := set $provider "clientSecret" $oidcSecret -}}{{- end }}
{{- $_ := set $oidc "providers" (list $provider) -}}
{{- $_ := set $merged "oidc" $oidc -}}
{{- end }}
{{- end }}
{{- end }}
{{- if $secretRefs.radarrApiKey }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.radarrApiKey.secret "key" $secretRefs.radarrApiKey.key "context" .) -}}
{{- if $val }}
{{- $radarr := $merged.radarr | default list -}}
{{- if $radarr }}
{{- $server := index $radarr 0 | default dict | deepCopy -}}
{{- $_ := set $server "apiKey" $val -}}
{{- $_ := set $merged "radarr" (list $server) -}}
{{- end }}
{{- end }}
{{- end }}
{{- if $secretRefs.sonarrApiKey }}
{{- $val := include "seerr.settings.secretValue" (dict "secret" $secretRefs.sonarrApiKey.secret "key" $secretRefs.sonarrApiKey.key "context" .) -}}
{{- if $val }}
{{- $sonarr := $merged.sonarr | default list -}}
{{- if $sonarr }}
{{- $server := index $sonarr 0 | default dict | deepCopy -}}
{{- $_ := set $server "apiKey" $val -}}
{{- $_ := set $merged "sonarr" (list $server) -}}
{{- end }}
{{- end }}
{{- end }}
{{- $merged | toPrettyJson -}}
{{- end }}

{{/*
Apply-settings init container image (reuses volumePermissions busybox image).
*/}}
{{- define "seerr.settings.initImage" -}}
{{- include "seerr.volumePermissions.image" . -}}
{{- end }}
