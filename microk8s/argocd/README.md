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
