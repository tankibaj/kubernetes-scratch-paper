
```bash
export SERVICE_NAMESPACE=argocd
export SERVICE_NAME=argo-argocd-server
```

```sh
kubectl patch svc $SERVICE_NAME -n $SERVICE_NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
```


```sh
kubectl patch svc $SERVICE_NAME -n $SERVICE_NAME -p '{"spec": {"type": "ClusterIP"}}'
```