
{{/*
Generate the name of the Cassandra keyspace and role name.
*/}}
{{- define "service.cassandraBaseName" -}}
{{- .Release.Namespace | replace "-" "_" }}
{{- end }}

{{/*
Generate the name of the Cassandra keyspace and role name.
*/}}
{{- define "service.keyspace" -}}
{{- include "service.cassandraBaseName" . }}_{{ include "service.name" . }}
{{- end }}

{{/*
Generate the name of the secret used to hold Cassandra authentication data for this service.
*/}}
{{- define "service.cassandraAuthSecret" -}}
{{ .Release.Namespace }}-{{ include "service.name" . }}-cassandra-auth
{{- end }}
