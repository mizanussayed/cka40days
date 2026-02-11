## Ingress in Kubernetes | Managing External Access to Services
Ingress in Kubernetes is a powerful API object that manages external access to services within a Kubernetes cluster, typically HTTP and HTTPS traffic. It provides a way to define rules for routing external requests to the appropriate services based on the request's host and path.

### Key Concepts of Ingress in Kubernetes:
1. **Ingress Resource**: An Ingress resource is a set of rules that define how external traffic should be routed to services within the cluster. It specifies the hostnames, paths, and the corresponding services to which the traffic should be directed.
2. **Ingress Controller**: An Ingress Controller is a specialized load balancer that implements the Ingress resource rules. It monitors the Kubernetes API for changes to Ingress resources and updates its configuration accordingly. Popular Ingress controllers include NGINX, Traefik, and HAProxy.
3. **Routing Rules**: Ingress allows for complex routing rules based on hostnames and URL paths. For example, traffic to `localhost/api` can be routed to one service, while traffic to `localhost/web` can be routed to another.
4. **TLS/SSL Termination**: Ingress supports TLS/SSL termination, allowing secure HTTPS connections to be established. Certificates can be managed using Kubernetes Secrets.
5. **Load Balancing**: Ingress controllers often provide load balancing capabilities, distributing incoming traffic across multiple instances of a service to ensure high availability and reliability.

## install nginx ingress controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

## Example of Ingress Resource Configuration
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # Optional for NGINX Ingress controller
spec:
  rules:
  - host: localhost
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```
## Port Forwarding to Access Ingress Locally
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8000:80 &
```

## Access Flow Diagram

### Step-by-Step Access Flow:

1. **Deploy the Ingress Resources**
   - Apply the ingress controller: `kubectl apply -f deploy.yaml`
   - Verify controller is running: `kubectl get pods -n ingress-nginx`

2. **Deploy Your Services & Deployments**
   - Create services (api-service, web-service): `kubectl apply -f task.yaml`
   - Create corresponding deployments with pods
   - Verify they are running: `kubectl get pods,svc`

3. **Create Ingress Rules**
   - Define ingress resource with routing rules for `/api` and `/web` paths
   - Ingress controller watches for ingress resources and configures NGINX accordingly

4. **Set Up Port Forwarding (Local Development)**
   - For local Kubernetes (kind/minikube), forward port to ingress controller:
   ```bash
   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8000:80 &
   ```

5. **Access Your Services via Browser or CLI**
   
   **Option A: Browser Access**
   - Web Service: `http://localhost:8000/web`
   - API Service: `http://localhost:8000/api`
   
   **Option B: CLI Access**
   ```bash
   # With Host header
   curl -H "Host: localhost" http://localhost:8000/web
   curl -H "Host: localhost" http://localhost:8000/api
   ```

### Request Flow Through Ingress:
```
Browser Request (localhost:8000/web)
    ↓
Port-Forward (8000 → 80)
    ↓
Ingress Controller (NGINX) on localhost
    ↓
Routes based on path (/web → web-service, /api → api-service)
    ↓
ClusterIP Service (port 80)
    ↓
Backend Pods (listening on port 80)
    ↓
Response sent back to browser
```

### Troubleshooting Common Issues:

| Issue | Solution |
|-------|----------|
| **502 Bad Gateway** | Service port mismatch - ensure `targetPort` matches pod listening port (usually 80 for nginx) |
| **Connection refused on port 8000** | Port-forward not running - restart with `kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8000:80 &` |
| **Ingress controller not processing routes** | Check `ingressClassName: nginx` is set in ingress spec |
| **Port 80 already in use** | Use different local port: `kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8001:80 &` |

### Verification Commands:
```bash
# Check ingress status
kubectl get ingress -A

# Check ingress controller
kubectl get pods -n ingress-nginx

# View ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test endpoint
curl -I -H "Host: localhost" http://localhost:8000/web
```