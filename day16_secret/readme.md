## kubernetes Secrets
Kubernetes Secrets are used to store and manage sensitive information, such as passwords, OAuth tokens, and SSH keys. Storing this information in a Secret is safer and more flexible than putting it directly in a Pod definition or in a container image.

### types of Secrets
* generic - Opaque type secret arbitrary user-defined data
* dockercfg - Docker config secret
* tls - TLS secret

### Creating a Secret
```bash
kubectl create secret generic my-secret --from-literal=username=myuser --from-literal=password=mypassword
kubectl create secret tls my-tls-secret --cert=path/to/cert/file --key=path/to/key/file
kubectl create secret docker-registry my-docker-secret --docker-username=myuser --docker-password=mypassword --docker-email=myemail@example.com
```
In the command above,
`generic` type of secret,
 `my-secret` - name of the secret, 
 and we are adding two key-value pairs: `username` and `password`.

## Viewing a Secret
```bash
kubectl get secrets
kubectl describe secret my-secret
```

### Accessing a Secret in a Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mycontainer
    image: myimage
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: username
    envFrom:
    - secretRef:
        name: my-secret
```

## generating a Secret from a file
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: bXl1c2Vy  # base64 encoded value of 'myuser'
  password: bXlwYXNzd29yZA==  # base64 encoded value of 'mypassword'
```

## command to encode a value to base64
```bash
echo -n 'myuser' | base64
```
## command to decode a base64 value
```bash
echo -n 'bXl1c2Vy' | base64 --decode
``` 
here, -n flag is used to avoid adding a newline character at the end of the string.

### Creating keys and certificates for TLS Secret
```bash
openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 365 -out tls.crt
```
This command generates a new RSA private key and a self-signed certificate valid for 365 days. The private key is saved to `tls.key` and the certificate to `tls.crt`.

### Using TLS Secret in a Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tls-pod
spec:
  containers:
  - name: tls-container
    image: nginx
    volumeMounts:
    - name: tls-volume
      mountPath: "/etc/tls"
      readOnly: true
  volumes:
  - name: tls-volume
    secret:
      secretName: my-tls-secret
```
In this example, the TLS secret `my-tls-secret` is mounted as a volume in the Pod at the path `/etc/tls`. The container can then use the TLS certificate and key for secure communications.
