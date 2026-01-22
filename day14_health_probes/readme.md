## Health Probes in Kubernetes
Health probes are essential for maintaining the health and availability of applications running in Kubernetes. They help Kubernetes determine whether a container is running correctly and can serve traffic. There are two main types of health probes: Liveness Probes and Readiness Probes.
### Types of Health Probes
1. **Liveness Probes**: These probes check if a container is still running. If a liveness probe fails, Kubernetes will restart the container.
2. **Readiness Probes**: These probes check if a container is ready to serve traffic. If a readiness probe fails, Kubernetes will stop sending traffic to the container until it passes the readiness check again.
3. **Startup Probes**: These probes are used to check if a container has started successfully. They are useful for applications that take a long time to start up.

### Example Health Probe Configuration / http
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app-container
    image: my-app-image
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
        initialDelaySeconds: 10
        periodSeconds: 15
```

### Configuring Health Probes
- **httpGet**: This method sends an HTTP GET request to the specified path and port.
- **initialDelaySeconds**: The number of seconds to wait before performing the first probe.
- **periodSeconds**: How often to perform the probe.

## by tcpSocket
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app-container
    image: my-app-image
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10 
```
## by exec
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat 
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```