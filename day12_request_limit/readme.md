# Kubernetes Requests & Limits 🚀🔧
Pod requires specific resources like CPU and memory to function:

- **Requests**: This is the minimum amount of resources a pod needs to operate smoothly. Think of it as a guaranteed reservation for the pod.
- **Limits**: This is the maximum amount of resources a pod can use. It acts as a safety cap to prevent any pod from consuming more than its fair share and disrupting others.

---

## 🧐 Why are Requests & Limits Important?

- **Resource Control**: By setting limits, you prevent a single pod from monopolizing resources, which can lead to issues like out-of-memory (OOM) kills or CPU starvation. ☠️ Why OOM can be a good thing? Because it kills the pod; otherwise, the container would have consumed all the memory and could kill the node. Killing the pod is a better option than killing a node itself.
- **Predictability**: Requests help the scheduler allocate resources efficiently and ensure pods have the necessary resources to run effectively.

---
## 🔍 Exploring Resource Management in Action
1. **Exceeding Available Memory**:
   - A pod requesting more memory than is available will be killed due to an OOM (Out of Memory) error.
     
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-2
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```

2. The Below pod will be scheduled

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "200Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```