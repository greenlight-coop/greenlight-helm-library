{{/*
Retrieve the domain (host) name used to access Cassandra.
*/}}{{- define "cassandra.domain" -}}
{{ .Values.cassandra.domain | default "k8ssandra-dc1-service.k8ssandra-operator" }}
{{- end }}

{{/*
Retrieve the domain (host) name used to access Cassandra.
*/}}{{- define "cassandra.port" -}}
{{ .Values.cassandra.port | default "9042" }}
{{- end }}

{{/*
Retrieve the domain (host) name used to access Cassandra.
*/}}{{- define "cassandra.datacenter" -}}
{{ .Values.cassandra.datacenter | default "dc1" }}
{{- end }}

{{/*
Generate the name of the Cassandra keyspace and role name.
*/}}
{{- define "cassandra.keyspace" -}}
{{- print .Release.Namespace "_" (include "cassandra.deployedService" .) | replace "-" "_" }}
{{- end }}

{{/*
The name of the deployed service accessing Cassandra.
*/}}
{{- define "cassandra.deployedService" -}}
{{ .Values.cassandra.deployedService | default (include "service.basename" .) }}
{{- end }}

{{/*
Retrieve the image identifier used to run Liquibase jobs.
*/}}
{{- define "cassandra.liquibase.image" -}}
  {{- with .Values.cassandra -}}
    {{- if . -}}
      {{- if .liquibase -}}
        {{ default "docker.io/greenlightcoop/cassandra-liquibase:0.1.6@sha256:99dc3c0e3cc00f22f393455517e51635b835b6e2f09fd98288060f81ca91978d" .liquibase.image }}
      {{- else -}} 
        "docker.io/greenlightcoop/cassandra-liquibase:0.1.6@sha256:99dc3c0e3cc00f22f393455517e51635b835b6e2f09fd98288060f81ca91978d"
      {{- end -}}
    {{- else -}}
      "docker.io/greenlightcoop/cassandra-liquibase:0.1.6@sha256:99dc3c0e3cc00f22f393455517e51635b835b6e2f09fd98288060f81ca91978d"
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Generate the name of the secret used to hold Cassandra authentication data for this service.
*/}}
{{- define "cassandra.auth.secret.name" -}}
{{ include "cassandra.deployedService" . }}-cassandra-auth
{{- end }}

{{- define "cassandra.resources" -}}
{{- if .Values.cassandra -}}
{{- if .Values.cassandra.enabled -}}
{{ include "cassandra.auth.secret" . }}
{{ include "cassandra.setup.job" . }}
{{ include "cassandra.schema.job" . }}
{{ include "cassandra.teardown.job" . }}
{{ include "cassandra.values.configmap" . }}
{{ end -}}
{{- end -}}
{{- end -}}