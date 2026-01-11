## Multi-Container Pod (Init & Sidecar)
A multi-container Pod runs multiple containers that share the same network and storage. It is commonly used with init containers for setup and sidecar containers for support tasks like logging or monitoring.

### Key Concepts

* Init Container: Runs first and completes setup before app containers start
* Main Container: Runs the primary application
* Sidecar Container: Runs alongside the app to extend functionality
* Shared Volume: Enables data sharing between containers

Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logging-sidecar-pod
spec:
  volumes:
  - name: log-volume
    emptyDir: {}

  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'while true; do echo "app log" >> /var/log/app.log; sleep 5; done']
    volumeMounts:
    - name: log-volume
      mountPath: /var/log

  - name: log-sidecar
    image: busybox
    command: ['sh', '-c', 'tail -f /var/log/app.log']
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
```

### Init pod yaml for checking service is ready or not
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-init-pod
spec:
  containers:
  - name: main-app
    image: busybox
    command: ['sh', '-c', 'echo Main application is running; sleep 3600']
  initContainers:
  - name: init-check
    image: busybox
    command: ['sh', '-c', 'until nc -zv google.com 80; do echo waiting for network; sleep 5; done; echo Network is ready']
```

get pods logging-sidecar-pod
```bash
kubectl logs logging-sidecar-pod -c log-sidecar\
```