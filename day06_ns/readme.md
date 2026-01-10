tasK: 
1. Create two namespaces and name them ns1 and ns2
2. Create a deployment with a single replica in each of these namespaces with the image as nginx and name as deploy-ns1 and deploy-ns2, respectively
3. Get the IP address of each of the pods (Remember the kubectl command for that?)
4. Exec into the pod of deploy-ns1 and try to curl the IP address of the pod running on deploy-ns2
5. Your pod-to-pod connection should work, and you should be able to get a successful response back.
6. Now scale both of your deployments from 1 to 3 replicas.
7. Create two services to expose both of your deployments and name them svc-ns1 and svc-ns2
8. Exec into each pod and try to curl the IP address of the service running on the other namespace.
9. This curl should work.
10. Now try curling the service name instead of IP. You will notice that you are getting an error and cannot resolve the host.
11. Now use the FQDN of the service and try to curl again, this should work.
## Kubernetes Namespace and Pod Communication
```bash
# Step 1: Create namespaces
kubectl create namespace ns1
kubectl create namespace ns2
# Step 2: Create deployments
kubectl create deployment deploy-ns1 --image=nginx -n ns1
kubectl create deployment deploy-ns2 --image=nginx -n ns2
# Step 3: Get pod IPs
kubectl get pods -n ns1 -o wide
kubectl get pods -n ns2 -o wide
#
# Step 4: Exec into deploy-ns1 pod and curl deploy-ns2 pod IP
kubectl exec -n ns1 <deploy-ns1-pod-name> -- curl <deploy-ns2-pod-ip>
# Step 6: Scale deployments
kubectl scale deploy deploy-ns1 --replicas=3 -n ns1
kubectl scale deploy deploy-ns2 --replicas=3 -n ns2
# Step 7: Create services
kubectl expose deploy deploy-ns1 --name=svc-ns1 --type=NodePort --port=80 -n ns1
kubectl expose deploy deploy-ns2 --name=svc-ns2 --type=NodePort --port=80 -n ns2
# Step 8: Exec into each pod and curl the service IP of the other namespace
kubectl exec -n ns1 <deploy-ns1-pod-name> -- curl <svc-ns2-ip>
kubectl exec -n ns2 <deploy-ns2-pod-name> -- curl <svc-ns1-ip>
# Step 10: Curl using service name (this will fail)
kubectl exec -n ns1 <deploy-ns1-pod-name> -- curl svc-ns2
kubectl exec -n ns2 <deploy-ns2-pod-name> -- curl svc-ns1
# Step 11: Curl using FQDN (fully qualified domain name) (this should work)
# /etc/resolv.conf shows how DNS is configured
kubectl exec -n ns1 <deploy-ns1-pod-name> -- curl svc-ns2.ns2.svc.cluster.local
kubectl exec -n ns2 <deploy-ns2-pod-name> -- curl svc-ns1.ns1.svc.cluster.local
```