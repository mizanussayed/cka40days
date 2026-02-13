# Introduction to NGINX Gateway Fabric: Gateway API

[nginx-fabric](https://youtu.be/zbAb2e_Q_Y0)

## Prerequisites

To get started, you will need to follow the [Introduction to Gateway API](../README.md) first. You'll need an understanding of the Gateway API.

In the introduction guide, you will:

- Create a local Kubernetes cluster
- Install the Gateway API CRDs
- Deploy example apps to our cluster
- Have Domains for our traffic
- Have TLS certificates

This will allow us access to the Gateway API so we can go ahead and deploy a Gateway API controller to use.

## What is NGINX Gateway Fabric

NGINX Gateway Fabric is an [open-source project](https://github.com/nginx/nginx-gateway-fabric) that provides an implementation of the Gateway API using NGINX as the data plane.

Let's checkout the [Official Documentation](https://docs.nginx.com/nginx-gateway-fabric/overview/gateway-architecture/)

## Install a NGINX Gateway Class

In our other guides, we deployed and managed a Gateway Class outside of the controller installation. NGINX Fabric is a little different as their `GatewayClass` is managed by helm and there are extra configurations managed by the chart that gets injected into the `GatewayClass` under the `parametersRef` field.

If you've been following this series you will know the `parametersRef` field is used to extend the class. NGINX uses a custom CRD called `NginxProxy` to customize the class, but these settings come from their `helm` chart.

For example:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-gateway
  annotations:
    meta.helm.sh/release-name: ngf
    meta.helm.sh/release-namespace: nginx-gateway
  labels:
    app.kubernetes.io/managed-by: Helm
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
  parametersRef:
    group: gateway.nginx.org
    kind: NginxProxy
    name: ngf-proxy-config
    namespace: nginx-gateway
```

## NGINX Fabric: Gateway API controller

NGINX Fabric covers most of the core Gateway API features. It also supports custom features using policies.

### Configuration

Most of the Gateway API controllers are installed using `helm`. Before we install it, let's take a look at the [values.yaml](values.yaml)

The Helm chart allows us to configure many options. Some I find quite important:

- Control plane deployment & Service
- Data plane deployment & Service modification
- Ports to use for incoming traffic
- Control Gateway API
  - Default CRDs
  - Default GatewayClass
  - Default Gateways

There are [helm examples](https://github.com/nginx/nginx-gateway-fabric/tree/v2.2.2/examples/helm) on Github maintained by the NGINX community.

Here is the [helm chart documentation](https://github.com/nginx/nginx-gateway-fabric/blob/v2.2.2/charts/nginx-gateway-fabric/README.md)

It's always good to get a grip on the default helm values to see what we can do with the chart.

The values file is used to customize NGINX control & data plane, underlying pods, deployments and services as well as turning features on and off.

We can go ahead and install the controller to start with and use `helm upgrade` to make changes as we need to.

### Installation

Install:

```bash
CHART_VERSION="2.3.0"

helm show values oci://ghcr.io/nginx/charts/nginx-gateway-fabric > nginx-fabric/default-values.yaml

helm show chart oci://ghcr.io/nginx/charts/nginx-gateway-fabric

helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --values nginx-fabric/values.yaml \
  --version $CHART_VERSION \
  --namespace nginx-gateway \
  --create-namespace
```

Upgrade:

```bash
helm upgrade ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
  --values nginx-fabric/values.yaml \
  --version $CHART_VERSION \
  --namespace nginx-gateway
```

Check our installation:

```bash
# check the pods
kubectl -n nginx-gateway get pods

# check the logs 
kubectl -n nginx-gateway logs -l app.kubernetes.io/instance=ngf
```

## Install a NGINX Gateway

So we have the `GatewayClass` managed by the `helm` chart, therefore we skip the `01-gatewayclass.yaml` and go straight to the gateway.

This will deploy NGINX dataplane pods to our target `default` namespace:

```bash
kubectl apply -f nginx-fabric/02-gateway.yaml

# check gateway pods
kubectl get pods 

# check logs
kubectl logs -l app.kubernetes.io/instance=ngf

# port forward for access
kubectl port-forward svc/gateway-api-nginx-gateway 80
```

## Check & Configure the NGINX Dataplane

We can configure our NGINX Gateway, using the `spec.infrastructure.parametersRef` and point a Gateway to a `NginxProxy` resource. We can attach this config to a `Gateway` or `GatewayClass`. This allows us to control specific gateways or all gateways globally.

Let's create a configuration to set the number of replicas on our Gateway deployment and set our service to `ClusterIP` since we don't have a load balancer.

Apply changes:

```bash
kubectl apply -f nginx-fabric/02.1-gateway-config.yaml
```

In addition - When we define `HTTPRoute`'s for our traffic, The NGINX control plane detects those and works with the data plane pods to get an `nginx.conf` for the desired traffic rules.

If you are familiar with NGINX you will know all traffic rules are in the `nginx.conf`. So this solution transforms K8s CRDs to NGINX rules under the hood.

```bash
# get a dataplane pod name
kubectl get pods 
pod=gateway-api-nginx-gateway-5899b6cd6f-dpkbh

# check the generated nginx configuration file
kubectl exec -it -n default $pod -- nginx -T
```

## HTTP Traffic management

Feel free to quickly run through the basic [traffic management table](../README.md#traffic-management-features--http-routes) for using `HTTPRoute` routing for traffic.

**Note**: HTTPRoute features are not specific to this controller and should be available to any other gateway API controller that you choose.

You can use all the HTTPRoute files from the parent directory:
- `03-httproute-by-hostname.yaml`
- `04-httproute-by-path-exact.yaml`
- `05-httproute-by-path-rewrite.yaml`
- `06-httproute-header-modify.yaml`
- `07-httproute-tls.yaml`

Just make sure to update them to use `gatewayClassName: nginx-gateway` instead of `traefik`.

## Policy APIs

Kubernetes Gateway API provides [policy attachment](https://gateway-api.sigs.k8s.io/reference/policy-attachment/) that allows us to augment or add configuration to existing resources.

### Client Settings Policies

`ClientSettingsPolicy` is an NGINX Fabric CRD that allows us to customize how our Gateway behaves with client connections. We can set things like Keep Alive, Timeout settings and HTTP Body sizes. This CRD uses the above-mentioned policy attachment API for Gateway API.

Ensure the policy is accepted:

```bash
kubectl apply -f nginx-fabric/08-clientsettings-keepalive.yaml

# check 
kubectl describe clientsettingspolicies gateway-client-settings
```

Make more than 5 requests and notice every one re-using the connection except for the last:

```bash
# make 6 requests
curl -v http://example-app.com/api/go \
  http://example-app.com/api/go \
  http://example-app.com/api/go \
  http://example-app.com/api/go \
  http://example-app.com/api/go \
  http://example-app.com/api/go

# note connection re-use 
# * Re-using existing connection with host example-app.com
```

### SnippetsFilter API

If you have used the NGINX Ingress controller, you may recall "custom snippets", "server snippets" or "location snippets". `SnippetsFilter` is an API that allows NGINX Gateway Fabric to expose some of NGINX raw configuration for tweaking.

Similar to NGINX Ingress, the NGINX proxy in Gateway Fabric also generates NGINX configuration files as demonstrated earlier. `SnippetsFilter` allows us to insert our own NGINX configuration into these files.

This feature is enabled in our [values.yaml](values.yaml) file.

```bash
kubectl apply -f nginx-fabric/09-snippetsfilter.yaml

# check 
kubectl describe SnippetsFilter custom-snippet
```

## Additional Links

- [NGINX Gateway Fabric Documentation](https://docs.nginx.com/nginx-gateway-fabric/)
- [NGINX Gateway Fabric GitHub](https://github.com/nginx/nginx-gateway-fabric)
- [Gateway API Official Documentation](https://gateway-api.sigs.k8s.io/)
- [Original Source Code](https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/kubernetes/gateway-api/nginx-fabric)
