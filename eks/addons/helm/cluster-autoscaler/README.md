```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
```

```bash
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler --version 9.13.1 --namespace kube-system  --values values.yaml
```