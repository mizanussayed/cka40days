# Dotnet API – Helm + Argo CD

This task file focuses on deploying the Helm chart with Argo CD.
---
## Prerequisites

```bash
kubectl version --client
helm version
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
fi
# step 4 expose Argo CD server
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

# step 5 login to Argo CD CLI
curl localhost:8080

# step 7 create namespaces in both clusters
kubectl create namespace dev
kubectl create namespace prod
```
---

## Helm values (local-only secrets)
Use the example file to override the database password locally (do not commit it):

```bash
cp api-gitops/helm/secrets.yaml.example api-gitops/helm/secrets.yaml
```
---

## Create Argo CD Applications (Helm)
Create an Argo CD app for dev (Helm chart from repo path):
```bash 
kubectl apply -f api-gitops/argocd/dev-app.yaml 
kubectl apply -f api-gitops/argocd/prod-app.yaml
```