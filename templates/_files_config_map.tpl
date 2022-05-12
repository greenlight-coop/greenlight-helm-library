{{- define "service.files.configmap" -}}
{{- $globdata := .Files.Glob "files/*" }}
{{ if $globdata -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
data:
{{ ($globdata).AsConfig | indent 2 }}

---
{{ end -}}
{{- end -}}