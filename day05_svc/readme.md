
# k8s Service
As pode ip is not stable and can change when pods are recreated, Kubernetes Services provide a stable IP address and DNS name to access a set of pods.

## Service Types
1. ClusterIP (default)
2. NodePort
3. LoadBalancer
4. ExternalName

## Setting up kind cluster with port mapping
By default, kind cluster nodes run as Docker containers and their ports are not exposed to the host machine. To access services running inside the kind cluster from your host machine, you need to expose the desired ports.
```bash
kind create cluster --name cka-cluster --config kind-config.yaml
```
Create a configuration file named `kind-config.yaml` with the following content:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraoyppings:
     - containerPort: 30031
       hostPort: 30031
  - role: worker
  - role: worker
```

### Imparative Commands to create svc:
```bash
# first create a deployment
kubectl create deploy nginx-depl --image=nginx --replicas=2 --labels=app=nginx

# ClusterIP / NodePort / LoadBalancer
kubectl expose deploy nginx-depl --type=NodePort --name=svc-np --port=80 --target-port=80

# ExternalName
kubectl create service externalname svc-externalname --external-name=example.com --port=80
```
## NodePort by yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-np
  labels:
    app: nginx
spec:
  type: NodePort  # LoadBalancer / ClusterIP 
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30031
```
## ExternalName by yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-externalname
spec:
  type: ExternalName
  externalName: example.com
  ports:
    - port: 80
```

## Accessing Services
- ClusterIP: Accessible only within the cluster.
- NodePort: Accessible via <NodeIP>:<NodePort> (e.g., localhost:30000).
- LoadBalancer: Accessible via the external IP assigned by the cloud provider (in kind, it maps to the NodePort).
- ExternalName: Resolved to the specified external DNS name.

## Tips and Tricks
- exec into a pod to test service connectivity:
```bash
kubectl exec -it <pod-name> -- curl <service-name>:<port>
```






