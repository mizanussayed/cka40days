## Role base access control (RBAC) in Kubernetes
Kubernetes provides a built-in role-based access control (RBAC) mechanism to regulate access to the Kubernetes API. RBAC allows you to define roles and assign them to users or groups, controlling what actions they can perform on various resources within the cluster.
### Key Concepts
- **Role**: A Role defines a set of permissions within a specific namespace. It specifies what actions (verbs) can be performed on which resources.
- **ClusterRole**: Similar to a Role, but it applies to the entire cluster rather than a specific namespace.
- **RoleBinding**: A RoleBinding associates a Role with a user or group within a specific namespace, granting them the permissions defined in the Role.
- **ClusterRoleBinding**: A ClusterRoleBinding associates a ClusterRole with a user or group across the entire cluster.
### Example
Here is an example of how to create a Role, RoleBinding, ClusterRole, and ClusterRoleBinding in Kubernetes.
1. **Create a Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```
2. **Create a RoleBinding**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```
3. **Create a ClusterRole**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["secrets", "pods", "nodes", "deployments"]
  verbs: ["get", "list", "watch", "create", "delete", "update"]
```
4. **Create a ClusterRoleBinding**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
subjects:
- kind: User
  name: admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```
### Applying the Configurations
To apply these configurations, save each YAML snippet to a file (e.g., `role.yaml`, `rolebinding.yaml`, `clusterrole.yaml`, `clusterrolebinding.yaml`) and use the following command:
```bash
kubectl apply -f <filename>
```
Replace `<filename>` with the respective file name.