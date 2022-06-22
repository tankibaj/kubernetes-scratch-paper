```bash
helm repo add argo https://argoproj.github.io/argo-helm
```

```bash
ARGOCD_NAMESPACE=argocd
```

```bash
kubectl create namespace ${ARGOCD_NAMESPACE}
```

```bash
helm upgrade --install argocd argo/argo-cd --version 4.8.3 --namespace ${ARGOCD_NAMESPACE}  --values values.yaml
```

```bash
export ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_ADMIN_PASSWORD
```
