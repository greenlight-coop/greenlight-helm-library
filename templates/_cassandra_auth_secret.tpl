{{- define "cassandra.auth.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "cassandra.auth.secret.name" . }}
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: password
    helm.sh/hook: pre-install
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
stringData:
  username: {{ include "cassandra.keyspace" . }}

---
{{- end -}}