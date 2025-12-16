{{/*
Expand the name of the chart.
*/}}
{{- define "cloudflare-operator.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cloudflare-operator.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
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
{{- define "cloudflare-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cloudflare-operator.labels" -}}
helm.sh/chart: {{ include "cloudflare-operator.chart" . }}
{{ include "cloudflare-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cloudflare-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cloudflare-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: controller-manager
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cloudflare-operator.serviceAccountName" -}}
{{- if .Values.features.rbac.create }}
{{- default (printf "%s-controller-manager" (include "cloudflare-operator.fullname" .)) .Values.rbac.serviceAccountName }}
{{- else }}
{{- default "default" .Values.rbac.serviceAccountName }}
{{- end }}
{{- end }}

{{/*
Generate the namespace to use
*/}}
{{- define "cloudflare-operator.namespace" -}}
{{- if .Values.global.namespace }}
{{- .Values.global.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Generate webhook service name
*/}}
{{- define "cloudflare-operator.webhook.serviceName" -}}
{{- printf "%s-webhook-service" (include "cloudflare-operator.fullname" .) }}
{{- end }}

{{/*
Generate metrics service name
*/}}
{{- define "cloudflare-operator.metrics.serviceName" -}}
{{- printf "%s-controller-manager-metrics-service" (include "cloudflare-operator.fullname" .) }}
{{- end }}

{{/*
Generate certificate name
*/}}
{{- define "cloudflare-operator.certificate.name" -}}
{{- default "serving-cert" .Values.certManager.certificate.name }}
{{- end }}

{{/*
Generate issuer name
*/}}
{{- define "cloudflare-operator.issuer.name" -}}
{{- default "selfsigned-issuer" .Values.certManager.issuer.name }}
{{- end }}

{{/*
Generate image name with tag
*/}}
{{- define "cloudflare-operator.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
Validate webhook dependencies
*/}}
{{- define "cloudflare-operator.validateWebhook" -}}
{{- if and .Values.features.webhooks.enabled (not .Values.features.certManager.enabled) }}
{{- fail "Webhook functionality requires cert-manager to be enabled. Please set features.certManager.enabled=true or disable webhooks." }}
{{- end }}
{{- end }}

{{/*
Validate feature combinations
*/}}
{{- define "cloudflare-operator.validateFeatures" -}}
{{- include "cloudflare-operator.validateWebhook" . }}
{{- if and .Values.features.metrics.enabled (not .Values.features.rbac.create) }}
{{- fail "Metrics functionality requires RBAC to be enabled. Please set features.rbac.create=true or disable metrics." }}
{{- end }}
{{- if and .Values.features.crds.install (not .Values.features.rbac.create) }}
{{- fail "CRD installation requires RBAC to be enabled for proper operator functionality. Please set features.rbac.create=true." }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "cloudflare-operator.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Generate cert-manager CA injection annotation
*/}}
{{- define "cloudflare-operator.certManager.caInjection" -}}
{{- if .Values.features.certManager.enabled }}
cert-manager.io/inject-ca-from: {{ include "cloudflare-operator.namespace" . }}/{{ include "cloudflare-operator.certificate.name" . }}
{{- end }}
{{- end }}

{{/*
Generate resource name with prefix
*/}}
{{- define "cloudflare-operator.resourceName" -}}
{{- $name := include "cloudflare-operator.fullname" . }}
{{- if .suffix }}
{{- printf "%s-%s" $name .suffix }}
{{- else }}
{{- $name }}
{{- end }}
{{- end }}