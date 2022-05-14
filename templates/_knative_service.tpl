{{- define "containerPort" -}}
{{ .Values.containerPort | default "8080" }}
{{- end }}

{{- define "probes.liveness.path" -}}
  {{- with .Values -}}
    {{- if .probes -}}
      {{- if .probes.liveness -}}
        {{ default "/healthz" .probes.liveness.path }}
      {{- else -}} 
        "/healthz"
      {{- end -}}
    {{- else -}}
      "/healthz"
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "probes.readiness.path" -}}
  {{- with .Values -}}
    {{- if .probes -}}
      {{- if .probes.readiness -}}
        {{ default "/healthz" .probes.readiness.path }}
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
        {{- if .Values.access }}
          {{- if .Values.access.public }}
        greenlightcoop.dev/access.public: allow
          {{- end -}}
          {{- range .Values.access.roles }}
        {{ print "greenlightcoop.dev/access." . ": allow" }}
          {{- end -}}  
        {{ end -}}  
        {{- include "service.labels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ include "service.name" . }}
        {{- with .Values.image }}
        image: "{{.repository}}:{{ .tag }}{{- if (.digest) -}} @{{.digest}} {{- end -}}"
        {{- end }}
        env:
        - name: DEBUG
          value: {{ .Values.global.debug | quote}}
        {{- if .Values.keycloak }}
        {{- if .Values.keycloak.clientSuffix }}
        - name: KEYCLOAK_CLIENT_ID
          value: {{ .Release.Namespace }}-{{ .Values.keycloak.clientSuffix }}
        - name: KEYCLOAK_REALM
          value: {{ .Release.Namespace }}-realm
        - name: KEYCLOAK_URL
          value: https://keycloak.{{ .Values.global.domain }}/auth
        {{- end }}
        {{- end }}
        {{- if .Values.cassandra }}
        {{- if .Values.cassandra.enabled }}
        - name: CASSANDRA_DOMAIN
          value: {{ include "cassandra.domain" . | quote }}
        - name: CASSANDRA_PORT
          value: {{ include "cassandra.port" . | quote }}
        - name: CASSANDRA_KEYSPACE
          value: {{ include "cassandra.keyspace" . | quote }}
        - name: CASSANDRA_USERNAME
          valueFrom:
            secretKeyRef:
              name: {{ include "cassandra.auth.secret.name" . | quote }}
              key: username
        - name: CASSANDRA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "cassandra.auth.secret.name" . | quote }}
              key: password
        {{- end }}
        {{- end }}
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