{{/*
Expand the name of the chart.
*/}}
{{- define "happy-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "happy-server.fullname" -}}
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
{{- define "happy-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "happy-server.labels" -}}
helm.sh/chart: {{ include "happy-server.chart" . }}
{{ include "happy-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "happy-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "happy-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "happy-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "happy-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "happy-server.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
Database URL (constructed from PostgreSQL subchart)
*/}}
{{- define "happy-server.databaseUrl" -}}
{{- if .Values.postgresql.enabled }}
postgresql://{{ .Values.postgresql.auth.username }}:$(POSTGRES_PASSWORD)@{{ include "happy-server.fullname" . }}-postgresql:5432/{{ .Values.postgresql.auth.database }}
{{- else }}
$(DATABASE_URL)
{{- end }}
{{- end }}

{{/*
Redis URL (constructed from Redis subchart)
*/}}
{{- define "happy-server.redisUrl" -}}
{{- if .Values.redis.enabled }}
{{- if .Values.redis.auth.enabled }}
redis://:$(REDIS_PASSWORD)@{{ include "happy-server.fullname" . }}-redis-master:6379
{{- else }}
redis://{{ include "happy-server.fullname" . }}-redis-master:6379
{{- end }}
{{- else }}
$(REDIS_URL)
{{- end }}
{{- end }}

{{/*
S3/MinIO configuration helpers
*/}}
{{- define "happy-server.s3Host" -}}
{{- if .Values.minio.enabled }}
{{ include "happy-server.fullname" . }}-minio
{{- else }}
$(S3_HOST)
{{- end }}
{{- end }}

{{- define "happy-server.s3Port" -}}
{{- if .Values.minio.enabled }}
9000
{{- else }}
$(S3_PORT)
{{- end }}
{{- end }}

{{- define "happy-server.s3UseSsl" -}}
{{- if .Values.minio.enabled }}
false
{{- else }}
$(S3_USE_SSL)
{{- end }}
{{- end }}

{{- define "happy-server.s3Bucket" -}}
{{- if .Values.minio.enabled }}
{{ .Values.minio.defaultBuckets }}
{{- else }}
$(S3_BUCKET)
{{- end }}
{{- end }}

{{- define "happy-server.s3PublicUrl" -}}
{{- if .Values.minio.enabled }}
http://{{ include "happy-server.fullname" . }}-minio:9000/{{ .Values.minio.defaultBuckets }}
{{- else }}
$(S3_PUBLIC_URL)
{{- end }}
{{- end }}
