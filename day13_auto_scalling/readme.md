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