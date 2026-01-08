# run pod with imparative way (name here is nginx-pod)

```bash
kubectl run nginx-pod --image=nginx
```
* run created pod config to yaml file

```bash
kubectl get pod nginx-pod -o yaml > nginx-pod.yaml
```

* delete the pod

```bash
kubectl delete pod nginx-pod
```

# create pod from yaml file

```bash
kubectl apply -f nginx-pod.yaml
```