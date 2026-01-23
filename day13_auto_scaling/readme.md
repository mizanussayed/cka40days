# kubernetes auto scaling
Auto-scaling in Kubernetes allows your applications to automatically adjust their resource allocation based on demand, ensuring optimal performance and cost-efficiency.

## Horizontal Pod Autoscaler (HPA)
The Horizontal Pod Autoscaler automatically scales the number of pods in a deployment, replica set, or stateful set based on observed CPU utilization or other select metrics.

### Example HPA Configuration
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

## Vertical Pod Autoscaler (VPA)
The Vertical Pod Autoscaler automatically adjusts the CPU and memory requests and limits for your pods based on their actual usage.
### Example VPA Configuration
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       my-app
  updatePolicy:
    updateMode: "Auto"
```
## Event-driven Autoscaling (KEDA)
KEDA (Kubernetes Event-driven Autoscaling) allows you to scale your applications based on external events, such as messages in a queue or HTTP requests.
### Example KEDA Configuration
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-app-scaledobject
spec:
  scaleTargetRef:
    name: my-app
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
  - type: cpu
    metadata:
      type: Utilization
      value: "50"
```

## By using commands
You can create autoscalers using kubectl commands as well. For example:
```bash
# for HPA
kubectl autoscale deployment my-app --min=2 --max=10 --cpu-percent=50
# for VPA & KEDA by command line is not directly supported, you need to apply the yaml file
kubectl apply -f vpa-keda.yaml
``` 
