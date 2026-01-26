#### What is a service account in Kubernetes

There are multiple types of accounts in Kubernetes that interact with the cluster. These could be user accounts used by Kubernetes Admins, developers, operators, etc., and service accounts primarily used by other applications/bots or Kubernetes components to interact with other services.

### Create a service account
```bash
kubectl create sa <name>
kubectl get sa
```
### Declarative way
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
    name: sa-demo
    namespace: default
```
### Usage of service account in a pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
spec:
  serviceAccountName: sa-demo
  containers:
  - name: sa-container
    image: nginx
```
## Disable default service account in a pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: sa-container
    image: nginx
```
### Important points
- Each service account gets a token which is mounted inside the pod at /var/run/secrets/kubernetes.io/serviceaccount
- By default, if we don't specify any service account in the pod spec, it will use the default service account of that namespace
- We can add role and role binding to grant access to the service account
- Note: Kubernetes also create 1 default service account in each of the default namespace such as kube-sytem, kube-node-lease and so on
