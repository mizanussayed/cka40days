# Dotnet API – Helm + Argo CD

This task file focuses on deploying the Helm chart with Argo CD.
---

## Prerequisites

Install the following tools:

```bash
kubectl version --client
helm version
argocd version
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
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

# step 5 login to Argo CD CLI
argocd login localhost:8080

# step 6 register prod cluster in Argo CD
argocd cluster add kind-prod

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
argocd app create dotnet-api-helm-dev \
  --repo https://github.com/mizanussyed/dotnet-api-gitops.git \
  --path api-gitops/helm \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated
```

Create an Argo CD app for prod:

```bash
argocd app create dotnet-api-helm-prod \
  --repo https://github.com/mizanussyed/dotnet-api-gitops.git \
  --path api-gitops/helm \
  --dest-server https://kind-prod \
  --dest-namespace prod \
  --sync-policy automated
```

---

## Verify

```bash
argocd app list
argocd app get dotnet-api-helm-dev
argocd app get dotnet-api-helm-prod
```
