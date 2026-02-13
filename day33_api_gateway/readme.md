# Introduction to Gateway API
[Documentation](https://gateway-api.sigs.k8s.io/)

Gateway API is a SIG-Network project that defines Kubernetes resources for L4/L7 routing. It is designed to be role-oriented, expressive, and extensible.

### We need a Kubernetes cluster
```bash
kind create cluster --name gatewayapi --image kindest/node:v1.34.0
```

## Gateway API CRDs

Gateway API CRDs are not installed by default. You can install them directly, or install a controller that bundles them. The official guide recommends using the Standard channel by default.

[Installing Gateway API](https://gateway-api.sigs.k8s.io/guides/getting-started/#installing-gateway-api)

Install the Standard channel:

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

Standard channel includes stable resources such as `GatewayClass`, `Gateway`, `HTTPRoute`, `GRPCRoute`, and `ReferenceGrant`.

### Verify CRD install and channel

```bash
# list Gateway API CRDs
kubectl get crd | grep gateway.networking.k8s.io

# check installed bundle version and channel
kubectl get crd gatewayclasses.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}{"\n"}{.metadata.annotations.gateway\.networking\.k8s\.io/channel}{"\n"}'
```

## Setup some example applications

The following will deploy a `deployment`, `service` and require `configMap` and `secret` for the applications to work.

```bash
# deploy example apps
kubectl apply -f web-app.yaml
```

Check example apps:

```bash
kubectl get pods
NAME                             READY   STATUS    RESTARTS
python-deploy-54cbfc948b-5ch7w   1/1     Running   0
python-deploy-54cbfc948b-qh22f   1/1     Running   0
web-app-67fbb5d844-68wq4         1/1     Running   0

kubectl get service
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
go-svc       ClusterIP   10.96.173.22    <none>        5000/TCP
python-svc   ClusterIP   10.96.113.49    <none>        5000/TCP
web-app      ClusterIP   10.96.44.18     <none>        80/TCP
```

### Create test Domains

We also need to imagine we have a domain called `example-app.com`, so let's set that up on our `.../etc/hosts` file

```bash
127.0.0.1  example-app.com
127.0.0.1  example-app-go.com
127.0.0.1  example-app-python.com
```

## Install a Gateway API controller

To use the Gateway API features in Kubernetes, you need a controller that implements the above CRDs. here we will use Gateway API controller called Traefik.
A Basic Gateway API controller install:

```bash
CHART_VERSION="37.3.0" # traefik version v3.6.0
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm search repo traefik --versions

helm install traefik traefik/traefik \
  --version $CHART_VERSION \
  --values values.yaml \
  --namespace traefik \
  --create-namespace
```

As we don't have a LoadBalancer service in `kind`, let's `port-forward` so we can pretend we have one

```bash
# check the pods
kubectl -n traefik get pods 

# check the logs 
kubectl -n traefik logs -l app.kubernetes.io/instance=traefik-traefik

# port forward for access
kubectl -n traefik port-forward svc/traefik 80
```

## Install a Gateway Class

To start enabling traffic to our newly created apps, we will start with installing a Gateway Class.

[Documentation](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/)

`GatewayClass` is a cluster-scoped resource defined by the infrastructure provider. This resource represents a class of Gateways that can be instantiated.

```bash
kubectl apply -f traefik/01-gatewayclass.yaml

# check
kubectl get gatewayclass

# describe
kubectl describe gatewayclass
```

## Install a Gateway

Next we need to install a Gateway that implements our Gateway Class.
This gateway lives in the same namespace as the routes and applications

```bash
kubectl apply -f traefik/02-gateway.yaml

# check
kubectl get gateway

# describe
kubectl describe gateway
```

## Traffic Management Features : HTTP Routes

The important fields on HTTP Route we cover here are:

- `parentRefs`
- `sectionName`
- `hostnames`
- `rules`
- `matches`
- `filters`

For traffic management, we can take a look at some basic HTTP routes.

### Route by Hostname

We can route by host. This will route all traffic that matches the `Host` header with the `hostnames` field:

- http://example-app-python.com/ -> http://python-svc:5000
- http://example-app-go.com/ -> http://go-svc:5000

```bash
kubectl apply -f 03-httproute-by-hostname.yaml

# test
curl http://example-app-python.com/
curl http://example-app-go.com/
```

### Route by Path

We can also route by host and path with different matching strategies.

**Exact**:
- http://example-app-python.com/ -> http://python-svc:5000/
- http://example-app-go.com/ -> http://go-svc:5000/

**PathPrefix**:
- http://example-app-python.com/* -> http://python-svc:5000/*
- http://example-app-go.com/* -> http://go-svc:5000/*

```bash
kubectl apply -f 04-httproute-by-path-exact.yaml

# test
curl http://example-app-python.com/
curl http://example-app-go.com/
```

### Route using URL Rewrite

We can rewrite the hostname or URL using URL rewrite. This way, we can combine our services under one domain and our controller can act as a true API gateway:

- http://example-app.com/api/python -> http://python-svc:5000/
- http://example-app.com/api/go -> http://go-svc:5000/

As well as:
- http://example-app.com/api/go/status -> http://go-svc:5000/status

```bash
kubectl apply -f 05-httproute-by-path-rewrite.yaml

# test
curl http://example-app.com/api/python
curl http://example-app.com/api/go
curl http://example-app.com/api/go/status
```

### Request/Response Header Manipulation

With Gateway API, you can modify request and response headers using HTTPRoute filters. Controller support varies; see the [HTTP header modifier guide](https://gateway-api.sigs.k8s.io/guides/http-header-modifier/).

Let's do a basic CORS header modification for our Go HTTPRoute

```bash
kubectl port-forward svc/web-app 8000:80
```

The Header modification:

```bash
kubectl apply -f 06-httproute-header-modify.yaml

# test
curl http://example-app.com/api/go -v
```

### CORS (Experimental Channel)

The CORS filter is an experimental feature in Gateway API. You must install the Experimental channel CRDs and ensure your controller supports it. See the [HTTP CORS guide](https://gateway-api.sigs.k8s.io/guides/http-cors/) for details.

```bash
kubectl apply -f httproute-cors.yaml

# test
curl http://example-app.com/api/go -v
```

### HTTPS and TLS

generate a test TLS cert using [mkcert](https://github.com/FiloSottile/mkcert)

```bash
curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 -o mkcert && chmod +x mkcert && mv mkcert /usr/local/bin/

# linux
export CAROOT=${PWD}/tls
# windows
$env:CAROOT = "${PWD}" + "\tls"

mkcert -key-file tls/key.pem -cert-file tls/cert.pem example-app.com

mkcert -install
```

Now that we have a TLS cert, we can create a Kubernetes secret to store it:

```bash
kubectl create secret tls secret-tls -n default --cert tls/cert.pem --key tls/key.pem
```

We need to:

- Adjust our Gateway, to enable the TLS Listener first!
- Then apply the TLS listener in our HTTP Route to enable TLS, using `sectionName`

```bash
kubectl apply -f 07-httproute-tls.yaml
```

Let's `port-forward` to 443 since that is where TLS is exposed:

```bash
kubectl -n traefik port-forward svc/traefik 443
```

Result:
- https://example-app.com/api/go -> http://go-svc:5000/

See the [official guides](https://gateway-api.sigs.k8s.io/guides/) for more traffic management examples.

## Infrastructure Attributes

A useful feature is the ability to customize infrastructure created for Gateways (for example, cloud load balancers). See [Infrastructure attributes](https://gateway-api.sigs.k8s.io/guides/infrastructure/) for details.

## Gateway API Implementations

Use the [official implementations list](https://gateway-api.sigs.k8s.io/implementations/) to see which controllers are conformant and what features they support.

Local examples in this repo:

| Controller | Docs | Directory |
|------------|------|-----------|
| Traefik | [Traefik Gateway provider docs](https://doc.traefik.io/traefik/v3.6/reference/install-configuration/providers/kubernetes/kubernetes-gateway/) | [traefik](traefik) |
| NGINX Gateway Fabric | [NGINX Gateway Fabric docs](https://docs.nginx.com/nginx-gateway-fabric/) | [nginx-fabric](nginx-fabric) |
| NGINX Ingress migration | [Ingress-NGINX migration guide](https://gateway-api.sigs.k8s.io/guides/getting-started/migrating-from-ingress-nginx/) | [nginx-ingress](nginx-ingress) |

