{{- define "cassandra.teardown.job" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Namespace }}-{{ include "service.name" . }}-cassandra-teardown
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
        image: {{ include "cassandra.liquibase.image" . }}
        command: ["/bin/sh"]
        args:
          - -c
          - >
            mkdir -p /liquibase/processed \
              && for file in /liquibase/templates/*; do envsubst < $file > /liquibase/processed/${file##*/}; done \
              && cqlsh \
              --request-timeout="600" \
              --no-color \
              --username=$SUPERUSER_USERNAME \
              --password=$SUPERUSER_PASSWORD \
              --file=/liquibase/processed/cassandra-teardown.cql \
              {{ include "cassandra.domain" . }}
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
          - name: SERVICE_KEYSPACE
            value: {{ include "cassandra.keyspace" . | quote }}
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
{{ end -}}