{{- define "service.deployment" -}}
{{- if .Values.cassandra.enabled -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "service.cassandraAuthSecret" . }}
  namespace: default
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: password
    helm.sh/hook: pre-install
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
stringData:
  username: {{ include "service.keyspace" . }}

---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "service.cassandraAuthSecret" . }}
  namespace: default
  annotations:
    helm.sh/hook: post-delete
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded,hook-failed
    helm.sh/hook-weight: "2"
  labels:
    {{- include "service.labels" . | nindent 4 }}
stringData:
  username: {{ include "service.keyspace" . }}

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
  namespace: default
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
data:
{{ (.Files.Glob "files/*").AsConfig | indent 2 }}

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
  namespace: default
  annotations:
    helm.sh/hook: post-delete
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded,hook-failed
    helm.sh/hook-weight: "0"
  labels:
    {{- include "service.labels" . | nindent 4 }}
data:
{{ (.Files.Glob "files/*").AsConfig | indent 2 }}

---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-cassandra-setup
  namespace: default
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
    helm.sh/hook-weight: "1"
  labels:
    {{- include "service.labels" . | nindent 4 }}
spec:
  template:
    spec:
      containers:
      - name: liquibase
        image: {{ .Values.cassandra.liquibase.image }}
        command: ["/bin/sh"]
        args:
          - -c
          - >
            mkdir -p /liquibase/processed \
              && for file in /liquibase/templates/*; do envsubst < $file > /liquibase/processed/${file##*/}; done \
              && cqlsh \
              --no-color \
              --username=$SUPERUSER_USERNAME \
              --password=$SUPERUSER_PASSWORD \
              --file=/liquibase/processed/cassandra-setup.cql \
              {{ .Values.cassandra.domain }}
        env:
          - name: SERVICE_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: username
          - name: SERVICE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: password
          - name: SERVICE_KEYSPACE
            value: {{ include "service.keyspace" . }}
          - name: SUPERUSER_USERNAME
            valueFrom:
              secretKeyRef:
                name: k8ssandra-superuser
                key: username
          - name: SUPERUSER_PASSWORD
            valueFrom:
              secretKeyRef:
                name: k8ssandra-superuser
                key: password
        volumeMounts:
        - name: templates
          mountPath: "/liquibase/templates"
          readOnly: true
      volumes:
      - name: templates
        configMap:
          name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
      restartPolicy: Never

---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-schema
  namespace: default
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
    helm.sh/hook-weight: "2"
  labels:
    {{- include "service.labels" . | nindent 4 }}
spec:
  template:
    spec:
      containers:
      - name: liquibase
        image: {{ .Values.cassandra.liquibase.image }}
        command: ["/bin/sh"]
        args:
          - -c
          - >
            mkdir -p /liquibase/processed \
              && for file in /liquibase/templates/*; do envsubst < $file > /liquibase/processed/${file##*/}; done \
              && liquibase \
                --log-level=INFO \
                --defaultsFile=processed/liquibase.properties \
                --changelog-file=processed/changelog.yaml \
                --username=$SERVICE_USERNAME \
                --password=$SERVICE_PASSWORD \
                update
        env:
          - name: SERVICE_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: username
          - name: SERVICE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: password
          - name: CASSANDRA_DOMAIN
            value: {{ .Values.cassandra.domain }}
          - name: SERVICE_KEYSPACE
            value: {{ include "service.keyspace" . }}
        volumeMounts:
        - name: templates
          mountPath: "/liquibase/templates"
          readOnly: true
      volumes:
      - name: templates
        configMap:
          name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
      restartPolicy: Never

---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-cassandra-teardown
  namespace: default
  annotations:
    helm.sh/hook: post-delete	
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
    helm.sh/hook-weight: "1"
  labels:
    {{- include "service.labels" . | nindent 4 }}
spec:
  template:
    spec:
      containers:
      - name: liquibase
        image: {{ .Values.cassandra.liquibase.image }}
        command: ["/bin/sh"]
        args:
          - -c
          - >
            mkdir -p /liquibase/processed \
              && for file in /liquibase/templates/*; do envsubst < $file > /liquibase/processed/${file##*/}; done \
              && cqlsh \
              --no-color \
              --username=$SUPERUSER_USERNAME \
              --password=$SUPERUSER_PASSWORD \
              --file=/liquibase/processed/cassandra-teardown.cql \
              {{ .Values.cassandra.domain }}
        env:
          - name: SERVICE_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: username
          - name: SERVICE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ include "service.cassandraAuthSecret" . }}
                key: password
          - name: SERVICE_KEYSPACE
            value: {{ include "service.keyspace" . }}
          - name: SUPERUSER_USERNAME
            valueFrom:
              secretKeyRef:
                name: k8ssandra-superuser
                key: username
          - name: SUPERUSER_PASSWORD
            valueFrom:
              secretKeyRef:
                name: k8ssandra-superuser
                key: password
        volumeMounts:
        - name: templates
          mountPath: "/liquibase/templates"
          readOnly: true
      volumes:
      - name: templates
        configMap:
          name: {{ .Release.Namespace }}-{{ include "service.name" . }}-files
      restartPolicy: Never

---
{{-- end }}
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
        greenlightcoop.dev/access.worker: allow
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
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 3

---
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
        exact: /api/{{ include "service.name" . }}
    rewrite:
      uri: /
      authority: {{ include "service.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
    route:
    - destination:
        port:
          number: 80
        host: {{ include "service.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local
    
{{-- end }}