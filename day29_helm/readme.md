### Helm Tutorial
-Package manager for Kubernetes like we have apt for ubuntu, yum for redhat, the same way we have package manager for Kubernetes which is called.

- Create, find, share and use software packages on kubernetes

- Package in helm is called a Chart or a helm chart like yum rpm file, apt dpkg file, its a bundle of tools, binaries and dependencies
- Reporistory: central storage for chart management like Github or Dockerhub
- Release: Instace of a running chart , containers in dockers

- charts are reusable, you can install a single chart multiple times, every time it will create a new release
- you can also search helm charts in the kubernetes repository

- Helm install resources in following order: Namespace, netpol, quota, limitrange and so on.

## Helm commands
https://helm.sh/docs/

- `helm create NAME` will create the following structure
- .helmignore
- chart.yaml ( metadata about the chart)
- values.yaml ( override the values in the file)
- charts/ (chart dependency)
- template/ 
    /tests/

- helm lint to check for syntactical error



  
