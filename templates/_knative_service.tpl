{{- define "containerPort" -}}
{{ .Values.probes.liveness.port | default "8080" }}
{{- end }}

{{- define "probes.liveness.path" -}}
{{ .Values.probes.liveness.path | default "/healthz" | quote }}
{{- end }}


{{- define "probes.readiness.path" -}}
{{ .Values.probes.readiness.path | default "/healthz" | quote }}
{{- end }}

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