{{/*
Retrieve the domain (host) name used to access Cassandra.
*/}}{{- define "cassandra.domain" -}}
{{ .Values.cassandra.domain | default "k8ssandra-dc1-service" | quote }}
{{- end }}

{{/*
Retrieve the domain (host) name used to access Cassandra.
*/}}{{- define "cassandra.port" -}}
{{ .Values.cassandra.port | default "9042" }}
{{- end }}

{{/*
Generate the name of the Cassandra keyspace and role name.
*/}}
{{- define "cassandra.keyspace" -}}
{{- .Release.Namespace | replace "-" "_" }}_{{ include "service.name" . }}
{{- end }}

{{/*
Retrieve the image identifier used to run Liquibase jobs.
*/}}
{{- define "cassandra.liquibase.image" -}}
{{- .Values.cassandra.liquibase.image | default "docker.io/greenlightcoop/cassandra-liquibase:0.1.5@sha256:93af22f41fe3926b36191f84e87f79a97b6b203a41eedde06fff141b7d59acfe" }}
{{- end }}

{{/*
Generate the name of the secret used to hold Cassandra authentication data for this service.
*/}}
{{- define "cassandra.auth.secret.name" -}}
{{ .Release.Namespace }}-{{ include "service.name" . }}-cassandra-auth
{{- end }}

{{- define "cassandra.resources" -}}
{{- if .Values.cassandra.enabled -}}
{{ include "cassandra.auth.secret" . }}
{{ include "cassandra.setup.job" . }}
{{ include "cassandra.schema.job" . }}
{{ include "cassandra.teardown.job" . }}
{{ end -}}
{{- end -}}