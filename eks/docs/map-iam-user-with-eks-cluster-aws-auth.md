### RBAC manifest

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: argo
  name: developer-role
rules:
- apiGroups: ["*"]   # "" indicates the core API group
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer
  namespace: argo
subjects:
- kind: User
  name: developer # "name" is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: developer-role # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

### Backup current aws-auth ConfigMap

```bash
kubectl -n kube-system get configmaps aws-auth -o yaml > aws-auth.yaml
```


### Apply RBAC

```bash
kubectl apply -f rbac.yaml
```


### Update the aws-auth ConfigMap

```bash
 export AWS_REGION=eu-central-1
 export EKS_CLUSTER_NAME=demo-eks-cluster
 export IAM_ROLE_ARN=arn:aws:iam::1111111111111:role/developer
 export ROLE_BINDING_USERNAME=developer
```

```bash
 eksctl create iamidentitymapping \
    --cluster $EKS_CLUSTER_NAME \
    --arn $IAM_ROLE_ARN \
    --username ROLE_BINDING_USERNAME \
    --profile demo_profile
```
