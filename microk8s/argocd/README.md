```bash
ARGOCD_NAMESPACE=argocd
kubectl create namespace ${ARGOCD_NAMESPACE}
helm upgrade --install argocd argo/argo-cd --version 4.5.0 --namespace ${ARGOCD_NAMESPACE}  --values values.yaml
```