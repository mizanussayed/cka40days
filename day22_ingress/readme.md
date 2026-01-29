## Ingress in Kubernetes | Managing External Access to Services
Ingress in Kubernetes is a powerful API object that manages external access to services within a Kubernetes cluster, typically HTTP and HTTPS traffic. It provides a way to define rules for routing external requests to the appropriate services based on the request's host and path.


### Key Concepts of Ingress in Kubernetes:
1. **Ingress Resource**: An Ingress resource is a set of rules that define how external traffic should be routed to services within the cluster. It specifies the hostnames, paths, and the corresponding services to which the traffic should be directed.
2. **Ingress Controller**: An Ingress Controller is a specialized load balancer that implements the Ingress resource rules. It monitors the Kubernetes API for changes to Ingress resources and updates its configuration accordingly. Popular Ingress controllers include NGINX, Traefik, and HAProxy.
3. **Routing Rules**: Ingress allows for complex routing rules based on hostnames and URL paths. For example, traffic to `example.com/api` can be routed to one service, while traffic to `example.com/web` can be routed to another.
4. **TLS/SSL Termination**: Ingress supports TLS/SSL termination, allowing secure HTTPS connections to be established. Certificates can be managed using Kubernetes Secrets.
5. **Load Balancing**: Ingress controllers often provide load balancing capabilities, distributing incoming traffic across multiple instances of a service to ensure high availability and reliability.

### Why is Ingress Important in Kubernetes?
- **Centralized Access Management**: Ingress provides a centralized way to manage external access to multiple services, simplifying the configuration and maintenance of access rules.
- **Flexibility**: With Ingress, you can define complex routing rules and manage traffic based on various criteria.
- **Security**: Ingress supports TLS/SSL termination, enabling secure communication between clients and services.
- **Cost Efficiency**: By using a single Ingress controller to manage access to multiple services, you can reduce the need for multiple load balancers, lowering infrastructure costs.

### configure by yaml files
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: example.com
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
    tls:
    - hosts:
      - example.com
      secretName: example-tls
```