## Node Affinity
Node Selectors are great for basic pod placement based on node labels. But what if you need more control over where your pods land? Enter Node Affinity! This feature offers advanced capabilities to fine-tune pod scheduling in your Kubernetes cluster.
### Key Features of Node Affinity:
- **Required During Scheduling**: Similar to Node Selectors, you can specify hard requirements that must be met for a pod to be scheduled on a node.
- **Preferred During Scheduling**: You can also define soft preferences, allowing the scheduler to prioritize certain nodes without making it a strict requirement.
- **Logical Operators**: Node Affinity supports a variety of operators (In, NotIn, Exists, DoesNotExist, Gt, Lt) to create complex scheduling rules.
### Example
Here's a sample pod specification using Node Affinity:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-example
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: region
            operator: In
            values:
            - us-west
            - us-east
  containers:
  - name: nginx
    image: nginx
``` 

In this example, the pod will only be scheduled on nodes with the label `disktype=ssd`. Additionally, it prefers nodes in the `us-west` or `us-east` regions, but this is not a strict requirement.

### Add labels to nodes
To use Node Affinity effectively, you need to label your nodes accordingly. Here’s how you can add labels to your nodes:
```bash
kubectl label nodes <node-name> disktype=ssd
kubectl label nodes <node-name> region=us-west

# remove labels
kubectl label nodes <node-name> disktype-
```
