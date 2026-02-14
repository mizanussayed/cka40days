#!/bin/bash
set -e

ROOT=api-gitops

mkdir -p \
$ROOT/helm/templates \
$ROOT/kustomize/{base,overlays,overlays/dev,overlays/prod} \
$ROOT/argocd \
$ROOT/.github/workflows

##################################
# HELM CHART
##################################

cat <<EOF > $ROOT/helm/Chart.yaml
apiVersion: v2
name: dotnet-api
version: 0.1.0
appVersion: "1.0"
EOF

cat <<EOF > $ROOT/helm/values.yaml
deployment:
  replicaCount: 2
  name: dotnet-api
  image:
    repository: mizanussyed/dotnet-api
    tag: latest

database:
  name: postgres
  secretName: postgres-secret
EOF

cat <<EOF > $ROOT/helm/templates/api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.deployment.name }}-deployment
spec:
  replicas: {{ .Values.deployment.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.deployment.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.deployment.name }}
    spec:
      containers:
        - name: api
          image: "{{ .Values.deployment.image.repository }}:{{ .Values.deployment.image.tag }}"
          ports:
            - containerPort: 8080
          env:
            - name: ConnectionStrings__Default
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.database.secretName }}
                  key: CONNECTION_STRING
EOF

cat <<EOF > $ROOT/helm/templates/api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.deployment.name }}-service
spec:
  type: ClusterIP
  selector:
    app: {{ .Values.deployment.name }}
  ports:
    - port: 80
      targetPort: 8080
EOF

cat <<EOF > $ROOT/helm/templates/postgres-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.database.name }}-service
spec:
  clusterIP: None
  selector:
    app: {{ .Values.database.name }}
  ports:
    - port: 5432
EOF

cat <<EOF > $ROOT/helm/templates/postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Values.database.name }}-statefulset
spec:
  serviceName: {{ .Values.database.name }}-service
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Values.database.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.database.name }}
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.database.secretName }}
                  key: POSTGRES_PASSWORD
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 5Gi
EOF

##################################
# KUSTOMIZE BASE
##################################

cat <<EOF > $ROOT/kustomize/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: dotnet-api
    releaseName: dotnet-api
    repo: file://../../helm
    version: 0.1.0
    valuesFile: values.yaml
EOF

##################################
# KUSTOMIZE DEV
##################################

cat <<EOF > $ROOT/kustomize/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev

resources:
  - ../base
  - secret.yaml

patches:
  - target:
      kind: Deployment
      name: dotnet-api
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
EOF

cat <<EOF > $ROOT/kustomize/overlays/dev/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  CONNECTION_STRING: Host=postgres;Port=5432;Database=appdb;Username=appuser;Password=devpassword
  POSTGRES_PASSWORD: devpassword
EOF

##################################
# KUSTOMIZE PROD
##################################

cat <<EOF > $ROOT/kustomize/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: prod

resources:
  - ../base
  - sealedsecret.yaml

patches:
  - target:
      kind: Deployment
      name: dotnet-api
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 3
EOF

cat <<EOF > $ROOT/kustomize/overlays/prod/sealedsecret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: postgres-secret
spec:
  encryptedData:
    CONNECTION_STRING: AgBzREPLACE_ME==
    POSTGRES_PASSWORD: AgBzREPLACE_ME==
EOF

##################################
# ARGO CD APPS
##################################

cat <<EOF > $ROOT/argocd/dev-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dotnet-api-dev
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/mizanussyed/dotnet-api-gitops.git
    targetRevision: main
    path: kustomize/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

cat <<EOF > $ROOT/argocd/prod-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dotnet-api-prod
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/mizanussyed/dotnet-api-gitops.git
    targetRevision: main
    path: kustomize/prod
  destination:
    server: https://kind-prod
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
