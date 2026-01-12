What is a daemonset?
A daemon set is another type of Kubernetes object that controls pods. Unlike deployment, the DS automatically deploys 1 pod to each available node. You don't need to update the replica based on demand; the DS takes care of it by spinning X number of pods for X number of nodes.
If you create a ds in a cluster of 5 nodes, then 5 pods will be created.
If you add another node to the cluster, a new pod will be automatically created on the new node.

When to use a daemonset?
Daemon sets are useful for running background tasks on all nodes, such as log collection, monitoring, or networking services. They ensure that each node has a copy of the pod running, which is essential for tasks that need to be executed on every node in the cluster.
Common use cases for daemon sets include:
- Log collection agents (e.g., Fluentd, Logstash)
- Monitoring agents (e.g., Prometheus Node Exporter)
- Network plugins (e.g., Calico, Weave)
- Storage daemons (e.g., GlusterFS, Ceph)   

How to create a daemonset?
You can create a daemon set using a YAML configuration file or the kubectl command-line tool. Here is an example of a simple daemon set YAML file:```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: my-daemonset
spec:
  selector:
    matchLabels:
      name: my-daemonset
  template:
    metadata:
      labels:
        name: my-daemonset
    spec:
      containers:
      - name: my-container
        image: my-image:latest
```
To create the daemon set, save the above YAML to a file named `daemonset.yaml` and run the following command:
```bashkubectl apply -f daemonset.yaml
```     
by Kubectl command:
```bash
kubectl create daemonset my-daemonset --image=my-image:latest
```
What is a CronJob?
A CronJob in Kubernetes is a resource that allows you to run jobs on a scheduled basis, similar to the cron utility in Unix/Linux systems. It creates Jobs that run periodically at specified times or intervals.

Example yaml for CronJob:
```yamlapiVersion: batch/v1
kind: CronJob
metadata:
  name: my-cronjob
spec:
  schedule: "*/5 * * * *" # This schedule runs the job every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: my-container
            image: my-image:latest
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes CronJob!
          restartPolicy: OnFailure
```

