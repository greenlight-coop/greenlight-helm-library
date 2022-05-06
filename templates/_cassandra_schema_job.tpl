{{- define "cassandra.schema.job" -}}
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
        image: {{ include "cassandra.liquibase.image" . }}
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
                name: {{ include "cassandra.auth.secret.name" . | quote }}
                key: username
          - name: SERVICE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ include "cassandra.auth.secret.name" . | quote }}
                key: password
          - name: CASSANDRA_DOMAIN
            value: {{ include "cassandra.domain" . | quote }}
          - name: CASSANDRA_PORT
            value: {{ include "cassandra.port" . | quote }}
          - name: SERVICE_KEYSPACE
            value: {{ include "cassandra.keyspace" . | quote }}
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
{{ end -}}