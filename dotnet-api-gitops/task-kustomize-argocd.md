# Dotnet API – Kustomize + Argo CD

This task file focuses on using Kustomize overlays with Argo CD.

---

## Prerequisites

Install the following tools:

```bash
kubectl version --client
kind version
helm version
kubeseal --version
```
---
## Steps

```bash
# step 1 create kind clusters
kind create cluster --name dev
kind create cluster --name prod

# step 2 verify clusters
kind get clusters

# step 3 install Argo CD in dev cluster
kubectl config use-context kind-dev
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# or by using helm
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd

# step 4 expose Argo CD server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

# step 5 login to Argo CD CLI
curl localhost:8080

# step 6 install Sealed Secrets controller in prod cluster
kubectl config use-context kind-prod
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml

# step 7 create namespaces in both clusters
kubectl create namespace dev
kubectl create namespace prod

# dev secret is plain text (do not commit)
kubectl config use-context kind-dev
kubectl apply -f api-gitops/kustomize/overlays/dev/secret.yaml

# prod secret is sealed using kubeseal
kubectl config use-context kind-prod

# create plain secret first (not pushed to git)
cat <<EOF > prod-postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: prod
type: Opaque
stringData:
  CONNECTION_STRING: Host=postgres;Port=5432;Database=appdb;Username=appuser;Password=STRONGPASSWORD
  POSTGRES_PASSWORD: STRONGPASSWORD
EOF

# create sealed secret
kubectl config use-context kind-prod

kubeseal \
  --namespace prod \
  --format yaml \
  < prod-postgres-secret.yaml > api-gitops/kustomize/overlays/prod/sealedsecret.yaml

# deploy Argo CD Applications (Kustomize)
kubectl apply -f api-gitops/argocd/dev-app.yaml
kubectl apply -f api-gitops/argocd/prod-app.yaml
```
