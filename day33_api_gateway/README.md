# Introduction to Gateway API

[intro](https://youtu.be/q76XVCTDZCY)

In this video, we will dive into the features of Gateway API. Once you finish this video, click [here](https://github.com/marcel-dempers/docker-development-youtube-series/blob/master/kubernetes/gateway-api) to deep dive each of the Gateway API controllers.

[Documentation](https://gateway-api.sigs.k8s.io/)

## We need a Kubernetes cluster

Lets create a Kubernetes cluster to play with using [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)

```bash
kind create cluster --name gatewayapi --image kindest/node:v1.34.0
```

Test our cluster and makes sure `kubectl` is configured for it:

```bash
kubectl get nodes
NAME                       STATUS   ROLES           AGE   VERSION
gatewayapi-control-plane   Ready    control-plane   40s   v1.34.0
```

## Gateway API CRDs

The Kubernetes Gateway API is not installed on kubernetes by default. My guess is it may at some point. For now, we can grab it from the [Gateway API SIGS Guide](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api)

**Important Note**: At the time of recording this guide, we'd like to look at as many features as possible, hence the `experimental` install is used.

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml
```

This will install (Stable Channel):

- Gateway Classes: `kubectl get gatewayclass`
- Gateways: `kubectl get gateway`
- HTTP Routes: `kubectl get httproute`

These APIs are part of the Experimental Channel:

- TLS Routes: `kubectl get tlsroute`
- TCP Routes: `kubectl get tcproute`
- UDP Routes: `kubectl get udproute`

**Note**: Gateway API is very new, and all of the above is subject to change quite rapidly

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
go-deploy-b9c69978d-529qb        1/1     Running   0
go-deploy-b9c69978d-jfb2b        1/1     Running   0
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

We also need to imagine we have a domain called `example-app.com`, so let's set that up on our hosts file

```bash
127.0.0.1  example-app.com
127.0.0.1  example-app-go.com
127.0.0.1  example-app-python.com
```

## Install a Gateway API controller

To use the Gateway API features in Kubernetes, you need a controller that implements the above CRDs. In this introduction guide I will use an existing Gateway API controller called Traefik.

**Note**: Keep in mind that this introduction has no dependency on Traefik specifically, therefore any controller that supports Gateway API can be used. At the bottom of this guide, I will provide guides on each of the popular Gateway API implementations.

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

**Note** that we use a Traefik Class in our example.

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

Next we need to install a Gateway that implements our Gateway Class. **Note** that we use a Traefik Gateway in our example.

[Documentation](https://gateway-api.sigs.k8s.io/api-types/gateway)

This gateway lives in the same namespace as the routes and applications

```bash
kubectl apply -f traefik/02-gateway.yaml

# check
kubectl get gateway

# describe
kubectl describe gateway
```

## Traffic Management Features : HTTP Routes

[Documentation](https://gateway-api.sigs.k8s.io/api-types/httproute/)

The important fields on HTTP Route we will cover:

- `parentRefs`
- `sectionName`
- `hostnames`
- `rules`
- `matches`
- `filters`

For traffic management, we can take a look at some basic HTTP routes.

### Route by Hostname

We can route by host. This will route all traffic that matches the `Host` header with the `hostnames` field:

- http://example-app-python.com/ 👉🏽 http://python-svc:5000
- http://example-app-go.com/ 👉🏽 http://go-svc:5000

```bash
kubectl apply -f 03-httproute-by-hostname.yaml

# test
curl http://example-app-python.com/
curl http://example-app-go.com/
```

### Route by Path

We can also route by host and path with different matching strategies.

**Exact**:
- http://example-app-python.com/ 👉🏽 http://python-svc:5000/
- http://example-app-go.com/ 👉🏽 http://go-svc:5000/

**PathPrefix**:
- http://example-app-python.com/* 👉🏽 http://python-svc:5000/*
- http://example-app-go.com/* 👉🏽 http://go-svc:5000/*

```bash
kubectl apply -f 04-httproute-by-path-exact.yaml

# test
curl http://example-app-python.com/
curl http://example-app-go.com/
```

### Route using URL Rewrite

We can rewrite the hostname or URL using URL rewrite. This way, we can combine our services under one domain and our controller can act as a true API gateway:

- http://example-app.com/api/python 👉🏽 http://python-svc:5000/
- http://example-app.com/api/go 👉🏽 http://go-svc:5000/

As well as:
- http://example-app.com/api/go/status 👉🏽 http://go-svc:5000/status

```bash
kubectl apply -f 05-httproute-by-path-rewrite.yaml

# test
curl http://example-app.com/api/python
curl http://example-app.com/api/go
curl http://example-app.com/api/go/status
```

### Request/Response Header Manipulation

With Gateway API, you can modify request and response headers. This is possible with the `ResponseHeaderModifier` filter.

At the time of this recording, Gateway API does not natively support CORS. Even with it in the Experimental channel, many controllers do not support it yet.

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

### HTTPS and TLS

In my video, I generate a test TLS cert using [mkcert](https://github.com/FiloSottile/mkcert)

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
- https://example-app.com/api/go 👉🏽 http://go-svc:5000/

Checkout [More Official Guides](https://gateway-api.sigs.k8s.io/guides/) on the Kubernetes Gateway API SIGs page.

## Infrastructure Labels

A useful feature is the ability to customize infrastructure under the hood for Gateways. For example, cloud load balancers etc.

We can use [Infrastructure Labels](https://kubernetes.io/blog/2023/11/28/gateway-api-ga/#gateway-infrastructure-labels) to do so. This will set annotations or labels on any infrastructure that gets created.

## Gateway API Controllers Guides

| Controller | Video Guide | Directory |
|------------|-------------|-----------|
| Traefik | Introduction to Traefik Gateway API | traefik |
| Envoy | Introduction to Envoy Gateway API | envoy |
| Istio | Introduction to Istio Gateway API | istio |
| NGINX Fabric | Introduction to NGINX Fabric Gateway API | nginx-fabric |
| Cilium | Introduction to Cilium Gateway API | cilium |
| kgateway | Introduction to kgateway (a.k.a Gloo Gateway) | kgateway |
| Linkerd | Introduction to Linkerd Gateway API | linkerd |

## Additional Links

- [Gateway API Official Documentation](https://gateway-api.sigs.k8s.io/)
- [Gateway API GitHub](https://github.com/kubernetes-sigs/gateway-api)
- [Original Source Code](https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/kubernetes/gateway-api)
