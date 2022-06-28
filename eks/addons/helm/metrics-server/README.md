```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
```

```bash
helm upgrade --install metrics-server metrics-server/metrics-server --version 3.8.2 --namespace kube-system
```