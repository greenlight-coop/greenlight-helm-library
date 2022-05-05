{{- define "containerPort" -}}
{{ .Values.containerPort | default "8080" }}
{{- end }}

{{- define "probes.liveness.path" -}}
  {{- with .Values.probes -}}
    {{- if . -}}
      {{- if .liveness -}}
        {{ .default "/healthz" .liveness.path }}
      {{- else -}} 
        "/healthz"
      {{- end -}}
    {{- else -}}
      "/healthz"
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "probes.readiness.path" -}}
  {{- with .Values.probes -}}
    {{- if . -}}
      {{- if .readiness -}}
        {{ .default "/healthz" .readiness.path }}
      {{- else -}} 
        "/healthz"
      {{- end -}}
    {{- else -}}
      "/healthz"
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "knative.service" -}}
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: {{ include "service.fullname" . }}
  namespace: {{ .Release.Namespace }}
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/min-scale: "1"
      labels:
        app.kubernetes.io/component: rest-service
        app.kubernetes.io/part-of: greenlight-application
        {{- if .Values.access.public }}
        greenlightcoop.dev/access.public: allow
        {{ end -}}
        {{- range .Values.access.roles }}
        {{ print "greenlightcoop.dev/access." . ": allow" }}
        {{- end }}  
        {{- include "service.labels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ include "service.name" . }}
        {{- with .Values.image }}
        image: "{{.repository}}:{{ .tag }}{{- if (.digest) -}} @{{.digest}} {{- end -}}"
        {{- end }}
        env:
        - name: DEBUG
          value: "{{ .Values.global.debug }}"
        {{- if .Values.keycloak }}
        {{- if .Values.keycloak.clientSuffix }}
        - name: KEYCLOAK_CLIENT_ID
          value: {{ .Release.Namespace }}-{{ .Values.keycloak.clientSuffix }}
        - name: KEYCLOAK_REALM
          value: {{ .Release.Namespace }}-realm
        - name: KEYCLOAK_URL
          value: https://keycloak.{{ .Values.global.domain }}/auth
        {{ end -}}
        {{ end -}}
        ports:
        - containerPort: {{ include "containerPort" . }}
        livenessProbe:
          httpGet:
            path: {{ include "probes.liveness.path" . }}
            port: {{ include "containerPort" . }}
          initialDelaySeconds: 3
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: {{ include "probes.readiness.path" . }}
            port: {{ include "containerPort" . }}
          initialDelaySeconds: 3
          periodSeconds: 3

---
{{ end -}}