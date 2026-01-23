## ConfigMap in Kubernetes
A ConfigMap is a Kubernetes object used to store non-confidential configuration data in key-value pairs. It allows you to decouple configuration artifacts from image content to keep containerized applications portable.

### Creating a ConfigMap
You can create a ConfigMap using a YAML file or directly from the command line.
#### Example YAML file (configmap.yaml)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  database_url: "mongodb://localhost:27017"
  feature_flag: "true"
```
#### Create ConfigMap from YAML
```bashkubectl apply -f configmap.yaml
```
#### Create ConfigMap from command line
```bash
kubectl create configmap my-config --from-literal=database_url="mongodb://localhost:27017" --from-literal=feature_flag="true"
```

### Using ConfigMap in Pods
You can use ConfigMaps in your Pods by mounting them as files or by using them as environment variables.
#### Example Pod using ConfigMap as environment variables (pod.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: my-image
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: database_url
    - name: FEATURE_FLAG
      valueFrom:
        configMapKeyRef:
          name: my-config
          key: feature_flag
```