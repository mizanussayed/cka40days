# Gateway API with NGINX Gateway Fabric

## Prerequisites
- kubectl installed and configured
- Helm 3.x installed
- Kind (Kubernetes in Docker) installed
- Basic understanding of Kubernetes concepts such as pod, deployment, Ingress, services etc

## Step 1: Create Kind Cluster

First, let's create a Kind cluster with port mappings for the Gateway. Save the following to `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 80
    protocol: TCP
  - containerPort: 30443
    hostPort: 443
    protocol: TCP
```

Create the cluster:

```bash
# Create the Kind cluster
kind create cluster --config kind-config.yaml --name gateway-demo

# Verify the cluster
kubectl cluster-info
kubectl get nodes
```

## Step 2: Install Gateway API Resources

Install the latest Gateway API CRDs (v1.2.0):

```bash
# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# Verify installation
kubectl get crd | grep gateway
```

Expected output should include CRDs like:
- `gatewayclasses.gateway.networking.k8s.io`
- `gateways.gateway.networking.k8s.io`
- `httproutes.gateway.networking.k8s.io`
- `grpcroutes.gateway.networking.k8s.io`

## Step 3: Install NGINX Gateway Fabric Using Helm

Add the NGINX Helm repository and install the Gateway controller:

```bash
# Add NGINX Helm repository
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update

# Create namespace for NGINX Gateway Fabric
kubectl create namespace nginx-gateway

# Install NGINX Gateway Fabric using Helm with NodePort service
helm install nginx-gateway nginx-stable/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --set service.type=NodePort \
  --set service.ports[0].name=http \
  --set service.ports[0].port=80 \
  --set service.ports[0].targetPort=80 \
  --set service.ports[0].protocol=TCP \
  --set service.ports[0].nodePort=30080 \
  --set service.ports[1].name=https \
  --set service.ports[1].port=443 \
  --set service.ports[1].targetPort=443 \
  --set service.ports[1].protocol=TCP \
  --set service.ports[1].nodePort=30443

# Verify the deployment
kubectl get pods -n nginx-gateway
kubectl get svc -n nginx-gateway
```

You should see the NGINX Gateway Fabric pods running:

```
NAME                                      READY   STATUS    RESTARTS   AGE
nginx-gateway-nginx-gateway-fabric-xxx    2/2     Running   0          30s
```

And the service with NodePort configured:

```
NAME                                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway-nginx-gateway-fabric   NodePort   10.96.188.84    <none>        80:30080/TCP,443:30443/TCP   2m
```

## Step 4: Create GatewayClass and Gateway Resources

Create the GatewayClass and Gateway resources. Save the following YAML to `gateway-resources.yaml`:

```yaml
---
# GatewayClass defines the controller that implements the Gateway API
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
---
# Gateway resource defines the listener and ports
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    allowedRoutes:
      namespaces:
        from: All
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: gateway-tls
```

Apply the configuration:

```bash
kubectl apply -f gateway-resources.yaml

# Verify resources
kubectl get gatewayclass
kubectl get gateway -n nginx-gateway
```

You should see both resources created:

```
NAME    CONTROLLER                                  ACCEPTED   AGE
nginx   gateway.nginx.org/nginx-gateway-controller  True       15s

NAME            CLASS   ADDRESS         PROGRAMMED   AGE
nginx-gateway   nginx   10.96.188.84    True         15s
```

## Step 5: Deploy Sample Application

Create a deployment and service for the frontend application. Save to `frontend-app.yaml`:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-app
  namespace: default
  labels:
    app: frontend
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: default
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

Apply the configuration:

```bash
kubectl apply -f frontend-app.yaml

# Verify deployment
kubectl get pods
kubectl get svc frontend-svc
```

## Step 6: Create HTTPRoute to Expose the Service

Create an HTTPRoute to route traffic to the `frontend-svc` service. Save the following YAML to `frontend-route.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: default
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: frontend-svc
      port: 80
      weight: 1
```

Apply the configuration:

```bash
kubectl apply -f frontend-route.yaml

# Verify the HTTPRoute
kubectl get httproute frontend-route
kubectl describe httproute frontend-route
```

You should see the HTTPRoute created and showing as "Accepted":

```
NAME             HOSTNAMES   AGE
frontend-route   *           30s
```

The `describe` command should show that the HTTPRoute is accepted by the Gateway and the parent is correctly referenced.

## Step 7: Test the Configuration

Test the configuration using curl or a web browser:

```bash
# Test from localhost (Kind cluster port mapping)
curl http://localhost

# Or open in a browser
echo "You can access the application at: http://localhost"

# Check the HTTPRoute status
kubectl get httproute frontend-route -o yaml
```

You should see the response from the NGINX frontend application (the default NGINX welcome page).

## Troubleshooting

If you encounter issues:

1. **Check Gateway status**:
   ```bash
   kubectl describe gateway nginx-gateway -n nginx-gateway
   ```
   Look for any errors in the status section. The status should show `Programmed: True`.

2. **Check HTTPRoute status**:
   ```bash
   kubectl describe httproute frontend-route
   ```
   Check if the route is accepted by the gateway and verify the parent reference.

3. **Check NGINX Gateway Fabric logs**:
   ```bash
   # List pods in nginx-gateway namespace
   kubectl get pods -n nginx-gateway
   
   # Check logs (replace pod name with actual name)
   kubectl logs -n nginx-gateway -l app.kubernetes.io/name=nginx-gateway-fabric --all-containers=true
   ```
   Look for any errors or issues in the controller logs.

4. **Verify services exist and have endpoints**:
   ```bash
   kubectl get endpoints frontend-svc
   kubectl get svc frontend-svc
   ```
   Make sure your services have endpoints pointing to the pods.

5. **Check Helm release status**:
   ```bash
   helm list -n nginx-gateway
   helm status nginx-gateway -n nginx-gateway
   ```

6. **Verify Gateway API CRDs are installed**:
   ```bash
   kubectl get crd | grep gateway.networking.k8s.io
   ```

## Cleanup

To remove all resources:

```bash
# Delete HTTPRoute and application
kubectl delete -f frontend-route.yaml
kubectl delete -f frontend-app.yaml
kubectl delete -f gateway-resources.yaml

# Uninstall NGINX Gateway Fabric
helm uninstall nginx-gateway -n nginx-gateway

# Delete Gateway API CRDs
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# Delete Kind cluster
kind delete cluster --name gateway-demo
```

## Key Concepts

1. **GatewayClass**: Defines the implementation/controller that will handle the Gateway API (e.g., NGINX, Istio, Envoy)
2. **Gateway**: Defines the actual gateway deployment that processes traffic - specifies listeners, ports, and protocols
3. **HTTPRoute**: Defines how HTTP/HTTPS traffic is routed to backend services
4. **GRPCRoute**: Routes gRPC traffic (available in v1.2.0+)
5. **Routing Rules**: 
   - Path-based routing
   - Header-based routing 
   - Query parameter routing
   - Traffic splitting/weighting
   - Request/response header manipulation

## Advantages of Gateway API over Traditional Ingress

1. **More expressive routing** - Complex routing patterns are natively supported with match conditions and filters
2. **Separation of concerns** - Different teams can manage different resources (infrastructure vs. application teams)
3. **Standardization** - Consistent behavior across different implementations (NGINX, Istio, HAProxy, etc.)
4. **Extensibility** - Well-designed for custom resources and vendor-specific implementations
5. **Type safety** - Strongly typed API with clear validation and error reporting
6. **Advanced features** - Support for weighted traffic splitting, header modification, redirects, and more

## Advanced Examples

### Traffic Splitting (Canary Deployment)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - backendRefs:
    - name: frontend-v1
      port: 80
      weight: 90
    - name: frontend-v2
      port: 80
      weight: 10
```

### Header-Based Routing

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: header-route
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - headers:
      - name: x-version
        value: "v2"
    backendRefs:
    - name: frontend-v2
      port: 80
```

## Additional Resources

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [Gateway API v1.2.0 Release Notes](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.2.0)

