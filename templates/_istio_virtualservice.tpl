{{- define "uri.prefix" -}}
  {{- if .Values.uri -}}
    {{ .Values.uri.override | default (print "/" (include "service.name" .)) | quote }}
  {{- else -}}
    {{ default (print "/" (include "service.name" .)) | quote }}
  {{- end -}}
{{- end -}}

{{- define "istio.virtualservice" -}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ include "service.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/component: rest-service
    app.kubernetes.io/part-of: greenlight-application
    {{- include "service.labels" . | nindent 4 }}
spec:
  gateways:
  - istio-system/istio-gateway
  hosts:
  - {{ .Values.global.subdomain }}{{ if .Values.global.subdomain }}.{{ end }}{{ .Values.global.domain }}
  http:
  - match:
    - uri:
        prefix: "{{ include "uri.prefix" . }}/"
    - uri:
        prefix: "{{ include "uri.prefix" . }}"
    rewrite:
      uri: "/"
      authority: {{ include "service.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
    route:
    - destination:
        port:
          number: 80
        host: {{ include "service.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local

---
{{ end -}}