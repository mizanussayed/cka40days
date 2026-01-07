## Install Kubectl for ubuntu #
```sudo apt update```

```sudo apt install kubectl -y```

## creates a single-node Kubernetes cluster.

`kind create cluster --name cka-cluster `

What “single node” means in kind
That one node acts as:

 * Control plane

 * Worker node

 ## use below command for get cluster nodes

  ```kubectl get nodes```

## for multiple node need to use a config file

``` 
cat <<EOF > kind-multinode.yaml 
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```
## use below command to create cluster with multiple nodes

```kind create cluster --name cka-cluster --config kind-multinode.yaml```




