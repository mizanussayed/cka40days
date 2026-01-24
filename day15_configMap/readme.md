## ConfigMap in Kubernetes
A ConfigMap is a Kubernetes object used to store non-confidential configuration data in key-value pairs. It allows you to decouple configuration artifacts from image content to keep containerized applications portable.

## Scope of ConfigMap
ConfigMaps are namespace-scoped resources.

### Creating a ConfigMap
You can create a ConfigMap using a YAML file or directly from the command line.

### by command line
```bash
kubectl create configmap cm1 --from-literal=name="mizanussayed"
kubectl create configmap cm2 --from-literal=linkedin="/in/mizanussayed" --from-literal=github="/mizanussayed"
kubectl create configmap cm3 --from-file=data-file
```
### inside data-file
```bash
app_name="myapp"
app_env="production"
```
#### By YAML file (configmap.yaml)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
  namespace: my-namespace
data:
   name: "mizanussayed"
   linkedin: "/in/mizanussayed"
   github: "/mizanussayed"
   app_name: "myapp"
   app_env: "production"
```

### Using ConfigMap in Pods
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm1-cm2-pod
spec:
  containers:
  - name: my-container
    image: my-image
    envFrom:
    - configMapRef:
        name: cm1
    env: GITHUB_PROFILE
      valueFrom:
        configMapKeyRef:
          name: cm2
          key: github
```

## Mounting ConfigMap as Volume
We can also mount a ConfigMap as a volume inside a Pod.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cm3-pod
spec:
  containers:
  - name: my-container
    image: my-image
    volumes:
    - name: config-volume
      configMap:
        name: cm3
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
```

## Checking ConfigMap
To check the details of a ConfigMap, you can use the following command:
```bash
kubectl exec -it <pod-name> -- printenv
## To filter for a specific key
kubectl exec -it <pod-name> -- printenv | grep <KEY_NAME>
```