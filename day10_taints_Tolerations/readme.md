## Taints and Tolerations in Kubernetes
Taints and tolerations work together to control which pods can be scheduled on which nodes.

***-- Taints are applied to nodes and restrict pods.***

***-- Tolerations are applied to pods and allow them to tolerate (ignore) certain taints.***

By default, a pod cannot be scheduled onto a node with a taint unless the pod has a matching toleration.

### Why They Are Used

* Taints and tolerations are commonly used to:

* Reserve nodes for specific workloads (e.g., system, GPU, or high-memory workloads)

* Isolate workloads (e.g., production vs. development)

* Prevent certain pods from running on special-purpose nodes

* Handle node conditions (e.g., memory pressure, disk pressure)

### Taint Structure
A taint has three parts:

## `key=value:effect`


### Effects`
* `NoSchedule` - Pods without a matching toleration will not be scheduled on the node.

* `PreferNoSchedule` - Kubernetes will try to avoid scheduling pods on the node, but it’s not guaranteed.

* `NoExecute` - Pods without a matching toleration are evicted from the node (and new ones won’t be scheduled).

### Adding a Taint to a Node
example command to taint a node:
```bash
kubectl taint nodes node-name key=value:effect
```
For example:
```bash
kubectl taint nodes node1 dedicated=production:NoSchedule
```
This means: 
Only pods that tolerate `dedicated=production` can run on `node1`.

## Tolerations (Applied to Pods)

A toleration allows a pod to be scheduled onto a node with a matching taint.

Example Pod with a Toleration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "production"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
```
This pod can be scheduled on nodes tainted with `dedicated=production:NoSchedule`.

### Toleration Operators

`Equal` (default): key and value must match

`Exists`: only the key must exist (value is ignored)

Example:
```yaml
tolerations:
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"
```

### NoExecute Toleration with Time Limit

For `NoExecute` taints, you can control how long a pod stays on the node:

```yaml
tolerations:
- key: "node.kubernetes.io/not-ready"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300
  ```
This pod will be evicted (উচ্ছেদ)  after 5 minutes if the node becomes NotReady.
## reomve taint from node
```bash
kubectl taint nodes node-name key:effect-
```
### Labels vs Taints/Tolerations
Labels group nodes based on size, type,env, etc. Unlike taints, labels don't directly affect scheduling but are useful for organizing resources.

### Limitations to Remember 🚧
Taints and tolerations are powerful tools.But they cannot handle complex expressions like "AND" or "OR." So, what do we use in that case? We use a combination of Taints, tolerance, and Node affinity,