{{- define "authorization.policy.system" -}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: system-authorization-policy
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "service.labels" . | nindent 4 }}
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths:
        - /metrics 
        - /healthz
---
{{- end -}}