# Helm Templates

Semua template menggunakan konvensi namespace `{{ .Chart.Name }}-{{ .Values.environment }}`.

## 1. Deployment (`deployment-http-private.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "deployment-http-private"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
  labels:
    app: "deployment-http-private"
    environment: {{ .Values.environment }}
spec:
  revisionHistoryLimit: 3
  {{- if not .Values.autoscalingHttpPrivate.enabled }}
  replicas: {{ .Values.replicaCountHttpPrivate }}
  {{- end }}
  selector:
    matchLabels:
      app: "deployment-http-private"
  template:
    metadata:
      labels:
        app: "deployment-http-private"
    spec:
      restartPolicy: Always
      {{- if .Values.registryECR.enabled }}
      imagePullSecrets:
      - name: "{{ .Values.registryECR.secretName }}"
      {{- end }}
      containers:
        - name: "deployment-http-private"
          envFrom:
            - secretRef:
                name: "env-secret"
          image: "{{ .Values.image }}"
          imagePullPolicy: Always
          ports:
          - containerPort: 33200
          livenessProbe:
            httpGet:
              path: /health
              port: 33200
          readinessProbe:
            httpGet:
              path: /health
              port: 33200
```

### Pattern Penting Deployment:
- Environment variables di-inject via `secretRef` ke `env-secret` (bukan configmap)
- Container port default `33200`
- Health check di `/health` (liveness + readiness)
- `replicas` hanya di-set jika HPA tidak enabled
- `imagePullSecrets` conditional, hanya jika ECR enabled
- `revisionHistoryLimit: 3` untuk limit rollback history

## 2. Service (`service-http-private.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: "service-http-private"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
  labels:
    app: "service-http-private"
    environment: {{ .Values.environment }}
spec:
  selector:
    app: "deployment-http-private"
  type: ClusterIP
  ports:
    - name: "deployment-http-private"
      port: 80
      targetPort: 33200
      protocol: TCP
```

### Pattern Penting Service:
- Type selalu `ClusterIP` (internal only, exposed via Ingress)
- Port `80` → targetPort `33200`
- Selector match ke deployment label `app: "deployment-http-private"`

## 3. Ingress (`ingress-http-private.yaml`)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "ingress-http-private"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  labels:
    app: "ingress-http-private"
    environment: {{ .Values.environment }}
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - {{ .Values.ingressHttpPrivate.domain }}
    secretName: {{ .Values.ingressHttpPrivate.tlsSecret }}
  rules:
    - host: {{ .Values.ingressHttpPrivate.domain }}
      http:
        paths:
          - path: {{ .Values.ingressHttpPrivate.path }}
            pathType: Prefix
            backend:
              service:
                name: "service-http-private"
                port:
                  number: 80
```

### Pattern Penting Ingress:
- `ingressClassName: nginx`
- TLS enabled dengan `<tls-secret-name>`
- Rewrite target annotation
- Backend ke `service-http-private` port `80`

## 4. HPA (`hpa-http-private.yaml`)

```yaml
{{- if .Values.autoscalingHttpPrivate.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: "hpa-http-private"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
  labels:
    app: "hpa-http-private"
    environment: {{ .Values.environment }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: "deployment-http-private"
  minReplicas: {{ .Values.autoscalingHttpPrivate.minReplicas }}
  maxReplicas: {{ .Values.autoscalingHttpPrivate.maxReplicas }}
  metrics:
    {{- if .Values.autoscalingHttpPrivate.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscalingHttpPrivate.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if .Values.autoscalingHttpPrivate.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscalingHttpPrivate.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
```

### Pattern Penting HPA:
- Seluruh file di-wrap dalam `{{- if .Values.autoscalingHttpPrivate.enabled }}`
- Target ke `deployment-http-private`
- Metrics: CPU dan Memory utilization (conditional)
- Default disabled, enable via `values.<env>.yaml`

## 5. Secret (`secret.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: "env-secret"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
  labels:
    app: "env-secret"
    environment: {{ .Values.environment }}
type: Opaque
stringData:
  {{- toYaml .Values.env | nindent 2 }}
```

### Pattern Penting Secret:
- Name selalu `env-secret` (di-reference oleh deployment via `secretRef`)
- `.Values.env` berasal dari SOPS-decrypted `secrets.<env>.yaml`
- `stringData` (bukan `data`) karena values sudah plaintext dari SOPS

## 6. ECR CronJob (`ecr-cron.yaml`)

```yaml
{{- if .Values.registryECR.enabled }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: "update-ecr-secret"
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
spec:
  schedule: "0 */12 * * *"
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 2
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: ecr-secret-updater
              image: agungsdas/aws-cli-kubectl:latest
              env:
                - name: AWS_ACCESS_KEY_ID
                  value: "{{ .Values.env.ECR_ACCESS_KEY_ID }}"
                - name: AWS_SECRET_ACCESS_KEY
                  value: "{{ .Values.env.ECR_SECRET_ACCESS_KEY }}"
              command:
                - /bin/sh
                - -c
                - |
                  export AWS_DEFAULT_REGION={{ .Values.registryECR.region }}
                  docker_password=$(aws ecr get-login-password --region {{ .Values.registryECR.region }})
                  kubectl create secret docker-registry {{ .Values.registryECR.secretName }} \
                    --docker-server={{ .Values.registryECR.accountId }}.dkr.ecr.{{ .Values.registryECR.region }}.amazonaws.com \
                    --docker-username=AWS \
                    --docker-password=$docker_password \
                    --docker-email=[email] \
                    --namespace={{ .Chart.Name }}-{{ .Values.environment }} --dry-run=client -o yaml | kubectl apply -f -
          restartPolicy: OnFailure
          serviceAccountName: ecr-updater-sa
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-updater-sa
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ecr-secret-updater-role
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ecr-secret-updater-rb
  namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ecr-secret-updater-role
subjects:
  - kind: ServiceAccount
    name: ecr-updater-sa
    namespace: "{{ .Chart.Name }}-{{ .Values.environment }}"
{{- end }}
```

### Pattern Penting ECR CronJob:
- Conditional: hanya dibuat jika `registryECR.enabled: true`
- Schedule: setiap 12 jam (`0 */12 * * *`)
- Image: `agungsdas/aws-cli-kubectl:latest` (custom image dengan aws-cli + kubectl)
- AWS credentials dari `.Values.env` (ECR_ACCESS_KEY_ID, ECR_SECRET_ACCESS_KEY)
- Buat/update docker-registry secret via `kubectl create --dry-run=client -o yaml | kubectl apply`
- Includes: ServiceAccount, Role, RoleBinding (RBAC lengkap)
