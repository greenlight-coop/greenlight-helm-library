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
        {{ default "docker.io/greenlightcoop/cassandra-liquibase:0.1.7@sha256:bd3daf4f2a24416701ceb133c3a367b0dde727be5485b9a24b20cd4a89f91ca5" .liquibase.image }}
      {{- else -}} 
        "docker.io/greenlightcoop/cassandra-liquibase:0.1.7@sha256:bd3daf4f2a24416701ceb133c3a367b0dde727be5485b9a24b20cd4a89f91ca5"
      {{- end -}}
    {{- else -}}
      "docker.io/greenlightcoop/cassandra-liquibase:0.1.7@sha256:bd3daf4f2a24416701ceb133c3a367b0dde727be5485b9a24b20cd4a89f91ca5"
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