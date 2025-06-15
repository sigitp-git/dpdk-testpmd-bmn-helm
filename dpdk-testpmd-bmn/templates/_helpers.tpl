{{/*
Expand the name of the chart.
*/}}
{{- define "dpdk-testpmd-bmn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "dpdk-testpmd-bmn.fullname" -}}
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
{{- define "dpdk-testpmd-bmn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dpdk-testpmd-bmn.labels" -}}
helm.sh/chart: {{ include "dpdk-testpmd-bmn.chart" . }}
{{ include "dpdk-testpmd-bmn.selectorLabels" . }}
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
{{- define "dpdk-testpmd-bmn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dpdk-testpmd-bmn.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dpdk-testpmd-bmn.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dpdk-testpmd-bmn.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "dpdk-testpmd-bmn.image" -}}
{{- if .Values.global.imageRegistry }}
{{- printf "%s/%s:%s" .Values.global.imageRegistry .Values.dpdkPods.image.repository .Values.dpdkPods.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.dpdkPods.image.repository .Values.dpdkPods.image.tag }}
{{- end }}
{{- end }}

{{/*
Create network list for pod annotations
*/}}
{{- define "dpdk-testpmd-bmn.networkList" -}}
{{- $networks := list }}
{{- range .Values.networkAttachmentDefinitions.networks }}
{{- $networks = append $networks .name }}
{{- end }}
{{- join ", " $networks }}
{{- end }}
