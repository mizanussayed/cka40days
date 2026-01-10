# Replicaset & Deployments in Kubernetes

A ReplicaSet to ensure that a specified number of pod replicas are running at any given time. ReplicaSets are typically not created directly; instead, they are managed by Deployments, which provide declarative updates for Pods and ReplicaSets.

A Deployment provides declarative updates for Pods and ReplicaSets. You describe a desired state in a Deployment object, and the Deployment controller changes the actual state to the desired state at a controlled rate. You can define Deployments to create new ReplicaSets, or to remove existing Deployments and adopt all their resources with new Deployments.

| ReplicaSet           | Deployment                 |
| -------------------- | -------------------------- |
| Keeps pods running   | Manages ReplicaSets        |
| No updates           | Rolling updates & rollback |
| Rarely used directly | Best practice              |

## The hierarchy is as follows:
Deployment → ReplicaSet → Pods

## Some useful commands for managing ReplicaSets and Deployments:
```bash 
kubectl create deployment nginx-deployment --image=nginx --replicas=3

# to view the created ReplicaSet
kubectl get rs

# to view the created Deployment
kubectl get deployments

# scale the ReplicaSet to 5 replicas
kubectl scale rs nginx-replicaset --replicas=5

# scale the Deployment to 5 replicas
kubectl scale deploy nginx-deployment --replicas=5

# update the deployment to use a different image
kubectl set image deploy nginx-deployment nginx=nginx:1.16.1
```

## Create a ReplicaSet by YAML file
below is an example of a ReplicaSet configuration file:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```
## Create deployment by YAML file
below is an example of a Deployment configuration file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```