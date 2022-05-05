{{- define "service.deployment" -}}
{{ include "cassandra.resources" . }}
{{ include "service.files.configmap" . }}
{{ include "knative.service" . }}
{{ include "istio.virtualservice" . }}
{{- end -}}