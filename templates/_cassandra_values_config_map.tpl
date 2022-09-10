{{- define "cassandra.values.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "service.name" . }}-cassandra-values
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
data:
  replicationFactor: {{ .Values.global.cassandra.replicationFactor | quote }}

---
{{- end -}}