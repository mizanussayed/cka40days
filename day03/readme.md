## Run pod with imperative way (name here is nginx-pod)

```bash
kubectl run nginx-pod --image=nginx
```
* Get created pod config to a yaml file

```bash
kubectl get pod nginx-pod -o yaml > nginx-pod.yaml
```

* delete the pod

```bash
kubectl delete pod nginx-pod
```

## Create pod from yaml file

```yaml
# nginx-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    env: demo
    type: frontend
spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort:80
```
*Apply the yaml file to create the pod*

```bash
kubectl apply -f nginx-pod.yaml
```