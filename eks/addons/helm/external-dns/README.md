```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```

```bash
helm upgrade --install external-dns external-dns/external-dns --version 1.7.1 --namespace kube-system  --values values.yaml
```