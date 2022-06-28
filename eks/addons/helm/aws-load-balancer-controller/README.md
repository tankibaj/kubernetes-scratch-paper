```bash
helm repo add eks https://aws.github.io/eks-charts
```

```bash
helm --namespace kube-system upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version 1.4.1 --namespace kube-system  --values values.yaml
```