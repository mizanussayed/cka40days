```bash
#!/bin/bash
set -e

ROOT=dotnet-api-gitops
rm -rf $ROOT dotnet-api-gitops.zip

mkdir -p \
$ROOT/helm/dotnet-api/templates \
$ROOT/kustomize/{base,dev,prod} \
$ROOT/argocd \
$ROOT/.github/workflows

##################################
# HELM CHART
##################################

cat <<EOF > $ROOT/helm/dotnet-api/Chart.yaml
apiVersion: v2
name: dotnet-api
version: 0.1.0
appVersion: "1.0"
EOF

cat <<EOF > $ROOT/helm/dotnet-api/values.yaml
replicaCount: 2

image:
  repository: mizanussyed/dotnet-api
  tag: latest

database:
  secretName: postgres-secret
EOF

cat <<EOF > $ROOT/helm/dotnet-api/templates/api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dotnet-api
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: dotnet-api
  template:
    metadata:
      labels:
        app: dotnet-api
    spec:
      containers:
        - name: api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 8080
          env:
            - name: ConnectionStrings__Default
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.database.secretName }}
                  key: CONNECTION_STRING
EOF

cat <<EOF > $ROOT/helm/dotnet-api/templates/api-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: dotnet-api
spec:
  type: ClusterIP
  selector:
    app: dotnet-api
  ports:
    - port: 80
      targetPort: 8080
EOF

cat <<EOF > $ROOT/helm/dotnet-api/templates/postgres-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - port: 5432
EOF

cat <<EOF > $ROOT/helm/dotnet-api/templates/postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
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
                  name: postgres-secret
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
    repo: file://../../helm/dotnet-api
    version: 0.1.0
    valuesFile: values.yaml
EOF

##################################
# KUSTOMIZE DEV
##################################

cat <<EOF > $ROOT/kustomize/dev/kustomization.yaml
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

cat <<EOF > $ROOT/kustomize/dev/secret.yaml
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

cat <<EOF > $ROOT/kustomize/prod/kustomization.yaml
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

cat <<EOF > $ROOT/kustomize/prod/sealedsecret.yaml
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
